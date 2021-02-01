function R = plotTracesFromAllTrials (IOnVokeData)

nTrials = getNtrialsFromROIdata(IOnVokeData);

for trial = 1:nTrials
    trialData = IOnVokeData(trial, :);
   plotROItracesFromTrial (trialData);
end
R = 1;