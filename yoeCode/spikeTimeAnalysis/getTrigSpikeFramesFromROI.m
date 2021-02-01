function [trigSpikeFrames trigFraction] = getTrigSpikeFramesFromROI(trialData, ROI, trigFrames, PREWIN, POSTWIN)

% return spike frames that match the trigFrame, prewin, postwin,
% from one ROI trace
% trigFraction = fraction of triggers that evoked a spike (matching the
% criteria)

rangeStart = trigFrames - PREWIN;
rangeEnd = trigFrames + POSTWIN;
nTrigs = length(trigFrames);
trigSpikeFrames = [];

allSpikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');
allSpikeFramesInROI = allSpikeFrames{ROI};

% loop through all the trigs
for trigInd = 1:nTrigs
    trigSpikeFrameInd = intersect(find(allSpikeFramesInROI> rangeStart(trigInd)), find(rangeEnd(trigInd) > allSpikeFramesInROI));
    if (length(trigSpikeFrameInd)>1)
        trigSpikeFrameInd = trigSpikeFrameInd(1); % in case criteria allow several spikes, we just want one
    end
    trigSpikeFrames = [ trigSpikeFrames ; allSpikeFramesInROI(trigSpikeFrameInd)];
end

nTrigSpikes = length(trigSpikeFrames);
if nTrigSpikes == 0
    trigFraction = nan;
else
trigFraction = nTrigSpikes / nTrigs;
end