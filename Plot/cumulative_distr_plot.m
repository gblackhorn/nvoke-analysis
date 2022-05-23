function [varargout] = cumulative_distr_plot(CellArrayData,varargin)
	% Cumulative distribution plot
	% Input: 
	%	- CellArrayData: each cell contains a group of data. 

	% Defaults
	groupNum = numel(CellArrayData); % number of groups
	groupNames = num2cell([1:groupNum]'); % prepare a single column cell array
	groupNames = cellfun(@(x) num2str(x), groupNames, 'UniformOutput',false); % convert numbers to strings

	colorCombine = '#3D3D3D';
	% colorGroup = {'#A0DFF0', '#F29665', '#6C80BD', '#BD7C6C', '#27418C',...
	% 	'#B1F0C7', '#F276A5', '#79BDB7', '#BD79B5', '#318C85'};
	colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
		'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};
	LineWidth = 2;
	lcn = 'southeast'; % ledgend location. 'southeastoutside'

	plotCombine = true; % true/false. Combine data from all the groups and plot
	combineDataName = 'All';
	plotWhere = [];
	FontSize = 18;
	FontWeight = 'bold';

	% save_fig = false;
	% save_dir = '';

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('groupNames', varargin{ii})
	        groupNames = varargin{ii+1};
	    elseif strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('plotCombine', varargin{ii})
	        plotCombine = varargin{ii+1};
	    elseif strcmpi('FontSize', varargin{ii})
	        FontSize = varargin{ii+1};
	    elseif strcmpi('FontWeight', varargin{ii})
	        FontWeight = varargin{ii+1};
	    end
	end


	%% Main content
	if isempty(plotWhere)
    	f = figure;
    else
    	axes(plotWhere)
    	f = gcf;
    end
    hold(gca, 'on')

	num_group = numel(CellArrayData);
	struct_length = cell(1, num_group);
	data_struct = struct('group', struct_length,...
		'data', struct_length,'f', struct_length, 'x', struct_length);
	dis_idx=[];
	for n = 1:num_group
		data_struct(n).group = groupNames{n};
		data_struct(n).data = CellArrayData{n};
		legendStr = groupNames;
		if ~isempty(data_struct(n).data)
			[data_struct(n).f, data_struct(n).x]= ecdf(data_struct(n).data); % Get the cumulative distribution f at x
		else
			dis_idx = [dis_idx n];
		end
    end
    num_group = num_group-numel(dis_idx);
	data_struct(dis_idx) = [];
	legendStr(dis_idx) = [];

	if plotCombine
        data_reshape = cellfun(@(x) reshape(x,1,[]),CellArrayData,'UniformOutput',false);
		dataAll = [cat(2, data_reshape{:})];
		% dataAll = [cat(1, CellArrayData{:})];
		data_struct_combine.group = combineDataName;
		data_struct_combine.data = dataAll;
		[data_struct_combine.f, data_struct_combine.x]= ecdf(data_struct_combine.data);
		legendStr = ['all', legendStr];

		stairs(gca, data_struct_combine.x, data_struct_combine.f,...
			'color', colorCombine, 'LineWidth', LineWidth);
		hold on
	else
		data_struct_combine = [];
	end

	for pn = 1:num_group
		stairs(gca, data_struct(pn).x, data_struct(pn).f,...
			'color', colorGroup{pn}, 'LineWidth', LineWidth);
		hold on
	end

	legend(legendStr, 'Location', lcn);
	legend('boxoff')
	set(gca,'box','off')
	set(gca, 'FontSize', FontSize)
	set(gca, 'FontWeight', FontWeight)

	varargout{1} = data_struct; 
	varargout{2} = data_struct_combine; 
end