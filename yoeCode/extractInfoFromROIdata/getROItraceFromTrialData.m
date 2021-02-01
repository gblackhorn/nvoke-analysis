function trace = getROItraceFromTrialData(trialData, ROI, TYPE)
% return the lowpassed ca trace for indicated ROI
if (~exist('TYPE', 'var'))
    TYPE = 'lowpass';
end
if strcmp(TYPE, 'lowpass')
traceT = table2array(trialData{1, 2}.lowpass);
else
    traceT = table2array(trialData{1, 2}.decon);
end
trace = traceT (:, ROI+1);

