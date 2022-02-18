function [APspikeTraces, spontSpikeTraces] = getAPspontSpikeTracesForAllTrials (IOnVokeData, PREwin, POSTwin, trigWINDOW)
% return calcium traces for the spikes in all ROIs in the trial
% separate AP-evoked and spontaneous
APspikeTraces = [];
spontSpikeTraces =[];
spikeFractions = []; % fraction of APs that evoked a spike in a trial

%trigWINDOW = 10; % how many frames max between trigger and peak

trialIDs = getTrialIDsFromROIdataStruct(IOnVokeData);
nTrials = length(trialIDs);

for trial = 1:nTrials
    [APspike, spontSpike] = getAPspontSpikeTracesForTrial (IOnVokeData(trial, :), PREwin, POSTwin, trigWINDOW);
    APspikeTraces = [APspikeTraces APspike];
    spontSpikeTraces = [spontSpikeTraces spontSpike];
end

%todo: add calculation of fraction of events that evoke a spike
frameRate = getFrameRateForTrial(IOnVokeData(1, :));

% stimFrames = getAPstimFramesForTrial(IOnVokeData, frameRate);
% nStims = length(stimFrames);


xAx = [1:PREwin+POSTwin+1];
xAx = xAx ./ frameRate;


figure; 
suptitle(['Pooled data from all trials, trigwindow length ' num2str(frames2sec(trigWINDOW)) ' sec']);
subplot (1, 3, 1); hold on;
plot(xAx, APspikeTraces, 'b');
plot(xAx, mean(APspikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
xlabel('sec');
title ('APspikes');


subplot (1, 3, 2); hold on;
plot(xAx, spontSpikeTraces, 'b');
plot(xAx, mean(spontSpikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
xlabel('sec');
title ('Spont spikes');

subplot (1, 3, 3); hold on;
plot(xAx, mean(spontSpikeTraces', 'omitnan'), 'g', 'LineWidth', 3)
plot(xAx, mean(APspikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
xlabel('sec');
legend ({'Spontaneous' 'Airpuff'});

