function [EventsPeriStimulus,PeriStimulusRange,varargout] = group_EventsPeriStimulus(EventTimeStamps,StimRanges,varargin)
    % Group events using stimulation ranges and set the event timestamps relative to stimulation
    % onset, which is 0

    % [EventsPeriStimulus,PeriStimulusRange] = group_EventsPeriStimulus(EventTimeStamps,StimRanges) 
    % Using the StimRanges (a n*2 array containing the start and end
    % times of n stimulations) to group EventTimeStamps (a numerical array). By default, the
    % EventTimeStamps will be aligned to their own stimRanges (the onset).

    % Defaults
    AlignEventsToStim = true; % align the EventTimeStamps to the onsets of the stimulations: subtract EventTimeStamps with stimulation onset time
    preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
    postStim_duration = 5; % unit: second. include events happened after the end of stimulations
    round_digit_sig = 2; % round to the Nth significant digit for duration

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('AlignEventsToStim', varargin{ii}) 
            AlignEventsToStim = varargin{ii+1}; % events happened before the onset of stimulations will be collected and grouped
        elseif strcmpi('preStim_duration', varargin{ii}) 
            preStim_duration = varargin{ii+1}; % events happened before the onset of stimulations will be collected and grouped
        elseif strcmpi('postStim_duration', varargin{ii})
            postStim_duration = varargin{ii+1}; % events happened after the end of stimulations will be collected and grouped
        elseif strcmpi('StimDuration', varargin{ii})
            StimDuration = varargin{ii+1}; % specify the duration of stimulations. only a single number is valid
        elseif strcmpi('round_digit_sig', varargin{ii})
            round_digit_sig = varargin{ii+1}; % round to the Nth significant digit for duration
        end
    end

    if exist('StimDuration')==0 
        [StimDurationInfo] = CalculateStimDuration(StimRanges,round_digit_sig); % Get a structure var 'StimDurationInfo'
        StimDuration = StimDurationInfo.fixed;
        StimDuration_aligned = StimDurationInfo.range_aligned; % [0 StimDuration]
    end

    PeriStimulusRange = [StimRanges(:,1)-preStim_duration StimRanges(:,2)+postStim_duration]; % add pre- and post stimulation to the range. This will be used to find events
    group_num = size(StimRanges,1); % number of stimulations = number of groups
    EventsPeriStimulus = cell(group_num,1); % create an empty cell array to store the EventTimeStamps around each stimulation
    EventTimeStamps = EventTimeStamps(:); % make sure that EventTimeStamps is a vertical array
    for gn = 1:group_num
        event_idx = find(EventTimeStamps>=PeriStimulusRange(gn,1) & EventTimeStamps<=PeriStimulusRange(gn,2));
        EventsPeriStimulus{gn} = EventTimeStamps(event_idx);

        if AlignEventsToStim
            EventsPeriStimulus{gn} = EventsPeriStimulus{gn}-StimRanges(gn,1);
        end
    end
    if AlignEventsToStim
        PeriStimulusRange = [StimDuration_aligned(1)-preStim_duration StimDuration_aligned(2)+postStim_duration]; % stimulation onset at 0, preStim_duration and postStim_duration are added to the beginning and the end of it.
    end
end
