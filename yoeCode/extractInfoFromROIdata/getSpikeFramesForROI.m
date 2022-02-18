function spikeFrames = getSpikeFramesForROI(trialData,ROIind, TYPE)
% returns frames where spike peaks detected for one ROI in trialData
% trialData is one row from ROIdata cell array (one trial, many ROIs)
% ROIind is indext of ROI we're interested in
% TYPE is 'raw' or 'lowpassed' for now

if (~exist('TYPE', 'var'))
    TYPE = 'lowpass';
end

singleROIdata = table2array(trialData{1, 5}(:, ROIind));
switch (TYPE)
    case 'lowpass'
        spikeFrames = singleROIdata{3}.peak_loc;
    case 'decon'
        spikeFrames = singleROIdata{1}.peak_loc;
    case 'rise'
        spikeFrames = singleROIdata{3}.rise_loc;
    case 'decay'
        spikeFrames = singleROIdata{3}.decay_loc;
end

if isempty(spikeFrames)
	spikeFrames = NaN;
end
        


% if strcmp(TYPE, 'lowpass')
%     spikeFrames = singleROIdata{3}.peak_loc;
% else
%     if strcmp(TYPE, 'rise')
%         spikeFrames = singleROIdata{3}.rise_loc;
%     else
%         spikeFrames = singleROIdata{1}.peak_loc;
%     end
% end
%     
