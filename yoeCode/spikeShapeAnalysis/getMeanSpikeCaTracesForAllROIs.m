function meanSpikes = getMeanSpikeCaTracesForAllROIs(trialData, PREwin, POSTwin)

nROIs = getNROIsFromTrialData(trialData);
traceLength = PREwin+POSTwin+1;
meanSpikes = nan(traceLength, nROIs);

for ROI = 1:nROIs
    spikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);
    meanSpikes (:, ROI) = mean(spikeTraces', 'omitnan');
    
end

