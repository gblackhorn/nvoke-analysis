function [data_struct,varargout] = plot_event_info_scatter(event_info_struct,par_name_1, par_name_2,varargin)
	% Scatter plot to show event info
	% Input: 
	%	- structure array(s) with field "group" and "event_info"  
	%	- "par_name_1" and "par_name_2" are the fieldnames of "event_info" 
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
	marker_size = 40;
	marker_face_alpha = 1;
	marker_edge_alpha = 0;
% 	colorGroup = {'#A0DFF0', '#F29665', '#6C80BD', '#BD7C6C', '#27418C',...
% 		'#B1F0C7', '#F276A5', '#79BDB7', '#BD79B5', '#318C85'};
    
    colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};

	linearFit = true; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('linearFit', varargin{ii})
	        linearFit = varargin{ii+1};
	    end
	end

	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end


	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);

	data_struct = struct('group', struct_length_size,...
		par_name_1, struct_length_size, par_name_2, struct_length_size);


	% all data
	data_cell_1 = cell(1, group_num);
	data_cell_2 = cell(1, group_num);
	dis_idx = [];
	for n = 1:group_num
		data_cell_1{n} = [event_info_struct(n).event_info.(par_name_1)];
		data_cell_2{n} = [event_info_struct(n).event_info.(par_name_2)];
		if isempty(data_cell_1{n}) || isempty(data_cell_2{n})
			dis_idx = [dis_idx n];
		end
	end
	group_num = group_num-numel(dis_idx);
	data_cell_1(dis_idx) = [];
	data_cell_2(dis_idx) = [];
	event_info_struct(dis_idx) = [];
	data_struct(dis_idx) = [];

	data_all_1 = [data_cell_1{:}];
	data_all_2 = [data_cell_2{:}];
	data_struct(1).group = 'all';
	data_struct(1).(par_name_1) = data_all_1;
	data_struct(1).(par_name_2) = data_all_2;

	
	title_str = sprintf('Scatter-plot: %s vs %s', par_name_1, par_name_2); 
	title_str = replace(title_str, '_', '-');
	figure('Name', title_str);
	hold on
	for n = 1:group_num
		group_data_1 = data_cell_1{n};
		group_data_2 = data_cell_2{n};

		data_struct(n+1).group = event_info_struct(n).group;

		data_struct(n+1).par_name_1 = group_data_1;
		data_struct(n+1).par_name_2 = group_data_2;

		h(n) = scatter(group_data_1, group_data_2,...
			marker_size, 'filled', 'MarkerFaceColor', colorGroup{n},...
			'MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);
		if linearFit
			p{n} = polyfit(group_data_1, group_data_2, 1);
			f{n} = polyval(p{n}, group_data_1);
			plot(group_data_1, f{n}, '-', 'Color', colorGroup{n}, 'LineWidth', 2); 
		end
	end

	legendstr = {data_struct(2:end).group}';
	legend(h(1:group_num), legendstr);
	par_name_1 = replace(par_name_1, '_', '-');
	par_name_2 = replace(par_name_2, '_', '-');
	xlabel(par_name_1);
	ylabel(par_name_2);
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