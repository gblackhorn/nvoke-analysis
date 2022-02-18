function R = plotAPstimSpontSpikesSeparatelyForTrial (trialData)

ROI = 3;
PREwin = 1; 
POSTwin = 20;
% all 
spikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');
spikeFrames = spikeFrames(ROI);
spikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);

APframes =  getAPstimFramesForTrial(trialData, 10);
fullTrace = getROItraceFromTrialData(trialData, ROI);



APTrigSpikeFrames = getTrigSpikeFramesFromROI(trialData, APframes, 1, 10);

nTrigSpikes = length(APTrigSpikeFrames);
spikeTraces = nan(PREwin+POSTwin+1, nTrigs);

for trig = 1:nTrigSpikes
    % get Ca trace segment for each event indicated in trig
    trace =  getEventTrigCaTraceForROI(fullTrace, APTrigSpikeFrames(trig), PREwin, POSTwin);
    spikeTraces = [spikeTraces trace'];
end