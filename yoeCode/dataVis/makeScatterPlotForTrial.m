function R = makeScatterPlotForTrial(trialData, plotWhere)


frameRate = getFrameRateForTrial(trialData);
spikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');
nROIs = length(spikeFrames);
nFrames = getTrialLengthInFrames(trialData);

% if plotWhere is given, it is a handle for axes for plotting
% if not given, make a new fig
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end
% draw locations of stimulations
annotateStims(trialData, plotWhere);

% loop through all ROIS
% TODO: make prettier scatter markers
for roi = 1:nROIs
    roiSpikes = spikeFrames{roi};
    roiTimes = frames2sec(roiSpikes);
    yVals = ones(length(roiSpikes), 1)*(roi);
    scatter(roiTimes, yVals, 'ro', 'filled');
    
end

%% labels for figure
ylim ([0 nROIs]);
xlabel('sec');
ylabel ('ROI ID')

trialID = getTrialIDFromFilename(trialData{1});
title (trialID);

R=1;