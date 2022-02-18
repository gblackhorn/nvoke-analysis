function OGdur = getOGdurFromTrialData(trialData)

 frameRate = getFrameRateForTrial(trialData);
[OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
OGdur = OGLEDends(1) - OGLEDstarts(1);