function R = makeScatterPlotsForAllTrials(ROIdata)

trialIDs = getTrialIDsFromROIdataStruct(ROIdata);
nTrials = length(trialIDs);

nROWS = 5;
nCOLS = ceil(nTrials / nROWS);
figure;

for trial = 1:nTrials


    
    subplot(nROWS, nCOLS, trial); hold on;
    makeScatterPlotForTrial(ROIdata(trial, :), gca);
    

end
trialType = getTrialTypeFromROIdataStruct(ROIdata);
suptitle(['Experiment type: ' trialType]);