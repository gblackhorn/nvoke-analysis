function [tracesAverage,tracesShade,varargout] = plotAlignedTracesAverage(plotWhere,tracesData,timeInfo,varargin)
    % Plot the average of aligned traces. Use ste/std values for plotting the shade
    
    % Defaults
    eventsProps = [];
    plot_combined_data = true; % mean value and std of all traces
    plot_raw_races = false; % true/false. true: plot every single trace
    shadeType = 'ste'; % std/ste
    y_range = [];
    tickInt_time = 1; % interval of tick for timeInfo (x axis)

    stimName = '';
    eventCat = '';

    % plotUnitWidth = 0.3; % normalized size of a single plot to the display
    % plotUnitHeight = 0.4; % nomralized size of a single plot to the display

    % % Optionals for inputs
    for ii = 1:2:(nargin-3)
    	if strcmpi('eventsProps', varargin{ii})
    		eventsProps = varargin{ii+1};
    	elseif strcmpi('shadeType', varargin{ii})
    		shadeType = varargin{ii+1};
    	elseif strcmpi('plot_combined_data', varargin{ii})
    		plot_combined_data = varargin{ii+1};
        elseif strcmpi('plot_raw_races', varargin{ii})
            plot_raw_races = varargin{ii+1};
        elseif strcmpi('y_range', varargin{ii})
            y_range = varargin{ii+1};
        elseif strcmpi('tickInt_time', varargin{ii})
            tickInt_time = varargin{ii+1};
        elseif strcmpi('stimName', varargin{ii})
            stimName = varargin{ii+1};
        elseif strcmpi('eventCat', varargin{ii})
            eventCat = varargin{ii+1};
        end
    end

    tracesAverage = mean(tracesData, 2, 'omitnan');
    stimRepeatNum = size(tracesData,2);

    % Calculate the number of recordings, the number of dates
    % (animal number), the number of neurons and the number of
    % traces
    if ~isempty(eventsProps)
        [nNum.recNum,nNum.recDateNum,nNum.roiNum,nNum.tracesNum] = calcDataNum(eventsProps);
    else
        nNum.recNum = NaN;
        nNum.recDateNum = NaN;
        nNum.roiNum = NaN;
        nNum.tracesNum = size(tracesData,2);
    end

    % tracesShade = std(tracesData, 0, 2, 'omitnan');
    switch shadeType
        case 'std'
            tracesShade = std(tracesData, 0, 2, 'omitnan');
        case 'ste'
            tracesShade = std(tracesData, 0, 2, 'omitnan')/sqrt(stimRepeatNum);
        otherwise
            error('invalid shadeType. It must be either std or ste')
    end


    if ~isempty(tracesData)
        % Use the shade area to decide the y_range
        if isempty(y_range)
            yUpperLim = max(tracesAverage+tracesShade);
            yLowerLim = min(tracesAverage-tracesShade);
            yDiff = yUpperLim-yLowerLim;
            y_range = [yLowerLim-yDiff*yRangeMargin yUpperLim+yDiff*yRangeMargin];
        end

        plot_trace(timeInfo, tracesData, 'plotWhere', plotWhere,...
            'plot_combined_data', plot_combined_data,...
            'mean_trace', tracesAverage, 'mean_trace_shade', tracesShade,...
            'plot_raw_races',plot_raw_races,'y_range', y_range,'tickInt_time',tickInt_time); % 'y_range', y_range
    end
    titleName = sprintf('%s [%s] %g-animal %g-roi %g-trace',...
        stimName,eventCat,nNum.recDateNum,nNum.roiNum,nNum.tracesNum);
    title(titleName)

    varargout{1} = nNum;
    varargout{2} = titleName;
end

function [recNum,recDateNum,roiNum,tracesNum] = calcDataNum(eventsProps)
    % calculte the n numbers using the structure var 'eventsProps'

    % get the date and time info from trial names
    % one specific date-time (exp. 20230101-150320) represent one recording
    % one date, in general, represent one animal
    if ~isempty(eventsProps)
        dateTimeRoiAll = {eventsProps.DateTimeRoi};
        dateTimeAllRec = cellfun(@(x) x(1:15),dateTimeRoiAll,'UniformOutput',false);
        dateAllRec = cellfun(@(x) x(1:8),dateTimeRoiAll,'UniformOutput',false);
        dateTimeRoiUnique = unique(dateTimeRoiAll);
        dateTimeUnique = unique(dateTimeAllRec);
        dateUnique = unique(dateAllRec);

        % get all the n numbers
        recNum = numel(dateTimeUnique);
        recDateNum = numel(dateUnique);
        roiNum = numel(dateTimeRoiUnique);
        tracesNum = numel(dateTimeRoiAll);
    else
        recNum = 0;
        recDateNum = 0;
        roiNum = 0;
        tracesNum = 0;
    end
end