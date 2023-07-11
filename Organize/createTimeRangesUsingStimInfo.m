function [timeRanges,timeRangesIDX,stimRanges,stimRangesIDX,varargout] = createTimeRangesUsingStimInfo(timeData,stimInfo,varargin)
    % Create time ranges using 'timeInfo' and stimInfo

    % timeInfo: a vector. Its length is same as the column number of traceData：each
    % stimInfo: alignedData_trial.stimInfo

    % Defaults
    preTime = 5; % include time before stimulation starts for plotting
    postTime = 5; % include time after stimulation ends for plotting. []: until the next stimulation starts

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1};
        elseif strcmpi('postTime', varargin{ii})
            postTime = varargin{ii+1};
        % elseif strcmpi('yRange', varargin{ii})
        %     yRange = varargin{ii+1}; % input a 1x2 number array for yMin and yMax to draw shade in this range
        end
    end


    % Get necessary information from stimInfo 
    stimRanges = stimInfo.UnifiedStimDuration.range;

    % Get data point number from the timeData
    maxDatapointNum = numel(timeData);


    % add the pre-time to the time ranges
    stimPlusRanges = NaN(size(stimRanges));
    stimPlusRanges(:,1) = stimRanges(:,1)-preTime;
    if ~isempty(postTime)
        stimPlusRanges(:,2) = stimRanges(:,2)+postTime;
    end


    % This code only works for the fixed stimulation repeats 
    if ~stimInfo.UnifiedStimDuration.varied
        stimNum = size(stimRanges,1);
        stimPlusRangesIDX = NaN(size(stimRanges));
        stimRangesIDXIDX = NaN(size(stimRanges));

        [stimPlusRanges(:,1),stimPlusRangesIDX(:,1)] = find_closest_in_array(stimPlusRanges(:,1),timeData);
        [stimRanges(:,1),stimRangesIDX(:,1)] = find_closest_in_array(stimRanges(:,1),timeData);
        [stimRanges(:,2),stimRangesIDX(:,2)] = find_closest_in_array(stimRanges(:,2),timeData);

        if ~isempty(postTime)
            [stimPlusRanges(:,2),stimPlusRangesIDX(:,2)] = find_closest_in_array(stimPlusRanges(:,2),timeData);
        end


        % Get the number of data points for the first stim start to the first stim end. And use this
        % number for all the following stimulations
        timeRanges = NaN(size(stimRanges));
        timeRanges(:,1) = stimPlusRanges(:,1);

        timeRangesIDX = NaN(size(stimRanges));
        timeRangesIDX(1,1) = stimPlusRangesIDX(1,1); % start from the 1st stimulation 
        if isempty(postTime)
            timeRangesIDX(1,2) = stimRangesIDX(2,1)-1; % end just before the 2nd stimulation
        else
            timeRangesIDX(1,2) = stimPlusRangesIDX(1,2);
        end

        timeRanges(1,2) = timeData(timeRangesIDX(1,2));
        datapointNum = timeRangesIDX(1,2)-timeRangesIDX(1,1)+1; % data point number of a single range of timeRanges
        timeDuration = timeData(timeRangesIDX(1,2))-timeData(timeRangesIDX(1,1));

        for sn = 2:stimNum
            timeRangesIDX(sn,1) = stimPlusRangesIDX(sn,1);
            timeRangesIDX(sn,2) = stimPlusRangesIDX(sn,1)+datapointNum-1;

            % use the maxDatapointNum as the range end if there is not enough data point
            if timeRangesIDX(sn,2) > maxDatapointNum
                timeRangesIDX(sn,2) = maxDatapointNum;
            end
            timeRanges(sn,2) = timeData(timeRangesIDX(sn,2));
        end
    end


    varargout{1} = timeDuration;
    varargout{2} = datapointNum; % data point number of a single range of timeRanges
    % varargout{2} = rangEventsTime; % cell var
    % varargout{3} = rangEventsIDX; % cell var
end
