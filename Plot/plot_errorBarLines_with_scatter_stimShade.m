function [varargout] = plot_errorBarLines_with_scatter_stimShade(xDataCells,yDataCells,varargin)
	% Plot the data using lines with error bars. show data points with scatter plot. 

	% xDataCells: each cell contains a group of data
	% yDataCells: each cell contains a group of data. Length of it must be the same as the one of xData

	% Example:
	%		

	% Defaults

	% figure parameters
	unit_width = 0.4; % normalized to display
	unit_height = 0.4; % normalized to display
	column_lim = 1; % number of axes column
	xlabelStr = 'Time (s)';
	ylabelStr = '';
	new_xticksLabel = {};
	xTickAngle = 45;
	legStr = {}; 
	figTitleStr = 'line plots with scatter';

	stimShadeData = {};
	stimShadeColorA = {'#F05BBD','#4DBEEE','#ED8564'};
	shadeHeightScale = 0.05; % percentage of y axes
	shadeGapScale = 0.01; % diff between two shade in percentage of y axes
	% yRangeShade = [];

	errorBarColor = {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'};
	scatterColor = errorBarColor;
	scatterSize = 20;
	scatterAlpha = 0.5;
	FontSize = 14;


	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('legStr', varargin{ii})
	        legStr = varargin{ii+1}; % it has the same length as the xDataCells and yDataCells
	    elseif strcmpi('xlabelStr', varargin{ii})
	        xlabelStr = varargin{ii+1}; 
	    elseif strcmpi('ylabelStr', varargin{ii})
	        ylabelStr = varargin{ii+1};
	    elseif strcmpi('new_xticks', varargin{ii})
	        new_xticks = varargin{ii+1};
	    elseif strcmpi('new_xticksLabel', varargin{ii})
	        new_xticksLabel = varargin{ii+1};
	    elseif strcmpi('xTickAngle', varargin{ii})
	        xTickAngle = varargin{ii+1};
	    elseif strcmpi('figTitleStr', varargin{ii})
	        figTitleStr = varargin{ii+1};
	    elseif strcmpi('stimShadeData', varargin{ii})
	        stimShadeData = varargin{ii+1}; % it has the same length as the xDataCells and yDataCells
	    elseif strcmpi('stimShadeColor', varargin{ii})
	        stimShadeColor = varargin{ii+1};
	    elseif strcmpi('plotWhere', varargin{ii})
	    	plotWhere = varargin{ii+1};
	    end
	end


	% Set up the figure
	if ~exist('plotWhere','var')
		f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
	else
		plotWhere;
	end

	% get the number of data groups (number of lines to be plotted)
	XgroupNum = numel(xDataCells);
	YgroupNum = numel(yDataCells);
	if XgroupNum ~= YgroupNum
		error('numbers of xData and yData must be the same')
	end

	% create a empty array to store the number of data points for each group of data
	% data in the first cell of a group will be used to calculate this 
	% exp. numel(yDataCells{1}{1});
	scatterNum = NaN(1,XgroupNum);
	legStrAll = cell(1,XgroupNum);


	% Calculate the means and standard errors. Plot the error bars with scatter
	hold on
	for gn = 1:XgroupNum
		xData = xDataCells{gn};
		yData = yDataCells{gn};
		[h(gn)] = plot_errorBarLine_with_scatter(xData,yData,...
			'errorBarColor',errorBarColor{gn},'scatterAlpha',scatterAlpha,'scatterSize',scatterSize,...
			'plotWhere',gca);
		scatterNum(gn) = numel(yData{1});
		legStrAll{gn} = sprintf('%s (n=%g)',legStr{gn},scatterNum(gn));
	end
	xlabel(xlabelStr)
	ylabel(ylabelStr)
	title(figTitleStr)
	set(gca, 'FontSize', FontSize)


	% get the y lim
	ylimVal = ylim(gca); 
	yHeight = ylimVal(2)-ylimVal(1);
	shadeHeight = yHeight*shadeHeightScale;
	shadeGap = yHeight*shadeGapScale;


	% draw stimulation shade
	if ~isempty(stimShadeData)
		shadeDataNum = numel(stimShadeData);
		for sn = 1:shadeDataNum
			yRangeShade = [ylimVal(2)-sn*shadeHeight ylimVal(2)-(sn-1)*shadeHeight-shadeGap];

			% get the shade for a single group. It may contains multiple shades (combined stimulations)
			groupShadeData = stimShadeData{sn}.shadeData; 
			for m = 1:numel(groupShadeData)
				draw_WindowShade(gca,groupShadeData{m},'shadeColor',stimShadeColorA{m},'yRange',yRangeShade);
			end
		end
	end


	% Add legend for error bars only
	legend(legStrAll,'Location', 'Best') % 'northeastoutside'

	hold off

	set(gca, 'TickDir', 'out');
	if exist('new_xticks','var')
		xticksVal = new_xticks;
	else
		xticksVal = xData;
	end
	xticks(xticksVal);

	if ~isempty(new_xticksLabel) && numel(xticksVal) == numel(new_xticksLabel)
		xticklabels(new_xticksLabel)
		xtickangle(xTickAngle)
	end


	% statistics
	% run ttest (if the group number is 2) or one-way ANOVA (if the group number is bigger then 2)
	if XgroupNum == 2 % two-sample ttest
		% Discard x positions contain only one group of data
		[commonX,ia,ib] = intersect(xDataCells{1},xDataCells{2},'stable');
		yDataA = yDataCells{1}(ia);
		yDataB = yDataCells{2}(ib);
		[ttest_p,ttest_h] = unpaired_ttest_cellArray(yDataA,yDataB);
		statResult = vertcat(ttest_p,ttest_h);
	elseif XgroupNum > 2 % one-way ANOVA
		statResult = []; % not ready
	else
		statResult = [];
	end

	varargout{1} = statResult;
	varargout{2} = scatterNum;
end
