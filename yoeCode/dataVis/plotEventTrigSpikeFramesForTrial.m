function R = plotEventTrigSpikeFramesForTrial(trialData, PREWINtime, POSTWINtime)

frameRate = getFrameRateForTrial(trialData);
%[OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
[eventStarts eventEnds] = getEventStartStopsforTrial(trialData, frameRate);

trigSpikeFrames = getEventTrigSpikes(trialData, eventStarts, PREWINtime, POSTWINtime);
trigSpikeTimes = frames2sec(trigSpikeFrames, frameRate);

h = histogram (trigSpikeTimes, (PREWINtime+POSTWINtime)*2);
maxCount = max(h.Values);

trialType = getTrialTypeFromROIdataStruct(trialData);
switch (trialType)
    
    case 'GPIO1-1s'
        line([0 0], [0, 10], 'Color', 'r');
    case 'noStim'
        % do nothing
    otherwise
 %       [eventStarts eventEnds] = getOGLEDstartStopsforTrial(trialData, frameRate);
        OGLEDdurs = eventEnds-eventStarts;
        nOGLEDs = length(OGLEDdurs);
        rectPos = [0 0 frames2sec(OGLEDdurs(1)) maxCount];
        rectangle(plotWhere, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.4]);
end



xlabel ('sec relative to triggered event');
title(getTrialIDsFromROIdataStruct(trialData));

R = 1;