function allSpikes = getAllSpikesAllTrials(ROIdata, PREwin, POSTwin)

nTrials = getNtrialsFromROIdata(ROIdata);
trialIDs = getTrialIDsFromROIdataStruct(ROIdata);
trialType = getTrialTypeFromROIdataStruct(ROIdata);
trialLength = PREwin+POSTwin+1;


allSpikes = [];

for trial = 1:nTrials
    trialData = ROIdata(trial, :);
    nROIs = getNROIsFromTrialData(trialData);
    for ROI = 1:nROIs
        spikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);
        allSpikes = [allSpikes spikeTraces];
    end
end
