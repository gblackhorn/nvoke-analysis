function trialID = getFileNameDescriptor(fileName)
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
        trialID = fileName(firstDash:end);
        %underscores are annoying in matlab plotting, replacing with dash
        trialID = replaceUSwithDash(trialID);
    else
        
        fileName(firstDash([1 2 4 5])) = '';
        firstUS = strfind(fileName, '_');
        firstUS = firstUS(1);
        trialID = fileName(firstUS:end);
    end
    
end