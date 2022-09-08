function [varargout] = boxPlot_with_scatter(CellArrayData,varargin)
	% Box plot with scatter data 

	% CellArrayData: data should be organized in cell array. each cell contain a group of data.
	%				each cell contains a single vector

	% Defaults
	groupNum = numel(CellArrayData); % number of groups
	groupNames = num2cell([1:groupNum]'); % prepare a single column cell array
	groupNames = cellfun(@(x) num2str(x), groupNames, 'UniformOutput',false); % convert numbers to strings

	boxColor = [0 0.1 0.4]; % '#0B4870';
	notchMode = 'off';
	outlier_marker = false;

	plotScatter = true; % true/false. Scatter plot of every single value used for box plot. 

	scatter_spread = 0.3; % spread range of scatter plot (for a single boxplot) on x axis
	scatter_size = 5; % matlab default is 36
	scatterColor = '#0071BD'; 
	scatterColor_1 = '#0071BD'; % when scatter data for each single boxplot are seperated to 2 groups
	scatterColor_2 = '#BD6F00'; 

	TickAngle = 45; 
	FontSize = 18;
	FontWeight = 'bold';

	% save_fig = false; % true/false
	% save_dir = '';

	plotWhere = [];
	stat = false; % true if want to run anova
	stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('groupNames', varargin{ii})
	        groupNames = varargin{ii+1};
	    elseif strcmpi('traceMeanCom', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        traceMeanCom = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('outlier_marker', varargin{ii}) 
	        outlier_marker = varargin{ii+1}; 
	    elseif strcmpi('plotScatter', varargin{ii}) 
	        plotScatter = varargin{ii+1}; 
	    elseif strcmpi('plotWhere', varargin{ii}) 
	        plotWhere = varargin{ii+1}; 
	    elseif strcmpi('FontSize', varargin{ii}) 
	        FontSize = varargin{ii+1}; 
	    elseif strcmpi('FontWeight', varargin{ii}) 
	        FontWeight = varargin{ii+1}; 
	    elseif strcmpi('stat', varargin{ii})
            stat = varargin{ii+1};
	    elseif strcmpi('stat_fig', varargin{ii})
            stat_fig = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	boxGroups_cell = cell(groupNum, 1);
	dis_idx = []; % in case there are empty groups
	for n = 1:groupNum
		datapointNum = numel(CellArrayData{n});
		if datapointNum==0
			dis_idx = [dis_idx n];
		end
		singleGroup = cell(datapointNum, 1);
		singleGroup(:) = groupNames(n);
		boxGroups_cell{n} = singleGroup;
	end
	groupNum = groupNum-numel(dis_idx);
	CellArrayData(dis_idx) = [];
	boxGroups_cell(dis_idx) = [];

	% boxPlot_data = cat(1, CellArrayData{:});
	boxPlot_data = cat(1, [CellArrayData{:}]');
	boxPlot_group = cat(1, boxGroups_cell{:});
    
	if isempty(plotWhere)
    	f = figure;
    else
    	axes(plotWhere)
    	f = gcf;
    end

    if outlier_marker
    	symbol = '+'; % show outlier as defult: '+'
    else
    	symbol = ''; % do not show outlier marker
    end

	boxplot(boxPlot_data,boxPlot_group,'symbol',symbol,'Notch',notchMode,'Colors', boxColor);
	set(gca, 'box', 'off')
	set(gca, 'FontSize', FontSize)
	set(gca, 'FontWeight', FontWeight)
	xtickangle(TickAngle)
	xt = xticks(gca);
	hold on

	if plotScatter
		for n = 1:groupNum

			scatterY = CellArrayData{n};
			scatterX = rand(size(scatterY))*scatter_spread-(scatter_spread/2)+xt(n);
			if exist('traceMeanCom', 'var') 

				sig_diff_logVec = logical(traceMeanCom{n});
				scatterY_1 = scatterY(sig_diff_logVec); % data points (ROIs) in which mean traces diffs are significant 
				scatterX_1 = scatterX(sig_diff_logVec);

				scatterY_2 = scatterY(~sig_diff_logVec); % data points (ROIs) in which mean traces diffs are not significant 
				scatterX_2 = scatterX(~sig_diff_logVec);

				scatter(gca, scatterX_1, scatterY_1, scatter_size,...
					'filled', 'MarkerFaceColor', scatterColor_1, 'MarkerEdgeColor', 'none');
				scatter(gca, scatterX_2, scatterY_2, scatter_size,...
					'filled', 'MarkerFaceColor', scatterColor_2, 'MarkerEdgeColor', 'none');
			else
				scatter(gca, scatterX, scatterY, scatter_size,...
					'filled', 'MarkerFaceColor', scatterColor, 'MarkerEdgeColor', 'none');
			end
		end
	end

	p = NaN;
	tbl = NaN;
	stats = NaN; 
	c = NaN;
	gnames = NaN;
	if stat && groupNum>1
		[p,tbl,stats] = anova1(boxPlot_data, boxPlot_group, stat_fig);
		if stats.df~=0
			[c,~,~,gnames] = multcompare(stats, 'Display', stat_fig); % multiple comparison test. Check if the difference between groups are significant
			% 'tukey-kramer'
			% The first two columns of c show the groups that are compared. 
			% The fourth column shows the difference between the estimated group means. 
			% The third and fifth columns show the lower and upper limits for 95% confidence intervals for the true mean difference. 
			% The sixth column contains the p-value for a hypothesis test that the corresponding mean difference is equal to zero. 

			% convert c to a table
	        c = num2cell(c);
			c(:, 1:2) = cellfun(@(x) gnames{x}, c(:, 1:2), 'UniformOutput',false);
			c = cell2table(c,...
				'variableNames', {'g1', 'g2', 'lower-confi-int', 'estimate', 'upper-confi-int', 'p'});
			h = NaN(size(c, 1), 1);
			idx_sig = find(c.p < 0.05);
			idx_nonsig = find(c.p >= 0.05);
			h(idx_sig) = 1;
			h(idx_nonsig) = 0;
			c.h = h;
		end
	end
	statInfo.anova_p = p; % p-value of anova test
	statInfo.tbl = tbl; % anova table
	statInfo.stats = stats; % structure used to perform  multiple comparison test (multcompare)
	statInfo.multCompare = c; % result of multiple comparision test.
	statInfo.multCompare_gnames = gnames;

	varargout{1} = f; % handle of the plot
	varargout{2} = statInfo; 
end
