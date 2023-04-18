function [alignedData_filtered,varargout] = filter_eventProp_followEvents_trials(alignedData,eventCat,followEventCat,varargin)
    % Filter eventProps from every ROI 
    % This function use function 'get_followingEvent' on every eventProp


    % Defaults
    eventCatField = 'peak_category';
    followEventDuration = 5; % unit: s. Following event(s) will be found in this time duration after the event with specified category
    followEventNum = 1; % number of following event for each specified category event.
    timeType = 'rise_time';


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

    alignedData_filtered = alignedData;

    % Loop through trials
    trialNum = numel(alignedData_filtered);
    for tn = 1:trialNum
        ROIsInfo = alignedData_filtered.traces(tn);
        roiNum = numel(ROIsInfo);

        % loop through trials
        for rn = 1:roiNum
            eventProp = ROIsInfo(rn).eventProp;
            NeweventProp = get_followingEvent(eventProp,eventCat,followEventCat,...
                'followEventDuration',followEventDuration);
            ROIsInfo(rn).eventProp = NeweventProp;
        end
        alignedData_filtered.traces(tn) = ROIsInfo;
    end
end

