function [violinData,statInfo,varargout] = violinplotPeriStimFreq2(periStimFreqBarData,stimNames,binIDX,varargin)
    % violin plot of specific bins in periStimFreq

    % periStimFreqBarData: an output, barStat, from function 'plot_event_freq_alignedData_allTrials'

    % periStimFreqDiffStat is an output, diffStat, from plot_event_freq_alignedData_allTrials

    % default
    % stimNames = {'og-5s','og-5s ap-0.1s'}; % periStimFreqBarstat.stim. data using these stimulations will be compared
    % binIDX = [4, 4]; % the nth bin from the data listed in stimNames

    normToFirst = true; % normalize all the data to the mean of the first group (first stimNames)

    plot_unit_width = 0.4; % normalized size of a single plot to the display
    plot_unit_height = 0.4; % nomralized size of a single plot to the display
    titleStr = sprintf('periStim eventFreq');
    save_fig = false;
    save_dir = [];
    gui_save = 'off';

    debug_mode = false;

    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('normToFirst', varargin{ii})
            normToFirst = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
        end
    end 

    % create some empty vars
    stimIDX = NaN(size(stimNames));
    violinDataField = {'stim','eventFreq','eventFreqNorm','stimMod','binName',...
        'recNum','recDateNum','roiNum','stimRepeatNum'};
    violinData = empty_content_struct(violinDataField,numel(stimNames));

    % decide which field should be used for the plot
    if normToFirst
        dataField = 'eventFreqNorm';
    else
        dataField = 'eventFreq';
    end

    % get all the stimulation names in the 'periStimFreqBarData'
    periStimAllNames = {periStimFreqBarData.stim};

    % loop through 'stimNames' and find the relative data in 'periStimFreqBarData'
    for n = 1:numel(stimIDX)
        % get the position of data in 'periStimFreqBarData'
        stimIDX(n) = find(strcmpi(periStimAllNames,stimNames{n}));

        % if stimName exists add the info from 'periStimFreqBarData' to 'violinData'
        if isempty(stimIDX(n))
            error('stim name is not found in the input data')
        else
            % add data from 'periStimFreqBarData' to 'violinData'
            barData = periStimFreqBarData(stimIDX(n));
            violinData(n).stim = barData.stim;
            violinData(n).eventFreq = barData.data(binIDX(n)).group_data;
            violinData(n).binNum = binIDX(n);
            violinData(n).binName = barData.binNames{binIDX(n)};
            violinData(n).recNum = barData.recNum;
            violinData(n).recDateNum = barData.recDateNum;
            violinData(n).roiNum = barData.roiNum;
            violinData(n).stimRepeatNum = barData.stimRepeatNum;

            % use the first stim group to normalize other group data
            if n == 1
                normMean = mean(violinData(n).eventFreq);
            end 

            % normalize the data with the mean of first group data
            violinData(n).eventFreqNorm = violinData(n).eventFreq/normMean;
        end
    end

    % add 'stimMod' content to violinData.stimMod. 
    [violinData] = addFieldCompatibleStimName(violinData);


    % form a struct var for violin plot
    violinDataStruct = empty_content_struct({violinData.stimMod},1);

    for n = 1:numel(violinData)
        violinDataStruct.(violinData(n).stimMod) = violinData(n).(dataField);
        % violinDataStruct.(violinData(n).stimMod) = eventFreqData;
    end


    % create a canvas for the plot
    % 1st plot: violin. 2nd plot: stat. 3rd plot: animal number, roi number, etc.
    [f,f_rowNum,f_colNum] = fig_canvas(3,'unit_width',...
        plot_unit_width,'unit_height',plot_unit_height,'column_lim',1,...
        'fig_name',titleStr); % create a figure
    tlo = tiledlayout(f, 5, 1); % setup tiles


    % 1st plot: violin
    ax = nexttile(tlo,[3 1]); % activate the ax for the violin plot
    violinplot(violinDataStruct);
    set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
    set(gca, 'box', 'off')

    % 2nd plot: stat at a table. ttest if there are two groups, ANOVA if there are more groups
    if numel(violinData) == 2 % two-sample ttest
        [pVal,hVal] = unpaired_ttest_cellArray({violinData(1).(dataField)},...
            {violinData(2).(dataField)});
        statInfo.method = 'two-sample ttest';
        statInfo.group1 = violinData(1).stim;
        statInfo.group2 = violinData(2).stim;
        statInfo.p = pVal;
        statInfo.h = hVal;

        % Create a table with variable names 'p' and 'h'
        statTab = table(pVal,hVal,'VariableNames',{'p', 'h'});
        statTitle = 'two-sample ttest';
    else numel(violinData) > 2 % one-way ANOVA with tucky multiple comparison
        [dataVector,dataGroupCell] = prepareStructDataforAnova(violinDataStruct);
        [statInfo] = anova1_with_multiComp(dataVector,dataGroupCell);
        statTab = statInfo.c(:,["g1","g2","p","h"]);
        statTitle = 'one-way ANOVA [tuckey multiple comparison]';
    end
    % plot stat table
    axStat = nexttile(tlo,[1 1]);
    plotUItable(gcf,axStat,statTab);
    title(statTitle);


    % 3rd plot: figure info as a table
    violinDataTable = struct2table(violinData);
    figInfoTable = violinDataTable(:,["stim","binNum","binName","recNum","recDateNum","roiNum","stimRepeatNum"]);
    axInfo = nexttile(tlo,[1 1]);
    plotUItable(gcf,axInfo,figInfoTable);


    % set the title for the figure
    sgtitle(titleStr)
    if save_fig
        if isempty(save_dir)
            gui_save = 'on';
        end
        msg = 'Choose a folder to save the violin plot and the statistics for periStim frequency';
        save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
            'guiInfo',msg,'fname',titleStr);
        save(fullfile(save_dir, [titleStr, '_dataStat']),...
            'violinData','statInfo');
    end 
    varargout{1} = save_dir;
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