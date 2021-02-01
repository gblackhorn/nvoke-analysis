function [OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate)

if (~exist('frameRate', 'var'))
    frameRate = 10;
end

stimRangeData = trialData{4}(3).stim_range;

stimRangeFrames = round(stimRangeData*frameRate);
OGLEDstarts = stimRangeFrames(:, 1);
OGLEDends = stimRangeFrames(:, 2);
