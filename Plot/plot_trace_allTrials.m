function [varargout] = plot_trace_allTrials(alignedData_allTrials,varargin)
	% Plot aligned traces from a all trials. Traces in ROIs from each single trial are grouped
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

	subplot_row_num = 3;
	subplot_col_num = 3;
	subplot_num = subplot_col_num*subplot_row_num;

	save_fig = false;
	save_dir = '';

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
	if save_fig 
		save_dir = uigetdir(save_dir,...
			'Choose a folder to save plots');
		varargout{1} = save_dir;
		if save_dir == 0
			disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false')
			varargout{1} = save_dir;
			return
		end
	end


	trial_num = numel(alignedData_allTrials);
	figure_num = ceil(trial_num/subplot_num);

	for fn = 1:figure_num
		f(fn) = figure;
		set(gcf, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8])
		if fn == figure_num
			subplot_num = trial_num-(fn-1)*subplot_num;
		end

		for sn = 1:subplot_num
			trial_n = (fn-1)*subplot_num+sn;
			alignedData = alignedData_allTrials(trial_n);
			trialName = alignedData.trialName;
			stim_name = alignedData.stim_name;
			event_type = alignedData.event_type;
			cat_keywords = alignedData.cat_keywords;

			time_info = alignedData.time;
			trace_data = alignedData.traces;
			grouped_traces = [trace_data.value];
			mean_grouped_traces = mean(grouped_traces, 2);
			std_grouped_traces = std(grouped_traces, 0, 2);

			switch event_type
				case 'detected_events'
					if ~isempty(cat_keywords)
						cat_joined = strjoin(cat_keywords);
					else
						cat_joined = 'none';
					end
					title_str = sprintf('%s \nstim: %s  %s filtered by keywords [%s]', trialName, stim_name, event_type, cat_joined);
					plot_stim_shade = false;
				case 'stimWin'
					title_str = sprintf('%s \nstim: %s  around stimulation window', trialName, stim_name);
					plot_stim_shade = true;
					stim_range = alignedData.stimInfo.time_range;
			end

			subplot(subplot_row_num, subplot_col_num, sn);
			plot_trace(time_info, grouped_traces, 'plotWhere', gca,...
				'plot_combined_data', plot_combined_data,...
				'mean_trace', mean_grouped_traces, 'mean_trace_shade', std_grouped_traces,...
				'plot_stim_shade', plot_stim_shade, 'stim_range', stim_range);
			title(strrep(title_str, '_', '-'));
		end

		if save_fig 
			dt = datestr(now, 'yyyymmdd');
			switch event_type
				case 'detected_events'
					filename = sprintf('%s-%s-stim-%s-%d', dt,stim_name, cat_joined, fn);
				case 'stimWin'
					filename = sprintf('%s-%s-stim-window-%d', dt, stim_name, fn);
			end
			filename = replace(filename, '_', '-');
			filepath = fullfile(save_dir, filename);
			savefig(gcf, [filepath, '.fig']);
			saveas(gcf, [filepath, '.jpg']);
			saveas(gcf, [filepath, '.svg']);
		end
	end

	% if save_fig && isempty(save_dir)
	% 	save_dir = uigetdir;
	% end

end