function [stimEventJitter,varargout] = stimEventJitterAnalysis(alignedData,stimNames,stimEventCat,varargin)
	% Calculate the jitter of stimulation caused events and compare it to the CV of spon event
	% intervals


	% Defaults
	plotUnitWidth = 0.3;
	plotUnitHeight = 0.1;
	thresholdStimDelay = true; % If true, use the smallest spon interval to threshold the delay of stim events

	% Input parser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);
	addRequired(p, 'stimNames', @iscell); % names of stimulations. Recordings applied with these stims will be used
	addRequired(p, 'stimEventCat', @ischar); % category of stim related events

	% Optional parameters with default values
	addParameter(p, 'eventTimeType', 'peak_time', @ischar); % 'peak_time'/'rise_time'. Type of spon event time
	addParameter(p, 'maxDiff', 2, @isnumeric); % The max difference between leading and following events
	addParameter(p, 'thresholdStimDelay', false, @islogical); % The max difference between leading and following events
	addParameter(p, 'modelType', 'GLMM', @ischar); % GLMM
	addParameter(p, 'distribution', 'gamma', @ischar); % GLMM
	addParameter(p, 'link', 'log', @ischar); % GLMM
	addParameter(p, 'groupVarType', 'categorical', @ischar); % GLMM
	addParameter(p, 'titlePrefix', '', @ischar); % GLMM

	% Parse inputs
	parse(p, alignedData, stimNames, stimEventCat, varargin{:});

	% Assign parsed values to variables
	alignedData = p.Results.alignedData;
	stimNames = p.Results.stimNames;
	stimEventCat = p.Results.stimEventCat;
	maxDiff = p.Results.maxDiff;
	thresholdStimDelay = p.Results.thresholdStimDelay;
	eventTimeType = p.Results.eventTimeType;
	modelType = p.Results.modelType;
	distribution = p.Results.distribution;
	link = p.Results.link;
	groupVarType = p.Results.groupVarType;
	titlePrefix = p.Results.titlePrefix;



	% filter the alignedData with stimNames
	stimNameAll = {alignedData.stim_name};
	stimPosIDX = [];
	for sn = 1:numel(stimNames)
		IDX = find(cellfun(@(x) strcmpi(stimNames{sn},x),stimNameAll));
		stimPosIDX = [stimPosIDX, IDX];
	end
	alignedDataFiltered = alignedData(stimPosIDX);


	% Get the time difference between two close spon events
	sponAndSponInt = getEventInterval(alignedDataFiltered,'spon','spon','maxDiff',maxDiff);

	% Copy the specified fields in sponAndSponInt to the new structure
	fieldsToKeep = {'recName', 'roi', 'pairCat', 'pairTimeDiff'};
	sponAndSponIntClean = keepSpecificFields(sponAndSponInt, fieldsToKeep);

	% Get the smallest spon interval
	sponIntMin = min([sponAndSponIntClean.pairTimeDiff]);

	% Get the delay of stimRelated events
	stimEventDelay = getStimEventDelay(alignedDataFiltered, stimEventCat);

	% Threshold the stimEventDelay using the sponIntMin
	if thresholdStimDelay
		threshTF = [stimEventDelay.pairTimeDiff] >= sponIntMin;
		stimEventDelay = stimEventDelay(threshTF);
	end

	% Get the CVs
	CVsponAndSpon = getCoefVariation([sponAndSponIntClean.pairTimeDiff]);
	CVstimEventDelay = getCoefVariation([stimEventDelay.pairTimeDiff]);

	% disp(CVsponAndSpon)
	% disp(CVstimEventDelay)


	% Run GLMM on the data for stat
	stimEventJitter.timeDiffStruct = [ensureHorizontal(sponAndSponIntClean), ensureHorizontal(stimEventDelay)];
	[me,~,~,~,~,meStatReport] = mixed_model_analysis(stimEventJitter.timeDiffStruct,'pairTimeDiff','pairCat',{'recName','roi'},...
		'modelType',modelType,'distribution',distribution,'link',link,'groupVarType',groupVarType);



	% Create a structure to organize the data for violin plot
	stimEventJitter.violinData.sponInt = [sponAndSponIntClean.pairTimeDiff];
	stimEventJitter.violinData.stimEventDelay = [stimEventDelay.pairTimeDiff];

	% Get n number and prepare to plot it in a UI table
	nNumberTabSponInt = getRecordingNeuronCounts(sponAndSponIntClean);
	nNumberTabStimEventDelay = getRecordingNeuronCounts(stimEventDelay);
	combinedNumTable = combineSummaryTables(nNumberTabStimEventDelay, 'stimEventDelay',...
	nNumberTabSponInt, 'sponInt'); % combine the nNumber tables



	% Create figure canvas
	titleStr = sprintf('%s stimEvent-delay vs sponEvent-int [%s %s maxDiff-%gs]',...
		titlePrefix, stimNames{1},stimEventCat,maxDiff);
	[f,f_rowNum,f_colNum] = fig_canvas(15,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'row_lim',5,'column_lim',3,'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);

	% Plot violin
	axViolin = nexttile(1,[5,1]);
	violinplot(stimEventJitter.violinData);

	% Plot CD
	axCD = nexttile(2,[5,1]);
	colorGroupCD = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
        '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};
	cumulative_distr_plot(struct2cell(stimEventJitter.violinData), 'groupNames', {'sponInt','stimEventDelay'}, 'plotWhere', axCD,...
	    'plotCombine',false,'colorGroup', colorGroupCD,...
	    'FontSize', 12, 'FontWeight', 'bold');


	% Plot nNumber
	axNum = nexttile(3);
	plotSummaryTableInUITable(axNum, combinedNumTable);


	% Plot GLMM stat
	axGlmmTitle = nexttile(6);
	glmmTitleStr = sprintf('(Top) %s model comparison: no-fixed-effects vs fixed-effects\n[%s]\nVS\n[%s]\n(Bottom) Group comparison',...
		modelType, char(meStatReport.chiLRT.formula{1}), char(meStatReport.chiLRT.formula{2}));
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
	[hKS, pKS] = kstest2(stimEventJitter.violinData.sponInt, stimEventJitter.violinData.stimEventDelay);
	plotUItableKStest(axKS, pKS, hKS);
	% disp(['K-S test p-value: ', num2str(p)]);


	stimEventJitter.CVsponInt = CVsponAndSpon;
	stimEventJitter.CVstimDelay = CVstimEventDelay;
	stimEventJitter.GlmmReport = meStatReport;
	stimEventJitter.KStest.h = hKS;
	stimEventJitter.KStest.p = pKS;

	varargout{1} = f;
	varargout{2} = titleStr;

end

function stimEventDelay = getStimEventDelay(alignedDataFiltered, stimEventCat);
	% Collect the delay of events belonging to the stimEventCat from alignedDataFiltered

	% Get the recording number
	recNum = numel(alignedDataFiltered);

	% Create cells to store the event intervals. One cell per recording
	eventIntStructRecCell = cell(recNum, 1);

		% Loop through all the recordings
		for rn = 1:recNum
			% Get the name of the recording
			recName = getShortRecName(alignedDataFiltered(rn).trialName);

			% Get the number and names of neurons
			neuronNum = numel(alignedDataFiltered(rn).traces);
			% neuronNames = {alignedDataFiltered(rn).traces.roi};

			% Get the time stamps and categories of events from neurons
			if neuronNum ~= 0
				eventDelayStructNeuronCell = cell(neuronNum, 1);
				for nn = 1:neuronNum
					eventDelayStructNeuronCell{nn} = getStimEventDelayFromNeuron(alignedDataFiltered(rn).traces(nn),...
						stimEventCat, recName);
				end

				% Concatenate the data from neurons
				eventIntStructRecCell{rn} = vertcat(eventDelayStructNeuronCell{:});
			end
		end

		% Concatenate the data from recordings
		stimEventDelay = vertcat(eventIntStructRecCell{:});

end

function shortRecName = getShortRecName(recName)
	% Get the date-time part from the recording name

	% Find the index of the first underscore
	underscoreIndex = find(recName == '_', 1);

	% Separate the parts of the string
	shortRecName = recName(1:underscoreIndex-1);
end

function eventDelayStructNeuron = getStimEventDelayFromNeuron(neuronDataStruct, stimEventCat, recName)
	% Get the time stamps of paired leading and following events from a neuron

	neuronName = neuronDataStruct.roi; % Get neuron name

	% Get the categories of events and the idx of leading events
	eventProps = neuronDataStruct.eventProp;
	eventCats = {eventProps.peak_category}; 
	stimEventTF = strcmpi(eventCats, stimEventCat); 
	EventIDX = find(stimEventTF);


	% Create an empty struct var to store the data
	structLength = sum(stimEventTF);
	eventDelayStructNeuronFields = {'recName', 'roi', 'pairCat', 'pairTimeDiff'};
	eventDelayStructNeuron = empty_content_struct(eventDelayStructNeuronFields, structLength);

	% Loop through eventDelayStructNeuron and fill in the data
	if structLength > 0
		[eventDelayStructNeuron.recName] = deal(recName);		
		[eventDelayStructNeuron.roi] = deal(neuronName);		
		[eventDelayStructNeuron.pairCat] = deal(['stim-', stimEventCat]);		

		for sl = 1:structLength 
			% Get the delay of stimEvent
			eventDelayStructNeuron(sl).pairTimeDiff = eventProps(EventIDX(sl)).peak_delay;

		end
	end
end

function newStruct = keepSpecificFields(originalStruct, fieldsToKeep)
    % Get the list of all fields in the structure array
    allFields = fieldnames(originalStruct);
    
    % Determine the fields to delete
    fieldsToDelete = setdiff(allFields, fieldsToKeep);
    
    % Remove the unwanted fields from the entire structure array
    newStruct = rmfield(originalStruct, fieldsToDelete);
end

function coefVariation = getCoefVariation(vectorData)
	% Calculate the CV for spon-spon
	meanVectorData = mean(vectorData);
	stdVectorData = std(vectorData);
	coefVariation = stdVectorData / meanVectorData;
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

function plotUItableKStest(ax, pVal, hVal)
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