function [EventFreqInBins,varargout] = get_EventFreqInBins_AllTrials(alignedData,StimName,varargin)
    % Collect events from trials, stored in alignedData, applied with the same kind of stimulation
    % (repeat number can be different) and calculate the event frequency in time bins. Return a
    % struct var containing the frequencies trial names and roi names. 

    % Note: This is used for the trials with only one type of stimulation (same parameters, such as
    % duration).


    % [EventFreqInBins] = get_EventFreqInBins_roi(alignedData_allTrials,'og-5s')
    % 'alignedData_allTrials' is a struct var. It contains calcium signals, event propertis,
    %  stimulation infos of multiple recording trials. Use 'og-5s' to get the EventFreqInBins only
    %  from the trials applied with optogenetic stimulation for 5 second

    % Defaults
    binWidth = 1; % the width of histogram bin. the default value is 1 s.
    PropName = 'rise_time'
    % plotHisto = false; % true/false [default].Plot histogram if true.

    AlignEventsToStim = true; % align the EventTimeStamps to the onsets of the stimulations: subtract EventTimeStamps with stimulation onset time
    preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
    postStim_duration = 5; % unit: second. include events happened after the end of stimulations
    round_digit_sig = 2; % round to the Nth significant digit for duration

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('binWidth', varargin{ii}) 
            binWidth = varargin{ii+1}; % denorminator used to normalize the EventFreq 
        elseif strcmpi('PropName', varargin{ii}) 
            PropName = varargin{ii+1}; % denorminator used to normalize the EventFreq 
        elseif strcmpi('denorm', varargin{ii}) 
            denorm = varargin{ii+1}; % denorminator used to normalize the EventFreq 
        elseif strcmpi('TrialName', varargin{ii})
            TrialName = varargin{ii+1}; % specify the duration of stimulations. only a single number is valid
        elseif strcmpi('roiNames', varargin{ii})
            roiNames = varargin{ii+1}; % round to the Nth significant digit for duration
        elseif strcmpi('preStim_duration', varargin{ii})
            preStim_duration = varargin{ii+1}; % round to the Nth significant digit for duration
        elseif strcmpi('postStim_duration', varargin{ii})
            postStim_duration = varargin{ii+1}; % round to the Nth significant digit for duration
        elseif strcmpi('round_digit_sig', varargin{ii})
            round_digit_sig = varargin{ii+1}; % round to the Nth significant digit for duration
        end
    end

    % Calculate the StimDuration_aligned which is the [0 StimDuration]
    stim_names = {alignedData.stim_name}; % Get all the stimulation names
    stim_names_tf = strcmpi(stim_names,StimName); % compare the stimulation names with the input 'StimName'
    trial_idx = find(stim_names_tf); % get the index of trials applied with specified stimulations
    alignedData_filtered = alignedData(trial_idx);

    trialNum = numel(alignedData_filtered);
    EventFreqInBins_cell = cell(1,trialNum);
    for tn = 1:trialNum
        TrialName = alignedData_filtered(tn).trialName; % get the current recording trial name
        StimRanges = alignedData_filtered(tn).stimInfo.UnifiedStimDuration.range; % get the ranges of stimulations
        EventsProps = {alignedData_filtered(tn).traces.eventProp}; % get the event properties of rois from current trial
        roiNames = {alignedData_filtered(tn).traces.roi}; % get the roi names from current trial

        EventFreqInBins_cell{tn} = get_EventFreqInBins_trial(EventsProps,StimRanges,...
            'binWidth',binWidth,'PropName',PropName,'AlignEventsToStim',AlignEventsToStim,...
            'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
            'round_digit_sig',round_digit_sig);
    end
    EventFreqInBins = EventFreqInBins_cell{:};
end
