function dispRecSubnucleiLoc(alignedDataStruct, targetFunction)
    % dispRecSubnucleiLoc reads alignedDataStructure and list the subnuclei information of
    % recordings


    % Get the length of the alignedDataStruct
    recNum = numel(alignedDataStruct);

    % % Create a stucture to store the subNuclei information
    % RecSubnucleiLoc = empty_content_struct({'recName','subNucleiInfo'}, recNum);

    % Loop through all the recordings
    for n = 1:recNum
        % Use the date-time as the recording name
        recName = extractDateTime(alignedDataStruct(n).trialName);
        % RecSubnucleiLoc(n).recName = extractDateTime(alignedDataStruct(n).trialName);

        if ~isempty(alignedDataStruct(n).traces)
            % Disp the recording name
            recNameStr = sprintf('%d. Recording %s', n, recName);
            disp(recNameStr)

            % Get the ROIs' subNuclei information, and find the unique ones
            ROIsubNuclei = {alignedDataStruct(n).traces.subNuclei};
            ROIsubNucleiUnique = unique(ROIsubNuclei);

            % Loop through the unique subNuclei names and create a string for disp the info
            for m =1:numel(ROIsubNucleiUnique)
                % Get the subNuclei name and the number of neurons in the subNuclei
                subNucleiName = ROIsubNucleiUnique{m};
                subNucleiRoiNum = sum(strcmpi(subNucleiName, ROIsubNuclei));

                % Disp the subNuclei name and the number of ROIs
                subNucleiInfoStr = sprintf(' - %s (%d)', subNucleiName, subNucleiRoiNum);
                disp(subNucleiInfoStr)
            end
        end
    end

end


function dateTimeStr = extractDateTime(inputStr)
    % Ensure the input is a character array (string)
    inputStr = char(inputStr);
    
    % Find the index of the first underscore
    underscoreIndex = find(inputStr == '_', 1);
    
    % Extract the date-time string up to the first underscore
    if ~isempty(underscoreIndex)
        dateTimeStr = inputStr(1:underscoreIndex-1);
    else
        error('No underscore found in the input string.');
    end
end


