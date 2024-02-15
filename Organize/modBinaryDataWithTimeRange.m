function [newBinaryMatrix,varargout] = modBinaryDataWithTimeRange(binaryMatrix,binSize,timeRanges,varargin)
	% Remove the binary data in the time Ranges or only use the binary data in the time Ranges

	% binaryMatrix (m*n): Every row contains data in a time bin. 1st row starts from time zero
	% binSize: The size of time bin
	% timeRanges (r*2): r times of ranges. 1st column contains the starts and 2nd column contains
	% 					the ends of the time ranges 

	% Example:
	%		

	% Defaults
	funMode = 1; % 1: Remove the rows in the time ranges. 2: Keep the rows in the time ranges and remove other rows
				 % Default: 1


	% funMode: Default = 1
	% 1: Remove the rows in the time ranges. 
	% 2: Keep the rows in the time ranges and remove other rows
	if nargin = 3
		funMode = 1;
	elseif nargin = 4
		funMode = varargin{1};
	end

	% Get the number of bins
	binNum = size(binaryMatrix,1);
	allIndices = 1:binNum; % Vector of all row indices in 'binaryMatrix'


	% % Get the bin vector (bin time)
	% binVec = [1:binNum]*binSize;


	% Convert the timeRanges to the bin indices
	timeRangesIDX = ceil(timeRanges/binSize);


	% Get all the indices of bins in the time ranges
	timeRangesBins = [];
	for i = 1:size(timeRanges,1)
		timeRangesBins = [timeRangesBins,[timeRangesIDX(i,1):timeRangesIDX(i,2)]];
	end


	% Get all the indices of bins not in the time ranges
	nonTimeRangesBins = setdiff(allIndices,timeRangesBins);


	% modify the binaryMatrix using the timeRanges
	newBinaryMatrix = binaryMatrix;
	if funMode == 1
		newBinaryMatrix(timeRangesBins,:) = [];
	elseif funMode == 2
		newBinaryMatrix(nonTimeRangesBins,:) = [];
	else
		error('the funMode(function mode) must be either 1 or 2')
	end


	varargout{1} = timeRangesBins;
	varargout{2} = nonTimeRangesBins;
end