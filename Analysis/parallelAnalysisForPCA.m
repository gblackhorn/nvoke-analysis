function [numComponentsToRetain,varargout] = parallelAnalysisForPCA(dataMat,pcaLatent,varargin)
	% Run parallel analysis for PCA to select the optimal number of principle components

	% dataMat: data matrix. Every row contains a time recording, such as a roi data. 
	% pcaLatent: 'latent' of dataMat returned by the function 'pca' 

	% Example:
	%		

	% Defaults
	% dispCorr = false;
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     % if strcmpi('eventTimeType', varargin{ii}) 
	%     %     eventTimeType = varargin{ii+1}; 
	%     % elseif strcmpi('plotWhere', varargin{ii})
    %     %     plotWhere = varargin{ii+1};
	%     % elseif strcmpi('dispCorr', varargin{ii})
    %     %     dispCorr = varargin{ii+1};
	% end


	% Parameters for Parallel Analysis
	numIterations = 1000;  % Number of random datasets to generate
	numComponents = size(dataMat,2);  % Number of components to analyze
	eigenValuesRandom = zeros(numIterations, numComponents);

	% Generate random dataMat and perform PCA for each iteration
	for i = 1:numIterations
	    % Generate a random dataset with the same size and variance as the original dataMat
	    randomData = randn(size(dataMat)) .* std(dataMat) + mean(dataMat);
	    
	    % Perform PCA on the standardized random dataMat
	    [~, ~, latentRandom] = pca(zscore(randomData));
	    
	    % Store the eigenvalues
	    eigenValuesRandom(i, :) = latentRandom(1:numComponents);
	end

	% Calculate the mean eigenvalue for each component from all iterations
	meanEigenValuesRandom = mean(eigenValuesRandom, 1);

	% Compare the actual eigenvalues with the mean of the random eigenvalues
	numComponentsToRetain = sum(pcaLatent > meanEigenValuesRandom');


	varargout{1} = meanEigenValuesRandom;
end