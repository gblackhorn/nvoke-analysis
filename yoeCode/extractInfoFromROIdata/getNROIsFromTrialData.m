function nROIs = getNROIsFromTrialData(trialData)
% how many ROIs in trial data structure
nROIs = 0;

if (~ validateTrialData(trialData))
    warning('Invalid trial data');
else
    
    nROIs = width(trialData{1, 5});
end