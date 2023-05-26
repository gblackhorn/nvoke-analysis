function [EventFreqInBins,varargout] = get_EventFreqInBins_trials(alignedData,StimName,varargin)
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

    binWidth = 1; % the width of histogram bin. the default value is 1 s.
    PropName = 'rise_time';
    % plotHisto = false; % true/false [default].Plot histogram if true.

    stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
    stimEvents(1).stimName = 'og-5s';
    stimEvents(1).eventCat = 'rebound';
    stimEvents(2).stimName = 'ap-0.1s';
    stimEvents(2).eventCat = 'trig';
    stimEvents(3).stimName = 'og-5s ap-0.1s';
    stimEvents(3).eventCat = 'rebound';

    AlignEventsToStim = true; % align the EventTimeStamps to the onsets of the stimulations: subtract EventTimeStamps with stimulation onset time
    preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
    postStim_duration = 5; % unit: second. include events happened after the end of stimulations
    round_digit_sig = 2; % round to the Nth significant digit for duration

    debug_mode = false;

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('stim_ex', varargin{ii}) 
            stim_ex = varargin{ii+1}; % logical. stimulation effect: excitation 
        elseif strcmpi('stim_in', varargin{ii}) 
            stim_in = varargin{ii+1}; % logical. stimulation effect: inhibition 
        elseif strcmpi('stim_rb', varargin{ii}) 
            stim_rb = varargin{ii+1}; % logical. stimulation effect: rebound 
        elseif strcmpi('binWidth', varargin{ii}) 
            binWidth = varargin{ii+1}; 
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
        elseif strcmpi('TrialName', varargin{ii})
            TrialName = varargin{ii+1}; 
        elseif strcmpi('roiNames', varargin{ii})
            roiNames = varargin{ii+1}; 
        elseif strcmpi('preStim_duration', varargin{ii})
            preStim_duration = varargin{ii+1}; 
        elseif strcmpi('postStim_duration', varargin{ii})
            postStim_duration = varargin{ii+1}; 
        elseif strcmpi('round_digit_sig', varargin{ii})
            round_digit_sig = varargin{ii+1}; % round to the Nth significant digit for duration
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1}; 
        end
    end

    % Collect trials/recording applied with a specific stimulation  
    stim_names = {alignedData.stim_name}; % Get all the stimulation names
    stim_names_tf = strcmpi(stim_names,StimName); % compare the stimulation names with the input 'StimName'
    trial_idx = find(stim_names_tf); % get the index of trials applied with specified stimulations
    alignedData_filtered = alignedData(trial_idx);


    % Loop through trials/recordings
    trialNum = numel(alignedData_filtered);
    EventFreqInBins_cell = cell(1,trialNum);
    for tn = 1:trialNum
        TrialName = alignedData_filtered(tn).trialName; % get the current recording trial name

        if debug_mode
            fprintf('trial %d/%d: %s\n',tn,trialNum,TrialName);
            if tn == 3
                pause
            end
        end
        
        % get the ranges of stimulations
        StimRanges = alignedData_filtered(tn).stimInfo.UnifiedStimDuration.range; 

        % Get the stimulation patch_coor, and modify it for plot shade to indicate the stimulation period
        stimInfo = alignedData_filtered(tn).stimInfo.StimDuration;
        stimShadeData = cell(size(stimInfo));
        stimShadeName = cell(size(stimInfo));
        for sn = 1:numel(stimInfo) % go through every stimulation in the recording
            stimShadeData{sn} = stimInfo(sn).patch_coor(1:4,1:2); % Get the first 4 rows for the first repeat of stimulation
            stimShadeData{sn}(1:2,1) = stimInfo(sn).range_aligned(1); % Replace the first 2 x values (stimu gpio rising) with the 1st element from range_aligned
            stimShadeData{sn}(3:4,1) = stimInfo(sn).range_aligned(2); % Replace the last 2 x values (stimu gpio falling) with the 2nd element from range_aligned
            % stimShadeData{sn}(:,1) = stimShadeData{sn}(:,1) - stimShadeData{sn}(1,1); % Modify the time, so the shade time starts from 0
            stimShadeName{sn} = stimInfo(sn).type; % Get the stimulation type 
        end


        % Specify which repeat(s) of stimulation will be used to gather the event frequencies
        if exist('stimIDX','var') && ~isempty(stimIDX)
            StimRanges = StimRanges(stimIDX,:);
        end

        % Filter ROIs using their response to the stimulation: excitatory/inhibitory/rebound
        [alignedDataTraces_filtered] = Filter_AlignedDataTraces_withStimEffect(alignedData_filtered(tn).traces,...
            'ex',stim_ex,'in',stim_in,'rb',stim_rb);
        EventsProps = {alignedDataTraces_filtered.eventProp}; % get the event properties of rois from current trial
        roiNames = {alignedDataTraces_filtered.roi}; % get the roi names from current trial


        % Collect peri-stimulus events from every ROI and organized them in bins
        roi_num = numel(EventsProps); % number of ROIs
        TrialNames = repmat({TrialName},1,roi_num); % create a 1*roi_num cell containing the 'TrialNames' in every element
        EventFreqInBins = emptyStruct({'TrialNames','roiNames','EventFqInBins'},[1, roi_num]); % create an empty structure
        [EventFreqInBins.TrialNames] = TrialNames{:}; % add trial names in struct EventFreqInBins
        [EventFreqInBins.roiNames] = roiNames{:}; % add roi names in struct EventFreqInBins

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

        for rn = 1:roi_num
            if debug_mode
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

            EventTimeStamps = [EventsProps{rn}.(PropName)]; % get the (rn)th ROI event time stamps from the EventsProps

            if ~isempty(StimRangesFinal)
                [EventsPeriStimulus,PeriStimulusRange] = group_EventsPeriStimulus(EventTimeStamps,StimRangesFinal,...
                    'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
                    'round_digit_sig',round_digit_sig); % group event time stamps around stimulations

                [EventFreqInBins(rn).EventFqInBins,binEdges] = get_EventFreqInBins_roi(EventsPeriStimulus,PeriStimulusRange,...
                    'binWidth',binWidth,'plotHisto',false); % calculate the event frequencies (in bins) in a roi and assigne the array to the EventFreqInBins
            end
        end
        EventFreqInBins_cell{tn} = EventFreqInBins;
        if roi_num == 0 && ~exist('binEdges','var')
            binEdges = [];
        end


    end
    EventFreqInBins = [EventFreqInBins_cell{:}];
    varargout{1} = binEdges;
    varargout{2} = stimShadeData;
    varargout{3} = stimShadeName;
    varargout{4} = stimEventCatName;
end
