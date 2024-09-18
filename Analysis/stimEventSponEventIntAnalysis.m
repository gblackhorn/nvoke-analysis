function [varargout] = stimEventSponEventIntAnalysis(alignedData,stimName,stimEventCat,varargin)
	% Caclulate the interval-1 between stim-related events and following events (usually spontaneous
	% event) and the interval-2 between spontaneous events. Compare interval-1 and -2

	% alignedData: get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'
	% stimEventCat: such as 'trig', 'rebounds', etc.

	% Defaults
	defaultReleventEventCat = 'spon'; % Use this category for relavent events when defReleventEventCat is true
	colorGroupCD = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
        '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};

	% Stat model setting
	modelType = 'LMM';
	distribution = 'gamma';
	link = 'log';
	groupVarType = 'categorical';

	plotUnitWidth = 0.3;
	plotUnitHeight = 0.1;
	columnLim = 3;

	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);
	addRequired(p, 'stimName', @ischar);
	addRequired(p, 'stimEventCat', @ischar);

	% Add optional parameters to the input p
	addParameter(p, 'eventTimeType', 'peak_time', @ischar);
	addParameter(p, 'releventEventLoc', 'post', @ischar); % 'pre'/'post'. The location of relevent event. Pre or post to the ref event
	addParameter(p, 'defReleventEventCat', false, @islogical); 
	addParameter(p, 'maxDiff', 5, @isnumeric);
	addParameter(p, 'titlePrefix', '', @ischar);
	addParameter(p, 'debugMode', false, @islogical);

	% Parse inputs
	parse(p, alignedData, stimName, stimEventCat, varargin{:});

	% Retrieve parsed values
	eventTimeType = p.Results.eventTimeType;
	releventEventLoc = p.Results.releventEventLoc;
	defReleventEventCat = p.Results.defReleventEventCat;
	maxDiff = p.Results.maxDiff;
	titlePrefix = p.Results.titlePrefix;
	debugMode = p.Results.debugMode;


	% filter the alignedData with stimName
	stimNameAll = {alignedData.stim_name};
	stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
	alignedDataFiltered = alignedData(stimPosIDX);


	% % filter the ROIs using filters
	% [alignedDataFiltered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedDataFiltered,...
	% 	'stim_names',stimName,'filters',filters);

	if defReleventEventCat % Only work if the input 'releventEventLoc' is 'post'
		% Get the time diff between stim-related events and their following spon events
		stimAndNeighbourInt = getEventInterval(alignedDataFiltered,stimEventCat,defaultReleventEventCat,'maxDiff',maxDiff);
	else
		stimAndNeighbourInt = getEventIntervalFromRef(alignedDataFiltered,stimEventCat,releventEventLoc,'maxDiff',maxDiff);
	end

	% Get the time difference between two close spon events
	sponAndSponInt = getEventInterval(alignedDataFiltered,'','','maxDiff',maxDiff);
	% sponAndSponInt = getEventInterval(alignedDataFiltered,'spon','spon','maxDiff',maxDiff);

	% Run GLMM on the data for stat
	combinedEventInt = [stimAndNeighbourInt; sponAndSponInt];
	[me,~,~,~,~,meStatReport] = mixed_model_analysis(combinedEventInt,'pairTimeDiff','pairCat',{'recName','roi'},...
		'modelType',modelType,'distribution',distribution,'link',link,'groupVarType',groupVarType);


	% Create a structure to organize the data for violin plot
	stimAndFollowingIntName = sprintf('%s2%s',stimEventCat,releventEventLoc);
	stimAndFollowingIntName = strrep(stimAndFollowingIntName, '-', '');
	sponAndSponIntName = 'spon2spon';
	violinData.(stimAndFollowingIntName) = [stimAndNeighbourInt.pairTimeDiff];
	violinData.(sponAndSponIntName) = [sponAndSponInt.pairTimeDiff];


	% Get n number and prepare to plot it in a UI table
	nNumberTabStimAndFollowing = getRecordingNeuronCounts(stimAndNeighbourInt);
	nNumberTabSponAndSpon = getRecordingNeuronCounts(sponAndSponInt);
	combinedNumTable = combineSummaryTables(nNumberTabStimAndFollowing, stimAndFollowingIntName,...
	nNumberTabSponAndSpon, sponAndSponIntName); % combine the nNumber tables



	% Create figure canvas
	titleStr = sprintf('%s %s vs AllInt [%s %s maxDiff-%gs]',...
		titlePrefix, stimAndFollowingIntName,stimName,stimEventCat,maxDiff);
	[f,f_rowNum,f_colNum] = fig_canvas(15,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'row_lim',5,'column_lim',columnLim,'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);

	% Remove the empty field
	isEmptyField = structfun(@isempty, violinData);
	fNames = fieldnames(violinData);
	emptyField = fNames(isEmptyField);
	violinData = rmfield(violinData, emptyField);

	% Plot violin
	axViolin = nexttile(1,[5,1]);
	violinplot(violinData);

	% Summarize the violinData stats and combine it to nNum table
	summerizedStats = summarizeStructStats(violinData);
	summerizedStatsAndNnumTab = combineTabsWithSameRowTitle(summerizedStats, combinedNumTable);

	% Plot cumulative distribution
	axCD = nexttile(2,[5,1]);
	cumulative_distr_plot(struct2cell(violinData), 'groupNames', fieldnames(violinData), 'plotWhere', axCD,...
	    'plotCombine',false,'colorGroup', colorGroupCD, 'FontSize', 12, 'FontWeight', 'bold');

	% Plot summarized stats and nNumber
	axStatsNum = nexttile(3);
	plotSummaryTableInUITable(axStatsNum, summerizedStatsAndNnumTab);


	% Plot LMM/GLMM stat
	axGlmmTitle = nexttile(6);
	glmmTitleStr = sprintf('(Top) %s model comparison: no-fixed-effects vs fixed-effects\n[%s]\nVS\n[%s]\n(Bottom) Group comparison',...
		meStatReport.modelInfoStr, char(meStatReport.chiLRT.Formula{1}), char(meStatReport.chiLRT.Formula{2}));
	set(axGlmmTitle, 'XColor', 'none', 'YColor', 'none'); % Hide X and Y axis lines, ticks, and labels
	% title(axGlmmTitle, glmmTitleStr); % Add a title to the axis
	text(axGlmmTitle, 'Units', 'normalized', 'Position', [0.5, 0.5], 'String', glmmTitleStr, ...
	     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12);
	set(axGlmmTitle, 'Box', 'off');

	axGlmmModelComp = nexttile(9);
	axGlmmGroupComp = nexttile(12);
	plot_stat_table(axGlmmModelComp, axGlmmGroupComp, meStatReport);

	set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
	sgtitle(titleStr);

	% Plot Kolmogorov-Smirnov Test stat: If two vectors are from the same continuous distribution
	axKS = nexttile(15);
	if isempty(emptyField)
		[hKS, pKS] = kstest2(violinData.(stimAndFollowingIntName), violinData.(sponAndSponIntName));
	else
		hKS = nan;
		pKS = nan;
	end
	KStestTab = plotUItableKStest(axKS, pKS, hKS);

	% disp(['K-S test p-value: ', num2str(p)]);



	intData.eventIntStruct = combinedEventInt;
	intData.violinData = violinData;
	intData.GlmmReport = meStatReport;
	intData.KStest.h = hKS;
	intData.KStest.p = pKS;

	varargout{1} = intData;
	varargout{2} = f;
	varargout{3} = titleStr;
	varargout{4} = summerizedStatsAndNnumTab; % table of n numbers
	varargout{5} = KStestTab; % table of K-S test


end

function nNumberTab = getRecordingNeuronCounts(eventStruct)
    % Extract the 'recName' and 'roi' fields from the structure
    recNames = {eventStruct.recName};
    rois = {eventStruct.roi};
    
    % Get the unique recording names
    uniqueRecNames = unique(recNames);
    nRecordings = length(uniqueRecNames);
    
    % Create a combined identifier for each neuron in each recording
    combinedIdentifiers = strcat(recNames, rois);
    
    % Get the unique neuron identifiers
    uniqueNeurons = unique(combinedIdentifiers);
    nNeurons = length(uniqueNeurons);
    
    % Get the total number of entries in the structure
    nEntries = length(eventStruct);

    % Create a table with the counts
    nNumberTab = table(nRecordings, nNeurons, nEntries, ...
        'VariableNames', {'Recordings', 'Neurons', 'Events'});
end

function combinedTable = combineSummaryTables(summaryTable1, groupName1, summaryTable2, groupName2)
    % Add group names to each table
    group1 = repmat({groupName1}, height(summaryTable1), 1);
    group2 = repmat({groupName2}, height(summaryTable2), 1);
    
    % Add the Group column to each summary table
    summaryTable1 = addvars(summaryTable1, group1, 'Before', 1, 'NewVariableNames', 'Group');
    summaryTable2 = addvars(summaryTable2, group2, 'Before', 1, 'NewVariableNames', 'Group');
    
    % Combine the tables
    combinedTable = [summaryTable1; summaryTable2];
end


function plotSummaryTableInUITable(ax, nNumberTab)
	figure(ax.Parent.Parent)
	set(ax, 'XTickLabel', []);
	set(ax, 'YTickLabel', []);
    % Convert the table to a cell array
    dataCell = table2cell(nNumberTab);
    columnNames = nNumberTab.Properties.VariableNames;
    
    % Get the position and units of the axis
    uit_pos = get(ax, 'Position');
    uit_unit = get(ax, 'Units');
    
    % Create the uitable in the figure
    uit = uitable('Data', dataCell, 'ColumnName', columnNames,...
                  'Units', uit_unit, 'Position', uit_pos);
    
    % Adjust table appearance
    jScroll = findjobj(uit);
    jTable = jScroll.getViewport.getView;
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
    drawnow;
end


function plot_stat_table(ax_stat1, ax_stat2, meStatReport)
    % Set the current figure to the one containing ax_stat1
    figure(ax_stat1.Parent.Parent);

    set(ax_stat1, 'XTickLabel', []);
    set(ax_stat1, 'YTickLabel', []);
    set(ax_stat2, 'XTickLabel', []);
    set(ax_stat2, 'YTickLabel', []);
    
    uit_pos1 = get(ax_stat1, 'Position');
    uit_unit1 = get(ax_stat1, 'Units');
    uit_pos2 = get(ax_stat2, 'Position');
    uit_unit2 = get(ax_stat2, 'Units');

    % Create the table in the correct figure and context
    if isfield(meStatReport, 'fixedEffectsStats') % if LMM or GLMM (mixed models) are used
        chiLRTCell = table2cell(meStatReport.chiLRT);
        chiLRTCell = convertCategoricalToChar(chiLRTCell);
        uit = uitable('Data', chiLRTCell, 'ColumnName', meStatReport.chiLRT.Properties.VariableNames,...
                    'Units', uit_unit1, 'Position', uit_pos1);

        fixedEffectsStatsCell = table2cell(meStatReport.fixedEffectsStats);
        fixedEffectsStatsCell = convertCategoricalToChar(fixedEffectsStatsCell);
        uit = uitable('Data', fixedEffectsStatsCell, 'ColumnName', meStatReport.fixedEffectsStats.Properties.VariableNames,...
                    'Units', uit_unit2, 'Position', uit_pos2);
    end
    
    % Adjust table appearance
    jScroll = findjobj(uit);
    jTable = jScroll.getViewport.getView;
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
    drawnow;
end

function convertedCellArray = convertCategoricalToChar(cellArray)
    % Check and convert categorical or nominal data to char in a cell array
    convertedCellArray = cellArray;  % Copy the input cell array
    
    % Iterate through each element in the cell array
    for i = 1:numel(cellArray)
        % Check if the current element is categorical or nominal
        if iscategorical(cellArray{i}) || isa(cellArray{i}, 'nominal')
            % Convert to char
            convertedCellArray{i} = char(cellArray{i});
        end
    end
end

function [varargout] = plotUItableKStest(ax, pVal, hVal)
	figure(ax.Parent.Parent)
	set(ax, 'XTickLabel', []);
	set(ax, 'YTickLabel', []);
    % Convert the table to a cell array
    dataCell = {'K-S', pVal, hVal};
    columnNames = {'method', 'p', 'h'};
    
    % Get the position and units of the axis
    uit_pos = get(ax, 'Position');
    uit_unit = get(ax, 'Units');
    
    % Create the uitable in the figure
    uit = uitable('Data', dataCell, 'ColumnName', columnNames,...
                  'Units', uit_unit, 'Position', uit_pos);
    
    % Adjust table appearance
    jScroll = findjobj(uit);
    jTable = jScroll.getViewport.getView;
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
    drawnow;

    KStestTab = cell2table(dataCell);
    KStestTab.Properties.VariableNames = columnNames;
    varargout{1} = KStestTab;
end

