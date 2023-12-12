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
	fname_suffix = '';

	unit_width = 0.4; % normalized to display
	unit_height = 0.4; % normalized to display
	column_lim = 2; % number of axes column

	marker_size = 10;
	marker_face_alpha = 1;
	marker_edge_alpha = 0;
	FontSize = 18;
	FontWeight = 'bold';
	LineWidth = 1.5;

% 	colorGroup = {'#A0DFF0', '#F29665', '#6C80BD', '#BD7C6C', '#27418C',...
% 		'#B1F0C7', '#F276A5', '#79BDB7', '#BD79B5', '#318C85'};
    
    colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};

	linearFit = true; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('plotwhere', varargin{ii})
	        plotwhere = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('fname_suffix', varargin{ii})
	        fname_suffix = varargin{ii+1};
	    elseif strcmpi('linearFit', varargin{ii})
	        linearFit = varargin{ii+1};
	    elseif strcmpi('FontSize', varargin{ii})
	        FontSize = varargin{ii+1};
	    elseif strcmpi('FontWeight', varargin{ii})
	        FontWeight = varargin{ii+1};
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

	
	if ~isempty(fname_suffix)
		title_str = sprintf('Scatter-plot: %s vs %s - %s', par_name_1, par_name_2, fname_suffix); 
	else
		title_str = sprintf('Scatter-plot: %s vs %s', par_name_1, par_name_2); 
	end
	title_str = replace(title_str, '_', '-');

	% Create a figure if no handle is input. Check if the handle is a figure if it is input
	if ~exist('plotwhere','var')
		figure('Name', title_str);
		% ax = gca;
	else
		if ~isa(plotwhere, 'matlab.ui.Figure')
			error('varargin for plotwhere must be a figure handle when linearFit is true')
		else
			plotwhere;
		end
		% ax = plotwhere;
	end

	% If fitting data to a linear model, create another axes for a table showing the fitting info
	if linearFit
		axNum = 2;
	else
		axNum = 1;
	end

	% Adjust the size of the figure 
	f = fig_canvas(axNum,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim,...
		'figHandle',gcf);
	fTile = tiledlayout(f,1,axNum);

	% polyCoef = cell(1,group_num); % coefficients for a polynomial fit
	% errEstStruct = cell(1,group_num); % a structure S that can be used as an input to polyval to obtain error estimates
	% yFit = cell(1,group_num); % y_fitted
	PearsonCorrCoef = nan(1,group_num);
	rsq = nan(1,group_num);
	PearsonCorrCoefPval = nan(1,group_num);

	scatterAx = nexttile(fTile,1);
	hold on
	for n = 1:group_num
		group_data_1 = data_cell_1{n};
		group_data_2 = data_cell_2{n};

		data_struct(n+1).group = event_info_struct(n).group;

		data_struct(n+1).par_name_1 = group_data_1;
		data_struct(n+1).par_name_2 = group_data_2;

		% Scatter plot
		h(n) = stylishScatter(group_data_1, group_data_2, 'plotWhere', scatterAx,...
			'MarkerSize', marker_size, 'FontSize', FontSize, 'LineWidth', LineWidth,...
			'MarkerEdgeColor', colorGroup{n}, 'MarkerFaceColor', colorGroup{n},...
			'MarkerFaceAlpha',marker_face_alpha,'MarkerEdgeAlpha',marker_edge_alpha);

		% Fitting linear model to Data
		if linearFit
			% Fit data and plot it as a line
			[yFit,PearsonCorrCoef(n),rsq(n),PearsonCorrCoefPval(n)] = LinearFitPlotTest(group_data_1,group_data_2,...
				'plotLine',linearFit,'plotWhere',scatterAx,'LineColor',colorGroup{n});
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

	% Show the stat information about the fitting (Pearson test, R-square) in a table
	if linearFit
		fitStatAx = nexttile(fTile,2);
		fitStat = struct('group',legendstr,...
			'PearsonCorrCoef',num2cell(PearsonCorrCoef(:)),'PearsonCorrCoefPval',num2cell(PearsonCorrCoefPval(:)),...
			'rsq',num2cell(rsq(:)));
		fitStatTab = struct2table(fitStat);
		plotUItable(gcf,gca,fitStatTab);
		title('stat for linear fit')
	end


	if save_fig
		title_str = replace(title_str, ':', '-');
		fig_path = fullfile(save_dir, title_str);
		savefig(gcf, [fig_path, '.fig']);
		saveas(gcf, [fig_path, '.jpg']);
		saveas(gcf, [fig_path, '.svg']);
	end
end