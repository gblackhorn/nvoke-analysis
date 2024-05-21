function [cv2,varargout] = calculateCV2(eventTimestamps, varargin)
    % CALCULATECV2 Computes the CV2 for intervals of spontaneous events,
    % excluding periods of stimulation and ignoring intervals that span across stimulation periods.
    %
    %   cv2 = calculateCV2(eventTimestamps)
    %   cv2 = calculateCV2(eventTimestamps, stimPeriods)
    %
    % Inputs:
    %   eventTimestamps - Vector of timestamps for spontaneous events
    %   stimPeriods (optional) - Nx2 matrix where each row represents the start and
    %                            end of a stimulation period [start, end]. If not provided,
    %                            the entire recording is considered.
    %
    % Outputs:
    %   cv2 - Vector of CV2 values for the spontaneous event intervals

    % Handle optional input
    if nargin < 2
        stimPeriods = [];
    else
        stimPeriods = varargin{1};
    end

    if isempty(stimPeriods)
        % No stimulation periods provided, process the entire recording
        intervals = diff(eventTimestamps);
        if length(intervals) > 1
            cv2Vector = ensureVertical(2 * abs(diff(intervals)) ./ (intervals(1:end-1) + intervals(2:end)));
            cv2 = mean(cv2Vector);
        else
            cv2Vector = []; % Not enough intervals to calculate CV2
            cv2 = [];
        end
    else
        % Remove events that occur during stimulation periods
        validEvents = true(size(eventTimestamps));
        for i = 1:size(stimPeriods, 1)
            validEvents = validEvents & ~(eventTimestamps >= stimPeriods(i, 1) & eventTimestamps <= stimPeriods(i, 2));
        end
        spontaneousEvents = eventTimestamps(validEvents);

        % Split spontaneous events into separate periods based on stimPeriods
        allPeriods = [0, stimPeriods(:)', Inf];
        validIndices = arrayfun(@(x, y) find(spontaneousEvents > x & spontaneousEvents < y), ...
                                allPeriods(1:end-1), allPeriods(2:end), 'UniformOutput', false);

        % Concatenate the intervals within each period and calculate CV2
        cv2Vector = [];
        for i = 1:length(validIndices)
            if length(validIndices{i}) > 1
                intervals = diff(spontaneousEvents(validIndices{i}));
                if length(intervals) > 1
                    cv2Vector = [cv2Vector; ensureVertical(2 * abs(diff(intervals)) ./ (intervals(1:end-1) + intervals(2:end)))];
                end
            end
        end

        if ~isempty(cv2Vector)
            cv2 = mean(cv2Vector);
        else
            cv2 = [];
        end
    end

    varargout{1} = cv2Vector;
end
