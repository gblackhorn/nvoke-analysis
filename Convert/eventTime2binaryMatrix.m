function [binaryMatrix,varargout] = eventTime2binaryMatrix(eventProps,maxTime,binSize,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi)

	% eventProps: Cell array. one cell contains eventProp from one ROI. it can be found in alignedData.traces
	% maxTime: The whole time duration. unit: second
	% binSize: unit: second

	% Example:
	%		

	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('roiNames', varargin{ii}) 
	        roiNames = varargin{ii+1}; 
	    elseif strcmpi('eventTimeType', varargin{ii})
            eventTimeType = varargin{ii+1};
	    end
	end

	% count the number of ROIs
	roiNum = numel(eventProps);

	% create roiNames if it is not input
	if ~exist('roiNames','var') || isempty(roiNames)
		roiNames = arrayfun(@(x) ['roi', num2str(x)], 1:roiNum, 'UniformOutput', false);
	end

	% initialize binary matrix and timePointsNum array
	binaryMatrix = NaN(ceil(maxTime/binSize),roiNum);
	timePointsNum = NaN(1,roiNum); % number of events for every ROI is stored in a single entry

	% fill in binaryMatrix: one roi data for one column
	for n = 1:roiNum
		eventTimePoints = [eventProps{n}.(eventTimeType)];
		[binaryMatrix(:,n),timePointsNum(n)] = time2binary(eventTimePoints,maxTime,binSize);
	end

	% Output the timePointsNum as a varargout
	varargout{1} = timePointsNum;
end