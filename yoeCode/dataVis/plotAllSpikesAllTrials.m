function allSpikes = plotAllSpikesAllTrials(IOnVokeData, PREwin, POSTwin, plotWhere)
% loop through all trials, all ROIs in a nVoke data structure 
% if plotWhere is given, it is a handle for axes for plotting
% if not given, make a new fig
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end

nTrials = getNtrialsFromROIdata(IOnVokeData);
trialIDs = getTrialIDsFromROIdataStruct(IOnVokeData);
trialType = getTrialTypeFromROIdataStruct(IOnVokeData);
trialLength = PREwin+POSTwin+1;

allSpikes = [];

for trial = 1:nTrials
    trialData = IOnVokeData(trial, :);
    nROIs = getNROIsFromTrialData(trialData);
    for ROI = 1:nROIs
        spikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);
        allSpikes = [allSpikes spikeTraces];
    end
end


frameRate = getFrameRateForTrial(trialData);
xAx = 1:trialLength;
xAx = xAx ./ frameRate;
normVal = PREwin -10;
if normVal < 1
    normVal = 1;
end
normAllSpikes = (allSpikes - normVal);
meanNormSpikes = mean(normAllSpikes', 'omitnan');
plot(xAx, normAllSpikes, 'Color', [0.5 0.5 0.5]);
plot (xAx, meanNormSpikes, 'red', 'LineWidth', 3);
%ylim ([-5 max(max(normAllSpikes))]);
xlabel ('s');
title (['All spikes from trials with ' trialType]);


