function spikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin)
% return ca traces for all spikes in the ROI in this trial
% ROI is the ID of the ROI; 

spikeFrames = getSpikeFramesForROI(trialData,ROI, 'lowpass');

ROItraces = table2array(trialData{1, 2}.lowpass);
ROItrace = ROItraces(:, ROI+1); % +1 because first column is time 
spikeTraces = getAllEventTrigCaTracesForRoi(ROItrace, spikeFrames, PREwin, POSTwin);