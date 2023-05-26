function [StimEventsTime,varargout] = getStimRelatedEvents(eventsProps,stimEventCat,varargin)
    % Giving eventProperties of multiple ROIs and a specified event cateogry, returns stimulation related events

    % Inputs:
    %   EventsProp: cell array. Each cell contains event properties from a single ROI
    %   stimEventCat: cell array containing 1 or more strings


    % Defaults
    % stimEventsPair(1).stimName = 'og-5s';
    % stimEventsPair(1).eventCat = 'rebound';
    % stimEventsPair(2).stimName = 'ap-0.1s';
    % stimEventsPair(2).eventCat = 'trig';
    % stimEventsPair(3).stimName = 'og-5s ap-0.1s';
    % stimEventsPair(3).eventCat = 'rebound';

    timeField = 'peak_time';
    catField = 'peak_category';
% 
    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        % if strcmpi('stimEventsPair', varargin{ii})
        %     stimEventsPair = varargin{ii+1};
        if strcmpi('timeField', varargin{ii})
            timeField = varargin{ii+1};
        % elseif strcmpi('yRange', varargin{ii})
        %     yRange = varargin{ii+1}; % input a 1x2 number array for yMin and yMax to draw shade in this range
        end
    end


    % Get the time and categories of events
    roiNum = numel(eventsProps);
    [eventsTime] = get_EventsInfo(eventsProps,timeField);
    [eventsCat] = get_EventsInfo(eventsProps,catField);


    % Find the stimulation name in stimEventsPair and get the paired event category
    % Get the index of specified event category in eventEventCat
    stimEventCatNum = numel(stimEventCat);
    stimEventsIDX = cell(roiNum,stimEventCatNum);
    for cn = 1:stimEventCatNum
        stimEventsIDX(:,cn) = cellfun(@(x) find(strcmpi(x,stimEventCat{cn})),eventsCat,'UniformOutput',false);
    end

    stimEventsIDXall = cell(roiNum,1);
    for rn = 1:roiNum
        for cn = 1:stimEventCatNum
            if cn == 1
                stimEventsIDXall{rn} = reshape(stimEventsIDX{rn,cn},1,[]);
            else
                stimEventsIDXall{rn} = [stimEventsIDXall{rn}, reshape(stimEventsIDX{rn,cn},1,[])];
            end
        end
    end

    % Get rid of duplicated contents in stimEventsIDXall
    stimEventsIDXall = cellfun(@(x) unique(x),stimEventsIDXall,'UniformOutput',false);

    % Get the time of events with specified cateogry
    StimEventsTime = cell(size(stimEventsIDXall));
    for rn = 1:roiNum
        StimEventsTime{rn} = eventsTime{rn}(stimEventsIDXall{rn});
    end

    varargout{1} = stimEventsIDXall;
end
