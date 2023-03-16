function [varargout] = plot_diff(xData,meanA,meanB,varargin)
	% Plot the data in group A and group B using line plots, and display the difference
	% (meanB-meanA) using a bar plot. 

	% Use varargin to input error values to plot error bars

	% Example:
	%		

	% Defaults
	errorA = zeros(size(meanA));
	errorB = zeros(size(meanB));
	legStrA = 'groupA';
	legStrB = 'groupB';

	% figure parameters
	unit_width = 0.4; % normalized to display
	unit_height = 0.4; % normalized to display
	column_lim = 1; % number of axes column
	xlabelStr = 'Time';
	ylabelStr = '';
	figTitleStr = 'line plots with diff bar';
	barAlpha = 0.5;

	save_fig = false;
	save_dir = '';
	gui_save = false;

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('errorA', varargin{ii})
	        errorA = varargin{ii+1}; % number array used to plot error bar for meanA
	    elseif strcmpi('errorB', varargin{ii})
	        errorB = varargin{ii+1}; % number array used to plot error bar for meanB
	    elseif strcmpi('legStrA', varargin{ii})
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
	    elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('gui_save', varargin{ii})
	    	gui_save = varargin{ii+1};
	    end
	end


	% Set up the figure
	if ~exist('plotWhere','var')
		f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
	else
		plotWhere;
	end
	% f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
	% tlo = tiledlayout(f,2,1);


	% Keep data in group A and B the same size (use the shorter one)
	sizeA = numel(meanA);
	sizeB = numel(meanB);
	sizeSmaller = min(sizeA,sizeB);
	meanA = meanA(1:sizeSmaller);
	meanB = meanB(1:sizeSmaller);
	errorA = errorA(1:sizeSmaller);
	errorB = errorB(1:sizeSmaller);
	xData = xData(1:sizeSmaller);


	% Line plots with errorbar
	% ax = nexttile(tlo);
	hold on
	xlabel(xlabelStr)
	ylabel(ylabelStr)
	title(figTitleStr)

	% Plot the means and error bars for each group at each time point
	errorbar(xData, meanA, errorA, 'o-', 'LineWidth', 1.5, 'CapSize', 10, 'MarkerSize', 8)
	errorbar(xData, meanB, errorB, 'o-', 'LineWidth', 1.5, 'CapSize', 10, 'MarkerSize', 8)

	% Add legend and grid
	% legend(legStrA, legStrB, 'Location', 'northeastoutside')
	% grid on

	% % Show the plot
	% hold off


	% bar plot show the difference between A and B
	diffVal = meanB-meanA;
	b = bar(xData,diffVal);
	diffLegStr = sprintf('(%s)-(%s)',legStrB,legStrA);
	b.FaceAlpha = barAlpha;

	set(gca, 'TickDir', 'out');
	if exist('new_xticks','var')
		xticksVal = new_xticks;
	else
		xticksVal = xData;
	end
	xticks(xticksVal);

	legend(legStrA, legStrB, diffLegStr,'Location', 'Best') % 'northeastoutside'


	varargout{1} = diffVal;



	% Save figure and statistics
	if save_fig
		if isempty(save_dir)
			gui_save = 'on';
		end
		msg = 'Choose a folder to save plots showing the diff between two groups';
		save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
			'guiInfo',msg,'fname',figTitleStr);
		% save(fullfile(save_dir, [figTitleStr, '_stat']),...
		%     'barStat');
	end 
end
