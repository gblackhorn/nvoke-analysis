function [data_struct,varargout] = plot_event_info_bar(event_info_struct,par_name,varargin)
	% Bar plot to show event info
	% Input: 
	%	- structure array(s) with field "group" and "event_info"  
	%	- "par_name" is one of the fieldnames of "event_info" 
	%		- rise_duration_mean
	%		- peak_mag_mean
	%		- peak_mag_norm_mean
	%		- peak_slope_mean
	% Output:
	%	- bar info including mean value and standard error
	%	- event interval histogram

	% Defaults
	save_fig = false;
	save_dir = '';

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    end
	end

	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end


	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);

	data_struct = struct('group', struct_length_size,...
		'mean_value', struct_length_size, 'ste', struct_length_size);


	% all data
	data_cell = cell(1, group_num);
	for n = 1:group_num
		data_cell{n} = [event_info_struct(n).event_info.(par_name)];
	end
	data_all = [data_cell{:}];
	data_struct(1).group = 'all';
	data_struct(1).mean_value = mean(data_all);
	data_struct(1).ste = std(data_all)/sqrt(numel(data_all));

	
	for n = 1:group_num
		group_data = data_cell{n};
		data_struct(n+1).group = event_info_struct(n).group;

		data_struct(n+1).mean_value = mean(group_data);
		data_struct(n+1).ste = std(group_data)/sqrt(numel(group_data));
	end

	title_str = ['Bar-plot: ', par_name]; 
	title_str = replace(title_str, '_', '-');
	figure('Name', title_str);
	hold on

	group_names = {data_struct(2:end).group};
	x = [1:1:group_num];
	y = cat(2, data_struct(2:end).mean_value);
	y_error = cat(2, data_struct(2:end).ste);

	fb = bar(x, y);
	ax.XTick = x;
	set(gca, 'XTick', [1:1:group_num]);
	set(gca, 'xticklabel', group_names);
	fe = errorbar(x, y, y_error, 'LineStyle', 'None');
	set(fe,'Color', 'k', 'LineWidth', 2, 'CapSize', 10);

	title(title_str)

	hold off

	if save_fig
		title_str = replace(title_str, ':', '-');
		fig_path = fullfile(save_dir, title_str);
		savefig(gcf, [fig_path, '.fig']);
		saveas(gcf, [fig_path, '.jpg']);
		saveas(gcf, [fig_path, '.svg']);
	end
	
end