function [varargout] = plot_trace(time_info,trace_data,varargin)
	% Plot aligned traces 

	% Defaults
	plotWhere = [];
	plot_combined_data = true; % mean trace for each single group. std・ste value can be used as mean_trace_shade to plot shade
	plot_stim_shade = false; % true/false
	% save_fig = false;
	% save_dir = '';
	mean_trace = [];
	mean_trace_shade = [];
	line_color = '#616887';
	mean_line_color = '#2942BA'; % color of the mean-value trace
	shade_color = '#4DBEEE';
	% stim_shade_color = '#ED8564';
	stim_shade_color = {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'};
	shade_alpha = 0.3;
	line_width = 0.2;
	line_mean_width = 3; % width of the mean-value trace

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1};
	    elseif strcmpi('mean_trace', varargin{ii})
	        mean_trace = varargin{ii+1};
	    elseif strcmpi('mean_trace_shade', varargin{ii})
	        mean_trace_shade = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('line_color', varargin{ii})
	        line_color = varargin{ii+1};
	    elseif strcmpi('mean_line_color', varargin{ii})
	        mean_line_color = varargin{ii+1};
	    elseif strcmpi('shade_color', varargin{ii})
	        shade_color = varargin{ii+1};
	    elseif strcmpi('plot_stim_shade', varargin{ii})
	        plot_stim_shade = varargin{ii+1};
	    elseif strcmpi('stim_range', varargin{ii})
	        stim_range = varargin{ii+1}; % cell array. Each cell contains the start(s) and end(s) ([start end]) of one type of shade
	    elseif strcmpi('y_range', varargin{ii})
	        y_range = varargin{ii+1};
	    end
	end

	if isempty(plotWhere)
		f = figure;
		% hold on
	else
		axes(plotWhere)
	end
	hold on

	% if save_fig && isempty(save_dir)
	% 	save_dir = uigetdir;
	% end

	% f = figure;
	% hold on
	if plot_combined_data
		h_m = plot(time_info, mean_trace,...
			'Color', mean_line_color, 'LineWidth', line_mean_width);


		shade_x = [time_info; flip(time_info)];

		shade_upperline = mean_trace+mean_trace_shade;
		shade_lowerline = mean_trace-mean_trace_shade;
		shade_y = [shade_upperline; flip(shade_lowerline)];
		h_s = patch('XData',shade_x, 'YData', shade_y,...
			'FaceColor', shade_color, 'FaceAlpha', shade_alpha, 'EdgeColor', 'none');
	end

	if isa(trace_data, 'double')
		h = plot(time_info, trace_data, 'LineWidth', line_width, 'Color', line_color);
	elseif isa(trace_data, 'cell')
		group_num = numel(trace_data);
		for n = 1:group_num
			h(n) = plot(time_info, trace_data{n}, 'LineWidth', line_width, 'Color', line_color);
		end
	end
	box off

	if exist('y_range', 'var')
		ylim(y_range);
	end

	if plot_stim_shade
		if exist('stim_range', 'var')
			stimTypeNum = numel(stim_range); % number of stimulation types
			for stn = 1:stimTypeNum
				stimShadeRange = stim_range{stn};
				draw_shade(stimShadeRange, gca, 'shadeColor', stim_shade_color{stn});
			end

			% ax = gca;
			% ymin = ax.YLim(1);
			% ymax = ax.YLim(2);
			% y_set = [ymin ymax ymax ymin];

			% stim_repeat = size(stim_range, 1);
			% stim_shade_x = [];
			% stim_shade_y = [];
			% for s = 1:stim_repeat
			% 	stim_shade_x = [stim_shade_x, repelem(stim_range(s, :), 2)];
			% 	stim_shade_y = [stim_shade_y, y_set];
			% end

			% % stim_shade_x = [stim_range, flip(stim_range)];
			% % stim_shade_y = [ymin, ymin, ymax, ymax];
			% h_s_stim = patch('XData',stim_shade_x, 'YData', stim_shade_y,...
			% 	'FaceColor', stim_shade_color, 'FaceAlpha', shade_alpha, 'EdgeColor', 'none');
		else
			fprintf('Warning: [stim_range] was not input, stim shade was not plotted\n')
			return
	end

	chi=get(gca, 'Children');
	set(gca, 'Children',flipud(chi));
	set(gca,'Xtick',[time_info(1):1:time_info(end)])
	% set(gca,'XtickLabel',time_info(1):1:time_info(end))


end