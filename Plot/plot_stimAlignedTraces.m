function [varargout] = plot_stimAlignedTraces(alignedData,varargin)
	% Plot traces around stimulation window
	% Note: 'event_type' for alignedData must be 'stimWin'

	% alignedData: multiple trials

	% Defaults
	plot_combined_data = true;
	plot_stim_shade = true;
	y_range = [-20 30];
	stimEffectType = 'excitation'; % options: 'excitation', 'inhibition', 'rebound'
	sponNorm = false; % true/false
	stimNames = {};

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1}; % 
        elseif strcmpi('plot_stim_shade', varargin{ii})
	        plot_stim_shade = varargin{ii+1};
        elseif strcmpi('y_range', varargin{ii})
	        y_range = varargin{ii+1};
        elseif strcmpi('stimEffectType', varargin{ii})
	        stimEffectType = varargin{ii+1};
        elseif strcmpi('sponNorm', varargin{ii})
	        sponNorm = varargin{ii+1};
        elseif strcmpi('section', varargin{ii})
	        section = varargin{ii+1}; % double/vector. specify the n-th repeat of stimulation
        elseif strcmpi('stimNames', varargin{ii})
	        stimNames = varargin{ii+1}; 
	    end
	end	

	%% Content
	% Plot alignedData. Group traces according to stimulation
	% event_type of alignedData is stimWin
	if sponNorm
		y_range = [-5 5]; % overwrite the y range of plot if sponNorm data is used
	end

	[C, ia, ic] = unique({alignedData.stim_name});
	if ~isempty(stimNames)
		[stimNames,stimNameIDXinC,~]=intersect(C, stimNames);
	else
		stimNames = C;
		% C = stimNames;
	end
	stimNum = numel(stimNames);

	f_trace_win = figure;
	fig_position = [0.1 0.1 0.6 0.7];
	set(gcf, 'Units', 'normalized', 'Position', fig_position)
	if isempty(stimEffectType)
		tile_row_num = 1;
	else
		tile_row_num = 2;
	end
	tlo = tiledlayout(f_trace_win, tile_row_num, stimNum);

	for n = 1:stimNum
		% stimName = C{n};
		stimName = C{stimNameIDXinC(n)};
		IDX_trial = find(ic == stimNameIDXinC(n));
		timeInfo = alignedData(IDX_trial(1)).time;
		stim_range = {alignedData(IDX_trial(1)).stimInfo.UnifiedStimDuration.range_aligned};
		% stim_range = {alignedData(IDX_trial(1)).stimInfo.time_range};
		num_stimTrial = numel(IDX_trial); % number of trials applied with the same stim
		traceData_cell_trials_g1 = cell(1, num_stimTrial); 
		traceData_cell_trials_g2 = cell(1, num_stimTrial); 
		
		for nst = 1:num_stimTrial
			traceInfo_trial = alignedData(IDX_trial(nst)).traces;
			num_roi = numel(traceInfo_trial);
			traceData_cell_rois_g1 = cell(1, num_roi);
			traceData_cell_rois_g2 = cell(1, num_roi);
			for nr = 1:num_roi
				if exist('section','var') && ~isempty(section)
					traceVal = traceInfo_trial(nr).value(:,section);
				else
					traceVal = traceInfo_trial(nr).value;
				end
				if isempty(stimEffectType)
					traceData_cell_rois_g1{nr} = traceVal;
				else
					if traceInfo_trial(nr).stimEffect.(stimEffectType)
						traceData_cell_rois_g1{nr} = traceVal;
					else
						traceData_cell_rois_g2{nr} = traceVal;
					end
				end
				if sponNorm
					sponAmp = traceInfo_trial(nr).sponAmp;
					traceData_cell_rois_g1{nr} = traceData_cell_rois_g1{nr}/sponAmp;
					traceData_cell_rois_g2{nr} = traceData_cell_rois_g2{nr}/sponAmp;
				end
			end
			traceData_cell_trials_g1{nst} = [traceData_cell_rois_g1{:}];
			traceData_cell_trials_g2{nst} = [traceData_cell_rois_g2{:}];
		end
		traceData_trials_g1 = [traceData_cell_trials_g1{:}];
		traceData_trials_g1_mean = mean(traceData_trials_g1, 2, 'omitnan');
		traceData_trials_g1_shade = std(traceData_trials_g1, 0, 2, 'omitnan');

		ax = nexttile(tlo);
		plot_trace(timeInfo, traceData_trials_g1, 'plotWhere', ax,...
			'plot_combined_data', plot_combined_data,...
			'mean_trace', traceData_trials_g1_mean, 'mean_trace_shade', traceData_trials_g1_shade,...
			'plot_stim_shade', plot_stim_shade, 'stim_range', stim_range,...
	        'y_range', y_range); % 'y_range', y_range
		if ~isempty(stimEffectType)
			titleName_g1 = sprintf('%s: %s', stimName, stimEffectType);
		else
			titleName_g1 = stimName;
		end
		title(titleName_g1)

		traceData_trials_g2 = [traceData_cell_trials_g2{:}];
		if ~isempty(traceData_trials_g2)
			traceData_trials_g2_mean = mean(traceData_trials_g2, 2, 'omitnan');
			traceData_trials_g2_shade = std(traceData_trials_g2, 0, 2, 'omitnan');

			ax = nexttile(tlo);
			plot_trace(timeInfo, traceData_trials_g2, 'plotWhere', ax,...
				'plot_combined_data', plot_combined_data,...
				'mean_trace', traceData_trials_g2_mean, 'mean_trace_shade', traceData_trials_g2_shade,...
				'plot_stim_shade', plot_stim_shade, 'stim_range', stim_range,...
		        'y_range', y_range); % 'y_range', y_range
			titleName_g2 = sprintf('%s: %s-negative ', stimName, stimEffectType);
			title(titleName_g2)
		end
	end
	varargout{1} = gcf;
end