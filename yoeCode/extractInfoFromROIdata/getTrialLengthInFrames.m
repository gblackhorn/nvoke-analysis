function nFrames = getTrialLengthInFrames(trialData)
[nFrames nROIs] = size(trialData{1, 2}.decon);