function trialIDs = getTrialIDsFromROIdataStruct(ROIdata)
% return cell array with trial IDs extraxted from ROIdata struct

[nTrials nCols] = size(ROIdata);
fileNames = ROIdata(:, 1);

trialIDs = cell(nTrials, 1);

for trial = 1:nTrials
    trialIDs{trial} = getTrialIDFromFilename(fileNames{trial});
end



 