function trigSpikeFrames = getEventTrigSpikeFramesForTrial(trialData, PREWINtime, POSTWINtime)

frameRate = getFrameRateForTrial(trialData);
%[OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
[eventStarts eventEnds] = getEventStartStopsforTrial(trialData, frameRate);

trigSpikeFrames = getEventTrigSpikes(trialData, eventStarts, PREWINtime, POSTWINtime);




R = 1;