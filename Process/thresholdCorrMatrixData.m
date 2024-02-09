function [maskedCorrMatrixData,varargout] = thresholdCorrMatrixData(CorrMatrixData,varargin)
	% Threshold CorrMatrixData using percentile

	% Originally, this is used for thresholding data before heatmap plot

	% CorrMatrixData: upper and lower triangle data are symatrical. 



	% % Defaults
	% percentileThreshold = 75; % Define the percentile

	% % dispCorr = false;
	% % filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
	% 	% filter number must be equal to stim_names

	% % Optionals
	% for ii = 1:2:(nargin-1)
	%     if strcmpi('percentileThreshold', varargin{ii}) 
	%         percentileThreshold = varargin{ii+1}; 
	%     % elseif strcmpi('plotWhere', varargin{ii})
    %     %     plotWhere = varargin{ii+1};
	%     % elseif strcmpi('dispCorr', varargin{ii})
    %     %     dispCorr = varargin{ii+1};
	% end

	if nargin < 2
		percentileThreshold = 75; % Define the percentile
	elseif nargin == 2
		percentileThreshold = varargin{1};
		if percentileThreshold <= 0 || percentileThreshold > 100
			error('percentile threshold value must be between 0 and 100')
		end
	end



	% Extract the upper triangular part of the correlation matrix, excluding the diagonal
	corrFlat = CorrMatrixData(triu(true(size(CorrMatrixData)), 1));

	% Take the absolute value of the flattened correlation coefficients
	absCorrFlat = abs(corrFlat);

	% Compute the 75th percentile of the absolute correlation values
	thresholdVal = prctile(absCorrFlat, percentileThreshold);

	% Create a masked version of the correlation matrix where values below the threshold are set to NaN or 0
	maskedCorrMatrixData = CorrMatrixData;
	maskedCorrMatrixData(abs(maskedCorrMatrixData) < thresholdVal) = NaN; % or 0, depending on how you want to visualize it

	varargout{1} = thresholdVal;
end