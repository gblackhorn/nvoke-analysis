function R = makeHistoPlotsForAllTrials(ROIdata)

trialIDs = getTrialIDsFromROIdataStruct(ROIdata);
nTrials = length(trialIDs);

nROWS = 5;
nCOLS = ceil(nTrials / nROWS);
figure;

for trial = 1:nTrials


    
    subplot(nROWS, nCOLS, trial); hold on;
    makeHistoPlotForTrial(ROIdata(trial, :), gca);
    

end
trialType = getTrialTypeFromROIdataStruct(ROIdata);
sgtitle(['Experiment type: ' trialType]);