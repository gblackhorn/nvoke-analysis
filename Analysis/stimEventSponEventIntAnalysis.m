function [varargout] = stimEventSponEventIntAnalysis(alignedData,stimName,stimEventCat,varargin)
	% Caclulate the interval-1 between stim-related events and following events (usually spontaneous
	% event) and the interval-2 between spontaneous events. Compare interval-1 and -2

	% alignedData: get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'
	% stimEventCat: such as 'trig', 'rebounds', etc.

	% Defaults
	% stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	eventTimeType = 'peak_time'; % rise_time/peak_time
	followEventCat = 'spon';
	% filters = [1 nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

	maxDiff = 5; % the max difference between the stim-related and the following events

	% Stat model setting
	modelType = 'GLMM';
	distribution = 'gamma';
	link = 'log';
	groupVarType = 'categorical';

	plotUnitWidth = 0.3;
	plotUnitHeight = 0.2;
	columnLim = 2;

	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    % if strcmpi('filters', varargin{ii})
	    %     filters = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    if strcmpi('followEventCat', varargin{ii})
	        followEventCat = varargin{ii+1}; 
	    elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('maxDiff', varargin{ii})
	        maxDiff = varargin{ii+1};
        elseif strcmpi('debugMode', varargin{ii})
	        debugMode = varargin{ii+1};
	    end
	end

	% filter the alignedData with stimName
	stimNameAll = {alignedData.stim_name};
	stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
	alignedDataFiltered = alignedData(stimPosIDX);


	% % filter the ROIs using filters
	% [alignedDataFiltered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedDataFiltered,...
	% 	'stim_names',stimName,'filters',filters);


	% Get the time diff between stim-related events and their following spon events
	stimAndFollowingInt = getEventInterval(alignedDataFiltered,stimEventCat,'spon','maxDiff',maxDiff);

	% Get the time difference between two close spon events
	sponAndSponInt = getEventInterval(alignedDataFiltered,'spon','spon','maxDiff',maxDiff);

	% Run GLMM on the data for stat
	combinedEventInt = [stimAndFollowingInt; sponAndSponInt];
	[me,~,~,~,~,meStatReport] = mixed_model_analysis(combinedEventInt,'pairTimeDiff','pairCat',{'recName','roi'},...
		'modelType',modelType,'distribution',distribution,'link',link,'groupVarType',groupVarType);


	% Create a structure to organize the data for violin plot
	stimAndFollowingIntName = sprintf('%s2spon',stimEventCat);
	sponAndSponIntName = 'spon2spon';
	violinData.(stimAndFollowingIntName) = [stimAndFollowingInt.pairTimeDiff];
	violinData.(sponAndSponIntName) = [sponAndSponInt.pairTimeDiff];


	% Get n number and prepare to plot it in a UI table
	nNumberTabStimAndFollowing = getRecordingNeuronCounts(stimAndFollowingInt);
	nNumberTabSponAndSpon = getRecordingNeuronCounts(sponAndSponInt);
	combinedNumTable = combineSummaryTables(nNumberTabStimAndFollowing, stimAndFollowingIntName,...
	nNumberTabSponAndSpon, sponAndSponIntName); % combine the nNumber tables



	% Create figure canvas
	titleStr = sprintf('stimEvent-followEvent-diff vs sponEvent-int [%s %s maxDiff-%gs]',...
		stimName,stimEventCat,maxDiff);
	[f,f_rowNum,f_colNum] = fig_canvas(8,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'column_lim',columnLim,'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);

	% Plot violin
	axViolin = nexttile(1,[4,1]);
	violinplot(violinData);

	% Plot nNumber
	axNum = nexttile(2);
	plotSummaryTableInUITable(axNum, combinedNumTable);

	% Plot GLMM stat
	axGlmmTitle = nexttile(4);
	glmmTitleStr = sprintf('(Top) %s model comparison: no-fixed-effects vs fixed-effects\n[%s]\nVS\n[%s]\n(Bottom) Group comparison',...
		modelType, char(meStatReport.chiLRT.formula{1}), char(meStatReport.chiLRT.formula{2}));
	set(axGlmmTitle, 'XColor', 'none', 'YColor', 'none'); % Hide X and Y axis lines, ticks, and labels
	% title(axGlmmTitle, glmmTitleStr); % Add a title to the axis
	text(axGlmmTitle, 'Units', 'normalized', 'Position', [0.5, 0.5], 'String', glmmTitleStr, ...
	     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12);
	set(axGlmmTitle, 'Box', 'off');

	axGlmmModelComp = nexttile(6);
	axGlmmGroupComp = nexttile(8);
	plot_stat_table(axGlmmModelComp, axGlmmGroupComp, meStatReport);

	set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
	sgtitle(titleStr);


	intData.eventIntStruct = combinedEventInt;
	intData.violinData = violinData;
	intData.GlmmReport = meStatReport;

	varargout{1} = intData;
	varargout{2} = f;
	varargout{3} = titleStr;


	% % loop through recordings
	% recNum = numel(alignedDataFiltered);
	% intDataCell = cell(1,recNum);
	% for n = 1:recNum
	% 	recData = alignedDataFiltered(n);
	% 	recName = recData.trialName;

	% 	if debugMode
	% 		fprintf('recording %g/%g: %s\n',n,recNum,recName)
	% 		if n == 5
	% 			pause
	% 		end
	% 	end

	% 	if ~isempty(recData.traces)

	% 		% Get the stimulation-related events and the first following events after them in ROIs
	% 		[stimFollowEventsPair] = getStimEventFollowEventROI(recData,stimEventCat,followEventCat,...
	% 			'maxDiff',maxDiff,'eventTimeType',eventTimeType);

	% 		% Get the the intervals between spontaneous events in all the ROIs in a recording
	% 		[sponEventInt] = getSponEventsInt(recData,...
	% 			'maxDiff',maxDiff,'followEventCat',followEventCat,'eventTimeType',eventTimeType);

	% 		% combine the fields from 'stimFollowEventsPair' and 'sponEventInt'
	% 		[eventInt] = combineStuctFields(stimFollowEventsPair,sponEventInt);

	% 		% loop through the ROIs. Make some further calculation and mark the empty ROIs 
	% 		roiDisIDX = [];
	% 		for rn = 1:numel(eventInt)
	% 			if isempty(eventInt(rn).stimFollowDiffTime) || isempty(eventInt(rn).sponEventsTimeIntMean)
	% 				roiDisIDX = [roiDisIDX rn];
	% 			else
	% 				% calculate the mean value of stimFollowDiffTime for a ROI
	% 				% eventInt(rn).stimFollowDiffTimeROI = mean(eventInt(rn).stimFollowDiffTime);

	% 				eventInt(rn).stimFollowVSsponInt = eventInt(rn).stimFollowDiffTimeROI-eventInt(rn).sponEventsTimeIntMean;
	% 			end
	% 		end

	% 		% discard the ROIs marked in roiDisIDX
	% 		eventInt(roiDisIDX) = [];

	% 		% add recording name to eventInt
	% 		[eventInt.recName] = deal(recName);
	% 		intDataCell{n} = eventInt;
	% 	end
	% end

	% % find the empty cells in intDataCell and delete them
	% emptyRecTF = cellfun(@(x) isempty(x),intDataCell);
	% emptyRecIDX = find(emptyRecTF);
	% intDataCell(emptyRecIDX) = [];

	% % concatenate eventInt from all recordings
	% intData = horzcat(intDataCell{:});



	% % Create figure canvas
	% titleStr = sprintf('stimEvent-followEvent-diff vs sponEvent-int [%s %s maxDiff-%gs]',...
	% 	stimName,stimEventCat,maxDiff);
	% [f,f_rowNum,f_colNum] = fig_canvas(4,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
	% 	'column_lim',columnLim,'fig_name',titleStr); % create a figure
	% tlo = tiledlayout(f,f_rowNum,f_colNum);



	% % compare the mean values of each ROI. Paired data
	% eventTimeDiffMean.stimAndFollowIntROI = [intData.stimFollowDiffTimeROI];
	% eventTimeDiffMean.sponIntROI = [intData.sponEventsTimeIntMean];
	% % eventTimeDiffMean.statName = 'paired ttest';

	% % paired ttest
	% pttest.name = 'paired ttest';
	% [pttest.h,pttest.p] = ttest(eventTimeDiffMean.stimAndFollowIntROI,eventTimeDiffMean.sponIntROI);
	% eventTimeDiffMean.pttest = pttest;
	% pttestTable = struct2table(eventTimeDiffMean.pttest);

	% % plot mean value data
	% ax = nexttile(tlo);
	% gca;
	% violinplot(eventTimeDiffMean);

	% % plot paired ttest table
	% ax = nexttile(tlo);
	% plotUItable(gcf,gca,pttestTable);




	% % Plot all event intervals
	% eventTimeDiff.stimAndFollowInt = [intData.stimFollowDiffTime];
	% % eventTimeDiff.stimAndFollowInt = horzcat(intData.stimFollowDiffTime);
	% sponIntCell = cellfun(@(x) horzcat(x{:}),{intData.sponEventsTimeInt},'UniformOutput',false);
	% eventTimeDiff.sponInt = horzcat(sponIntCell{:});

	% % un-paired ttest
	% upttest.name = 'two-sample ttest';
	% [upttest.h,upttest.p] = ttest2(eventTimeDiff.stimAndFollowInt,eventTimeDiff.sponInt);
	% eventTimeDiff.upttest = upttest;
	% ttestTable = struct2table(eventTimeDiff.upttest);

	% % plot mean value data
	% ax = nexttile(tlo);
	% gca;
	% violinplot(eventTimeDiff);

	% % plot paired ttest table
	% ax = nexttile(tlo);
	% plotUItable(gcf,gca,ttestTable);

	% sgtitle(titleStr);



	% varargout{1} = eventTimeDiffMean;
	% varargout{2} = eventTimeDiff;
	% varargout{3} = f;
	% varargout{4} = titleStr;
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


