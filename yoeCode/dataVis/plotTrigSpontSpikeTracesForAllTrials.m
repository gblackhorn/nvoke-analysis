function [EVENTspikeTraces, spontSpikeTraces, trigFractions] = plotTrigSpontSpikeTracesForAllTrials (IOnVokeData, PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE)
% return calcium traces for the spikes in all ROIs in the trial
% separate AP-evoked and spontaneous
EVENTspikeTraces = [];
spontSpikeTraces =[];
spikeFractions = []; % fraction of APs that evoked a spike in a trial

%trigWINDOW  % how many frames max between trigger and peak

trialIDs = getTrialIDsFromROIdataStruct(IOnVokeData);
trialType = getTrialTypeFromROIdataStruct(IOnVokeData);
nTrials = length(trialIDs);

for trial = 1:nTrials
%    [EVENTspikes, spontSpikes] = getAPspontSpikeTracesForTrial (IOnVokeData(trial, :), PREwin, POSTwin, trigWINDOW);
    [EVENTspikes, spontSpikes,  tf] = getTrigSpontSpikeTracesForTrial (IOnVokeData(trial, :), PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE);
    EVENTspikeTraces = [EVENTspikeTraces EVENTspikes];
    spontSpikeTraces = [spontSpikeTraces spontSpikes];
    trigFractions{trial} = tf;
    
  end

frameRate = getFrameRateForTrial(IOnVokeData(1, :));

meanTrigFractionsInTrials = cellfun(@(x) mean(x,'omitnan'), trigFractions);
meanTrigFractionInGroup = mean(meanTrigFractionsInTrials, 'omitnan');

xAx = [1:PREwin+POSTwin+1];
xAx = xAx ./ frameRate;

alignedEventTraces = alignCaEventsOnPeak(EVENTspikeTraces, PREwin, POSTwin);
alignedSpontTraces = alignCaEventsOnPeak(spontSpikeTraces, PREwin, POSTwin);

figure; 
titleString = ['Pooled data from selected airpuff trials, trigwindow length ' num2str(frames2sec(trigWINDOW)) ' sec'];
if NORMALIZE_AMPLITUDE
    titleString = [titleString '; event amplitudes normalized per ROI; event trigger reliability ' num2str(meanTrigFractionInGroup)];
end

[nFrames nSpikesSpont] = size(alignedSpontTraces);
[nFrames nSpikesTrig] = size(alignedSpontTraces);


meanSpont = mean(spontSpikeTraces', 'omitnan');
stdSpont = std(spontSpikeTraces', 'omitnan');
semSpont = stdSpont ./ sqrt(nSpikesSpont);
meanTrig =  mean(EVENTspikeTraces', 'omitnan');
stdTrig =  std(EVENTspikeTraces', 'omitnan');
semTrig = stdTrig ./ sqrt(nSpikesTrig);

suptitle(titleString);
subplot (2, 2, 1); hold on;
plot(xAx, EVENTspikeTraces, 'b');
plot(xAx, meanTrig, 'r', 'LineWidth', 3);
xlabel('sec');
legend ('Event-trig spikes');
ylim ([-3 5]);
%xlim ([0 2]);
%title ('Event-trig spikes');


subplot (2, 2, 2); hold on;
plot(xAx, spontSpikeTraces, 'g');
plot(xAx,meanSpont, 'r', 'LineWidth', 3);
xlabel('sec');
legend ('spontaneous spikes');
ylim ([-3 5]);
%xlim ([0 2]);
%title ('Spont spikes');

subplot (2, 2, 3); hold on;
% plot(xAx, meanSpont, 'g', 'LineWidth', 3)
% plot(xAx, meanTrig, 'b', 'LineWidth', 3);
xlabel('sec');
%xlim ([0 2]);
title ('Mean peaks aligned in time +- SEM');
legend ({'Spontaneous' 'Triggered'});

errorbar(xAx, meanSpont, semSpont, 'g');
errorbar(xAx, meanTrig, semTrig, 'b');

subplot (2, 2, 4); hold on;

plot(xAx, meanSpont ./ max(meanSpont), 'g', 'LineWidth', 3);
plot(xAx, meanTrig ./ max(meanTrig), 'b', 'LineWidth', 3);
xlabel('sec');
%xlim ([0 2]);
legend ({ 'Spontaneous' 'Triggered' });
title ('Peak-normalized means');

