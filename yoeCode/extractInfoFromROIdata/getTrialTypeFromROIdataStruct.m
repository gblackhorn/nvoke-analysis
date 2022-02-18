function trialType = getTrialTypeFromROIdataStruct(ROIdata)
% return trial type ID from ROI data struct
% should be string i 3rd column, format OG_LED-10s

[nTrials nCols] = size(ROIdata);
if (nCols >2)
    
    trialType = char(ROIdata{1, 3});
    %underscores are annoying in matlab plotting, replacing with dash
    trialType = replaceUSwithDash(trialType);


else
    error('Trial type info not found');
end
