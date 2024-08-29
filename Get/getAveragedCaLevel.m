function [caLevelData,nNum,binX,binDataStruct,varargout] = getAveragedCaLevel(alignedData,stimName,binWidth,varargin)
    % Get the peri-stimulation calcium level traces from recordings applied with specific stimulation

    % alignedData: Struct var containing the organized recording data
    % stimName: Name of stimulation. It should match one of the content in the field 'stim_name' of alignedData
    % binWidth: In addition the the raw data, the calcium level will also be organized in bins for  
    %   output 'binDataCell'. The size of bin is set with this value

    % Optional inputs
    % subNuclei: Screen the neurons using the subnuclei locations (DAO, PO)
    % stimEventCat: Consider if there is any events belong to this category around the stimulation
    % stimEventKeepOrDis: 'keep' or 'discard' the calcium level traces with the stimEventCat 

    % Defaults
    stimRangeExt = 2; % Add this value (unit: second) to the beginning and the end of the stimRanges
                      % Look for stim-related events (stimEventCat) in these ranges


    % Input parser
    p = inputParser;

    % Required input
    addRequired(p, 'alignedData', @isstruct);
    addRequired(p, 'stimName', @ischar); 
    addRequired(p, 'binWidth', @isnumeric); 

    % Optional parameters with default values
    addParameter(p, 'subNuclei', '', @ischar); % 'event'/'roi'. The type of entries in groupedEventProp(n).event_info
    addParameter(p, 'stimEventCat', '', @ischar); 
    addParameter(p, 'stimEventKeepOrDis', 'keep', @(x) ischar(x) && any(strcmp(x, {'keep', 'discard', ''}))); 
        % Keep or discard the calcium traces with events specified by 'stimEventCat'
    addParameter(p, 'norm2hpStd', false, @islogical); % Normalize the traces with the std of highpassed filter if true
    addParameter(p, 'debugMode', false, @islogical); % Normalize the traces with the std of highpassed filter if true

    % Parse inputs
    parse(p, alignedData, stimName, binWidth, varargin{:});

    % Assign parsed values to variables
    subNuclei = p.Results.subNuclei;
    stimEventCat = p.Results.stimEventCat;
    stimEventKeepOrDis = p.Results.stimEventKeepOrDis;
    norm2hpStd = p.Results.norm2hpStd;
    debugMode = p.Results.debugMode;



    % Filter recordings using 'stimName'
    stimNameAll = {alignedData.stim_name};
    stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
    alignedData = alignedData(stimPosIDX);


    % Screen neurons using subNuclei tags if 'subNucleiTypes' is not empty
    if ~isempty(subNuclei)
    	alignedData = screenSubNucleiROIs(alignedData,subNuclei);
    end


    % Create a structure to record the n numbers
    numAlignedData = numel(alignedData); % Get the number of recordings after the filter(s)
    nNum = empty_content_struct({'recNum','roiNum','traceNum'},1); 
    nNum.recNum = 0;
    nNum.roiNum = 0;
    nNum.traceNum = 0;

    % Get the time for aligned calcium level trace
    psthTimeinfo = alignedData(1).timeCaLevel;

    % Pre-allocate RAM for vars
    psthCaLevel = cell(1,numAlignedData);
    recNamesCell = cell(1,numAlignedData); % Rec name strings. One cell contains recNames for all stim repeats from all rois in a single recording
    roiNamesCell = cell(1,numAlignedData); % ROI name strings. One cell: all stim repeats from all rois in a single rec
    % eventFilterCell = cell(1,numAlignedData); % ROI name strings. One cell: all stim repeats from all rois in a single rec


    % Loop through the recordings and collect the peri-stim calcium traces
    for rn = 1:numAlignedData
        % Get the recording name 
        recName = extractDateTimeFromFileName(alignedData(rn).trialName);

        if debugMode
            fprintf('Recording %d/%d: %s\n', rn, numAlignedData, recName)
            if rn == 5
                pause
            end
        end

        % Get the stimulation ranges and add the stimRangeExt to the beginning and the end to them
        stimRanges = alignedData(rn).stimInfo.UnifiedStimDuration.range;
        stimRanges(:, 1) =stimRanges(:, 1) - stimRangeExt;
        stimRanges(:, 2) =stimRanges(:, 2) + stimRangeExt;

        % Get the trace data including event properties and calcium level traces for every ROI
        recTraceData = alignedData(rn).traces;

        % Get the roi number
        roiNum = numel(recTraceData);

        % Create cells to store the calcium traces data
        psthCaLevelRec = cell(1,roiNum);
        roiNamesInOneRoi = cell(1,roiNum); % Each cell: Roi names for all calcium traces in a single roi

        % Loop through the ROIs
        for nn = 1:roiNum
            % Get the roi name
            roiName = recTraceData(nn).roi;

            if debugMode
                fprintf(' - ROI %d/%d: %s\n', nn, roiNum, roiName)
            end

            % STD of highpass-filtered trace data
            hpStd = recTraceData(nn).hpStd;

            % Use the stimulation-related events to screen calcium level traces
            if ~isempty(stimEventCat)
                psthCaLevelRec{nn} = screenCaTraceWithEvent(recTraceData(nn).CaLevelTrace,...
                    stimRanges, recTraceData(nn).eventProp, stimEventCat, stimEventKeepOrDis);
            else
                psthCaLevelRec{nn} = recTraceData(nn).CaLevelTrace;
            end

            if ~isempty(psthCaLevelRec{nn})
                % Add up roiNum and traceNum
                nNum.roiNum = nNum.roiNum + 1;
                nNum.traceNum = nNum.traceNum + size(psthCaLevelRec{nn}, 2);

                % Normalize the calcium level trace
                if norm2hpStd
                    psthCaLevelRec{nn} = psthCaLevelRec{nn}./hpStd;
                end

                % Generate roiName strings for every trace
                roiNamesInOneRoi{nn} = repmat({roiName}, 1, size(psthCaLevelRec{nn}, 2));
            end
        end

        % Check if there are any traces collected from the current recording
        psthCaLevelRecTF = ~cellfun(@isempty, psthCaLevelRec);
        if ~isempty(find(psthCaLevelRecTF))
            % Add up recNum
            nNum.recNum = nNum.recNum + 1;

            % Combine calcium traces from a recording
            psthCaLevel{rn} = [psthCaLevelRec{:}];

            % Combine roiName string from a recording
            roiNamesCell{rn} = [roiNamesInOneRoi{:}];

            % Generate recName strings for every trace
            recNamesCell{rn} = repmat({recName},1,numel(roiNamesCell{rn}));

            % % Generate eventFilter strings for every trace
            % eventFilterCell{rn} = repmat({[]})
            % recNamesCell{rn} = repmat({recName},1,numel(roiNamesCell{rn}));

        end
    end

    % Store aligned calcium time data to caLevelData structure
    caLevelData.time = psthTimeinfo;

    % Combine all the calcium level traces, recNames, roiNames from multiple recordings
    caLevelData.data = [psthCaLevel{:}];
    caLevelData.recTags = [recNamesCell{:}];
    caLevelData.roiTags = [roiNamesCell{:}];
    caLevelData.recRoiTags = cellfun(@(r, n) [r, ' ', n],...
        caLevelData.recTags, caLevelData.roiTags, 'UniformOutput', false);

    traceNum = size(caLevelData.data,2);
    caLevelData.stimName = repmat({stimName},1,traceNum);
    caLevelData.subN = repmat({subNuclei},1,traceNum);
    caLevelData.eventFilter = repmat({[stimEventCat,'-',stimEventKeepOrDis]},1,traceNum);


    % Calculte the smapling freq
    freq = get_frame_rate(caLevelData.time);
    binDataPointNum = binWidth*freq; % Data point number in a singla box 

    % Calculate the number of boxes using the time duration and binWidth
    binNum = floor(max(caLevelData.time)-min(caLevelData.time))/binWidth;

    % Calculate the middle location for every bin
    binX = [caLevelData.time(1):binWidth:(caLevelData.time(1)+binWidth*(binNum-1))]+binWidth/2; % the x-axis location of data in the plot 

    % Pre-allocate RAM
    binDataCell = cell(binNum,1);
    binDataStructCell = cell(1,binNum);
    % data_groupName = cell(binNum,1);

    % Loop through the bins and collect calcium level data 
    for bn = 1:binNum
    	startLoc = (bn-1)*binDataPointNum+1;
    	endLoc = bn*binDataPointNum;
    	binData = mean(caLevelData.data(startLoc:endLoc,:));
    	binDataCell{bn} = binData(:);

        % subNcell = repmat({subNuclei},1,numel(binDataCell{bn}));
        % eventFilterCell = repmat({[stimEventCat,'-',stimEventKeepOrDis]},1,numel(binDataCell{bn}))

    	binDataStructCell{bn} = struct('binVal',num2cell(ensureHorizontal(binDataCell{bn})),...
    		'binIDX', num2cell(repmat(bn,1,numel(binDataCell{bn}))),'recTags',caLevelData.recTags,...
            'roiTags',caLevelData.roiTags,'recRoiTags',caLevelData.recRoiTags,...
            'stimName',caLevelData.stimName,'subN',caLevelData.subN,'eventFilter',caLevelData.eventFilter);
    end

    % Create a structure var to store bin data for GLMM analysis
    binDataStruct = [binDataStructCell{:}];

    varargout{1} = binDataStruct;
    varargout{2} = binNum;
