function stimFrames = getAPstimFramesForTrial(trialData, frameRate)
% return array of frame indexes for the trial where airpuff stimulation was given

if (~exist('frameRate', 'var'))
    frameRate = 10;
end

stimFrames = [];

if (~ validateTrialData(trialData))
    warning('Invalid trial data');
else
    % stim times are stored in seconds so need to convert to frames
    stimTimeData = trialData{4}(3).stim_range(:, 1);
    stimFrames = round(stimTimeData*frameRate);
end