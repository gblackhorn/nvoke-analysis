function R = annotateStims(trialData, plotWhere)
% to be used in trace plots,  scatters and histograms of trials
% plotWhere is the axis where to plot

trialType = getTrialTypeFromROIdataStruct(trialData);
frameRate = getFrameRateForTrial(trialData);
nROIs = getNROIsFromTrialData(trialData);
axes(plotWhere);
axp = get(gca);
ylims = axp.YLim;

switch (trialType)
    case 'GPIO1-1s'
        stimFrames = getAPstimFramesForTrial(trialData, frameRate);
        nStims = length(stimFrames);
        for stim = 1:nStims
            stimTime = frames2sec(stimFrames(stim));
            line(plotWhere, [ stimTime stimTime], [ylims(1) ylims(2)], 'Color', 'blue' ,'HandleVisibility','off');
        end
        
        
    case 'noStim'
        %no annotation
    otherwise
        % optogenetics are indicated with start and stop
        [OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
        OGLEDdurs = OGLEDends-OGLEDstarts;
        
        nOGLEDs = length(OGLEDdurs);
        
        for stim = 1:nOGLEDs
            rectPos = [frames2sec(OGLEDstarts(stim)) ylims(1) frames2sec(OGLEDdurs(stim)) ylims(2)-ylims(1)];
            rectangle(plotWhere, 'Position', rectPos, 'FaceColor', [0, 0.9, 0.9, 0.2]);
        end
        
end

R = 1;
