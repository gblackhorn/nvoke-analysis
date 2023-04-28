function [varargout] = plot_diff_usingRawData(xData,DataA,DataB,varargin)
	% Plot the data in group A and group B using line plots, and display the difference
	% (meanB-meanA) using a bar plot. 

	% Use varargin to input error values to plot error bars

	% Example:
	%		

	% Defaults
	legStrA = 'groupA';
	legStrB = 'groupB';

	% figure parameters
	unit_width = 0.4; % normalized to display
	unit_height = 0.4; % normalized to display
	column_lim = 1; % number of axes column
	xlabelStr = 'Time';
	ylabelStr = '';
	figTitleStr = 'line plots with diff bar';

	stimShadeDataA = {};
	stimShadeDataB = {};
	stimShadeColorA = {'#F05BBD','#4DBEEE','#ED8564'};
	stimShadeColorB = {'#F05BBD','#4DBEEE','#ED8564'};
	shadeHeightScale = 0.05; % percentage of y axes
	shadeGapScale = 0.01; % diff between two shade in percentage of y axes
	% yRangeShade = [];

	errorBarColor = {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'};
	scatterColor = errorBarColor;
	scatterSize = 20;
	scatterAlpha = 0.5;
	diffBarAlpha = 0.5;
	diffBarColor = '#616887';

	save_fig = false;
	save_dir = '';
	gui_save = false;

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('legStrA', varargin{ii})
	        legStrA = varargin{ii+1}; 
	    elseif strcmpi('legStrB', varargin{ii})
	        legStrB = varargin{ii+1}; 
	    elseif strcmpi('xlabelStr', varargin{ii})
	        xlabelStr = varargin{ii+1}; 
	    elseif strcmpi('ylabelStr', varargin{ii})
	        ylabelStr = varargin{ii+1};
	    elseif strcmpi('new_xticks', varargin{ii})
	        new_xticks = varargin{ii+1};
	    elseif strcmpi('figTitleStr', varargin{ii})
	        figTitleStr = varargin{ii+1};
	    elseif strcmpi('stimShadeDataA', varargin{ii})
	        stimShadeDataA = varargin{ii+1}; % by default, shade will be plot at the top of the axes
	    elseif strcmpi('stimShadeDataB', varargin{ii})
	        stimShadeDataB = varargin{ii+1}; % by default, shade will be plot at the top of the axes
	    elseif strcmpi('stimShadeColorA', varargin{ii})
	        stimShadeColorA = varargin{ii+1};
	    elseif strcmpi('stimShadeColorB', varargin{ii})
	        stimShadeColorB = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('gui_save', varargin{ii})
	    	gui_save = varargin{ii+1};
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


	% Keep data in group A and B the same size (use the shorter one)
	sizeA = numel(DataA);
	sizeB = numel(DataB);
	sizeSmaller = min(sizeA,sizeB);
	DataA = DataA(1:sizeSmaller);
	DataB = DataB(1:sizeSmaller);
	xData = xData(1:sizeSmaller);

	% Suppose the numbers of elements in all cells in DataA/B are the same, get the number of
	% element in the first cell
	scatterNumA = numel(DataA{1}); 
	scatterNumB = numel(DataB{1});

	% Calculate the means and standard errors. Plot the error bars with scatter
	hold on
	[hA,meanValA,steValA] = plot_errorBarLine_with_scatter(xData,DataA,...
		'errorBarColor',errorBarColor{1},'scatterAlpha',scatterAlpha,'scatterSize',scatterSize,...
		'plotWhere',gca);
	[hB,meanValB,steValB] = plot_errorBarLine_with_scatter(xData,DataB,'PlotWhere',gca,...
		'errorBarColor',errorBarColor{2},'scatterAlpha',scatterAlpha,'scatterSize',scatterSize,...
		'plotWhere',gca);

	
	xlabel(xlabelStr)
	ylabel(ylabelStr)
	title(figTitleStr)


	% bar plot show the difference between A and B
	diffVal = meanValB-meanValA;
	b = bar(xData,diffVal);
	diffLegStr = sprintf('(%s)-(%s)',legStrB,legStrA);
	b.FaceAlpha = diffBarAlpha;
	b.FaceColor = diffBarColor;
	b.EdgeColor = 'none';

	set(gca, 'TickDir', 'out');
	if exist('new_xticks','var')
		xticksVal = new_xticks;
	else
		xticksVal = xData;
	end
	xticks(xticksVal);


	% get the y lim
	ylimVal = ylim(gca); 
	yHeight = ylimVal(2)-ylimVal(1);
	shadeHeight = yHeight*shadeHeightScale;
	shadeGap = yHeight*shadeGapScale;


	% draw stimulation shadeA
	if ~isempty(stimShadeDataA)
		yRangeShade = [ylimVal(2)-1*shadeHeight ylimVal(2)];
		for sn = 1:numel(stimShadeDataA)
			draw_WindowShade(gca,stimShadeDataA{sn},'shadeColor',stimShadeColorA{sn},'yRange',yRangeShade);
		end
	end
	if ~isempty(stimShadeDataB)
		yRangeShade = [ylimVal(2)-2*shadeHeight-shadeGap ylimVal(2)-1*shadeHeight-shadeGap];
		for sn = 1:numel(stimShadeDataB)
			draw_WindowShade(gca,stimShadeDataB{sn},'shadeColor',stimShadeColorB{sn},'yRange',yRangeShade);
		end
	end

	% Add legend for error bars only
	legStrA_scatterNum = sprintf('%s (n=%g)',legStrA,scatterNumA);
	legStrB_scatterNum = sprintf('%s (n=%g)',legStrB,scatterNumB);
	legend(legStrA_scatterNum, legStrB_scatterNum, diffLegStr,'Location', 'Best') % 'northeastoutside'


	hold off

	[ttest_p,ttest_h] = unpaired_ttest_cellArray(DataA,DataB);
	scatterNum = [scatterNumA scatterNumB];
	varargout{1} = vertcat(ttest_p,ttest_h);
	varargout{2} = diffVal;
	varargout{3} = scatterNum;



	% Save figure and statistics
	if save_fig
		if isempty(save_dir)
			gui_save = 'on';
		end
		msg = 'Choose a folder to save plots showing the diff between two groups';
		save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
			'guiInfo',msg,'fname',figTitleStr);
		save(fullfile(save_dir, [figTitleStr, '_stat']),...
		    'ttest_p','diffVal','scatterNum');
	end 
end
