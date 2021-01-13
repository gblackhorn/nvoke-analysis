function trialID = getTrialIDFromFilename(fileName)
% returns the EXPID from a filename, that is stored in the ROIdata table
% format: 20180919-164803-PP-BP-MC-DFF-ROI.csv
% ID is the characters up tp the second '-'


firstDash = strfind(fileName, '-');
firstUS = strfind(fileName, '_');

if (isempty(firstDash) )
    warning(['fileName ' fileName ' does not contain valid ID info']);
    %note: could add more checking in this... 
    trialID ='';
    
else
%     if (fileName(1)) == 'r'
%         firstDash = firstDash(1);
%         firstUS = firstUS(1);
%         trialID = fileName(firstUS+1:firstDash-1);
%         %underscores are annoying in matlab plotting, replacing with dash
%         trialID = replaceUSwithDash(trialID);
%     else
%         
%         fileName(firstDash([1 2 4 5])) = '';
%         firstUS = strfind(fileName, '_');
%         firstUS = firstUS(1);
%         trialID = fileName(1:firstUS-1);
%     end
trialID =  fileName(1:firstDash(2)-1);
    
end
