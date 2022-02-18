function [varargout] = plot_trace_trial(alignedData,varargin)
	% Plot aligned traces from a single trial
	% Use alignedData (output of [get_event_trace_trial]) or a single component of alignedData_allTrials (output of [get_event_trace_allTrials])


	% Defaults
	plotWhere = [];
	plot_combined_data = true; % mean trace for each single group. std・ste value can be used as mean_trace_shade to plot shade
	plot_stim_shade = true;
	% save_fig = false;
	% save_dir = '';
	mean_trace = [];
	mean_trace_shade = [];
	stim_range = [];
	line_color = '#616887';
	mean_line_color = '#2942BA'; % color of the mean-value trace
	shade_color = '#4DBEEE';
	stim_shade_color = '#EFB188';
	shade_alpha = 0.5;
	line_width = 0.5;
	line_mean_width = 1; % width of the mean-value trace

	subplot_row_num = 4;
	subplot_col_num = 4;
	subplot_num = subplot_col_num*subplot_row_num;

	y_range = [-10 10];

	save_fig = false;
	save_dir = '';
	% dt = datestr(now, 'yyyymmdd');

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1};
	    elseif strcmpi('mean_trace', varargin{ii})
	        mean_trace = varargin{ii+1};
	    elseif strcmpi('mean_trace_shade', varargin{ii})
	        mean_trace_shade = varargin{ii+1};
	    % elseif strcmpi('save_fig', varargin{ii})
	    %     save_fig = varargin{ii+1};
	    % elseif strcmpi('save_dir', varargin{ii})
	    %     save_dir = varargin{ii+1};
	    elseif strcmpi('line_color', varargin{ii})
	        line_color = varargin{ii+1};
	    elseif strcmpi('mean_line_color', varargin{ii})
	        mean_line_color = varargin{ii+1};
	    elseif strcmpi('shade_color', varargin{ii})
	        shade_color = varargin{ii+1};
	    elseif strcmpi('plot_stim_shade', varargin{ii})
	        plot_stim_shade = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	if save_fig && isempty(save_dir)
		save_dir = uigetdir(save_dir,...
			'Choose a folder to save plots');
		if save_dir == 0
			disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false')
			return
		end
	end

	time_info = alignedData.time;
	roi_num = numel(alignedData.traces);
	figure_num = ceil(roi_num/subplot_num);
	trialName = alignedData.trialName;
	stim_name = alignedData.stim_name;
	fovID = alignedData.fovID;
	event_type = alignedData.event_type;
	cat_keywords = alignedData.cat_keywords;
	switch event_type
		case 'detected_events'
			if ~isempty(cat_keywords)
				cat_joined = strjoin(cat_keywords);
			else
				cat_joined = 'none';
			end
			sgtitle_ext = sprintf('stim: %s  %s filtered by keywords [%s]', stim_name, event_type, cat_joined);
			plot_stim_shade = false;

			filename_ext = sprintf('%s-%s-%s-stim-%s', trialName, fovID, stim_name, cat_joined);
		case 'stimWin'
			sgtitle_ext = sprintf('stim: %s  around stimulation window', stim_name);
			plot_stim_shade = true;
			stim_range = {alignedData.stimInfo.time_range};

			filename_ext = sprintf('%s-%s-%s-stim-window', trialName, fovID, stim_name);
	end

	for fn = 1:figure_num
		f(fn) = figure;
		set(gcf, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8])
		if fn == figure_num
			subplot_num_this_fig = roi_num-(fn-1)*subplot_num;
		else
			subplot_num_this_fig = subplot_num;
		end
		for sn = 1:subplot_num_this_fig
			
			roiData_num = (fn-1)*subplot_num+sn;
			roiData_struct = alignedData.traces(roiData_num);
			roi_name = roiData_struct.roi;
			trace_data = roiData_struct.value;
			mean_trace = roiData_struct.mean_val;
			mean_trace_shade = roiData_struct.std_val;
			subplot(subplot_row_num, subplot_col_num, sn);
			plot_trace(time_info, trace_data, 'plotWhere', gca,...
				'plot_combined_data', plot_combined_data,...
				'mean_trace', mean_trace, 'mean_trace_shade', mean_trace_shade,...
				'plot_stim_shade', plot_stim_shade, 'stim_range', stim_range, 'y_range', y_range);
			title(roi_name);
		end
		% sgtitleStr = strrep(sprintf('%s  %s', trialName, sgtitle_ext), '_', '-');
		sgtitleStr = strrep({[trialName, ' ', fovID], sgtitle_ext}, '_', '-');
		sgtitle(sgtitleStr, 'FontSize', 14);

		if save_fig
			filename = sprintf('%s-%d', filename_ext, fn);
			filename = replace(filename, '_', '-');
			filepath = fullfile(save_dir, filename);
			savefig(gcf, [filepath, '.fig']);
			saveas(gcf, [filepath, '.jpg']);
			saveas(gcf, [filepath, '.svg']);
		end
	end

	% group mean traces of all ROIs and plot
	mean_trace_data_all = [alignedData.traces.mean_val];
	mean_of_meanTrace = mean(mean_trace_data_all, 2);
	std_of_meanTrace = std(mean_trace_data_all, 0, 2);
	plot_trace(time_info, mean_trace_data_all,...
		'plot_combined_data', plot_combined_data,...
		'mean_trace', mean_of_meanTrace, 'mean_trace_shade', std_of_meanTrace,...
		'plot_stim_shade', plot_stim_shade, 'stim_range', stim_range, 'y_range', y_range);
	title(sgtitleStr);

	if save_fig
		groupmean_filepath = fullfile(save_dir, ['groupmean-', filename_ext]);
		savefig(gcf, [groupmean_filepath, '.fig']);
		saveas(gcf, [groupmean_filepath, '.jpg']);
		saveas(gcf, [groupmean_filepath, '.svg']);
	end
	% if save_fig && isempty(save_dir)
	% 	save_dir = uigetdir;
	% end

end