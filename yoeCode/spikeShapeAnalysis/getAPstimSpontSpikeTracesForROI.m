function [APspikeTraces, spontSpikeTraces] = getAPstimSpontSpikeTracesForROI (trialData, ROI, PREwin, POSTwin, trigWINDOW)

% return Ca traces for airpuff-evoked and spontaneous spikes in one ROI in
% a trial

% taking in spikes with peak less that 50 frames from stim frame
%trigWINDOW=10;

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
APTrigSpikeFrames = getTrigSpikeFramesFromROI(trialData, ROI, APframes, 1, trigWINDOW);
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

nAPTraces = length(APspikeTraces');
if nAPTraces % if we found 0 AP traces, skip normalizing
    APspikeTraces = APspikeTraces - APspikeTraces(1, :);
end

for spike = 1:nSpontSpikes
    trace =  getEventTrigCaTraceForROI(fullTrace, spontSpikeFrames(spike), PREwin, POSTwin);
    spontSpikeTraces = [spontSpikeTraces trace'];
end


nSpontTraces = length(spontSpikeTraces');
if nSpontTraces % if we found 0 AP traces, skip normalizing
    %shift to align at first frame
    spontSpikeTraces = spontSpikeTraces - spontSpikeTraces(1, :);
end



