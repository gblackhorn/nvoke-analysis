function trigSpikeFrames = getTrigSpikeFramesFromTrial(trialData, trigFrame, PREWIN, POSTWIN)


rangeStart = trigFrame - PREWIN;
rangeEnd = trigFrame + POSTWIN;
nTrigs = length(trigFrame);
trigSpikeFrames = [];

% loop through all the 
for trigInd = 1:nTrigs
    trigSpikeFramesTrigInd = getSpikeFramesInRangeFromTrial(trialData, rangeStart(trigInd), rangeEnd(trigInd) );
    trigSpikeFrames = [trigSpikeFrames; trigSpikeFramesTrigInd];
end
