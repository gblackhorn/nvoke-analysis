function spikeFrames = getAllSpikeFramesForTrial(trialData, TYPE)

% trialData is one row from ROIdata cell array (one trial, many ROIs)
% TYPE is 'deconv' or 'lowpass' for now

if (~exist('TYPE', 'var'))
    TYPE = 'lowpass';
end

[nFrames nROIs] = size (trialData{2}.raw);
nROIs = nROIs -1;
spikeFrames = cell(nROIs, 1);

for (roi = 1:nROIs)
    spikeFrames{roi} = getSpikeFramesForROI(trialData,roi, TYPE);
end