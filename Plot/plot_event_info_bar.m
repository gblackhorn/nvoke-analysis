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
	stat = false; % true if want to run anova
	stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

	TickAngle = 45;
	EdgeColor = 'none';
	FaceColor = '#4D4D4D';
	FontSize = 12;
	FontWeight = 'bold';

	plotWhere = [];

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('stat', varargin{ii})
	        stat = varargin{ii+1};
	    elseif strcmpi('stat_fig', varargin{ii})
	        stat_fig = varargin{ii+1};
	    elseif strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('FontSize', varargin{ii})
	        FontSize = varargin{ii+1};
	    elseif strcmpi('FontWeight', varargin{ii})
	        FontWeight = varargin{ii+1};
	    end
	end

	%% ====================
	% Main content
	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end

	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);

	data_struct = struct('group', struct_length_size,...
		'mean_value', struct_length_size, 'ste', struct_length_size);


	% all data
	data_cell = cell(1, group_num);
	data_cell_group = cell(1, group_num);
	for n = 1:group_num
		data_cell{n} = [event_info_struct(n).event_info.(par_name)];
		data_cell_group{n} = cell(size(data_cell{n}));
		data_cell_group{n}(:) = {event_info_struct(n).group}; 
	end
	data_all = [data_cell{:}]; % data_all and data_all_group will be used for annova 
	data_all_group = [data_cell_group{:}];
	data_struct(1).group = 'all';
	data_struct(1).mean_value = mean(data_all, 'omitnan');
	data_struct(1).std = std(data_all, 'omitnan');
	data_struct(1).ste = data_struct(1).std/sqrt(numel(data_all));
	data_struct(1).data.val = data_all;
	data_struct(1).data.group = data_all_group;
	data_struct(1).n_num = numel(data_all);

	
	for n = 1:group_num
		group_data = data_cell{n};
		data_struct(n+1).group = event_info_struct(n).group;

		data_struct(n+1).mean_value = mean(group_data, 'omitnan');
		data_struct(n+1).std = std(group_data, 'omitnan');
		data_struct(n+1).ste = data_struct(n+1).std/sqrt(numel(group_data));
		data_struct(n+1).n_num = numel(group_data);

		% data_struct(n+1).data = group_data(:);
	end

	if isempty(plotWhere)
    	f = figure;
    else
    	axes(plotWhere)
    	f = gcf;
    end

	% title_str = ['Bar-plot: ', par_name]; 
	% title_str = replace(title_str, '_', '-');
	% figure('Name', title_str);
	

	group_names = {data_struct(2:end).group};
	x = [1:1:group_num];
	y = cat(2, data_struct(2:end).mean_value);
	y_error = cat(2, data_struct(2:end).ste);
	n_num_str = num2str([data_struct(2:end).n_num]');

	fb = bar(x, y,...
		'EdgeColor', EdgeColor, 'FaceColor', FaceColor);
	hold on

	yl = ylim;
	yloc = yl(1)+0.05*(yl(2)-yl(1));
	yloc_array = repmat(yloc, 1, numel(x));
	text(x,yloc_array,n_num_str,'vert','bottom','horiz','center', 'Color', 'white');

	ax.XTick = x;
	set(gca, 'box', 'off')
	set(gca, 'FontSize', FontSize)
	set(gca, 'FontWeight', FontWeight)
	xtickangle(TickAngle)
	set(gca, 'XTick', [1:1:group_num]);
	set(gca, 'xticklabel', group_names);
	fe = errorbar(x, y, y_error, 'LineStyle', 'None');
	set(fe,'Color', 'k', 'LineWidth', 2, 'CapSize', 10);

	% title(title_str)

	hold off

	if save_fig
		title_str = replace(title_str, ':', '-');
		fig_path = fullfile(save_dir, title_str);
		savefig(gcf, [fig_path, '.fig']);
		saveas(gcf, [fig_path, '.jpg']);
		saveas(gcf, [fig_path, '.svg']);
	end

	p = NaN;
	tbl = NaN;
	statsInfo = NaN; 
	c = NaN;
	gnames = NaN;
	if stat && group_num>1% run one-way anova or not
		[statInfo] = anova1_with_multiComp(data_all,data_all_group,'displayopt',stat_fig);
	else
		statInfo.anova_p = p; % p-value of anova test
		statInfo.tbl = tbl; % anova table
		statInfo.stats = statsInfo; % structure used to perform  multiple comparison test (multcompare)
		statInfo.multCompare = c; % result of multiple comparision test.
		statInfo.multCompare_gnames = gnames; % group names. Use this to decode the first two columns of c

		% [p,tbl,stats] = anova1(data_all, data_all_group, stat_fig);
		% if stats.df~=0
		% 	[c,~,~,gnames] = multcompare(stats, 'Display', stat_fig); % multiple comparison test. Check if the difference between groups are significant
		% 	% 'tukey-kramer'
		% 	% The first two columns of c show the groups that are compared. 
		% 	% The fourth column shows the difference between the estimated group means. 
		% 	% The third and fifth columns show the lower and upper limits for 95% confidence intervals for the true mean difference. 
		% 	% The sixth column contains the p-value for a hypothesis test that the corresponding mean difference is equal to zero. 

		% 	% convert c to a table
	    %     c = num2cell(c);
		% 	c(:, 1:2) = cellfun(@(x) gnames{x}, c(:, 1:2), 'UniformOutput',false);
		% 	c = cell2table(c,...
		% 		'variableNames', {'g1', 'g2', 'lower-confi-int', 'estimate', 'upper-confi-int', 'p'});
		% 	h = NaN(size(c, 1), 1);
		% 	idx_sig = find(c.p < 0.05);
		% 	idx_nonsig = find(c.p >= 0.05);
		% 	h(idx_sig) = 1;
		% 	h(idx_nonsig) = 0;
		% 	c.h = h;
		% end
	end

	% statInfo.anova_p = p; % p-value of anova test
	% statInfo.tbl = tbl; % anova table
	% statInfo.stats = statsInfo; % structure used to perform  multiple comparison test (multcompare)
	% statInfo.multCompare = c; % result of multiple comparision test.
	% statInfo.multCompare_gnames = gnames; % group names. Use this to decode the first two columns of c

	varargout{1} = statInfo;
end