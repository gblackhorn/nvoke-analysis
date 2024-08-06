function [posRefEventIDX, varargout] = screenEventsWithPreOrPostEvents(eventProps, eventCat, preOrPost, preOrPostEventCat, varargin)
    % Get the events in the specified category from a ROI eventProp (including rise_time/peak_time
    % and peak_category info). The events must have a pre/post event belong to a specified category



    % Create an instance of the inputParser
    p = inputParser;

    % Required input
    addRequired(p, 'eventProps', @isstruct);
    addRequired(p, 'eventCat', @ischar);
    addRequired(p, 'preOrPost', @(x) ischar(x) && any(strcmp(x, {'pre', 'post'})));
    addRequired(p, 'preOrPostEventCat', @ischar);

    % Add optional parameters to the input p
    addParameter(p, 'preOrPostDiffTime', 5, @isnumeric); % Unit: second
    addParameter(p, 'refType', 'index', @(x) ischar(x) && any(strcmp(x,{'index', 'time'}))); 
        % Use index or time to locate the pre/post event
    addParameter(p, 'timeType', 'peak_time', @(x) ischar(x) && any(strcmp(x,{'peak_time', 'rise_time'}))); 
        % Choose the field used to locate the event time

    % addParameter(p, 'plotCombinedData', true, @islogical);

    % Parse inputs
    parse(p, eventProps, eventCat, preOrPost, preOrPostEventCat, varargin{:});

    % Retrieve parsed values
    preOrPostDiffTime = p.Results.preOrPostDiffTime;
    refType = p.Results.refType;
    timeType = p.Results.timeType;


    % Decide the relative index/time of preOrPost events
    switch preOrPost
        case 'pre'
            relativeIDX = -1;
            relativeTime = -preOrPostDiffTime; 
        case 'post'
            relativeIDX = 1;
            relativeTime = preOrPostDiffTime; 
    end


    % Look for the eventCat in the 'peak_category' field of eventProps
    eventCatTF = strcmpi({eventProps.peak_category}, eventCat);
    eventCatIDX = find(eventCatTF);


    if ~isempty(eventCatIDX)
        posRefEventTF = logical(zeros(1, length(eventCatIDX)));
        eventTimeAll = [eventProps.(timeType)]; % Time of all the events in the ROI

        % Loop through all the found eventCat and check if they have a pre/post event of specific category
        for n = 1:numel(eventCatIDX)
            if strcmp(refType, 'index')
                pIDX = eventCatIDX(n)+relativeIDX;

                if pIDX < 1 || pIDX > numel(eventProps)
                    % Discard the pIDX if the pre/post event IDX is outside of the event list
                    pIDX = [];
                elseif ~strcmp(eventProps(pIDX).peak_category, preOrPostEventCat)
                    pIDX = [];
                end
            elseif strcmp(refType, 'time')
                % Get the evnet time
                refEventTime = eventProps(eventCatIDX(n)).(timeType);

                % Set a time range end to look for pre/post event
                pTimeLimit = refEventTime+relativeTime;

                % Find the events around reference event's time (Use 'preOrPostDiffTime' as range)
                betweenIndices = find(eventTimeAll > min(refEventTime, pTimeLimit) & eventTimeAll < max(refEventTime, pTimeLimit));

                % Look for 'preOrPostEventCat' in the betweenIndices events
                pEventsTF = strcmp(eventProps(betweenIndices).peak_category, preOrPostEventCat);
                if isempty(find(pEventsTF))
                    pIDX = [];
                else
                    pIDX = betweenIndices(pEventsTF);
                end
            end

            % Keept the the referent event if it has a pre/post event
            if ~isempty(pIDX)
                posRefEventTF(n) = true; 
            end
        end

        % Get the index and properties of the referent events with a pre/post event
        posRefEventIDX = eventCatIDX(posRefEventTF);
        posRefEventProp = eventProps(posRefEventIDX);
    else
        posRefEventIDX = [];
        posRefEventProp = [];
    end

    varargout{1} = posRefEventProp;
end
