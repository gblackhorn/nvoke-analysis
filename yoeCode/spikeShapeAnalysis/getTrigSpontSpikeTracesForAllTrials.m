function [EVENTspikeTraces, spontSpikeTraces, trigFractions] = getTrigSpontSpikeTracesForAllTrials (IOnVokeData, PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE)
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

