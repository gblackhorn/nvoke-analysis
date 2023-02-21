function [EventFreqInBins,varargout] = get_EventFreqInBins_trial(EventsProps,StimRanges,varargin)
    % Collect events from multiple ROIs in a trial ('alignedData_allTrials') and calculate the event
    % frequency in time bins. Return a struct var containing the frequencies trial names and roi names. 
    % Note: This is used for the trial with only one type of stimulation (same parameters, such as duration).

    % Use fun 'group_EventsPeriStimulus' and 'get_EventFreqInBins_roi' to get events and calculate
    % the frequency in time bins

    % [EventFreqInBins] = get_EventFreqInBins_roi(EventsProps,StimRanges)
    % 'EventsProps' is a cell array, in which each cell contains the event properties from a single
    %  ROI. Specify the event property used to calculate the event frequency
    %  with 'PropName'. 'rise_time' is the default value for the 'PropName'. 

    % Defaults
    binWidth = 1; % the width of histogram bin. the default value is 1 s.
    PropName = 'rise_time';
    TrialName = 'trial';
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
    if exist('StimDuration_aligned')==0 || isempty(StimDuration_aligned)
        [StimDurationInfo] = CalculateStimDuration(StimRanges,round_digit_sig); % Get a structure var 'StimDurationInfo'
        StimDuration_aligned = StimDurationInfo.range_aligned; % [0 StimDuration]
    end

    % Calculate event frequencies in time bins for each ROI in the trial and organize them in 'EventFreqInBins'
    roi_num = numel(EventsProps); % number of ROIs
    if exist('roiNames')==0 || numel(roiNames)~=roi_num % if 'roiNames' does not exist or its number does not equal to roi_num
        roiNames = NumArray2StringCell(size(roi_num,1));
    end
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

    varargout{1} = binEdges;
end
