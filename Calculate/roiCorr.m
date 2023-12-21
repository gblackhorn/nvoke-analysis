function [corrMatrix,corrFlat,varargout] = roiCorr(matrixData,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi), and calculate the activity correlation between all neuron pairs

	% matrixData: each column being the activity data of one neuron
	% corrMatrix: roi correlation paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,corrMatrix,'Colormap',jet);
	% corrFlat: Get the upper triangular part of corrMatrix and flatten it to a vector

	% Example:
	%		

	% Defaults

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('roiNames', varargin{ii}) 
	        roiNames = varargin{ii+1}; 
	    end
	end



	% compute the correlation matrix
	corrMatrix = corr(binaryMatrix);

	% Flatten the upper triangular part (excluding the diagonal) for scatter plot
	% flattened correlation can be used to pair with flattened distances between ROI pairs
	% (using function 'roiDist')
	corrFlat = corrMatrix(triu(true(size(corrMatrix)),1));


	if exist('roiNames','var') && ~isempty(roiNames)
		% Prepare the roiPairNames for 'corrFlat'
		% Calculate the number of neurons
		numNeurons = size(corrMatrix, 1);

		% Initialize a cell array to hold the neuron pair names
		roiPairNames = cell(length(corrFlat), 1);

		% Obtain the upper triangular indices
		[row, col] = find(triu(ones(numNeurons, numNeurons), 1));

		% Loop through each index to get neuron names
		for i = 1:length(row)
		    roiPairNames{i} = [roiNames{row(i)}, '-', roiNames{col(i)}];
		end

		varargout{1} = roiPairNames;
	else
		varargout{1} = '';
	end
end