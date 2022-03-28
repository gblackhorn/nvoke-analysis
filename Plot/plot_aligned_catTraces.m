function [varargout] = plot_aligned_catTraces(alignedData,varargin)
	% Plot aligned traces of a certain event category
	% Note: 'event_type' for alignedData must be 'detected_events'

	% Defaults
	eventCat = 'spon'
	plot_combined_data = true; % plot the mean value of all trace and add a shade using std
	% plot_trace = true; % plot every single event
	y_range = [-20 30];
	sponNorm = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    % if strcmpi('plot_trace', varargin{ii})
	    %     plot_trace = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventCat', varargin{ii})
	        eventCat = varargin{ii+1};
        elseif strcmpi('y_range', varargin{ii})
	        y_range = varargin{ii+1};
        % elseif strcmpi('stimEffectType', varargin{ii})
	       %  stimEffectType = varargin{ii+1};
        elseif strcmpi('sponNorm', varargin{ii})
	        sponNorm = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	% Plot alignedData. Group traces according to stimulation
	% event_type of alignedData is stimWin
	if sponNorm
		y_range = [-5 5]; % overwrite the y range of plot if sponNorm data is used
	end

	[C, ia, ic] = unique({alignedData.stim_name});
	num_C = numel(C);

	f_trace_win = figure;
	fig_position = [0.1 0.1 0.6 0.7];
	set(gcf, 'Units', 'normalized', 'Position', fig_position)
	tile_row_num = 1;
	tlo = tiledlayout(f_trace_win, tile_row_num, num_C);

	for n = 1:num_C
		stimName = C{n};
		IDX_trial = find(ic == n);
		timeInfo = alignedData(IDX_trial(1)).time;
		num_stimTrial = numel(IDX_trial); % number of trials applied with the same stim
		traceData_cell_trials = cell(1, num_stimTrial); 
		
		for nst = 1:num_stimTrial
			traceInfo_trial = alignedData(IDX_trial(nst)).traces;
			num_roi = numel(traceInfo_trial);
			traceData_cell_rois = cell(1, num_roi);
			for nr = 1:num_roi
				eventCat_info = {traceInfo_trial(nr).eventProp.peak_category}
				event_idx = find(contains(eventCat_info,eventCat));
				if ~isempty(event_idx)
					traceData_cell_rois{nr} = traceInfo_trial(nr).value(:,event_idx);
				end
				if sponNorm
					sponAmp = traceInfo_trial(nr).sponAmp;
					traceData_cell_rois{nr} = traceData_cell_rois{nr}/sponAmp;
				end
			end
			traceData_cell_trials{nst} = [traceData_cell_rois{:}];
		end
		traceData_trials = [traceData_cell_trials{:}];
		traceData_trials_mean = mean(traceData_trials, 2, 'omitnan');
		traceData_trials_shade = std(traceData_trials, 0, 2, 'omitnan');

		ax = nexttile(tlo);

		plot_trace(timeInfo, traceData_trials, 'plotWhere', ax,...
			'plot_combined_data', plot_combined_data,...
			'mean_trace', traceData_trials_mean, 'mean_trace_shade', traceData_trials_shade,...
	        'y_range', y_range); % 'y_range', y_range
		titleName = sprintf('%s-%s',stimName,eventCat);
		title(titleName)

	end
	varargout{1} = gcf;
end