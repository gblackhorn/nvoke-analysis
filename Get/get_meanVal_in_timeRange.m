function [meanVal,varargout] = get_meanVal_in_timeRange(timeRange,timeInfo,traceData,varargin)
	% Return the mean values in time ranges
	% timeRange contents must be found in timeInfo

	% timeRange: a double column array. 1st col contains the starts of time range. 2nd col contains ends of time range
	% timeInfo: column vector. Full time information of a trial recording
	% traceData: vector var. Calcium level information from a single roi

	repeatNum = size(timeRange, 1);
	meanVal = NaN(repeatNum); 
	stdVal = NaN(repeatNum); 

	for rn = 1:repeatNum
		idxStart = find(timeInfo==timeRange(rn, 1));
		idxEnd = find(timeInfo==timeRange(rn, 2));
		rangeData = traceData(idxStart:idxEnd);
		meanVal(rn) = mean(rangeData);
		stdVal(rn) = std(rangeData);
	end
	varargout{1} = stdVal;
end