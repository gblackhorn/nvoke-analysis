function [alignedData] = screenSubNucleiROIs(alignedData,subNucleiType)
    % Keep ROIs in specific subnuclei, marked by subNucleiType, in 'alignedData' structure var and
    % remove others

    % alignedData: A struct var output by the function 'get_event_trace_allTrials'

    % subNucleiType: A character var, such as 'DAO', 'PO', etc.


    % Validate the data: Check if there is subNuclei field
    snTF = isfield(alignedData(1).traces,'subNuclei');
    if ~snTF
        error('Neurons must be tagged with subNuclei (field in alignedData(n).traces)')
    end

    % Create a vector used to mark the recordings to be removed
    rmRecTF = zeros(1,numel(alignedData));

    % Loop through recordings
    recNum = numel(alignedData);
    for i = 1:recNum
        % Get the subNuclei tags from all the ROIs in this recording
        snString = {alignedData(i).traces.subNuclei};

        % Get the index of ROIs with the input subnNuclei tag ('subNucleiType')
        sntIDX = find(strcmpi(snString,subNucleiType));

        if ~isempty(sntIDX)
            % Keep the ROI in sntIDX and remove others if sntIDX is not empty
            alignedData(i).traces = alignedData(i).traces(sntIDX);
        else
            % Mark this recording as to be removed. All the marked recordings will be removed later
            rmRecTF(i) = 1;
        end
    end

    % Remove the empty recordings marked in the loop above
    rmRecIDX = find(rmRecTF);
    alignedData(rmRecIDX) = [];
end
