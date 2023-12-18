function [corrMatrixHC,outperm,varargout] = hierachicalCluster(corrMatrix,varargin)
	% Re-order the cross correlation. Return a hierachical clustered corrMatrixHC 

	% Example:
	%		

	% Defaults
	pdistMetric = 'euclidean';
	linkageMethod = 'ward';

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('pdistMetric', varargin{ii}) 
	        pdistMetric = varargin{ii+1}; 
	    elseif strcmpi('linkageMethod', varargin{ii})
            linkageMethod = varargin{ii+1};
	    % elseif strcmpi('dispCorr', varargin{ii})
        %     dispCorr = varargin{ii+1};
	    end
	end

	% Hierarchical clustering for rows and columns
	Y_rows = pdist(corrMatrix, pdistMetric);
	Z_rows = linkage(Y_rows, linkageMethod);
	Y_cols = pdist(corrMatrix, pdistMetric);
	Z_cols = linkage(Y_cols, linkageMethod);

	% Calculate the order of the rows and columns
	figure;
	[~, ~, outperm] = dendrogram(Z_rows, 0);
	[~, ~, outperm] = dendrogram(Z_cols, 0);
	close(gcf); % Close the dendrogram figure

	% Reorder the corrMatrix matrix
	corrMatrixHC = corrMatrix(outperm, outperm);
end