function trigSpikeFrames = getEventTrigSpikes(trialData, trigTimes, PREWINtime, POSTWINtime)
% PREWINtime, POSTWINtime in sec
frameRate = getFrameRateForTrial(trialData);
PREWIN = PREWINtime * frameRate;
POSTWIN = POSTWINtime * frameRate;

trigSpikeFrames = [];
nTrigs = length(trigTimes);

for trig = 1:nTrigs
    trialTrigFrames = getTrigSpikeFramesFromTrial(trialData,trigTimes(trig), PREWIN, POSTWIN );
    trialTrigFrames = trialTrigFrames - trigTimes(trig);
    trigSpikeFrames = [trigSpikeFrames; trialTrigFrames];
end


% figure; 
% histogram (trigSpikeTimes, (PREWIN+POSTWIN)/5);
% line([0 0], [0, 10], 'Color', 'r');
% xlabel ('sec relative to triggered event');
% title(getTrialIDsFromROIdataStruct(trialData));