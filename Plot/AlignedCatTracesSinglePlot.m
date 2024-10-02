function [varargout] = AlignedCatTracesSinglePlot(alignedData, stimNames, eventCat, varargin)
    % Plot aligned traces of a certain event category

    % alignedData: A struct var output by the function 'get_event_trace_allTrials'
    % stimNames: A string containing the stimulation names. Recording applied with stimulations
    % specified in the string will be kept. If the input is empty, {''}, all stimulations will be kept
    % eventCat: A character var. Events belong to this event category, such as 'spon', 'trig', etc., will be plot

    % Note: 'event_type' for alignedData must be 'detected_events'

    % Parse input arguments
    p = inputParser;
    addParameter(p, 'filterROIs', false, @islogical);
    addParameter(p, 'filterROIsStimTags', {}, @iscell);
    addParameter(p, 'filterROIsStimEffects', {}, @iscell);
    addParameter(p, 'screenWithPreOrPost', false, @islogical); 
    addParameter(p, 'preOrPost', @(x) ischar(x) && any(strcmp(x, {'pre', 'post'}))); 
    addParameter(p, 'preOrPostEventCat', @ischar); 
    addParameter(p, 'preOrPostDiffTime', 5, @isnumeric); % Unit: second
    addParameter(p, 'plot_combined_data', true);
    addParameter(p, 'subNucleiType', '');
    addParameter(p, 'shadeType', 'std');
    addParameter(p, 'showRawtraces', true);
    addParameter(p, 'showMedian', false);
    addParameter(p, 'medianProp', 'FWHM');
    addParameter(p, 'y_range', [-20 30]);
    addParameter(p, 'yRangeMargin', 0.5);
    addParameter(p, 'normMethod', 'none', @(x) any(validatestring(x, {'none', 'spon', 'highpassStd'})));
    % addParameter(p, 'normalized', false);
    addParameter(p, 'tickInt_time', 1);
    addParameter(p, 'plotUnitWidth', 0.25);
    addParameter(p, 'plotUnitHeight', 0.4);
    addParameter(p, 'debugMode', false);
    addParameter(p, 'plotWhere', []);
    addParameter(p, 'fname', '');

    parse(p, varargin{:});
    args = p.Results;

    if args.filterROIs
        [alignedData,tfIdxWithSubNucleiInfo,roiNumAll,roiNumKep,roiNumDis] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
            'stim_names',args.filterROIsStimTags,'filters',args.filterROIsStimEffects);
    end


    % Filter data based on stimNames and subNucleiType
    alignedData = filterData(alignedData, stimNames, args.subNucleiType);

    % Determine the figure name
    fname = determineFigureName(args.fname, eventCat, stimNames, args.subNucleiType, args.shadeType, args.showMedian);

    % Decide where to plot the traces
    plotWhere = decidePlotLocation(args.plotWhere, fname);

    % Process trace data
    [tracesData, eventProp_trials, timeInfo] = processTraceData(alignedData, eventCat, args);

    % Plot aligned traces average
    [tracesAverage, tracesShade, nNum, titleName] = plotAlignedTracesAverage(plotWhere, tracesData, timeInfo, ...
        'eventsProps', eventProp_trials, 'shadeType', args.shadeType, ...
        'plot_median', args.showMedian, 'medianProp', args.medianProp, ...
        'plot_combined_data', args.plot_combined_data, 'plot_raw_traces', args.showRawtraces, ...
        'y_range', args.y_range, 'tickInt_time', args.tickInt_time, 'stimName', stimNames,...
        'titlePrefix', args.subNucleiType, 'eventCat', eventCat);

    % Create trace info structure
    traceInfo = createTraceInfo(fname, eventCat, args.subNucleiType, stimNames, timeInfo, ...
        tracesData, tracesAverage, tracesShade, eventProp_trials, nNum);

    % Return outputs
    varargout{1} = gca;
    varargout{2} = traceInfo;
end

function alignedData = filterData(alignedData, stimNames, subNucleiType)
    % Filter aligned data based on stimNames and subNucleiType
    if ~isempty(stimNames)
        alignedData = filter_entries_in_structure(alignedData, 'stim_name', 'tags_keep', stimNames,'ExactMatch',true);

    end
    if ~isempty(subNucleiType)
        alignedData = screenSubNucleiROIs(alignedData, subNucleiType);
    end
end

function fname = determineFigureName(fname, eventCat, stimNames, subNucleiType, shadeType, showMedian)
    % Determine the figure name based on input parameters
    if isempty(fname)
        fNameSubNucleiType = '';
        if ~isempty(subNucleiType)
            fNameSubNucleiType = ['-', subNucleiType];
        end
        if ~isempty(stimNames)
            stimNameTag = sprintf('[%s]', stimNames);
        else
            stimNameTag = '';
        end
        showMedianStr = '';
        if showMedian
            showMedianStr = '_MedianTrace';
        end
        fname = sprintf('alignedCalTraces-%s%s%s_shade-%s%s', eventCat, stimNameTag, fNameSubNucleiType, shadeType, showMedianStr);
    end
end

function plotWhere = decidePlotLocation(plotWhere, fname)
    % Decide where to plot the traces
    if isempty(plotWhere)
        fig_canvas(1, 'unit_width', 0.3, 'unit_height', 0.3, 'fig_name', fname);
        plotWhere = gca;
    end
