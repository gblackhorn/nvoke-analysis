function trigSpikeFrames = getSpikeFramesInRangeFromTrial(trialData, rangeStart, rangeEnd, normFR )
% returns all spike frames in all ROIS in the trial that fall between indicated frames
% trialData is one "row" from ROIdata
% rangeStart = first frame of range
% rangeEnd = last frame of range
% normFR - if 1, recalculate spike frames to standard fr of 10Hz
if (~exist('normFR', 'var'))
    normFR = 0;
end

STANDARDFR = 10;

frameRate = getFrameRateForTrial(trialData);

spikeFrames = getAllSpikeFramesForTrial(trialData, 'lowpass');

if normFR
    if (frameRate ~=10)
        warning(['Frame rate not 10 Hz in trial ' getTrialIDsFromROIdataStruct(trialData) ' - adjusting..']);
    end
    frRatio = frameRate / normFR;
    spikeFrames = spikeFrames *frRatio;
end

nROIs = length(spikeFrames);
nFrames = getTrialLengthInFrames(trialData);
allSpikes = cell2mat(spikeFrames);

if rangeStart < 1
    warning('trig range before trial start');
    rangeStart = 1;
end

if rangeEnd > nFrames
    warning('trig range too long');
    rangeStart = nFrames;
end
    

trigSpikeFrameInd = intersect(find(allSpikes> rangeStart), find(rangeEnd > allSpikes));
trigSpikeFrames = allSpikes(trigSpikeFrameInd);