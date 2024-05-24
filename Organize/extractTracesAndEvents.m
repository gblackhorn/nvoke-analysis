function [timeStamp,roiNames,roiTraces,eventTimeStamps] = extractTracesAndEvents(alignedDataStruct)
    % Read the alignedData and return the traces and event time stamps of ROIs 

    % alignedDataStruct: A structure var including organized calcium imaging data from a single
    % recording used for generating plots and running statistics.  
    %

    % Get the time stamp for the whole recording
    timeStamp = alignedDataStruct.fullTime;

    % Get the names of ROIs
    roiNames = {alignedDataStruct.traces.roi};

    % Get the traces of ROIs. The size of each trace is the same as the timeStamp. Size of array:
    % traceLength*roiNum 
    roiTraces = [alignedDataStruct.traces.fullTrace];

    % Collect all the event properties. One cell contains properties from one ROI
    eventPropAll = {alignedDataStruct.traces.eventProp};

    % Get the time stamps of events (peak). Each cell contains time stamps of events from one ROI 
    eventTimeStamps = cellfun(@(x) [x.peak_time],eventPropAll,'UniformOutput',false);
end
