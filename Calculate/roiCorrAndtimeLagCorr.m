function [timeLagCorrData,varargout] = roiCorrAndtimeLagCorr(alignedData,binSize,binLag,varargin)
	% Calculate the cross correlation and the time-lagged correlation between each pair of ROIs

	% alignedData: Including data from multiple recodings. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% binLag: a number or a vector. Plotting is designed to show 3 different binLag at maximum.
	% 	Parameters for 'fig_canvas' should be modified if more binLag will be used

	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time
	roiNameExcessiveStr = 'neuron'; % remove this string from the ROI name to shorten it
	visualizeData = false;
	figColNum = 4; % one figure colum contains one heatmap paired with a vertial and a horizontal histogram
	tileMultiplier = 4; % Multiple the number of tiles with this parametter for Managing the size of plots
	vertHistHeight = 1; % width of the the vertical histogram
	horHistWidth = 1; % height of the horizontal histogram

	unit_width = 0.2; % normalized to display
	unit_height = 0.4; % normalized to display

	heatFontsize = 8;
	histFontSize = 7;

	saveFig = false;
	guiSave = false;
	saveDir = [];
	listRec = true; % if true, list recordings
	dbMode = false; % debug mode

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    % elseif strcmpi('binLag', varargin{ii})
        %     binLag = varargin{ii+1};
	    elseif strcmpi('visualizeData', varargin{ii})
            visualizeData = varargin{ii+1};
	    elseif strcmpi('saveFig', varargin{ii})
            saveFig = varargin{ii+1};
	    elseif strcmpi('guiSave', varargin{ii})
            guiSave = varargin{ii+1};
	    elseif strcmpi('saveDir', varargin{ii})
            saveDir = varargin{ii+1};
	    elseif strcmpi('listRec', varargin{ii})
            listRec = varargin{ii+1};
	    elseif strcmpi('dbMode', varargin{ii})
            dbMode = varargin{ii+1};
	    end
	end

	% Create a stucture to store correlation and distance data from every recording
	recNum = numel(alignedData);
	timeLagCorrFields = {'recName','roiNames','roiPairNames','binSize','binLag',...
		'corrMatrix','corrFlat','corrMatrixTimeLag'};
	timeLagCorrData = empty_content_struct(timeLagCorrFields,recNum);

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
		if dbMode || listRec
			fprintf('recording (%d/%d): %s\n',n,recNum,alignedData(n).trialName);
			if dbMode && n == 13
				fprintf('pause for debugging\n')
				pause
			end
		end

		if ~isempty(alignedData(n).traces)
			close all
			% Get events' time from all the ROIs and create a binary matrix. Each column contains events
			% info of a single ROI. 1 if a time bin contains an event, 0 if there is no event in the bin
			% Extract recording and roi names as well
			[binaryMatrix,timePointsNum,roiNames,recDateTime] = recEventBinaryMatrix(alignedData(n),binSize,'eventTimeType',eventTimeType);

			% Calculate the activity cross correlation using event time
			[corrMatrix,corrFlat,roiPairNames] = roiCorr(binaryMatrix,roiNames);

			% Calculate the time-lagged cross-correlation between each pair of neurons
			corrMatrixTimeLagCells = cell(1,binLagNum);
			for m = 1:binLagNum
				corrMatrixTimeLagCells{m} = timeLagCorr(binaryMatrix,binLag(m));
				% timeLagCorr(binaryMatrix,binLag(m));
			end

			timeLagCorrData(n).recName = recDateTime;
			timeLagCorrData(n).roiNames = roiNames;
			timeLagCorrData(n).roiPairNames = roiPairNames;
			timeLagCorrData(n).binSize = binSize;
			timeLagCorrData(n).binLag = binLag;
			timeLagCorrData(n).corrMatrix = corrMatrix;
			timeLagCorrData(n).corrFlat = corrFlat;
			timeLagCorrData(n).corrMatrixTimeLag = corrMatrixTimeLagCells;


			if visualizeData
				% Create a figure name
				fName = sprintf('roiTimeLagCorrFig rec-%s binSize-%gs ',recDateTime,binSize);

				% Create a fig canvas and organize tiles
				heatmapNum = (1+binLagNum)*2; % cross correlation withou time lag will always be plotted
				figRowNum = ceil((1+binLagNum)/2);
				heatmapHeight = (tileMultiplier-vertHistHeight);
				heatmapWidth = (tileMultiplier-horHistWidth);
				f = fig_canvas(heatmapNum,'unit_width',unit_width,'unit_height',unit_height,'column_lim',figColNum,'fig_name',fName);
				fTile = tiledlayout(f,figRowNum*tileMultiplier,figColNum*tileMultiplier); % create tiles 


				% remove the 'neuron' part from the roiName for clearer display in the plots. For example,
				% change neuron5 to 5
				roiNamesShort = cell(size(roiNames));
				for i = 1:numel(roiNames)
					roiNamesShort{i} = strrep(roiNames{i},roiNameExcessiveStr,'');
				end


				% Figure 1: ROI correlation
				figIDX = 1; 
				[heatmapIDX,horHistIDX,vertHistIDX] = getPlotTileIDX(figIDX,figColNum,tileMultiplier,vertHistHeight,horHistWidth);

				% display the roi cross correlation using heatmap
				nexttile(fTile,heatmapIDX,[heatmapHeight heatmapWidth]);
				heatmapHandle = heatMapRoiCorr(corrMatrix,roiNamesShort,'recName',recDateTime,'plotWhere',gca,...
					'excludeSelfCorrColor',true,'FontSize',heatFontsize);
				title('Cross correlation')

				% add histogram next to the heatmap above showing the timePoint number in each ROI
				% horizontal histo on the left side of the heatmap
				nexttile(fTile,horHistIDX,[heatmapHeight horHistWidth]); 
				stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','horizontal',...
					'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)],'FontSize',histFontSize);
				% vertical histo below the the heatmap
				nexttile(fTile,vertHistIDX,[vertHistHeight heatmapWidth]); 
				stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','vertical',...
					'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)],'FontSize',histFontSize);


				if numel(corrMatrix)>1
					% Figure 2: ROI correlation hierarchical clustered
					figIDX = 2; 
					[heatmapIDX,horHistIDX,vertHistIDX] = getPlotTileIDX(figIDX,figColNum,tileMultiplier,vertHistHeight,horHistWidth);

					% Display the hierarchical clustered cross correlation using heatmap
					nexttile(fTile,heatmapIDX,[heatmapHeight heatmapWidth]);
					[corrMatrixHC,outperm] = hierachicalCluster(corrMatrix);
					roiNamesHC = roiNamesShort(outperm);
					timePointsNumHC = timePointsNum(outperm);
					heatmapHCHandle = heatMapRoiCorr(corrMatrixHC,roiNamesHC,'recName',recDateTime,'plotWhere',gca,...
						'excludeSelfCorrColor',true,'FontSize',heatFontsize);
					title('Hierachical clustered cross correlation')

					% add histogram next to the heatmap above showing the timePoint number in each ROI
					% horizontal histo on the left side of the heatmap
					nexttile(fTile,horHistIDX,[heatmapHeight horHistWidth]); 
					stylishHistogram(timePointsNumHC,'plotWhere',gca,'Orientation','horizontal',...
						'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)],'FontSize',histFontSize);
					% vertical histo below the the heatmap
					nexttile(fTile,vertHistIDX,[vertHistHeight heatmapWidth]); 
					stylishHistogram(timePointsNumHC,'plotWhere',gca,'Orientation','vertical',...
						'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)],'FontSize',histFontSize);



					% display the cross correlation with time lag using heatmap
					for m = 1:binLagNum
						% Figure (m+2): Time-lag cross-correlation 
						figIDX = 2*m+1; % (m-1)*2+1+2
						[heatmapIDX,horHistIDX,vertHistIDX] = getPlotTileIDX(figIDX,figColNum,tileMultiplier,vertHistHeight,horHistWidth);
						% timeLagCorrMatrix = timeLagCorr(binaryMatrix,binLag(m));

						% Display the roi time-lag cross-correlation using heatmap
						nexttile(fTile,heatmapIDX,[heatmapHeight heatmapWidth]); 
						heatmapHandle = heatMapRoiCorr(corrMatrixTimeLagCells{m},roiNamesShort,'recName',recDateTime,'plotWhere',gca,...
							'excludeSelfCorrColor',true,'FontSize',heatFontsize);
						title(sprintf('Time-lag (%d-bin) cross-corr',m));

						% add histogram next to the heatmap above showing the timePoint number in each ROI
						% horizontal histo on the left side of the heatmap
						nexttile(fTile,horHistIDX,[heatmapHeight horHistWidth]); 
						stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','horizontal',...
							'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)],'FontSize',histFontSize);
						% vertical histo below the the heatmap
						nexttile(fTile,vertHistIDX,[vertHistHeight heatmapWidth]); 
						stylishHistogram(timePointsNum,'plotWhere',gca,'Orientation','vertical',...
							'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)],'FontSize',histFontSize);

						% Figure 2: ROI correlation hierarchical clustered
						figIDX = 2*m+2; 
						[heatmapIDX,horHistIDX,vertHistIDX] = getPlotTileIDX(figIDX,figColNum,tileMultiplier,vertHistHeight,horHistWidth);

						% Display the hierarchical clustered cross correlation using heatmap
						nexttile(fTile,heatmapIDX,[heatmapHeight heatmapWidth]);
						[timeLagCorrMatrixHC,outperm] = hierachicalCluster(corrMatrixTimeLagCells{m});
						TLroiNamesHC = roiNamesShort(outperm);
						TLtimePointsNumHC = timePointsNum(outperm);
						TLheatmapHCHandle = heatMapRoiCorr(timeLagCorrMatrixHC,TLroiNamesHC,'recName',recDateTime,'plotWhere',gca,...
							'excludeSelfCorrColor',true,'FontSize',heatFontsize);
						% title('Hierachical clustered cross correlation')
						title(sprintf('Time-lag (%d-bin) Hierachical clustered',m));

						% add histogram next to the heatmap above showing the timePoint number in each ROI
						% horizontal histo on the left side of the heatmap
						nexttile(fTile,horHistIDX,[heatmapHeight horHistWidth]); 
						stylishHistogram(TLtimePointsNumHC,'plotWhere',gca,'Orientation','horizontal',...
							'titleStr','','xlabelStr','Event Num','ylabelStr','','XTick',[0 max(timePointsNum)],'FontSize',histFontSize);
						% vertical histo below the the heatmap
						nexttile(fTile,vertHistIDX,[vertHistHeight heatmapWidth]); 
						stylishHistogram(TLtimePointsNumHC,'plotWhere',gca,'Orientation','vertical',...
							'titleStr','','xlabelStr','','ylabelStr','Event Num','YTick',[0 max(timePointsNum)],'FontSize',histFontSize);
					end
				end
				sgtitle(fName,'FontSize',14,'FontWeight','Bold')

				% t.TileSpacing = 'compact'; % Reduces space between tiles
				% t.Padding = 'compact'; % Reduces padding around the outer edges
			end

			if saveFig
				saveDir = savePlot(f,'save_dir',saveDir,'guiSave',false,'fname',fName);
			end
		end
	end

	varargout{1} = saveDir;
end


% function [figRow, figCol] = getFigloc(figIDX,figColNum)
% 	% Return the location of a set of plots (heatmap+vertialHist+horizontalHist)

% 	figRow = ceil(figIDX/figColNum); 
% 	figCol = figIDX-(figColNum*(figRow-1));
% end


function [heatmapIDX,horHistIDX,vertHistIDX] = getPlotTileIDX(figIDX,figColNum,tileMultiplier,vertHistHeight,horHistWidth)
	% Return the the start tile locations of heatmap, vertical histogram, and horizontal histogram

	% Get the location of a set of plots (heatmap+vertialHist+horizontalHist)
	figRow = ceil(figIDX/figColNum); 
	figCol = figIDX-(figColNum*(figRow-1));

	% Calculate the height and width of heatmap
	heatmapHeight = tileMultiplier-vertHistHeight;
	heatmapWidth = tileMultiplier-horHistWidth;

	% Get the start tile of the vertial histogram
	horHistIDX = (figRow-1)*tileMultiplier*figColNum*tileMultiplier+(figCol-1)*tileMultiplier+1;

	% Get the start tile of the heatmap
	heatmapIDX = horHistIDX+horHistWidth;

	% Get the start tile of the horizontal histogram
	vertHistIDX = horHistIDX+heatmapHeight*figColNum*tileMultiplier+horHistWidth;
end