function [riseVals,peakVals,varargout] = getRisePeakValFromRecordings(alignedData,varargin)
	% Collect trace values at the rise and peak locations from all the region of interests (ROI) in
	% all the recordings

	% alignedData: structure data output by the function 'get_event_trace_allTrials'

	% Defaults
	normWithSponEvent = false; % Use the mean value of spontaneous events in a ROI to normalize the rise and peak values

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('normWithSponEvent', varargin{ii})
	        normWithSponEvent = varargin{ii+1}; % label style. 'shape'/'text'
	    end
	end	

	% Get the number of recordings 
	recNum = numel(alignedData);

	% Allocate RAM on recording level
	riseValsRecCell = cell(recNum,1);
	peakValsRecCell = cell(recNum,1);
	eventTypesRecCell = cell(recNum,1);

	% Loop through the recordings
	for i = 1:recNum
		% Get stimulation name of the current recording and modify it to a simpler version
		stimName = alignedData(i).stim_name;
		stimName = modStimName(stimName);

		% Get the trace data including the traces and events of all the ROIs in the current recording
		traceData = alignedData(i).traces;

		% Get the number of ROIs and allocate RAM
		roiNum = numel(traceData);
		riseValsRecCell{i} = cell(roiNum,1);
		peakValsRecCell{i} = cell(roiNum,1);
		eventTypesRecCell{i} = cell(roiNum,1);

		% Loop through the ROIs
		for j = 1:roiNum
			% Get the full trace of the current ROI
			fullTrace = traceData(j).fullTrace;
			fullTrace = fullTrace(:);

			% Get the mean value of the spontaneous data. It will be used to normalize the values of
			% rise and peak if 'normWithSponEvent' is true
			sponAmp = traceData(j).sponAmp;

			% Get the locations of rises and peaks, and the types of these events
			riseLocs = [traceData(j).eventProp.rise_loc];
			peakLocs = [traceData(j).eventProp.peak_loc];
			eventTypes = {traceData(j).eventProp.peak_category};

			% Add stimName in front of the event types
			eventTypes = cellfun(@(x) sprintf('%s-%s',stimName,x),eventTypes,'UniformOutput',false);

			% Get the values at rise and peak locations and save them to allocated cells
			riseValsRecCell{i}{j} = fullTrace(riseLocs);
			peakValsRecCell{i}{j} = fullTrace(peakLocs);

			% Normalize the rise and peak values if 'normWithSponEvent' is true
			if normWithSponEvent
				riseValsRecCell{i}{j} = riseValsRecCell{i}{j}./sponAmp;
				peakValsRecCell{i}{j} = peakValsRecCell{i}{j}./sponAmp;
			end

			% Transpose the 'eventTypes' if it is not row vectors. Save it to the eventTypesRecCell
			eventTypesRecCell{i}{j} = eventTypes(:);
		end

		% Concatenate the contents from all the ROIs in the current recording
		riseValsRecCell{i} = vertcat(riseValsRecCell{i}{:});
		peakValsRecCell{i} = vertcat(peakValsRecCell{i}{:});
		eventTypesRecCell{i} = vertcat(eventTypesRecCell{i}{:});
	end

	% Concatenate all the contents from all the recordings
	riseVals = vertcat(riseValsRecCell{:});
	peakVals = vertcat(peakValsRecCell{:});
	eventTypesAll = vertcat(eventTypesRecCell{:});
	varargout{1} = eventTypesAll;
end

function [stimNameNew,varargout] = modStimName(stimName)
    strPairs = {{'og-5s','OG'},...
        {'ap-0.1s','AP'}};
    blankRep = ''; % replacement for blank

    for m = 1:numel(strPairs)
        stimName = replace(stimName,strPairs{m}{1},strPairs{m}{2});
    end

    stimNameNew = replace(stimName,' ',blankRep);
end