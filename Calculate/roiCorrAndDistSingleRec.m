function [corrMatrix,corrFlat,distMatrix,distFlat,varargout] = roiCorrAndDistSingleRec(alignedDataRec,binSize,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi). Calculate the cross correlation of activity and ROI distances

	% Turn on the 'visualizeData':plot the cross correlation as heatmap and
	% correlation vs distance as scatter if 

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% corrMatrix: roi correlation paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,corrMatrix,'Colormap',jet);
	% corrFlat: Get the upper triangular part of corrMatrix and flatten it to a vector
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);
	% roi_coors: Cell array. one cell contains the coordinate from one ROI. it can be found in
	% alignedData.traces
	% distMatrix: roi distances paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,distMatrix,'Colormap',jet);
	% distFlat: Get the upper triangular part of distMatrix and flatten it to a vector


	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time
	visualizeData = false;
	corrThresh = 0.3; % correlation equal and below this threshhold will not be show in the graph and bundling plots  

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('visualizeData', varargin{ii})
            visualizeData = varargin{ii+1};
	    elseif strcmpi('corrThresh', varargin{ii})
            corrThresh = varargin{ii+1}; % pixels/um. used for calibrate the distance
	    elseif strcmpi('distScale', varargin{ii})
            distScale = varargin{ii+1}; % pixels/um. used for calibrate the distance
	    end
	end

	% calculate the activity correlation using event time
	[corrMatrix,corrFlat,roiNames,roiPairNames,recDateTime] = roiCorr(alignedDataRec,binSize,'eventTimeType',eventTimeType);

	% calculate the distances of all neuron pairs
	roi_coors = {alignedDataRec.traces.roi_coor};
	[distMatrix,distFlat] = roiDist(roi_coors);

	if exist('distScale','var') && ~isempty(distScale)
	    distMatrix = distMatrix./distScale;
	    distFlat = distFlat./distScale;
	    distLabelStr = 'Distance (um)';
	else
		distLabelStr = 'Distance (pixel)';
	end


	varargout{1} = roiNames;
	varargout{2} = roiPairNames;
	varargout{3} = recDateTime;

	% Plot data if visualizeData is true
	if visualizeData
		fName = sprintf('roiCorrFig rec-%s',recDateTime);
		f = fig_canvas(5,'unit_width',0.3,'unit_height',0.4,'column_lim',3,'fig_name',fName);
		fTile = tiledlayout(f,2,3); % create 1x2 tiles 

		% display the roi correlation using heatmap
		corrHeatmapAx = nexttile(fTile,1);
		heatmapHandle = heatMapRoiCorr(corrMatrix,roiNames,'recName',recDateTime,'plotWhere',gca,...
			'excludeSelfCorrColor',true);
		title('Cross correlation')

		
		if numel(corrMatrix)>1
			% display the hierachical clustered roi correlation usigng heatmap
			corrHeatmapAx = nexttile(fTile,2);
			[corrMatrixHC,outperm_cols,outperm_rows] = hierachicalCluster(corrMatrix);
			roiNamesHC = roiNames(outperm_cols);
			heatmapHCHandle = heatMapRoiCorr(corrMatrixHC,roiNamesHC,'recName',recDateTime,'plotWhere',gca,...
				'excludeSelfCorrColor',true);
			title('Hierachical clustered cross correlation')

			% display the relationship between the activity correlation and the roi distance
			corrDistScatterAx = nexttile(fTile,3);
			scatterHandle = stylishScatter(distFlat,corrFlat,'plotWhere',gca,...
				'xlabelStr',distLabelStr,'ylabelStr','Correlation','titleStr','Correlation vs Distance');

			% display the neuronal network graph
			corrHeatmapAx = nexttile(fTile,4);
			graphHandle = drawNeuronalNetworkGraph(corrMatrix,distMatrix,roiNames,'plotWhere',gca,'corrThresh',corrThresh);

			% display the edge bundling
			corrHeatmapAx = nexttile(fTile,5);
			drawEdgeBundling(corrMatrix,distMatrix,roiNames,'plotWhere',gca,'corrThresh',corrThresh,'colorBarStr',distLabelStr);
		end

		% display the roi map
		roi_map = alignedDataRec.roi_map;
		roiCoor = {alignedDataRec.traces.roi_coor}';
		roiCoor = cell2mat(roiCoor);
		roiCoor = convert_roi_coor(roiCoor);

		roiMapAx = nexttile(fTile,6);
		plot_roi_coor(roi_map,roiCoor,roiMapAx,...
			'label','text','textCell',roiNames,'textColor','black','labelFontSize',12,...
			'shapeColor','yellow','opacity',1,'showMap',true); % plotWhere is [] to supress plot


		sgtitle(fName)
		varargout{4} = f;
		varargout{5} = fName;
	else
		varargout{4} = [];
		varargout{5} = [];
	end
end