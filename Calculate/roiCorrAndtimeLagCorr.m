function [timeLagCorr,varargout] = roiCorrAndtimeLagCorr(alignedData,binSize,binLag,varargin)
	% Calculate the cross correlation and the time-lagged correlation between each pair of ROIs

	% alignedData: Including data from multiple recodings. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% binLag: a number or a vector. Plotting is designed to show 3 different binLag at maximum.
	% 	Parameters for 'fig_canvas' should be modified if more binLag will be used

	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time
	visualizeData = false;
	tileMultiplier = 4; % Multiple the number of tiles with this parametter for Managing the size of plots

	saveFig = false;
	guiSave = false;
	saveDir = [];
	dbMode = false; % debug mode

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('calTimeLagCorr', varargin{ii})
            calTimeLagCorr = varargin{ii+1};
	    elseif strcmpi('binLag', varargin{ii})
            binLag = varargin{ii+1};
	    elseif strcmpi('visualizeData', varargin{ii})
            visualizeData = varargin{ii+1};
	    elseif strcmpi('saveFig', varargin{ii})
            saveFig = varargin{ii+1};
	    elseif strcmpi('guiSave', varargin{ii})
            guiSave = varargin{ii+1};
	    elseif strcmpi('saveDir', varargin{ii})
            saveDir = varargin{ii+1};
	    elseif strcmpi('dbMode', varargin{ii})
            dbMode = varargin{ii+1};
	    end
	end

	% Create a stucture to store correlation and distance data from every recording
	recNum = numel(alignedData);
	timeLagCorrFields = {'recName','roiNames','roiPairNames','binSize','binLag',...
		'corrMatrix','corrFlat','corrMatrixTimeLag'};
	timeLagCorr = empty_content_struct(corrAndDistFields,recNum);

	% Get the number of binLag
	binLagNum = numel(binLag);

	% select folder to save figures
	if visualizeData && saveFig
	    if ~exist('saveDir','var') || isempty(saveDir) 
	        guiSave = true;
	        saveDir = [];
	    end

	    if guiSave
	    	saveDir = uigetdir(saveDir,'Save cross correlation figures');
	    end
	else
		saveFig = false;
	end


	% loop through every recording and collect data
	for n = 1:recNum
		if dbMode
			fprintf('recording (%d/%d): %s\n',n,recNum,alignedData(n).trialName);
			if n == 9
				pause
			end
		end

		if ~isempty(alignedData(n).traces)
			close all
			% Get events' time from all the ROIs and create a binary matrix. Each column contains events
			% info of a single ROI. 1 if a time bin contains an event, 0 if there is no event in the bin
			% Extract recording and roi names as well
			[binaryMatrix,timePointsNum,roiNames,recDateTime] = recEventBinaryMatrix(alignedDataRec,binSize,'eventTimeType',eventTimeType);

			% Calculate the activity cross correlation using event time
			[corrMatrix,corrFlat,roiPairNames] = roiCorr(binaryMatrix,roiNames);

			% Calculate the time-lagged cross-correlation between each pair of neurons
			corrMatrixTimeLagCells = cell(1,binLagNum);
			for m = 1:binLagNum
				corrMatrixTimeLagCells{m} = timeLagCorr(binaryMatrix,binLag(m));
			end

			corrAndDist(n).recName = recDateTime;
			corrAndDist(n).roiNames = roiNames;
			corrAndDist(n).roiPairNames = roiPairNames;
			corrAndDist(n).binSize = binSize;
			corrAndDist(n).binLag = binLag;
			corrAndDist(n).corrMatrix = corrMatrix;
			corrAndDist(n).corrFlat = corrFlat;
			corrAndDist(n).corrMatrixTimeLag = corrMatrixTimeLagCells;


			if visualizeData
				% Create a figure name
				fName = sprintf('roiTimeLagCorrFig rec-%s binSize-%gs ',recDateTime,binSize);

				% Create a fig canvas and organize tiles
				heatmapNum = (1+binLagNum)*2; % cross correlation withou time lag will always be plotted
				figRowNum = ceil((1+binLagNum)/2);
				figColNum = 4;
				heatmapHeight = (tileMultiplier-1);
				heatmapWidth = (tileMultiplier-1);
				f = fig_canvas(heatmapNum,'unit_width',0.2,'unit_height',0.4,'column_lim',figColNum,'fig_name',fName);
				fTile = tiledlayout(f,figRowNum*tileMultiplier,figColNum*tileMultiplier); % create tiles 

				% remove the 'neuron' part from the roiName for clearer display in the plots. For example,
				% change neuron5 to 5
				roiNamesShort = cell(size(roiNames));
				for i = 1:numel(roiNames)
					roiNamesShort{i} = strrep(roiNames{i},roiNameExcessiveStr,'');
				end


				% display the roi cross correlation using heatmap
				nexttile(fTile,2,[heatmapHeight heatmapWidth]);
				heatmapHandle = heatMapRoiCorr(corrMatrix,roiNamesShort,'recName',recDateTime,'plotWhere',gca,...
					'excludeSelfCorrColor',true);
				title('Cross correlation')

				% add histogram next to the heatmap above showing the timePoint number in each ROI
				% horizontal histo on the left side of the heatmap
				nexttile(fTile,1,[heatmapHeight 1]); 
				stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','horizontal',...
					'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)]);
				% vertical histo below the the heatmap
				nexttile(fTile,(heatmapHeight*figColNum*tileMultiplier)+2,[1 heatmapWidth]); 
				stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','vertical',...
					'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)]);


				% Display the hierarchical clustered cross correlation using heatmap
				nexttile(fTile,1+heatmapWidth+1,[heatmapHeight heatmapWidth]);
				[corrMatrixHC,outperm] = hierachicalCluster(corrMatrix);
				roiNamesHC = roiNamesShort(outperm);
				timePointsNumHC = timePointsNum(outperm);
				heatmapHCHandle = heatMapRoiCorr(corrMatrixHC,roiNamesHC,'recName',recDateTime,'plotWhere',gca,...
					'excludeSelfCorrColor',true);
				title('Hierachical clustered cross correlation')

				% add histogram next to the heatmap above showing the timePoint number in each ROI
				% horizontal histo on the left side of the heatmap
				tpNumVertAx = nexttile(fTile,1+heatmapWidth,[heatmapHeight 1]); 
				stylishHistogram(timePointsNumHC,'plotWhere',gca,'Orientation','horizontal',...
					'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)]);
				% vertical histo below the the heatmap
				tpNumVertAx = nexttile(fTile,(heatmapHeight*figColNum*tileMultiplier)+tileMultiplier+2,[1 heatmapWidth]); 
				stylishHistogram(timePointsNumHC,'plotWhere',gca,'Orientation','vertical',...
					'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)]);



				% display the cross correlation with time lag using heatmap
				for m = 1:binLagNum

				end
			end


			if saveFig
				saveDir = savePlot(fig,'save_dir',saveDir,'guiSave',false,'fname',figName);
			end
		end
	end

	varargout{3} = saveDir;
end