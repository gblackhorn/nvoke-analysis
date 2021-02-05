function R = plotTracesFromAllTrials (IOnVokeData)

nTrials = getNtrialsFromROIdata(IOnVokeData);

for trial = 1:nTrials
	trial % used for debugging
    if trial == 6 % used for debugging
        pause
    end

    trialData = IOnVokeData(trial, :);
   plotROItracesFromTrial (trialData);
end
R = 1;