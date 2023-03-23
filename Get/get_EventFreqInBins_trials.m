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
            if tn == 16
                pause
            end
        end
        
        % get the ranges of stimulations
        StimRanges = alignedData_filtered(tn).stimInfo.UnifiedStimDuration.range; 

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
        % if exist('roiNames')==0 || numel(roiNames)~=roi_num % if 'roiNames' does not exist or its number does not equal to roi_num
        %     roiNames = NumArray2StringCell(size(roi_num,1));
        % end
        TrialNames = repmat({TrialName},1,roi_num); % create a 1*roi_num cell containing the 'TrialNames' in every element
        EventFreqInBins = emptyStruct({'TrialNames','roiNames','EventFqInBins'},[1, roi_num]); % create an empty structure
        [EventFreqInBins.TrialNames] = TrialNames{:}; % add trial names in struct EventFreqInBins
        [EventFreqInBins.roiNames] = roiNames{:}; % add roi names in struct EventFreqInBins

        for rn = 1:roi_num
            EventTimeStamps = [EventsProps{rn}.(PropName)]; % get the (rn)th ROI event time stamps from the EventsProps
            [EventsPeriStimulus,PeriStimulusRange] = group_EventsPeriStimulus(EventTimeStamps,StimRanges,...
                'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
                'round_digit_sig',round_digit_sig); % group event time stamps around stimulations

            [EventFreqInBins(rn).EventFqInBins,binEdges] = get_EventFreqInBins_roi(EventsPeriStimulus,PeriStimulusRange,...
                'binWidth',binWidth,'plotHisto',false); % calculate the event frequencies (in bins) in a roi and assigne the array to the EventFreqInBins
        end
        EventFreqInBins_cell{tn} = EventFreqInBins;
        if roi_num == 0 && ~exist('binEdges','var')
            binEdges = [];
        end


        % [EventFreqInBins_cell{tn},trial_binEdges] = get_EventFreqInBins_trial(EventsProps,StimRanges,...
        %     'binWidth',binWidth,'PropName',PropName,'AlignEventsToStim',AlignEventsToStim,...
        %     'TrialName',TrialName,'roiNames',roiNames,...
        %     'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
        %     'round_digit_sig',round_digit_sig);

        % if ~isempty(trial_binEdges)
        %     binEdges = trial_binEdges;
        % end
    end
    EventFreqInBins = [EventFreqInBins_cell{:}];
    varargout{1} = binEdges;
end
