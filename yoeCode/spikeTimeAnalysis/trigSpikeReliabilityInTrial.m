function trigFractions = trigSpikeReliabilityInTrial(trialData, PREwin, POSTwin, trigWINDOW)

NORMALIZE_AMPLITUDE = 1; % when calling spike request
trigFractions = [];
nROIs = getNROIsFromTrialData(trialData);

for ROI = 1:nROIs
    [EVENTspikes, spontSpikes, trigFractions(ROI)] = getTrigSpontSpikeTracesForROI (trialData, ROI, PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE);
end
