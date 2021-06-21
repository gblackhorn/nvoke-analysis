function [renamedROIdata] = renamenVokeFilenames(ROIdata)
% used to make file names in ROIdatastructures uniform
% structure: 
% YYYYMMD-HHMMSS-whateveratthenend

nTrials = getNtrialsFromROIdata(ROIdata);
trialIDs = getTrialIDsFromROIdataStruct(ROIdata);
descStr = getFileNameDescriptorsFromROIdatastruct(ROIdata);

for trial = 1:nTrials
    ROIdata{trial, 1} = [trialIDs{trial} descStr{trial}];
    
end

renamedROIdata = ROIdata;

end

