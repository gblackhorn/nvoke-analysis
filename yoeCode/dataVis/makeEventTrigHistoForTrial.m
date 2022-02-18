function R = makeEventTrigHistoForTrial(trialData, PREwin, POSTwin, plotWhere)

if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end

frameRate = getFrameRateForTrial(trialData);
[OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);

trigSpikeFrames = getEventTrigSpikes(trialData, OGLEDstarts, PREwin, POSTwin);
trigSpikeTimes = frames2sec(trigSpikeFrames, frameRate);

h = histogram (trigSpikeTimes, (PREwin+POSTwin));
maxCount = max(h.Values);

trialType = getTrialTypeFromROIdataStruct(trialData);
switch (trialType)
    
    case 'GPIO1-1s'
        line([0 0], [0, 10], 'Color', 'r');
    case 'noStim'
        % do nothing
    otherwise
        [OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
        OGLEDdurs = OGLEDends-OGLEDstarts;
        nOGLEDs = length(OGLEDdurs);
        rectPos = [0 0 frames2sec(OGLEDdurs(1)) maxCount];
        rectangle(plotWhere, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.4]);
end



xlabel ('sec relative to triggered event');
title(getTrialIDsFromROIdataStruct(trialData));

R = 1;