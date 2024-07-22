function [EventFreqInBinsAll,varargout] = get_EventFreqInBins_trials(alignedData,StimName,varargin)
    % Collect events from trials, stored in alignedData, applied with the same kind of stimulation
    % (repeat number can be different) and calculate the event frequency in time bins. Return a
    % struct var containing the frequencies trial names and roi names. 

    % Note: This is used for the trials with only one type of stimulation (same parameters, such as
    % duration).


    % [EventFreqInBins] = get_EventFreqInBins_AllTrials(alignedData_allTrials,'og-5s')
    % 'alignedData_allTrials' is a struct var. It contains calcium signals, event propertis,
    %  stimulation infos of multiple recording trials. Use 'og-5s' to get the EventFreqInBins only
    %  from the trials applied with optogenetic stimulation for 5 second

    % Defaults
    stim_ex = nan;
    stim_in = nan;
    stim_rb = nan;
    stim_exApOg = nan; % excitatory AP during OG . If is nan, filter won't be applied

    groupLevel = 'roi'; % 'roi'/'stimTrial'. Collect event in bins and calculate the freq on specifiec group level
    baseBinIDX = 1; % The position of the baseline bin
    preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
    postStim_duration = 5; % unit: second. include events happened after the end of stimulations

    disZeroBase = true; % Discard the roi/stimTrial if the baseline value is zero

    customizeEdges = false; % customize the bins using function 'setPeriStimSectionForEventFreqCalc'
    stimEffectDuration = 1; % unit: second. Use this to set the end for the stimulation effect range

    binWidth = 1; % the width of histogram bin. the default value is 1 s.
    specialBin = []; % not used if it is empty
    PropName = 'rise_time';
    % plotHisto = false; % true/false [default].Plot histogram if true.

    stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
    stimEvents(1).stimName = 'og-5s';
    stimEvents(1).eventCat = 'rebound';
    stimEvents(2).stimName = 'ap-0.1s';
    stimEvents(2).eventCat = 'trig';
    stimEvents(3).stimName = 'og-5s ap-0.1s';
    stimEvents(3).eventCat = 'rebound';

    AlignEventsToStim = true; % align the eventTimeStamps to the onsets of the stimulations: subtract eventTimeStamps with stimulation onset time
    round_digit_sig = 2; % round to the Nth significant digit for duration

    splitLongStim = [1]; % If the stimDuration is longer than stimEffectDuration, the stimDuration 
                        %  part after the stimEffectDuration will be splitted using this var as edges inside. 
                        % If it is [1 1], the time during stimulation will be splitted using edges below
                        % [stimStart, stimEffectDuration, stimEffectDuration+splitLongStim, stimEnd] 

    debugMode = false;

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('stim_ex', varargin{ii}) 
            stim_ex = varargin{ii+1}; % logical. stimulation effect: excitation 
        elseif strcmpi('stim_in', varargin{ii}) 
            stim_in = varargin{ii+1}; % logical. stimulation effect: inhibition 
        elseif strcmpi('stim_rb', varargin{ii}) 
            stim_rb = varargin{ii+1}; % logical. stimulation effect: rebound 
        elseif strcmpi('customizeEdges', varargin{ii}) 
            customizeEdges = varargin{ii+1}; 
        elseif strcmpi('PeriBaseRange', varargin{ii}) 
            PeriBaseRange = varargin{ii+1}; 
        elseif strcmpi('stimEffectDuration', varargin{ii}) 
            stimEffectDuration = varargin{ii+1}; 
        elseif strcmpi('splitLongStim', varargin{ii})
            splitLongStim = varargin{ii+1};
        elseif strcmpi('binWidth', varargin{ii}) 
            binWidth = varargin{ii+1}; 
        elseif strcmpi('specialBin', varargin{ii}) 
            specialBin = varargin{ii+1}; 
        elseif strcmpi('PropName', varargin{ii}) 
            PropName = varargin{ii+1}; 
        elseif strcmpi('stimEventsPos', varargin{ii}) 
            stimEventsPos = varargin{ii+1}; 
        elseif strcmpi('stimEvents', varargin{ii}) 
            stimEvents = varargin{ii+1}; 
        elseif strcmpi('stimIDX', varargin{ii}) 
            stimIDX = varargin{ii+1}; 
        elseif strcmpi('denorm', varargin{ii}) 
            denorm = varargin{ii+1}; % denorminator used to normalize the EventFreq 
        % elseif strcmpi('recName', varargin{ii})
        %     recName = varargin{ii+1}; 
        % elseif strcmpi('roiNames', varargin{ii})
        %     roiNames = varargin{ii+1}; 
        elseif strcmpi('groupLevel', varargin{ii})
            groupLevel = varargin{ii+1}; 
        elseif strcmpi('preStim_duration', varargin{ii})
            preStim_duration = varargin{ii+1}; 
        elseif strcmpi('postStim_duration', varargin{ii})
            postStim_duration = varargin{ii+1}; 
        elseif strcmpi('disZeroBase', varargin{ii})
            disZeroBase = varargin{ii+1}; 
        elseif strcmpi('round_digit_sig', varargin{ii})
            round_digit_sig = varargin{ii+1}; % round to the Nth significant digit for duration
        elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1}; 
        end
    end

    % Collect trials/recording applied with a specific stimulation  
    stim_names = {alignedData.stim_name}; % Get all the stimulation names
    stim_names_tf = strcmpi(stim_names,StimName); % compare the stimulation names with the input 'StimName'
    trial_idx = find(stim_names_tf); % get the index of trials applied with specified stimulations
    alignedData_filtered = alignedData(trial_idx);


    % Loop through trials/recordings
    recNum = numel(alignedData_filtered);
    EventFreqInBins_cell = cell(1,recNum);
    for recN = 1:recNum
        recName = alignedData_filtered(recN).trialName; % get the current recording trial name
        EventsProps = {alignedData_filtered(recN).traces.eventProp}; % get the event properties of rois from current trial
        roiNames = {alignedData_filtered(recN).traces.roi}; % get the roi names from current trial
        subNuclei = {alignedData_filtered(recN).traces.subNuclei}; % get the roi names from current trial


        if debugMode
            fprintf('trial %d/%d: %s\n',recN,recNum,recName);
            if recN == 1
                pause
            end
        end
        
        % get the ranges of stimulations
        stimInfo = alignedData_filtered(recN).stimInfo;
        StimRanges = stimInfo.UnifiedStimDuration.range; 

        % Get the stimulation patch_coor, and modify it for plot shade to indicate the stimulation period
        stimInfoSep = stimInfo.StimDuration;
        stimShadeData = cell(size(stimInfoSep));
        stimShadeName = cell(size(stimInfoSep));
        for sn = 1:numel(stimInfoSep) % go through every stimulation in the recording
            stimShadeData{sn} = stimInfoSep(sn).patch_coor(1:4,1:2); % Get the first 4 rows for the first repeat of stimulation
            stimShadeData{sn}(1:2,1) = stimInfoSep(sn).range_aligned(1); % Replace the first 2 x values (stimu gpio rising) with the 1st element from range_aligned
            stimShadeData{sn}(3:4,1) = stimInfoSep(sn).range_aligned(2); % Replace the last 2 x values (stimu gpio falling) with the 2nd element from range_aligned
            % stimShadeData{sn}(:,1) = stimShadeData{sn}(:,1) - stimShadeData{sn}(1,1); % Modify the time, so the shade time starts from 0
            stimShadeName{sn} = stimInfoSep(sn).type; % Get the stimulation type 
        end


        % Specify which repeat(s) of stimulation will be used to gather the event frequencies
        if exist('stimIDX','var') && ~isempty(stimIDX)
            StimRanges = StimRanges(stimIDX,:);
        end

        roi_num = numel(EventsProps); % number of ROIs

        if ~exist('PeriBaseRange','var')
            PeriBaseRange = [-preStimDuration -2];
        end

        if customizeEdges
            % set the peri-stim sections (edges)
            [periStimSections,stimRepeatNum,binNames] = setPeriStimSectionForEventFreqCalc(alignedData_filtered(recN).fullTime,stimInfo,...
                'preStimDuration',preStim_duration,'postStimDuration',postStim_duration,...
                'PeriBaseRange',PeriBaseRange,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim);
        end


        % Get the time of stimulation related events
        if stimEventsPos && ~isempty(stimEvents) && ~isempty(EventsProps)
            stimEventsIDX = find(strcmpi({stimEvents.stimName},StimName));
            if ~isempty(stimEventsIDX) % if StimName can be found in the stimEventsIDX.stimName list
                stimEventCat = stimEvents(stimEventsIDX).eventCat;
                if ischar(stimEventCat)
                    stimEventCat = {stimEventCat};
                end
                [StimEventsTime,stimEventsIDXall] = getStimRelatedEvents(EventsProps,stimEventCat,...
                    'timeField',PropName);
                if numel(stimEventCat)>1
                    stimEventCatName = strjoin(stimEventCat);
                else
                    stimEventCatName = stimEventCat{:};
                end
            else
                stimEventCatName = '';
                StimEventsTime = [];
            end
        else
            stimEventCatName = '';
        end

        eventFreqStructFields = {'recNames','roiNames','subNuclei','EventFqInBins','stimNum'};

        if strcmpi(groupLevel, 'roi')
            % Filter ROIs using their response to the stimulation: excitatory/inhibitory/rebound
            % [alignedDataTraces_filtered] = Filter_AlignedDataTraces_withStimEffect(alignedData_filtered(recN).traces,...
            %     'ex',stim_ex,'in',stim_in,'rb',stim_rb,'exApOg',stim_exApOg);


            % binNames = {};

            % Collect peri-stimulus events from every ROI and organized them in bins
            recNames = repmat({recName},1,roi_num); % create a 1*roi_num cell containing the 'recNames' in every element
            EventFreqInBins = emptyStruct(eventFreqStructFields,[1, roi_num]); % create an empty structure
            [EventFreqInBins.recNames] = recNames{:}; % add trial names in struct EventFreqInBins
            [EventFreqInBins.roiNames] = roiNames{:}; % add roi names in struct EventFreqInBins
            [EventFreqInBins.subNuclei] = subNuclei{:}; % add roi names in struct EventFreqInBins

            disRoiIDX = [];
            for rn = 1:roi_num
                if debugMode
                    fprintf(' - roi %g/%g: %s\n',rn,roi_num,roiNames{rn})
                    % if rn == 7
                    %     pause
                    % end
                end
                % Use StimEventsTime to filter the peri-stimulation ranges
                if stimEventsPos
                    timeRanges = NaN(size(StimRanges));
                    timeRanges(:,1) = StimRanges(:,1)-preStim_duration;
                    timeRanges(:,2) = StimRanges(:,2)+postStim_duration;
                    [posTimeRanges,posRangeIDX] = getRangeIDXwithEvents(StimEventsTime{rn},timeRanges);
                    StimRangesFinal = StimRanges(posRangeIDX,:);
                else
                    StimRangesFinal = StimRanges;
                end

                eventTimeStamps = [EventsProps{rn}.(PropName)]; % get the (rn)th ROI event time stamps from the EventsProps

                if ~customizeEdges
                    if ~isempty(StimRangesFinal)
                        [EventsPeriStimulus,PeriStimulusRange] = group_EventsPeriStimulus(eventTimeStamps,StimRangesFinal,...
                            'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
                            'round_digit_sig',round_digit_sig); % group event time stamps around stimulations

                        % Get the bin edges and create bin names using the generic binWidth
                        modelSect = [PeriStimulusRange(1):binWidth:PeriStimulusRange(2)]; % PeriStim edges. Stimulation at 0
                        binXcell = num2cell(modelSect(1:end-1)+binWidth/2);
                        binNames = cellfun(@num2str, binXcell, 'UniformOutput', false);


                        % construct the bin edges if specialBin is not empty
                        % if ~isempty(specialBin)
                        %     binEdges = [PeriStimulusRange(1):binWidth:specialBin(1) specialBin(2):binWidth:PeriStimulusRange(2)];
                        % else
                        %     binEdges = [];
                        % end

                        [EventFreqInBins(rn).EventFqInBins,binEdges] = get_EventFreqInBins_roi(EventsPeriStimulus,PeriStimulusRange,...
                            'binWidth',binWidth,'plotHisto',false); % calculate the event frequencies (in bins) in a roi and assigne the array to the EventFreqInBins


                        EventFreqInBins(rn).stimNum = size(StimRangesFinal,1); % number of stim repeats used for one roi
                    end
                else
                    % if ~exist('PeriBaseRange','var')
                    %     PeriBaseRange = [-preStimDuration -2];
                    % end
                    % % set the peri-stim sections (edges)
                    % [periStimSections,stimRepeatNum,binNames] = setPeriStimSectionForEventFreqCalc(alignedData_filtered(recN).fullTime,stimInfo,...
                    %     'preStimDuration',preStim_duration,'postStimDuration',postStim_duration,...
                    %     'PeriBaseRange',PeriBaseRange,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim);

                    % calculate the averaged event frequencies in the bins defined by periStimSections
                    % Use the 3rd-column elements as default 0 for the peri-stim ranges 
                    [sectEventFreq,modelSect] = calcPeriStimEventFreqRoi(eventTimeStamps,periStimSections);

                    EventFreqInBins(rn).EventFqInBins = sectEventFreq;
                    EventFreqInBins(rn).stimNum = stimRepeatNum;
                    binEdges = modelSect;

                    if disZeroBase
                        % Set the ROI to be discarded if the baseline freq is 0
                        if sectEventFreq(baseBinIDX) == 0
                            disRoiIDX = [disRoiIDX, rn];
                        end
                    end
                end
            end
            EventFreqInBins(disRoiIDX) = [];
            EventFreqInBins_cell{recN} = EventFreqInBins;
            if roi_num == 0 && ~exist('binEdges','var')
                binEdges = [];
            % else
            %     binEdges = modelSect;
            end
        elseif strcmpi(groupLevel, 'stimTrial')
            EventFreqInBinsRoi_cell = cell(1, roi_num);

            for rn = 1:roi_num
                if debugMode
                    fprintf(' - roi %g/%g: %s\n',rn,roi_num,roiNames{rn})
                    % if rn == 7
                    %     pause
                    % end
                end

                % get the (rn)th ROI event time stamps from the EventsProps
                eventTimeStamps = [EventsProps{rn}.(PropName)]; 

                % Get the event counts from all the neurons and bin durations
                [~,modelSect,eventHistCountsMat,sectionsDuration] = calcPeriStimEventFreqRoi(eventTimeStamps,periStimSections);

                % Calculate the event freq in every stimulation trial
                eventFreqInBinsStimTrials = eventHistCountsMat./sectionsDuration;

                if disZeroBase
                    % Discard the stim trials if the basline freq is 0
                    baselineFreq = eventFreqInBinsStimTrials(:, baseBinIDX);
                    keepTF = baselineFreq~=0;
                    eventFreqInBinsStimTrials = eventFreqInBinsStimTrials(keepTF, :);
                end

                % Create an empty struct to store the event freq info
                structLength = size(eventFreqInBinsStimTrials, 1);
                EventFreqInBins = emptyStruct(eventFreqStructFields,[1, structLength]);

                if structLength > 0
                    for sl = 1:structLength
                        EventFreqInBins(sl).recNames = recName;
                        EventFreqInBins(sl).roiNames = roiNames{rn};
                        EventFreqInBins(sl).subNuclei = subNuclei{rn};
                        EventFreqInBins(sl).EventFqInBins = eventFreqInBinsStimTrials(sl, :);
                        EventFreqInBins(sl).stimNum = 1;
                    end
                end

                EventFreqInBinsRoi_cell{rn} = EventFreqInBins;
                % % Assign the values to the EventFreqInBins
                % EventFreqInBins(rn).EventFqInBins = eventFreqInBinsStimTrials;
                % EventFreqInBins(rn).stimNum = stimRepeatNum;
            end

            if roi_num == 0 % && ~exist('binEdges','var')
                if ~exist('binEdges','var')
                    binEdges = [];
                end
                EventFreqInBins_cell{recN} = emptyStruct(eventFreqStructFields,[1, 0]);
            else
                binEdges = modelSect;
                EventFreqInBins_cell{recN} = EventFreqInBinsRoi_cell{:};
            end
        end

        if ~exist('binNames','var')
            binNames = {};
        end
    end
    EventFreqInBinsAll = [EventFreqInBins_cell{:}];
    varargout{1} = binEdges;
    varargout{2} = stimShadeData;
    varargout{3} = stimShadeName;
    varargout{4} = stimEventCatName;
    varargout{5} = binNames;
end
