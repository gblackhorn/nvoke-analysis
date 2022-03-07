function [varargout] = plot_trace_with_rangeShade(time_info,trace_data,shade_val,plotWhere,varargin)
	% Plot a trace and a shade to show its range on y direction

	% time_info: vector. x-axis data
	% trace_data: vector. y-axis data
	% shade_val: vector. same size as time_info and trace_data. std of raw data used to calculate trace_data is often used

	% Defaults
	line_color = '#2942BA';
	line_width = 3; % width of the mean-value trace
	shade_color = '#4DBEEE';
	shade_alpha = 0.3;

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('shade_color', varargin{ii})
	        shade_color = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('shade_alpha', varargin{ii})
	        shade_alpha = varargin{ii+1};
	    end
	end	


	%% Content
	shade_x = [time_info; flip(time_info)];
	shade_upperline = trace_data+shade_val;
	shade_lowerline = trace_data-shade_val;
	shade_y = [shade_upperline; flip(shade_lowerline)];

	if isempty(plotWhere)
		f = figure;
		% hold on
	else
		axes(plotWhere)
	end
	hold on

	h_m = plot(time_info, trace_data,...
			'Color', line_color, 'LineWidth', line_width);
	h_s = patch('XData',shade_x, 'YData', shade_y,...
			'FaceColor', shade_color, 'FaceAlpha', shade_alpha, 'EdgeColor', 'none');
	hold off
end