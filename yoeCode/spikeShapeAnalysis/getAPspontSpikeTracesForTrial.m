function [APspikeTraces, spontSpikeTraces] = getAPspontSpikeTracesForTrial (trialData, PREwin, POSTwin, trigWINDOW)
% return calcium traces for the spikes in all ROIs in the trial
% separate AP-evoked and spontaneous
APspikeTraces = [];
spontSpikeTraces =[];
nROIs = getNROIsFromTrialData(trialData);
trialID = getTrialIDsFromROIdataStruct(trialData);

for ROI = 1:nROIs
    [APspike, spontSpike] = getAPstimSpontSpikeTracesForROI (trialData, ROI, PREwin, POSTwin, trigWINDOW);
    APspikeTraces = [APspikeTraces APspike];
    spontSpikeTraces = [spontSpikeTraces spontSpike];
end

frameRate = getFrameRateForTrial(trialData);

xAx = [1:PREwin+POSTwin+1];
xAx = xAx ./ frameRate;

figure; 
subplot (1, 2, 1); hold on;
plot(xAx, APspikeTraces, 'b');
plot(xAx, mean(APspikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
xlabel ('sec');
title (['All airpuff-evoked spikes in trial ' trialID]);

subplot (1, 2, 2); hold on;
plot(xAx, spontSpikeTraces, 'b');
plot(xAx, mean(spontSpikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
xlabel ('sec');
title (['All spontenaous spikes in trial ' trialID]);
