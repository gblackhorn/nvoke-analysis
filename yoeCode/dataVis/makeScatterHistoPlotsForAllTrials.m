function R = makeScatterHistoPlotsForAllTrials(ROIdata)

trialIDs = getTrialIDsFromROIdataStruct(ROIdata);
nTrials = length(trialIDs);

nROWS = 5;
nCOLS = ceil(nTrials / nROWS);
figure;
rowPad = 0;
scatterPos1 = 1;
scatterPos2 = scatterPos1 + nCOLS;
histoPos = scatterPos1 + nCOLS*2;
for trial = 1:nTrials

   scatterPos2 = scatterPos1 + nCOLS;
   histoPos = scatterPos1 + nCOLS*2;
    
    subplot(nROWS*3+3, nCOLS, [scatterPos1 scatterPos2]); hold on;
    makeScatterPlotForTrial(ROIdata(trial, :), gca);
    
    subplot(nROWS*3 +3, nCOLS, histoPos); hold on;
    makeHistoPlotForTrial(ROIdata(trial, :), gca);
    scatterPos1 = scatterPos1 + 1;
    if (~mod(trial, nCOLS))
        scatterPos1 = scatterPos1+nCOLS+2;
    end

end
trialType = getTrialTypeFromROIdataStruct(ROIdata);
sgtitle(['Experiment type: ' trialType]);