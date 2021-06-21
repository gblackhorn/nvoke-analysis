function [timeSeries_norm] = normalizeTimeSeries(timeSeries, varargin)
% Normalize time series data
%   timeSeries: 1-col is time info
% 				other-col trace data. can be 1 to any
%   varargin{1}: normalizing method. 1-norm to max value. If varargin{1} is empty, default is 1

	timeZeroLoc = find(timeSeries(:, 1) == 0); % idx of 0 in time info
	pointNum_for_findmax = ceil((size(timeSeries, 1)-timeZeroLoc)/5);
	findMaxEnd = timeZeroLoc+pointNum_for_findmax; % look for max value in range [timeZeroLoc findMaxEnd]
	traceNum = size(timeSeries, 2)-1; % number of traces
	for tn = 1:traceNum
		coln = tn+1; % column number of trace. 1st col is time
		maxVal = max(timeSeries(timeZeroLoc:findMaxEnd, coln));
		timeSeries(:, coln) = timeSeries(:, coln)/maxVal;
	end
	timeSeries_norm = timeSeries;
end