end

function [tracesData, eventProp_trials, timeInfo] = processTraceData(alignedData, eventCat, args)
    % Process trace data based on input parameters
    timeInfo = alignedData(1).time;
    num_stim = numel(alignedData);
    traceData_cell_trials = cell(1, num_stim);
    eventProp_cell_trials = cell(1, num_stim);

    for i = 1:num_stim
        trialName = alignedData(i).trialName;
        recDateTimeInfo = trialName(1:15);
        traceInfo_trial = alignedData(i).traces;
        num_roi = numel(traceInfo_trial);
        traceData_cell_rois = cell(1, num_roi);
        eventProp_cell_rois = cell(1, num_roi);

        for j = 1:num_roi
            if args.screenWithPreOrPost && ~isempty(args.preOrPostEventCat) && ~isempty(args.preOrPost)
                event_idx = screenEventsWithPreOrPostEvents(traceInfo_trial(j).eventProp, eventCat,...
                    args.preOrPost, args.preOrPostEventCat);
            else
                eventCat_info = {traceInfo_trial(j).eventProp.peak_category};
                event_idx = find(strcmpi(eventCat_info, eventCat));
            end
            if ~isempty(event_idx)
                roiName = alignedData(i).traces(j).roi;
                if args.debugMode
                    fprintf('  - roi (%g/%g): %s\n', j, num_roi, roiName);
                end
                traceData_cell_rois{j} = traceInfo_trial(j).value(:, event_idx);
                eventProp_cell_rois{j} = traceInfo_trial(j).eventProp(event_idx);
                % if args.normalized
                %     peakMagDelta = [traceInfo_trial(j).eventProp(event_idx).peak_mag_delta];
                %     peakMagDelta = reshape(peakMagDelta, 1, []);
                %     traceData_cell_rois{j} = traceData_cell_rois{j} ./ peakMagDelta;
                % end
                DateTimeRoi = sprintf('%s_%s', recDateTimeInfo, roiName);
                [eventProp_cell_rois{j}.DateTimeRoi] = deal(DateTimeRoi);
            end

            % Normalization methods
            switch args.normMethod
                case 'spon'
                    sponAmp = traceInfo_trial(j).sponAmp;
                    traceData_cell_rois{j} = traceData_cell_rois{j} / sponAmp;
                case 'highpassStd'
                    % Add your highpassStd normalization logic here
                    % For example:
                    highpassStd = traceInfo_trial(j).hpStd;  % Assuming highpassData exists
                    traceData_cell_rois{j} = traceData_cell_rois{j} / highpassStd;
                case 'none'
                    % No normalization
            end
        end
        traceData_cell_trials{i} = [traceData_cell_rois{:}];
        eventProp_cell_trials{i} = [eventProp_cell_rois{:}];
    end

    traceData_cell_trials = downSampleHighFreqCell(traceData_cell_trials);
    tracesData = [traceData_cell_trials{:}];
    eventProp_trials = [eventProp_cell_trials{:}];
end

function traceInfo = createTraceInfo(fname, eventCat, subNucleiType, stimNames, timeInfo, ...
    tracesData, tracesAverage, tracesShade, eventProp_trials, nNum)
    % Create a structure to store the info of aligned traces
    traceInfo_fields = {'fname', 'eventCat', 'subNucleiType', 'stim', 'stimNames', 'timeInfo', ...
        'mean_val', 'ste_val', 'recNum', 'recDateNum', 'roiNum', 'tracesNum', 'eventProps'};
    traceInfo = empty_content_struct(traceInfo_fields, 1);

    traceInfo.fname = fname;
    traceInfo.group = eventCat;
    traceInfo.subNucleiType = subNucleiType;
    traceInfo.stim = stimNames; 
    traceInfo.stimNames = stimNames;
    traceInfo.timeInfo = timeInfo;
    traceInfo.traces = tracesData;
    traceInfo.mean_val = tracesAverage;
    traceInfo.ste_val = tracesShade;
    traceInfo.eventProps = eventProp_trials;
    traceInfo.recNum = nNum.recNum;
    traceInfo.recDateNum = nNum.recDateNum;
    traceInfo.roiNum = nNum.roiNum;
    traceInfo.tracesNum = nNum.tracesNum;
end

function [CellArrayDataDS] = downSampleHighFreqCell(CellArrayData)
    % Check the datapoint number in every cell of CellArrayData. Downsample the high frequency cell 
    CellArrayDataDS = CellArrayData;
    CellArrayDataNum = cellfun(@(x) size(x, 1), CellArrayData);
    CellArrayDataNumUnique = unique(CellArrayDataNum);
    idx = find(CellArrayDataNumUnique, 1);
    targetLength = CellArrayDataNumUnique(idx);

    if ~isempty(targetLength)
        biggerLengthIDX = find(CellArrayDataNum > targetLength);
        if ~isempty(biggerLengthIDX) && ~isempty(targetLength)
            for n = 1:numel(biggerLengthIDX)
                cellIDX = biggerLengthIDX(n);
                originalLength = CellArrayDataNum(cellIDX);
                CellArrayDataDS{cellIDX} = resample(CellArrayData{cellIDX}, targetLength, originalLength);
            end
        end
    end
end
