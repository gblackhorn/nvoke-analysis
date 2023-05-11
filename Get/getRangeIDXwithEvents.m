function [posRangeIDX,varargout] = getRangeIDXwithEvents(eventTime,timeRanges,varargin)
    % Giving events time, time ranges, returns in which ranges the events can be found

    % timeRanges must be a n*2 number array. The first column contains the start of range, and the
    % 2nd colmn contains the end of range 

    % Defaults
% 
    % Optionals for inputs
    % for ii = 1:2:(nargin-2)
    %     if strcmpi('shadeColor', varargin{ii})
    %         shadeColor = varargin{ii+1};
    %     elseif strcmpi('shadeAlpha', varargin{ii})
    %         shadeAlpha = varargin{ii+1};
    %     elseif strcmpi('yRange', varargin{ii})
    %         yRange = varargin{ii+1}; % input a 1x2 number array for yMin and yMax to draw shade in this range
    %     end
    % end

    % Get the number of time ranges
    timeRangesNum = size(timeRanges,1);

    % Suppose none of the ranges contains events
    rangeIDX_tf = logical(false(timeRangesNum,1));


    % Loop through the timeRanges, and find out which ranges contain events, which do not
    for n = 1:timeRangesNum
        timeRange = timeRanges(n,:);
        eventInRange = find(eventTime>=timeRange(1) & eventTime<=timeRange(2));

        % Mark the ranges with events
        if ~isempty(eventInRange)
            rangeIDX_tf(n) = true;
        end
    end

    posRangeIDX = find(rangeIDX_tf==true);
    negRangeIDX = find(rangeIDX_tf==false);

    varargout{1} = negRangeIDX;
end
