function [tracesInfo,varargout] = combineAlignedTraces(stimAlignedTrace_means,stimNameEventCat,varargin)
    % Combine the data in stimAlignedTrace_means with the settings in stimNameEventCat

    % stimAlignedTrace_means: output of function 'plot_aligned_catTraces'
    % stimNameEventCat: {{stimName1,eventCat1},{stimName2,eventCat2},...}
    %   combine the 'evnetCat' in different 'stimName'

    % Defaults

    % % Optionals for inputs
    % for ii = 1:2:(nargin-3)
    % 	if strcmpi('eventsProps', varargin{ii})
    % 		eventsProps = varargin{ii+1};
    % 	elseif strcmpi('shadeType', varargin{ii})
    % 		shadeType = varargin{ii+1};
    % 	elseif strcmpi('plot_combined_data', varargin{ii})
    % 		plot_combined_data = varargin{ii+1};
    %     elseif strcmpi('plot_raw_races', varargin{ii})
    %         plot_raw_races = varargin{ii+1};
    %     elseif strcmpi('y_range', varargin{ii})
    %         y_range = varargin{ii+1};
    %     elseif strcmpi('tickInt_time', varargin{ii})
    %         tickInt_time = varargin{ii+1};
    %     elseif strcmpi('stimName', varargin{ii})
    %         stimName = varargin{ii+1};
    %     elseif strcmpi('eventCat', varargin{ii})
    %         eventCat = varargin{ii+1};
    %     end
    % end

    % get the number of stimNameEventCat pairs
    stimNameEventCatNum = numel(stimNameEventCat);
    tracesCell = cell(1,stimNameEventCatNum);
    eventsPropsCell = cell(1,stimNameEventCatNum);
    eventsPropsCell = cell(1,stimNameEventCatNum);
    stimNamesCell = cell(1,stimNameEventCatNum);
    eventNamesCell = cell(1,stimNameEventCatNum);
    tracesInfoFieldNames = fieldnames(stimAlignedTrace_means(1).trace);
    tracesInfo = empty_content_struct(tracesInfoFieldNames,1);
    tracesInfo.timeInfo = stimAlignedTrace_means(1).trace(1).timeInfo;

    for n = 1:stimNameEventCatNum
        % Find the location of data in 'stimAlignedTrace_means' using the 'eventCat' in 'stimNameEventCat'
        eventGroupNames = {stimAlignedTrace_means.event_group};
        eventGroupIDX = find(strcmpi(eventGroupNames,stimNameEventCat{n}{2}));

        % access the traceInfo structure
        traceInfo = stimAlignedTrace_means(eventGroupIDX).trace;

        % find the traces belong to the 'stimName' in 'stimNameEventCat'
        stimNames = {traceInfo.stim};
        stimIDX = find(strcmpi(stimNames,stimNameEventCat{n}{1}));

        % access the tracesData
        tracesCell{n} = traceInfo(stimIDX).traces;
        eventsPropsCell{n} = traceInfo(stimIDX).eventProps;

        if n ~= stimNameEventCatNum
            stimNamesCell{n} = sprintf('%s & ',stimNameEventCat{n}{1});
            eventNamesCell{n} = sprintf('%s & ',stimNameEventCat{n}{2});
        else
            stimNamesCell{n} = stimNameEventCat{n}{1};
            eventNamesCell{n} = stimNameEventCat{n}{2};
        end
    end

    % combine data in the cells
    tracesInfo.traces = horzcat(tracesCell{:});
    tracesInfo.eventProps = horzcat(eventsPropsCell{:});
    tracesInfo.stim = horzcat(stimNamesCell{:});
    eventCat = horzcat(eventNamesCell{:});

    tracesInfo.mean_val = mean(tracesInfo.traces, 2, 'omitnan');
    tracesInfo.ste_val = std(tracesInfo.traces, 0, 2, 'omitnan')/sqrt(size(tracesInfo.traces,2));

    [tracesInfo.recNum,tracesInfo.recDateNum,tracesInfo.roiNum,tracesInfo.tracesNum] = calcDataNum(tracesInfo.eventProps);

    tracesInfo.group = sprintf('%s-%s animal-%g roi-%g traceNum-%g',...
        tracesInfo.stim,eventCat,tracesInfo.recDateNum,tracesInfo.roiNum,tracesInfo.tracesNum);

    varargout{1} = tracesInfo.stim;
    varargout{2} = eventCat;
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