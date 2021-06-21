function[caDiffOG] = getCaDiffInOGForGroup(IOnVokeData)

if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end



nTrials = getNtrialsFromROIdata(IOnVokeData);
frameRate = getFrameRateForTrial(IOnVokeData(1, :));

figure;
NCOLS = 2;
NROWS = ceil(nTrials / NCOLS);

for trial = 1:nTrials
    subplot(NROWS, NCOLS, trial); hold on;
    trialData = IOnVokeData(trial, :);
    caDiffOG{trial} = getCaDiffInOGForTrial(trialData, gca);
end