function newTargetData = copylocTag(sourceData, targetData)
    % Copy the loc tag (subnuclei information) of ROIs from one recdata file to another

    % Defaults
    recNameCol = 1; % Column number in 'recdata' containing the recording file name
    roiInfoCol = 2; % Column number in 'recdata' containing the ROI info
    locTagStr = 'locTag';

    % Assign the value of targetData to newTargetData
    newTargetData = targetData;

    % Get the recording names of SourceData and targetData
    recNamesSource = sourceData(:,recNameCol);
    recNamesTarget = targetData(:,recNameCol);

    % Shorten the recording names: Only keep the date and time information
    % Suppose all the recording names have the following format: yyyymmdd-hhmmss_*
    % Locate the position of '_' and get the characters before it
    underScoreIDX = strfind(sourceData{1,recNameCol},'_');
    recNamesSource = cellfun(@(x) x(1:(underScoreIDX(1)-1)),recNamesSource,'UniformOutput',false);
    recNamesTarget = cellfun(@(x) x(1:(underScoreIDX(1)-1)),recNamesTarget,'UniformOutput',false);

    % Loop through all the recordings in the targetData and check if there are same recordings in
    % the sourceData
    recNumTarget = numel(recNamesTarget);
    for n = 1:recNumTarget
        recName = recNamesTarget{n};

        % Locate the recording in the sourceData
        recIdxInSource = find(strcmpi(recNamesSource,recName));

        if ~isempty(recIdxInSource)
            % Print: Recording is found in the sourceData
            fprintf('Recording [%s] (%d/%d) is found in the sourceData\n',recName,n,recNumTarget)

            % Check if loc tag (subnuclei information) exists 
            locTagTF = isfield(sourceData{recIdxInSource,roiInfoCol},locTagStr);
            if locTagTF
                newTargetData{n,roiInfoCol}.(locTagStr) = sourceData{recIdxInSource,roiInfoCol}.(locTagStr);

                % Print: loc tag is copied
                fprintf(' locTag (subnuclei information) copied to the targetData\n') 
            else
                fprintf(' locTag not found in the sourceData. Nothing copied\n')
            end
        else
            fprintf('Recording [%s] (%d/%d) not found in the sourceData\n',recName,n,recNumTarget)
        end
    end
end
