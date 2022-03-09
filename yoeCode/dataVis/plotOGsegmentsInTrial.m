function meanTraceSegments = plotOGsegmentsInTrial (trialData, PREwin, POSTwin, plotWhere)
% plot averare ca traces aligned on stimulations
% one line for average traces per each ROI
% red lines for average for all ROIs in trial

% if plotWhere is given, it is a handle for axes for plotting
% if not given, make a new fig
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end


frameRate = getFrameRateForTrial(trialData);
[eventStarts eventEnds] = getEventStartStopsforTrial(trialData, frameRate);
nROIs = getNROIsFromTrialData(trialData);
trialType = getTrialTypeFromROIdataStruct(trialData);
trialIDs = getTrialIDsFromROIdataStruct(trialData);
fovInfo = get_fov_info(trialData);


[stim_info] = get_stim_duration(trialType);
stim_dur = max(stim_info.duration);
stim_dur_frames = sec2frames(stim_dur, frameRate);

% stim_dur = 0;
% stim_ch_num = 0;

% if (strcmp(trialType, 'OG-LED-10s'))
%     stim_dur = sec2frames(10, frameRate);
% elseif (strcmp(trialType, 'OG-LED-5s'))
%     stim_dur = sec2frames(5, frameRate);
% elseif (strcmp(trialType, 'OG-LED-1s'))
%     stim_dur = sec2frames(1, frameRate);
% elseif (strcmp(trialType, 'GPIO-1-1s'))
%     stim_dur = sec2frames(1, frameRate);
% end


trialLength = PREwin+stim_dur_frames+POSTwin+1;

meanTraceSegments = nan(trialLength, nROIs);
traceSegments = [];

xAx = [1:trialLength];
xAx = xAx ./ frameRate;

if nROIs ~= 0
    for ROI = 1:nROIs
        ROItrace = getROItraceFromTrialData(trialData, ROI);
        TS =  getOGsegmentsFromROItrace(ROItrace, eventStarts, stim_dur_frames, PREwin, POSTwin) ;
        TS = TS(:, :) - TS(PREwin-1, :);
        traceSegments = [traceSegments TS];
        meanTraceSegments = [meanTraceSegments mean(traceSegments', 'omitnan')'];

    end
        plot(xAx, traceSegments, 'b', 'HandleVisibility','off');
        hold on
        plot (xAx, meanTraceSegments, 'r', 'LineWidth', 2);
    %    ylim ([min(min(meanTraceSegments)) max(max(meanTraceSegments))]);
        axp = get(gca);
        ylims = axp.YLim;

        rectPos = [frames2sec(PREwin, frameRate) ylims(1) stim_dur ylims(2)-ylims(1)];
        rectangle(gca, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.2]);

        xlabel ('sec');
    %    legend({'ROI mean'});
        titleString = [trialIDs{1} ' with ' num2str(nROIs) ' ROIs, ' num2str(length(eventStarts)) ' stimulations'];
        titleString = strrep(titleString, '_', ' ');
        if ~isempty(fovInfo)
            titleString = {titleString; fovInfo};
        end
        title(titleString);
end
    