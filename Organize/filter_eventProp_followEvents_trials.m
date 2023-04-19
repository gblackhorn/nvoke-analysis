function [alignedData_filtered,varargout] = filter_eventProp_followEvents_trials(alignedData,eventCat,followEventCat,varargin)
    % Filter eventProps from every ROI 
    % This function use function 'get_followingEvent' on every eventProp


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
        elseif strcmpi('debugMode', varargin{ii}) 
            debugMode = varargin{ii+1}; % rebound filter. 
        end
    end

    alignedData_filtered = alignedData;

    % Loop through trials
    trialNum = numel(alignedData_filtered);
    for tn = 1:trialNum
        ROIsInfo = alignedData_filtered(tn).traces;
        roiNum = numel(ROIsInfo);

        if debugMode
            fprintf('trial %g/%g: %s\n',tn,trialNum,alignedData_filtered(tn).trialName);
            if tn == 16
                pause
            end
        end

        % loop through trials
        for rn = 1:roiNum
            if debugMode
                fprintf('trial %g/%g: %s\n',rn,roiNum,ROIsInfo(rn).roi);
            end

            eventProp = ROIsInfo(rn).eventProp;
            NeweventProp = get_followingEvent(eventProp,eventCat,followEventCat,...
                'followEventDuration',followEventDuration);
            ROIsInfo(rn).eventProp = NeweventProp;
        end
        alignedData_filtered(tn).traces = ROIsInfo;
    end
end

