function [violinData,statInfo,varargout] = violinplotPeriStimFreq2(periStimFreqBarData,stimNames,binIDX,varargin)
    % violin plot of specific bins in periStimFreq

    % periStimFreqBarData: an output, barStat, from function 'plot_event_freq_alignedData_allTrials'

    % periStimFreqDiffStat is an output, diffStat, from plot_event_freq_alignedData_allTrials

    % default
    % stimNames = {'og-5s','og-5s ap-0.1s'}; % periStimFreqBarstat.stim. data using these stimulations will be compared
    % binIDX = [4, 4]; % the nth bin from the data listed in stimNames

    normToFirst = true; % normalize all the data to the mean of the first group (first stimNames)
    mmlHierarchicalVars = {'trialNames','roiNames'};

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
        elseif strcmpi('mmlHierarchicalVars', varargin{ii})
            mmlHierarchicalVars = varargin{ii+1};
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
    violinDataField = {'stim','eventFreq','eventFreqNorm','eventFreqStruct','eventFreqStructNorm',...
        'stimMod','binName','recNum','recDateNum','roiNum','stimRepeatNum'};
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
            violinData(n).binName = barData.binNames{binIDX(n)};
            violinData(n).eventFreq = barData.data(binIDX(n)).groupData;
            violinData(n).binNum = binIDX(n);
            violinData(n).recNum = barData.recNum;
            violinData(n).recDateNum = barData.recDateNum;
            violinData(n).roiNum = barData.roiNum;
            violinData(n).stimRepeatNum = barData.stimRepeatNum;

            % Replace the contents in xdata, center of bin time, to binNames
            binXcell = num2cell(barData.binX(:)); % convert xdataUnique from number to cell
            replacementCell = [binXcell, barData.binNames(:)]; % Create a replacementCell, in which old xdata and binNames are paired
            barData.dataStruct = replaceFieldValues(barData.dataStruct, 'xdata', replacementCell);

            % Get the datastruct enties with tagged with 'violinData(n).binName'
            eventFreqStructAll = barData.dataStruct;
            xdataAll = {eventFreqStructAll.xdata};
            binNamesTF = strcmpi(xdataAll, violinData(n).binName);
            violinData(n).eventFreqStruct = eventFreqStructAll(binNamesTF);
            % use the first stim group to normalize other group data
            if n == 1
                normMean = mean(violinData(n).eventFreq);
            end 

            % normalize the data with the mean of first group data
            violinData(n).eventFreqNorm = violinData(n).eventFreq/normMean;
            % violinData(n).eventFreqStructNorm = violinData(n).eventFreqStruct;

            % Normalize the data with the mean of first group data in the eventFreq Struct
            violinData(n).eventFreqStructNorm = replaceFieldWithArray(violinData(n).eventFreqStruct,...
                'val',[violinData(n).eventFreqStruct.val]/normMean);


            % add 'stimMod' content to violinData.stimMod. 
            violinData(n) = addFieldCompatibleStimName(violinData(n));

            % Add stim name to the xdata in eventFreq struct
            xdata = {violinData(n).eventFreqStruct.xdata};
            xdataUpdate = cellfun(@(x) sprintf('%s %s',violinData(n).stimMod,x),xdata,'UniformOutput',false);
            violinData(n).eventFreqStruct = replaceFieldWithArray(violinData(n).eventFreqStruct,...
                'xdata',xdataUpdate);
            violinData(n).eventFreqStructNorm = replaceFieldWithArray(violinData(n).eventFreqStructNorm,...
                'xdata',xdataUpdate);
        end
    end



    % If data are from different bins of the same stimulation, add the bin name to the data name
    if length(violinData) > 1 && length(unique({violinData.stimMod})) == 1
        for i = 1:length(violinData)
            violinData(i).stimMod = [violinData(i).stimMod,violinData(i).binName];
        end
    end

    % Combine the eventFreqStructNorm from the violinData
    eventFreqStructNormCombine = [violinData(:).eventFreqStructNorm];

    % Run GLMM to evaluate the differnece of every freq in various time bins
    [GLMMstat, GLMMfittingFig, GLMMfittingFigName] = twoPartMixedModelAnalysis(eventFreqStructNormCombine,...
        'val', 'xdata', mmlHierarchicalVars,'groupVarType', 'categorical',...
        'dispStat', save_fig, 'figNamePrefix', titleStr);


    % % form a struct var for violin plot
    % violinDataStruct = empty_content_struct({violinData.stimMod},1);

    % for n = 1:numel(violinData)
    %     violinDataStruct.(violinData(n).stimMod) = violinData(n).(dataField);
    %     % violinDataStruct.(violinData(n).stimMod) = eventFreqData;
    % end


    
    % Collect data for violin plot and statistics. Store data from different groups in cells
    violinDataCell = {violinData.(dataField)};

    % Collect stimulation names as violin plot group names
    groupNames = {violinData.stimMod};

    % Collect extra info about the data, which will be used to plot extra UI table
    violinDataTable = struct2table(violinData);
    figInfoTable = violinDataTable(:,["stim","binNum","binName","recNum","recDateNum","roiNum","stimRepeatNum"]);


    % Violin plot + statistics analysis
    [statInfo,save_dir] = violinplotWithStat(violinDataCell,...
        'groupNames',groupNames,'extraUItable',figInfoTable,...
        'titleStr',titleStr,'save_fig',save_fig,'save_dir',save_dir,'gui_save',gui_save);

    % Add GLMM stat info to the statInfo struct var
    statInfo.GLMMstat = GLMMstat;

    % Save GLMM fitting figure
    if save_fig
        savePlot(GLMMfittingFig,'save_dir',save_dir,'guiSave',false,...
            'fname',GLMMfittingFigName);
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

% function [dataVector,dataGroupCell] = prepareStructDataforAnova(violinDataStruct)
%     fields = fieldnames(violinDataStruct);
%     groupNum = numel(fields);
%     dataVector = cell(groupNum,1);
%     dataGroupCell = cell(groupNum,1);
%     for n = 1:groupNum
%         dataVector{n} = violinDataStruct.(fields{n});
%         dataVector{n} = reshape(dataVector{n},[],1);
%         dataGroupCell{n} = repmat({fields{n}},numel(dataVector{n}),1);
%     end
%     dataVector = vertcat(dataVector{:});
%     dataGroupCell = vertcat(dataGroupCell{:});
% end