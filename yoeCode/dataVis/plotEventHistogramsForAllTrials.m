function R = plotEventHistogramsForAllTrials(ROIdata)
% plots spike time histograms for all trials, aligned on stimulus onset
PREWIN = 10;
POSTWIN = 20;

nTrials = getNtrialsFromROIdata(ROIdata);
figure;
NCOLS = 2;
NROWS = ceil(nTrials / NCOLS);
for trial = 1:nTrials
    subplot(NROWS, NCOLS, trial);
    makeEventTrigHistoForTrial(ROIdata(trial, :), PREWIN, POSTWIN, gca);
end

trialType = getTrialTypeFromROIdataStruct(ROIdata);
suptitle(trialType);
R = 1;