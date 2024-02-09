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
	corrDataType = 'event'; % event/trace. Data used for calculation correlation
	eventTimeType = 'peak_time'; % rise_time/peak_time

	ThresholdCorrMat = true; % Use the percentile to threshold correlation data
	percentileThreshold = 75; % Threshold correlation matrix data. Keep the ones above the percentile

	visualizeData = false;
	corrThresh = []; % correlation equal and below this threshhold will not be show in the graph and bundling plots  
	roiNameExcessiveStr = 'neuron'; % remove this string from the ROI name to shorten it
	tileMultiplier = 3; % Multiple the number of tiles with this parametter for Managing the size of plots

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('ThresholdCorrMat', varargin{ii})
            ThresholdCorrMat = varargin{ii+1};
	    elseif strcmpi('corrDataType', varargin{ii})
            corrDataType = varargin{ii+1};
	    elseif strcmpi('visualizeData', varargin{ii})
            visualizeData = varargin{ii+1};
	    elseif strcmpi('corrThresh', varargin{ii})
            corrThresh = varargin{ii+1}; % pixels/um. used for calibrate the distance
	    elseif strcmpi('distScale', varargin{ii})
            distScale = varargin{ii+1}; % pixels/um. used for calibrate the distance
	    end
	end

	% Calculate the correlation
	switch corrDataType
		case 'event'
			% Get events' time from all the ROIs and create a binary matrix. Each column contains events
			% info of a single ROI. 1 if a time bin contains an event, 0 if there is no event in the bin
			% Extract recording and roi names as well
			[binaryMatrix,timePointsNum,roiNames,recDateTime] = recEventBinaryMatrix(alignedDataRec,binSize,'eventTimeType',eventTimeType);

			% calculate the activity correlation using event time
			[corrMatrix,corrFlat,roiPairNames] = roiCorr(binaryMatrix,roiNames);
		case 'trace'
			[traceMatrix,roiNames,recDateTime] = recTrace(alignedDataRec);
			lagExt = binSize/2;
			[~,corrMatrix,corrFlat,roiPairNames] = roiCorrTrace(traceMatrix,'roiNames',roiNames,...
				'lagsOfInterest',0,'lagExt',lagExt);
	end

	% Thresholding correlation data
	if ThresholdCorrMat && isempty(corrThresh)
		[maskedCorrMatrix,corrThresh] = thresholdCorrMatrixData(corrMatrix,percentileThreshold); 
	else
		maskedCorrMatrix = corrMatrix;
	end

	
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


	% remove the 'neuron' part from the roiName for clearer display in the plots. For example,
	% change neuron5 to 5
	roiNamesShort = cell(size(roiNames));
	for i = 1:numel(roiNames)
		roiNamesShort{i} = strrep(roiNames{i},roiNameExcessiveStr,'');
	end


	% Plot data if visualizeData is true
	if visualizeData
		fName = sprintf('roiCorrFig %s rec-%s binSize-%gs corrThresh-%g',corrDataType,recDateTime,binSize,corrThresh);
		f = fig_canvas(9,'unit_width',0.3,'unit_height',0.4,'column_lim',3,'fig_name',fName);
		fTile = tiledlayout(f,3*tileMultiplier,3*tileMultiplier); % create tiles 

		% display the roi correlation using heatmap
		corrHeatmapAx = nexttile(fTile,2,[3 2]);
		heatmapHandle = heatMapRoiCorr(maskedCorrMatrix,roiNamesShort,'recName',recDateTime,'plotWhere',gca,...
			'excludeSelfCorrColor',true);
		title('Cross correlation')

		% add histogram next to the heatmap above showing the timePoint number in each ROI
		% horizontal histo on the left side of the heatmap
		if exist('timePointsNum','var')
			tpNumVertAx = nexttile(fTile,1,[3 1]); 
			stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','horizontal',...
				'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)]);
			% vertical histo below the the heatmap
			tpNumVertAx = nexttile(fTile,29,[1 2]); 
			stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','vertical',...
				'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)]);
		end

		
		if numel(corrMatrix)>1
			% display the hierachical clustered roi correlation usigng heatmap
			corrHeatmapAx = nexttile(fTile,5,[3 2]);
			[corrMatrixHC,outperm] = hierachicalCluster(corrMatrix);
			roiNamesHC = roiNamesShort(outperm);
			if ThresholdCorrMat
				corrMatrixHC(abs(corrMatrixHC)<corrThresh) = NaN;
			end
			heatmapHCHandle = heatMapRoiCorr(corrMatrixHC,roiNamesHC,'recName',recDateTime,'plotWhere',gca,...
				'excludeSelfCorrColor',true);
			title('Hierachical clustered cross correlation')

			% add histogram next to the heatmap above showing the timePoint number in each ROI
			% horizontal histo on the left side of the heatmap
			if exist('timePointsNum','var')
				timePointsNumHC = timePointsNum(outperm);
				tpNumVertAx = nexttile(fTile,4,[3 1]); 
				stylishHistogram(timePointsNumHC,'plotWhere',gca,'Orientation','horizontal',...
					'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)]);
				% vertical histo below the the heatmap
				tpNumVertAx = nexttile(fTile,32,[1 2]); 
				stylishHistogram(timePointsNumHC,'plotWhere',gca,'Orientation','vertical',...
					'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)]);
			end


			% display the relationship between the activity correlation and the roi distance
			corrDistScatterAx = nexttile(fTile,7,[3 3]);
			scatterHandle = stylishScatter(distFlat,corrFlat,'plotWhere',gca,...
				'xlabelStr',distLabelStr,'ylabelStr','Correlation','titleStr','Correlation vs Distance');

			% display the neuronal network graph
			corrHeatmapAx = nexttile(fTile,37,[3 3]);
			graphHandle = drawNeuronalNetworkGraph(corrMatrix,'roiNames',roiNamesShort,'plotWhere',gca,'corrThresh',corrThresh);

			% display the edge bundling
			corrHeatmapAx = nexttile(fTile,40,[3 3]);
			drawEdgeBundling(corrMatrix,distMatrix,roiNamesShort,'plotWhere',gca,'corrThresh',corrThresh,'colorBarStr',distLabelStr);
		end

		% display the roi map
		roi_map = alignedDataRec.roi_map;
		roiCoor = {alignedDataRec.traces.roi_coor}';
		roiCoor = cell2mat(roiCoor);
		roiCoor = convert_roi_coor(roiCoor);

		roiMapAx = nexttile(fTile,43,[3 3]);
		plotRoiCoor2(roi_map,roiCoor,'plotWhere',roiMapAx,...
			'textCell',roiNamesShort,'textColor','m','labelFontSize',12,'showMap',true); % plotWhere is [] to supress plot
		% plot_roi_coor(roi_map,roiCoor,roiMapAx,...
		% 	'label','text','textCell',roiNamesShort,'textColor','black','labelFontSize',12,...
		% 	'shapeColor','yellow','opacity',1,'showMap',true); % plotWhere is [] to supress plot

		% display the synchronicity of ROIs in a recording using percentage
		syncPercAx = nexttile(fTile,64,[2,9]);
		displayRecSyncPerc(syncPercAx,alignedDataRec,binSize);


		sgtitle(fName,'FontSize',14,'FontWeight','Bold')
		varargout{4} = f;
		varargout{5} = fName;
	else
		varargout{4} = [];
		varargout{5} = [];
	end
end