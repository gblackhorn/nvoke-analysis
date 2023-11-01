function [distMatrix,distFlat,varargout] = roiDist(roi_coors,varargin)
	% compute the distances between roi pairs using their coordinations

	% roi_coors: Cell array. one cell contains the coordinate from one ROI. it can be found in
	% alignedData.traces
	% distMatrix: roi distances paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,distMatrix,'Colormap',jet);
	% distFlat: Get the upper triangular part of distMatrix and flatten it to a vector


	% Example:
	%		

	% Defaults
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% % Optionals
	% for ii = 1:2:(nargin-3)
	%     if strcmpi('roiNames', varargin{ii}) 
	%         roiNames = varargin{ii+1}; 
	%     elseif strcmpi('eventTimeType', varargin{ii})
    %         eventTimeType = varargin{ii+1};
	%     end
	% end

	% fill all the coordinates to a matrix
	roiCoord = vertcat(roi_coors{:});

	% the first column is the neuron idx, discard it
	roiIDX = roiCoord(:,1);
	roiCoord = roiCoord(:,[2:3]);

	% calculate the pairwise distances
	distMatrix = pdist2(roiCoord,roiCoord,'euclidean');

	% Flatten the upper triangular part (excluding the diagonal) 
	% flattened distances can be used to pair with activity correlation between ROI pairs, which is
	% flattend in the same way (using function 'roiCorr')
	distFlat = distMatrix(triu(true(size(distMatrix)),1));
end