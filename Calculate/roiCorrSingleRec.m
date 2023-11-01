function [corrMatrix,corrFlat,distMatrix,distFlat,roiNames] = roiCorrSingleRec(alignedDataRec,binSize,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi). Calculate the 

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% corrMatrix: roi correlation paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,corrMatrix,'Colormap',jet);
	% flatCorr: Get the upper triangular part of corrMatrix and flatten it to a vector
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);
	% roi_coors: Cell array. one cell contains the coordinate from one ROI. it can be found in
	% alignedData.traces
	% distMatrix: roi distances paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,distMatrix,'Colormap',jet);
	% flatDist: Get the upper triangular part of distMatrix and flatten it to a vector


	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    % elseif strcmpi('plotWhere', varargin{ii})
        %     plotWhere = varargin{ii+1};
	    % elseif strcmpi('dispCorr', varargin{ii})
        %     dispCorr = varargin{ii+1};
	    end
	end

	% calculate the activity correlation using event time
	[corrMatrix,corrFlat,roiNames,recDateTime] = roiCorr(alignedDataRec,binSize,'eventTimeType',eventTimeType);

	% calculate the distances of all neuron pairs
	roi_coors = {alignedDataRec.traces.roi_coor};
	[distMatrix,distFlat] = roiDist(roi_coors);
end