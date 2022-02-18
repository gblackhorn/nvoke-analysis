function R = makeHistoPlotForTrial(trialData, plotWhere)

% if plotWhere is given, it is a handle for axes for plotting
% if not given, make a new fig
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end


frameRate = getFrameRateForTrial(trialData);
spikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');
nROIs = length(spikeFrames);
nFrames = getTrialLengthInFrames(trialData);
% trialLength = floor(nFrames / frameRate);
trialLength = trialData{2}.lowpass.Time(end); % use timeinfo from data. 

binLength = 5; %sec
nBins = floor(trialLength /  binLength);


% draw locations of stimulations
annotateStims(trialData, plotWhere);

allSpikes = cell2mat(spikeFrames);
histogram(frames2sec(allSpikes), nBins, 'FaceColor', 'blue');

xlabel('sec');
ylabel ('count');
trialID = getTrialIDFromFilename(trialData{1});
title (trialID);