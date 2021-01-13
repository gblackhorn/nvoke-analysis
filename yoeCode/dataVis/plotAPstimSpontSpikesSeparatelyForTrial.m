function [APspikeTraces, spontSpikeTraces] = plotAPstimSpontSpikesSeparatelyForTrial (trialData)

ROI = 3;
PREwin = 10; 
POSTwin = 100;
% all spike frames in the TRIAL
spikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');
% all spike frames in the ROI
spikeFrames = spikeFrames(ROI);

% sliced calcium traces for all spikes in the ROI in this trial
allSpikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);
% entire trace for the ROI for the trial
fullTrace = getROItraceFromTrialData(trialData, ROI);

% frames of AP stimulations in the trial
APframes =  getAPstimFramesForTrial(trialData, 10);


% get the frames of spikes in the ROI that occur  after airpuffs  
APTrigSpikeFrames = getTrigSpikeFramesFromROI(trialData, ROI, APframes, 1, 100);
% everything else is spontaneous;
spontSpikeFrames = setdiff(spikeFrames{1}, APTrigSpikeFrames);
nSpontSpikes = length(spontSpikeFrames);


nTrigSpikes = length(APTrigSpikeFrames);
APspikeTraces = [];
spontSpikeTraces = [];

for trig = 1:nTrigSpikes
    % get Ca trace segment for each event that was found to happen after
    % airpuff
    trace =  getEventTrigCaTraceForROI(fullTrace, APTrigSpikeFrames(trig), PREwin, POSTwin);
    APspikeTraces = [APspikeTraces trace'];
end
%shift to align at first frame
APspikeTraces = APspikeTraces - APspikeTraces(1, :);

for spike = 1:nSpontSpikes
     trace =  getEventTrigCaTraceForROI(fullTrace, spontSpikeFrames(spike), PREwin, POSTwin);
    spontSpikeTraces = [spontSpikeTraces trace'];
end
%shift to align at first frame
spontSpikeTraces = spontSpikeTraces - spontSpikeTraces(1, :);


figure; 
subplot (1, 2, 1); hold on;
plot(APspikeTraces, 'b');
plot(mean(APspikeTraces', 'omitnan'), 'r', 'LineWidth', 3);

subplot (1, 2, 2); hold on;
plot(spontSpikeTraces, 'b');
plot(mean(spontSpikeTraces', 'omitnan'), 'r', 'LineWidth', 3);
