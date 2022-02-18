function [EVENTspikeTraces, spontSpikeTraces, trigFractions] = getTrigSpontSpikeTracesForTrial (trialData, PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE)
% return calcium traces for the spikes in all ROIs in the trial
% separate AP-evoked and spontaneous
EVENTspikeTraces = [];
spontSpikeTraces =[];
trigFractions = [];
nROIs = getNROIsFromTrialData(trialData);
trialID = getTrialIDsFromROIdataStruct(trialData);

for ROI = 1:nROIs
 %   [EVENTspikes, spontSpikes] = getAPstimSpontSpikeTracesForROI (trialData, ROI, PREwin, POSTwin, trigWINDOW);
    [EVENTspikes, spontSpikes, trigFractions(ROI)] = getTrigSpontSpikeTracesForROI (trialData, ROI, PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE);
    EVENTspikeTraces = [EVENTspikeTraces EVENTspikes];
    spontSpikeTraces = [spontSpikeTraces spontSpikes];
end
trigFractions = trigFractions';
%meanTrigFractions = mean(trigFractions, 'omitnan');
% frameRate = getFrameRateForTrial(trialData);
% 
% xAx = [1:PREwin+POSTwin+1];
% xAx = xAx ./ frameRate;
% 
% figure; 
% subplot (1, 2, 1); hold on;
% plot(xAx, EVENTspikeTraces, 'b');
% plot(xAx, mean(EVENTspikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
% xlabel ('sec');
% title (['All event-triggered spikes in trial ' trialID]);
% 
% subplot (1, 2, 2); hold on;
% plot(xAx, spontSpikeTraces, 'b');
% plot(xAx, mean(spontSpikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
% xlabel ('sec');
% title (['All spontenaous spikes in trial ' trialID]);
