function [meanCas, stdCas] = getMeanCaInOGsForTrial(trialData)

frameRate = getFrameRateForTrial(trialData);
[OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
nROIs = getNROIsFromTrialData(trialData);


for roi = 1:nROIs
    trace = getROItraceFromTrialData(trialData, roi);    
    [meanCas{roi}, stdCas{roi}] = getMeanCaInOGsFromROI(trace, OGLEDstarts, OGLEDends);
    
end