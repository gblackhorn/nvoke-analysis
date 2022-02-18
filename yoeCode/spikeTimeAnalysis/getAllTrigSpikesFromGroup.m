function trigSpikes = getAllTrigSpikesFromGroup(ROIdata, PREWINtime, POSTWINtime)


nTrials = getNtrialsFromROIdata(ROIdata);
frameRate = getFrameRateForTrial(ROIdata(1, :));
trigSpikes =[];

for trial = 1:nTrials
    trigSpikeFrames = getEventTrigSpikeFramesForTrial(ROIdata(trial, :), PREWINtime, POSTWINtime);
    trigSpikeTimes = trigSpikeFrames ./ frameRate;
    trigSpikes = [trigSpikes; trigSpikeTimes];

end

