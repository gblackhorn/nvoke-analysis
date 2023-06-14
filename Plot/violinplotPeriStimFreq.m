function [violinData,statInfo,varargout] = violinplotPeriStimFreq(alignedData,varargin)
    % violin plot of specific bins in periStimFreq
    % periStimFreqBarstat is the barStat from plot_event_freq_alignedData_allTrials

    % default
    filter_roi_tf = false; % do not filter ROIs by default

    stimTypeNum = 3;
    winDuration = 2; % seconds
    startTime1 = 1; % second
    startTime2 = 0; % second

    otherBinWidth = 1; % second. width of bins other than data used for violin plot [startTime startTime+winDuration]
    preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
    postStim_duration = 5; % unit: second. include events happened after the end of stimulations
    PropName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
    round_digit_sig = 2; % round to the Nth significant digit for duration
    normToBase = false; % normalize the data to baseline (data before baseBinEdgeEnd)
    baseStart = -preStim_duration; % where to start to use the bin for calculating the baseline. -1
    baseEnd = -2; % 0


    binRange = empty_content_struct({'stim','startTime'},stimTypeNum);
    % binRange = empty_content_struct({'stim','startTime','winDuration'},stimTypeNum);
    binRange(1).stim = 'og-5s';
    binRange(1).filters = [nan nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
    binRange(1).startTime = startTime1; % Use data in [startTime startTime+winDuration] range
    % binRange(1).winDuration = winDuration; 
    binRange(2).stim = 'ap-0.1s';
    binRange(2).filters = [nan nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
    binRange(2).startTime = startTime2; 
    % binRange(2).winDuration = winDuration; 
    binRange(3).stim = 'og-5s ap-0.1s';
    binRange(3).filters = [nan nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
    binRange(3).startTime = startTime1; 
    % binRange(3).winDuration = winDuration; 

    stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
    stimEvents(1).stimName = 'og-5s';
    stimEvents(1).eventCat = 'rebound';
    stimEvents(2).stimName = 'ap-0.1s';
    stimEvents(2).eventCat = 'trig';
    stimEvents(3).stimName = 'og-5s ap-0.1s';
    stimEvents(3).eventCat = 'rebound';

    plot_unit_width = 0.45; % normalized size of a single plot to the display
    plot_unit_height = 0.45; % nomralized size of a single plot to the display
    titleStr = sprintf('eventFreq [onset-of-airpuff to %gs after]',winDuration);
    save_fig = false;
    save_dir = [];

    debug_mode = false;

    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('binRange', varargin{ii})
            binRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('winDuration', varargin{ii})
            winDuration = varargin{ii+1};
        elseif strcmpi('filter_roi_tf', varargin{ii})
            filter_roi_tf = varargin{ii+1};
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        end
    end 

    violinData = binRange;

    % indicate that the data are normalized to baseline
    if normToBase
        normToBaseStr = ' normToBase';
    else
        normToBaseStr = '';
    end
    titleStr = sprintf('%s %s',titleStr,normToBaseStr);


    % Filter the ROIs in all trials according to the stimulation effect
    if filter_roi_tf
        [alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
            'stim_names',{binRange.stim},'filters',{binRange.filters});
        title_prefix = 'filtered';
    else
        title_prefix = '';
        for n = 1:numel(binRange)
            binRange(n).filters = [nan nan nan nan];
        end
    end 
    titleStr = sprintf('%s %s',title_prefix,titleStr);

    histEdges = [];
    % dataStimTypes = {periStimFreqBarstat.stim};

    % loop through stimulation types
    for stn = 1:numel(binRange)
        % Get the range using 'binRange' and 'winDuration'
        violinData(stn).range = [binRange(stn).startTime binRange(stn).startTime+winDuration];
        violinData(stn).winDuration = winDuration;

        % Get the event frequency in the specified range window
        [EventFreqInBins,binEdges] = get_EventFreqInBins_trials(alignedData,violinData(stn).stim,...
            'PropName',PropName,'binWidth',otherBinWidth,'specialBin',violinData(stn).range,...
            'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
            'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
            'round_digit_sig',round_digit_sig,'debug_mode',debug_mode); % get event freq in time bins 


        % Calculate the number of recordings, the number of dates(animal number), the number of
        % neurons and the number of stimulation repeats
        [violinData(stn).recNum,violinData(stn).recDateNum,violinData(stn).roiNum,violinData(stn).stimRepeatNum] = calcDataNum(EventFreqInBins);


        % collect event frequencies from all rois and combine them to a matrix 
        ef_cell = {EventFreqInBins.EventFqInBins}; % collect EventFqInBins in a cell array
        ef_cell = ef_cell(:); % make sure that ef_cell is a vertical array
        ef = vertcat(ef_cell{:}); % concatenate ef_cell contents and create a number array


        % normalize data with the base range if 'normToBase' is true
        idxBaseBinEdgeEnd = find(binEdges==baseEnd); 
        idxBaseBinEdgeStart = find(binEdges==baseStart); 
        idxBaseData = [idxBaseBinEdgeStart:idxBaseBinEdgeEnd-1]; % idx of baseline data in every cell in ef_cell 
        baseRangeStr = sprintf('%g to %g s',binEdges(idxBaseBinEdgeStart),binEdges(idxBaseBinEdgeEnd));
        if normToBase
            ef = ef/mean(ef(:,idxBaseData),'all'); 
            violinData(stn).baseRange = [baseStart baseEnd];
        else
            violinData(stn).baseRange = [];
        end


        % get the EventFreqInBins data in violinData(stn).range
        binStartIDX = find(binEdges==violinData(stn).range(1));
        binEndIDX = find(binEdges==violinData(stn).range(2));
        dataGroupIDX = [binStartIDX:(binEndIDX-1)];
        violinData(stn).eventFreq = ef(:,dataGroupIDX);
    end

    % add another field containing stimType names can be used for structure field
    % This part is for plotting using violinplot.m
    [violinData,shortStimNames] = addFieldCompatibleStimName(violinData);


    % prepare a canvas for plotting
    [f,f_rowNum,f_colNum] = fig_canvas(4,'unit_width',...
        plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
        'fig_name',titleStr); % create a figure
    tlo = tiledlayout(f, 3, 3); % setup tiles

    % violin plot
    ax = nexttile(tlo,[2 2]); % activate the ax for color plot
    violinDataStruct = empty_content_struct({violinData.stimMod},1);
    for n = 1:numel(violinData)
        violinDataStruct.(violinData(n).stimMod) = violinData(n).eventFreq;
    end
    violinplot(violinDataStruct);
    % violinplot(violinDataStruct,'GroupOrder',{violinData.stimMod});


    % anova test with multi-comparison
    [dataVector,dataGroupCell] = prepareStructDataforAnova(violinDataStruct);
    [statInfo] = anova1_with_multiComp(dataVector,dataGroupCell);


    % plot multi-comparison in the next ax
    axStat = nexttile(tlo,[2 1]);
    MultCom_stat = statInfo.c(:,["g1","g2","p","h"]);
    plotUItable(gcf,axStat,MultCom_stat);


    % plot figure info 
    axInfo = nexttile(tlo,[1 2]);
    violinDataTable = struct2table(violinData);
    figInfoTable = violinDataTable(:,["stim","startTime","recNum","recDateNum","roiNum","stimRepeatNum"]);
    plotUItable(gcf,axInfo,figInfoTable);

    % plot filters
    axInfo = nexttile(tlo,[1 1]);
    filtersArrayCell = {violinData.filters};
    filtersArray = vertcat(filtersArrayCell{:});
    filterstable = array2table(filtersArray,'VariableNames',{'ex','in','rb','exApOg'});
    plotUItable(gcf,axInfo,filterstable);

    sgtitle(titleStr)
    % Save figure and statistics
    if save_fig
        if isempty(save_dir)
            gui_save = 'on';
        else
            gui_save = 'off';
        end
        msg = 'Choose a folder to save the plot and the statistics';
        save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
            'guiInfo',msg,'fname',titleStr);
        save(fullfile(save_dir, [titleStr, '_dataStat']),...
            'violinData');
    end 
end

function [recNum,recDateNum,roiNum,stimRepeatNum] = calcDataNum(EventFreqInBins)
    % calculte the n numbers using the structure var 'EventFreqInBins'

    % each entry of EventFreqInBins contains data for one roi
    % find the empty roi entries
    EventFqInBinsAll = {EventFreqInBins.EventFqInBins};
    emptyEntryIDX = find(cellfun(@(x) isempty(x),EventFqInBinsAll));
    EventFreqInBins(emptyEntryIDX) = [];

    % get the date and time info from trial names
    % one specific date-time (exp. 20230101-150320) represent one recording
    % one date, in general, represent one animal
    trialNamesAll = {EventFreqInBins.TrialNames};
    trialNamesAllDateTime = cellfun(@(x) x(1:15),trialNamesAll,'UniformOutput',false);
    trialNamesAllDate = cellfun(@(x) x(1:8),trialNamesAll,'UniformOutput',false);
    trialNameUniqueDateTime = unique(trialNamesAllDateTime);
    trialNameUniqueDate = unique(trialNamesAllDate);

    % get all the n numbers
    recNum = numel(trialNameUniqueDateTime);
    recDateNum = numel(trialNameUniqueDate);
    roiNum = numel(trialNamesAll);
    stimRepeatNum = sum([EventFreqInBins.stimNum]);
end

function [violinDataNew,varargout] = addFieldCompatibleStimName(violinData)
    oldNewStr = {{'og-5s','OG'},...
        {'ap-0.1s','AP'}};
    blankRep = ''; % replacement for blank

    violinDataNew = violinData;
    for n = 1:numel(violinData)
        stimName = violinData(n).stim;

        for m = 1:numel(oldNewStr)
            stimName = replace(stimName,oldNewStr{m}{1},oldNewStr{m}{2});
        end

        stimName = replace(stimName,' ',blankRep);

        violinDataNew(n).stimMod = stimName;
    end

    % output a cell containing the modified stim names compatible with field name
    varargout{1} = {violinDataNew.stimMod};
end

function [dataVector,dataGroupCell] = prepareStructDataforAnova(violinDataStruct)
    fields = fieldnames(violinDataStruct);
    groupNum = numel(fields);
    dataVector = cell(groupNum,1);
    dataGroupCell = cell(groupNum,1);
    for n = 1:groupNum
        dataVector{n} = violinDataStruct.(fields{n});
        dataVector{n} = reshape(dataVector{n},[],1);
        dataGroupCell{n} = repmat({fields{n}},numel(dataVector{n}),1);
    end
    dataVector = vertcat(dataVector{:});
    dataGroupCell = vertcat(dataGroupCell{:});
end