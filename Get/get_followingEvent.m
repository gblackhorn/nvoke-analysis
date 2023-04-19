function [NeweventProp,varargout] = get_followingEvent(eventProp,eventCat,followEventCat,varargin)
    % Specify an Event category and find these events and their following one(s) in the EventProp,
    % and create NeweventProp with these events


    % Defaults
    eventCatField = 'peak_category';
    followEventDuration = 5; % unit: s. Following event(s) will be found in this time duration after the event with specified category
    followEventNum = 1; % number of following event for each specified category event.
    timeType = 'rise_time';
    debugMode = false; % true/false


    % Optionals for inputs
    for ii = 1:2:(nargin-3)
        if strcmpi('eventCatField', varargin{ii}) 
            eventCatField = varargin{ii+1}; % excitation filter.  
        elseif strcmpi('followEventDuration', varargin{ii}) 
            followEventDuration = varargin{ii+1}; % inhibition filter.
        elseif strcmpi('followEventNum', varargin{ii}) 
            followEventNum = varargin{ii+1}; % rebound filter. 
        elseif strcmpi('timeType', varargin{ii}) 
            timeType = varargin{ii+1}; % rebound filter. 
        end
    end


    % Valid the input
    if ~isstruct(eventProp) || ~ischar(eventCatField)
        error('Input_1 must be a structure, and input_2 must be a string')
    end


    % Find out which dimention of eventProp is longer
    [rowNum,colNum] = size(eventProp);
    [structLength,longerDim] = max([rowNum,colNum]);



    % Get the index of events with the specified category by 'eventCat'
    catCells = {eventProp.(eventCatField)};
    sEventsIDX = find(strcmpi(catCells,eventCat)); % index of events with specified category

    if ~isempty(sEventsIDX)
        sEventNum = numel(sEventsIDX);

        % Create a cell array. One specified event and its following events are stored in a single cell
        if longerDim == 1
            NewEventPropCell = cell(sEventNum,1);
        elseif longerDim == 2
            NewEventPropCell = cell(1,sEventNum);
        end

        for n = 1:sEventNum

            if sEventsIDX(n) < structLength
                % Get a specified-cat event and its following event(s)
                NewEventPropCell{n} = eventProp([sEventsIDX(n):sEventsIDX(n)+followEventNum]);


                % Check if the following window(s) belong to the 'followEventCat'
                fEvents = NewEventPropCell{n}(2:end);
                fEventsCat = {fEvents.(eventCatField)};
                fEventsCatTF = strcmpi(fEventsCat,followEventCat);
                if ~all(fEventsCatTF==true)
                    NewEventPropCell{n} = [];
                end

                % Check if the following window(s) is in the time range of 'followEventDuration'
                if ~isempty(NewEventPropCell{n})
                    sEvent = NewEventPropCell{n}(1);
                    sEventTime = sEvent.(timeType);
                    fEventsTime = [fEvents.(timeType)];
                    fEventsTimeRelative = fEventsTime-sEventTime;

                    if ~all(fEventsTimeRelative<=followEventDuration)
                        NewEventPropCell{n} = [];
                    end
                end
            else
                NewEventPropCell{n} = [];
            end  
        end

        % combine cell array and 
        if longerDim == 1
            NeweventProp = vertcat(NewEventPropCell{:});
        elseif longerDim == 2
            NeweventProp = horzcat(NewEventPropCell{:});
        end
    else
        NeweventProp = [];
        % varargout{1} = 
    end
end