end


%% ==========
function    psthCaLevelRec = screenCaTraceWithEvent(roiCaLevelTrace, stimRanges, roiEventProp, stimEventCat, stimEventKeepOrDis)
    % Use the values in this field in the 'eventProp' as event time 
    eventTimeType = 'peak_time';  

    % Get the event categories and look for the ones belong to the stimEventCat
    eventCat = {roiEventProp.peak_category};
    stimEvenTF = strcmpi(eventCat, stimEventCat);

    % If stim events exist
    if ~isempty(find(stimEvenTF))
        % Get the event time
        eventTimes = [roiEventProp(stimEvenTF).(eventTimeType)];

        % Initialize a cell array to store the results
        results = cell(size(stimRanges, 1), 1);

        % Find which stim ranges contain the stim-related events
        for n = 1:size(stimRanges, 1)
            results{n} = eventTimes(eventTimes > stimRanges(n, 1) & eventTimes < stimRanges(n, 2));
        end

        % Locate non-empty cells
        nonEmptyCellsTF = ~cellfun(@isempty, results);

        switch stimEventKeepOrDis
            case 'keep'
                % Get the calcium traces with stim-related events
                psthCaLevelRec = roiCaLevelTrace(:, nonEmptyCellsTF);
            case 'discard'
                % Get the calcium traces without stim-related events
                psthCaLevelRec = roiCaLevelTrace(:, ~nonEmptyCellsTF);
            case ''
                % Do not filter the calcium traces
                psthCaLevelRec = roiCaLevelTrace;
        end
    else
        switch stimEventKeepOrDis
            case 'keep'
                % Get the calcium traces with stim-related events
                psthCaLevelRec = [];
            case 'discard'
                % Get the calcium traces without stim-related events
                psthCaLevelRec = roiCaLevelTrace;
            case ''
                % Do not filter the calcium traces
                psthCaLevelRec = roiCaLevelTrace;
        end
    end
end
