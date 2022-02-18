function [renamedROIdata] = renameFileNamesInROI(ROIdata)
% used to make file names in ROIdatastructures uniform
% structure:
% YYYYMMD-HHMMSS-whateveratthenend

nTrials = LF_getNtrialsFromROIdata(ROIdata);
trialIDs = LF_getTrialIDsFromROIdataStruct(ROIdata);
descStr = LF_getFileNameDescriptorsFromROIdatastruct(ROIdata);

for trial = 1:nTrials
    ROIdata{trial, 1} = [trialIDs{trial} '-' descStr{trial}];

end

renamedROIdata = ROIdata;


function nTrials = LF_getNtrialsFromROIdata(ROIdata)

[nTrials nInfo] = size(ROIdata);

function trialIDs = LF_getTrialIDsFromROIdataStruct(ROIdata)
% return cell array with trial IDs extraxted from ROIdata struct

[nTrials nCols] = size(ROIdata);
fileNames = ROIdata(:, 1);

trialIDs = cell(nTrials, 1);

for trial = 1:nTrials
    trialIDs{trial} = LF_getTrialIDFromFilename(fileNames{trial});
end

function trialID = LF_getTrialIDFromFilename(fileName)
% returns the EXPID from a filename, that is stored in the ROIdata table
% format: recording_20180919_164803-PP-BP-MC-DFF-ROI.csv
% ID is between first _ and first -


firstDash = strfind(fileName, '-');
firstUS = strfind(fileName, '_');

if (isempty(firstDash) ||  isempty(firstDash)) % if we find both markers
    warning(['fileName ' fileName ' does not contain valid ID info']);
    trialID ='';

else
    if (fileName(1)) == 'r'
        firstDash = firstDash(1);
        firstUS = firstUS(1);
        trialID = fileName(firstUS+1:firstDash-1);
        %underscores are annoying in matlab plotting, replacing with dash
        trialID = LF_replaceUSwithDash(trialID);
    else

        fileName(firstDash([1 2 4 5])) = '';
        firstUS = strfind(fileName, '_');
        firstUS = firstUS(1);
        trialID = fileName(1:firstUS-1);
    end

end

function newString = LF_replaceUSwithDash(oldString)
    %underscores are annoying in matlab plotting, replacing with dash

    USloc = strfind(oldString, '_');
    if (USloc)
        oldString(USloc) = '-';
    end

    newString = oldString;


function trialIDs = LF_getFileNameDescriptorsFromROIdatastruct(ROIdata)
% return cell array with trial IDs extraxted from ROIdata struct

[nTrials nCols] = size(ROIdata);
fileNames = ROIdata(:, 1);

trialIDs = cell(nTrials, 1);

for trial = 1:nTrials
    trialIDs{trial} = LF_getFileNameDescriptor(fileNames{trial});
end

function trialID = LF_getFileNameDescriptor(fileName)
% returns the EXPID from a filename, that is stored in the ROIdata table
% format: recording_20180919_164803-PP-BP-MC-DFF-ROI.csv
% ID is between first _ and first -


firstDash = strfind(fileName, '-');
firstUS = strfind(fileName, '_');

if (isempty(firstDash) ||  isempty(firstDash)) % if we find both markers
    warning(['fileName ' fileName ' does not contain valid ID info']);
    trialID ='';

else
    if (fileName(1)) == 'r'
        firstDash = firstDash(1);
        firstUS = firstUS(1);
        trialID = fileName(firstDash+1:end);
        %underscores are annoying in matlab plotting, replacing with dash
        trialID = LF_replaceUSwithDash(trialID);
    else

        fileName(firstDash([1 2 4 5])) = '';
        firstUS = strfind(fileName, '_');
        firstUS = firstUS(1);
        trialID = fileName(firstUS+1:end);
        trialID = LF_replaceUSwithDash(trialID);
    end

end
