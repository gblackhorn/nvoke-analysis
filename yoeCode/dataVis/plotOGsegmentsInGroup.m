function R = plotOGsegmentsInGroup (IOnVokeData, PREwin, POSTwin)
%plots averaged calcium traces in entire group aligned on OG segments

frameRate = getFrameRateForTrial(IOnVokeData(1, :));
nTrials = getNtrialsFromROIdata(IOnVokeData);
trialType = getTrialTypeFromROIdataStruct(IOnVokeData);
OGdur = getOGdurFromTrialData(IOnVokeData(1, :));
grandAverageSegments = [];
figure;
NCOLS = 2;
NROWS = ceil(nTrials / NCOLS);
for trial = 1:nTrials
    subplot(NROWS, NCOLS, trial); hold on;
   MTS = plotOGsegmentsInTrial (IOnVokeData(trial, :), PREwin, POSTwin, gca);
   MTS = MTS(:, :) - MTS (PREwin-1, :); 
    meanTraceSegments{trial} = MTS;
    grandAverageSegments = [grandAverageSegments; mean(meanTraceSegments{trial}', 'omitnan')];
end

xAx = [1:length(meanTraceSegments{1})];
xAx = xAx ./ frameRate;



figure; hold on;
plot (xAx,grandAverageSegments', 'b', 'HandleVisibility','off' );
plot (xAx, mean(grandAverageSegments, 'omitnan'), 'r', 'LineWidth', 2);


axp = get(gca);
ylims = axp.YLim;
rectPos = [frames2sec(PREwin) ylims(1) frames2sec(OGdur) ylims(2)-ylims(1)];
rectangle(gca, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.2]);
xlabel('sec');
legend ({'Mean of all trials'});

titleString = ['Mean traces in ' trialType ' trials '];
title (titleString);

R = grandAverageSegments;