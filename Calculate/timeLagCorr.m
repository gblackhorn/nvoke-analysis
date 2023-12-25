function [corrMatrix,varargout] = timeLagCorr(matrixData,binLag,varargin)
	% Examine the time-lagged cross-correlation between each pair of neurons, where you consider the
	% correlation of each neuron's activity with a 'binLag' delayed activity of the other neurons

	% matrixData: each column being the activity data of one neuron
	% binLag: lag of data

	% Example:
	%		

	% Defaults
	ignoreAutoCorr = false;

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('ignoreAutoCorr', varargin{ii}) 
	        ignoreAutoCorr = varargin{ii+1}; 
	    % elseif strcmpi('dispCorr', varargin{ii})
        %     dispCorr = varargin{ii+1};
	    end
	end

	% Get the number of neurons
	numNeurons = size(matrixData,2);


	% Initialize a matrix to store correlation coefficients
	corrMatrix = zeros(numNeurons, numNeurons);


	% Loop through each pair of neurons
	for i = 1:numNeurons
	    for j = 1:numNeurons
	        if i ~= j || ~ignoreAutoCorr
	            % Shift the data of neuron j by binLag
	            shiftedData = [zeros(binLag, 1); matrixData(1:end-binLag, j)]; % Assuming 1 data point represents 1 second
	            
	            % Compute the correlation between neuron i and shifted neuron j
	            corrMatrix(i, j) = corr(matrixData(:, i), shiftedData, 'Rows', 'complete');
	        end
	    end
	end
end