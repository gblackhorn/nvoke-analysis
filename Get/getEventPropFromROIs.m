function [roiEventVal,recNames,roiNames,varargout] = getEventPropFromROIs(alignedData,propertyName,varargin)
    % Get the specified event properties from ROIs in a single recording
    % Calculate the variance, STD, and SEM of the property values

    % alignedData: output of function 'get_event_trace_allTrials'. Size can be 1 or bigger
    % propertyName: structure fields in alignedData(n).traces(m).eventProp
    %   - rise_duration
    %   - FWHM
    %   - peak_mag_delta
    %   - peak_delta_norm_hpstd

    % All the outputs are vertical cells. Each cell contain the data from a single recording

    % Example: 
    %   [roiEventVal,recNames,roiNames,roiVariance,roiStd,roiSem] = getEventPropFromROIs(alignedData_allTrials,'peak_mag_delta','normData',true);



    % default
    peakCat = 'spon'; % Collect the events in this specified category. If this var is empty, collect all.
    normData = false; % normalize the data with the mean of spontaneous event property
    peakCatSpon = 'spon'; % the peak category of spontaneous events


    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('peakCat', varargin{ii})
            peakCat = varargin{ii+1}; 
        elseif strcmpi('normData', varargin{ii})
            normData = varargin{ii+1}; 
        end
    end 


    % Get the number and names (data-time) of recordings
    recNum = numel(alignedData);
    recNamesFull = {alignedData.trialName};
    recNamesFull = recNamesFull(:);
    recNames = cellfun(@(x) x(1:15),recNamesFull,'UniformOutput',false);


    % Create variables
    roiNames = cell(recNum,1);
    roiEventVal = cell(recNum,1);
    roiEventCat = cell(recNum,1);
    roiVariance = cell(recNum,1);
    roiStd = cell(recNum,1);
    roiSem = cell(recNum,1);


    % Loop through recordings
    for i = 1:recNum
        alignedDataSingle = alignedData(i);

        % Get the number and names of ROIs
        roiNum = numel(alignedDataSingle.traces);
        roiNames{i} = {alignedDataSingle.traces.roi};
        roiNames{i} = roiNames{i}(:); % Transpose the var to a vertical vector if it is horizontal

        % Create empty vars
        eventVal = cell(roiNum,1);
        eventPeakCat = cell(roiNum,1); % This var stores the peak category of events 
        eventVariance = NaN(roiNum,1);
        eventStd = NaN(roiNum,1);
        eventSem = NaN(roiNum,1);


        % Loop through ROIs
        for j = 1:roiNum
            roiData = alignedDataSingle.traces(j);

            % Use peakCat to filter events if it is not empty 
            peakCatAll = {roiData.eventProp.peak_category};
            if ~isempty(peakCat)
                eventIDX = find(strcmpi(peakCat,peakCatAll));
            end

            % Get the specified event property values from a single ROI
            eventVal{j} = [roiData.eventProp(eventIDX).(propertyName)];
            eventVal{j} = eventVal{j}(:);
            eventPeakCat{j} = peakCatAll(eventIDX);
            eventPeakCat{j} = eventPeakCat{j}(:);


            % Normalize data with the mean spontaneous event values
            if normData
                sponIDX = find(strcmpi(peakCatSpon,peakCatAll));
                eventValSpon = [roiData.eventProp(sponIDX).(propertyName)];
                eventValSponMean = mean(eventValSpon);
                eventVal{j} = eventVal{j}./eventValSponMean;
            end 


            % Calculate the variance
            eventVariance(j) = var(eventVal{j});

            % Calculate the STD
            eventStd(j) = std(eventVal{j});

            % Calculate the SEM
            eventSem(j) = eventStd(j)/sqrt(numel(eventStd(j)));
        end

        % Store the data from a single recording to the cell variables
        roiEventVal{i} = eventVal;
        roiEventCat{i} = eventPeakCat;
        roiVariance{i} = eventVariance;
        roiStd{i} = eventStd;
        roiSem{i} = eventSem;
    end


    varargout{1} = roiVariance;
    varargout{2} = roiStd;
    varargout{3} = roiSem;
    varargout{4} = roiEventCat;
end
