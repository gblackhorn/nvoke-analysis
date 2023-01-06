function [EventsPeriStimulus,PeriStimulusRange,varargout] = group_EventsPeriStimulus(eventTimeStamps,StimRanges,varargin)
    % Group events using stimulation ranges and set the event timestamps relative to stimulation
    % onset, which is 0

    % group_EventsPeriStimulus(eventTimeStamps,StimRanges) Using the StimRanges (a n*2 array
    % containing the start and end times of n stimulations) to group eventTimeStamps (a numerical
    % array). By default, the eventTimeStamps will be aligned to their own stimRanges (the onset).

    % Defaults
    AlignEventsToStim = true; % align the eventTimeStamps to the onsets of the stimulations
    preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
    postStim_duration = 5; % unit: second. include events happened after the end of stimulations
    round_digit_sig = 2; % round to the Nth significant digit for duration

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('preStim_duration', varargin{ii}) 
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
    EventsPeriStimulus = cell(group_num,1); % create an empty cell array to store the eventTimeStamps around each stimulation
    eventTimeStamps = eventTimeStamps(:); % make sure that eventTimeStamps is a vertical array
    for gn = 1:group_num
        event_idx = find(eventTimeStamps>=PeriStimulusRange(gn,1) & eventTimeStamps<=PeriStimulusRange(gn,2));
        EventsPeriStimulus{gn} = eventTimeStamps(event_idx);

        if AlignEventsToStim
            EventsPeriStimulus{gn} = EventsPeriStimulus{gn}-StimRanges(gn,1);
        end
    end
end
