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


OGdur = 0;
if (strcmp(trialType, 'OG-LED-10s'))
    OGdur = sec2frames(10);
else
    if (strcmp(trialType, 'OG-LED-5s'))
        OGdur = sec2frames(5);
    else
        if (strcmp(trialType, 'OG-LED-1s'))
            OGdur = sec2frames(1);
        end
    end
end
trialLength = PREwin+OGdur+POSTwin+1;

meanTraceSegments = nan(trialLength, nROIs);
traceSegments = [];

xAx = [1:trialLength];
xAx = xAx ./ frameRate;

for ROI = 1:nROIs
    ROItrace = getROItraceFromTrialData(trialData, ROI);
    TS =  getOGsegmentsFromROItrace(ROItrace, eventStarts, OGdur, PREwin, POSTwin) ;
    TS = TS(:, :) - TS(PREwin-1, :);
    traceSegments = [traceSegments TS];
    meanTraceSegments = [meanTraceSegments mean(traceSegments', 'omitnan')'];

end
    plot(xAx, traceSegments, 'b', 'HandleVisibility','off');
    plot (xAx, meanTraceSegments, 'r', 'LineWidth', 2);
%    ylim ([min(min(meanTraceSegments)) max(max(meanTraceSegments))]);
    axp = get(gca);
    ylims = axp.YLim;
    rectPos = [frames2sec(PREwin) ylims(1) frames2sec(OGdur) ylims(2)-ylims(1)];
    rectangle(gca, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.2]);
    xlabel ('sec');
%    legend({'ROI mean'});
    titleString = [trialIDs{1} ' with ' num2str(nROIs) ' ROIs, ' num2str(length(eventStarts)) ' stimulations'];
    title(titleString);
    