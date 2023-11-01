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

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('visualizeData', varargin{ii})
            visualizeData = varargin{ii+1};
	    % elseif strcmpi('dispCorr', varargin{ii})
        %     dispCorr = varargin{ii+1};
	    end
	end

	% calculate the activity correlation using event time
	[corrMatrix,corrFlat,roiNames,recDateTime] = roiCorr(alignedDataRec,binSize,'eventTimeType',eventTimeType);

	% calculate the distances of all neuron pairs
	roi_coors = {alignedDataRec.traces.roi_coor};
	[distMatrix,distFlat] = roiDist(roi_coors);

	varargout{1} = roiNames;
	varargout{2} = recDateTime;

	% Plot data if visualizeData is true
	if visualizeData
		fName = sprintf('roiCorrFig rec-%s',recDateTime);
		f = fig_canvas(2,'unit_width',0.3,'unit_height',0.4,'column_lim',2,'fig_name',fName);
		fTile = tiledlayout(f,1,2); % creat 1x2 tiles 

		% display the roi correlation using heatmap
		corrHeatmapAx = nexttile(fTile);
		heatmapHandle = heatMapRoiCorr(corrMatrix,roiNames,'recName',recDateTime,'plotWhere',gca);
		title('Cross correlation')

		% display the relationship between the activity correlation and the roi distance
		corrDistScatterAx = nexttile(fTile);
		scatterHandle = scatter(gca,distFlat, corrFlat, 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r');
		xlabel('Distance');
		ylabel('Correlation');
		title('Correlation vs Distance');
		box off;
		set(gca, 'FontSize', 12, 'LineWidth', 1.5);
		set(gcf, 'Color', 'w');
		grid on;
		set(gca, 'GridLineStyle', ':', 'GridColor', 'k', 'GridAlpha', 0.5);

		sgtitle(fName)
		varargout{3} = f;
		varargout{4} = fName;
	else
		varargout{3} = [];
		varargout{4} = [];
	end
end