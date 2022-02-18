function R = plotMeanSpikesAllTrials(ROIdata, PREwin, POSTwin)

nTrials = getNtrialsFromROIdata(ROIdata);
trialIDs = getTrialIDsFromROIdataStruct(ROIdata);
trialType = getTrialTypeFromROIdataStruct(ROIdata);


NCOLS = 2; 
NROWS = ceil(nTrials / NCOLS);

figure; sgtitle(trialType);

for trial = 1:nTrials
    subplot(NROWS, NCOLS, trial); hold on;
    trialData = ROIdata(trial, :);
    frameRate = getFrameRateForTrial(trialData);
    meanSpikes = getMeanSpikeCaTracesForAllROIs(trialData, PREwin, POSTwin);
    spikeAmps{trial} = measureCalciumEvent(meanSpikes, 10, 100,frameRate, gca);
    
    
%     plot(meanSpikes, 'black');
%     plot(mean(meanSpikes'), 'red');
%     title (trialIDs(trial));
%     xlabel('frames');
end

