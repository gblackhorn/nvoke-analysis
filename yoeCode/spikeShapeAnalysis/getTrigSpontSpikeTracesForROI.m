function [EVENTspikeTraces, spontSpikeTraces, trigFraction] = getTrigSpontSpikeTracesForROI (trialData, ROI, PREwin, POSTwin, trigWINDOW, NORMALIZE_AMPLITUDE)

% return Ca traces for stim-evoked and spontaneous spikes in one ROI in
% a trial

% taking in spikes with peak less that 50 frames from stim frame
%trigWINDOW - how close to stim the spike peak has to be to included
frameRate = getFrameRateForTrial(trialData);
% all spike frames in the TRIAL
spikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');
% all spike frames in the ROI
spikeFrames = spikeFrames(ROI);

% sliced calcium traces for all spikes in the ROI in this trial
allSpikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);
% entire trace for the ROI for the trial
fullTrace = getROItraceFromTrialData(trialData, ROI);

% frames of AP stimulations in the trial
[eventStarts eventEnds] = getEventStartStopsforTrial(trialData, frameRate);


% get the frames of spikes in the ROI that occur  after airpuffs
[EventTrigSpikeFrames trigFraction] = getTrigSpikeFramesFromROI(trialData, ROI, eventStarts, 1, trigWINDOW);

%EventTrigSpikeFrames = getTrigSpikeFramesFromROI(trialData, ROI, eventEnds, 1, trigWINDOW);
% everything else is spontaneous;
spontSpikeFrames = setdiff(spikeFrames{1}, EventTrigSpikeFrames);
nSpontSpikes = length(spontSpikeFrames);


nTrigSpikes = length(EventTrigSpikeFrames);
EVENTspikeTraces = [];
spontSpikeTraces = [];

for trig = 1:nTrigSpikes
    % get Ca trace segment for each event that was found to happen after
    % airpuff
    trace =  getEventTrigCaTraceForROI(fullTrace, EventTrigSpikeFrames(trig), PREwin, POSTwin);
    EVENTspikeTraces = [EVENTspikeTraces trace'];
end
%shift to align at first frame

nAPTraces = length(EVENTspikeTraces');
if nAPTraces % if we found 0 AP traces, skip normalizing
    EVENTspikeTraces = EVENTspikeTraces - EVENTspikeTraces(1, :);
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


if NORMALIZE_AMPLITUDE
    pks = [];
    locs = [];
    meanSpontAplitudes = mean(max(spontSpikeTraces), 'omitnan');
    [nFr nS] = size(spontSpikeTraces); % some traces get excluded because theyre off limits
    for tr = 1:nS
        [p l] = findpeaks(spontSpikeTraces(:, tr), 'MinPeakProminence', 0.5);
        if (~isempty(p))
            
            pks =[pks p(1)];
            locs = [locs l(1)];
        end
    end
    meanSpontAplitudes = mean (pks);
    spontSpikeTraces = spontSpikeTraces ./ meanSpontAplitudes;
    EVENTspikeTraces = EVENTspikeTraces ./ meanSpontAplitudes;
    
    
end

