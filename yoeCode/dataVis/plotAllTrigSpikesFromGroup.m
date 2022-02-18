function R = plotAllTrigSpikesFromGroup(ROIdata, PREWINtime, POSTWINtime, plotWhere)
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end


nTrials = getNtrialsFromROIdata(ROIdata);
frameRate = getFrameRateForTrial(ROIdata(1, :));
trigSpikes =[];

for trial = 1:nTrials
    trigSpikeFrames = getEventTrigSpikeFramesForTrial(ROIdata(trial, :), PREWINtime, POSTWINtime);
    trigSpikeTimes = trigSpikeFrames ./ frameRate;
    trigSpikes = [trigSpikes; trigSpikeTimes];

end


h = histogram(trigSpikes, (PREWINtime+POSTWINtime)*2);

maxCount = max(h.Values);

trialType = getTrialTypeFromROIdataStruct(ROIdata);
switch (trialType)
    
    case 'GPIO1-1s'
        line([0 0], [0, maxCount], 'Color', 'r', 'LineWidth', 2);
    case 'noStim'
        % do nothing
    otherwise
        [eventStarts eventEnds] = getOGLEDstartStopsforTrial(ROIdata(trial, :), frameRate);
        OGLEDdurs = eventEnds-eventStarts;
        nOGLEDs = length(OGLEDdurs);
        rectPos = [0 0 frames2sec(OGLEDdurs(1)) maxCount];
        rectangle(gca, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.4]);
end

xlabel ('sec relative to stim start');
ylabel ('count')
title (['Pooled spikes (n=' num2str(length(trigSpikes)) ') from all trials (N=' num2str(nTrials) ') with trial type ' trialType]);

R = 1;