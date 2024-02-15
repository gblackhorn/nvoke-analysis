function [corrAndDist,varargout] = roiCorrAndDistMultiRec(alignedData,binSize,varargin)
	% Calculate the roi cross correlation and roi distances for all recordings

	% alignedData: Including data from multiple recodings. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second

	% Defaults
	corrDataType = 'event'; % event/trace. Data used for calculation correlation
	eventTimeType = 'peak_time'; % rise_time/peak_time
	useStimRange = 'include'; % include/exclude/only. Include or exclude the data during stimulation range or only use it

	ThresholdCorrMat = true; % Use the percentile to threshold correlation data
	percentileThreshold = 75; % Threshold correlation matrix data. Keep the ones above the percentile

	visualizeData = false;
	corrThresh = 0.3; % correlation equal and below this threshhold will not be show in the graph and bundling plots  
	distScale = []; % pixels/um. used for calibrate the distance
	saveFig = false;
	guiSave = false;
	saveDir = [];
	dbMode = false; % debug mode

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('corrDataType', varargin{ii})
            corrDataType = varargin{ii+1};
	    elseif strcmpi('useStimRange', varargin{ii})
            useStimRange = varargin{ii+1};
	    elseif strcmpi('ThresholdCorrMat', varargin{ii})
            ThresholdCorrMat = varargin{ii+1};
	    elseif strcmpi('visualizeData', varargin{ii})
            visualizeData = varargin{ii+1};
	    elseif strcmpi('corrThresh', varargin{ii})
            corrThresh = varargin{ii+1}; % pixels/um. used for calibrate the distance
	    elseif strcmpi('distScale', varargin{ii})
            distScale = varargin{ii+1}; % pixels/um. used for calibrate the distance
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

	% create a stucture to store correlation and distance data from every recording
	recNum = numel(alignedData);
	corrAndDistFields = {'recName','roiNames','roiPairNames','binSize','corrMatrix','corrFlat','distMatrix','distFlat'};
	corrAndDist = empty_content_struct(corrAndDistFields,recNum);

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
			[corrMatrix,corrFlat,distMatrix,distFlat,roiNames,roiPairNames,recDateTime,fig,figName] = roiCorrAndDistSingleRec(alignedData(n),...
				binSize,'corrDataType',corrDataType,'useStimRange',useStimRange,...
				'ThresholdCorrMat',ThresholdCorrMat,'percentileThreshold',percentileThreshold,...
				'visualizeData',visualizeData,'corrThresh',corrThresh,'distScale',distScale);

			corrAndDist(n).recName = recDateTime;
			corrAndDist(n).roiNames = roiNames;
			corrAndDist(n).roiPairNames = roiPairNames;
			corrAndDist(n).binSize = binSize;
			corrAndDist(n).corrMatrix = corrMatrix;
			corrAndDist(n).corrFlat = corrFlat;
			corrAndDist(n).distMatrix = distMatrix;
			corrAndDist(n).distFlat = distFlat;

			if saveFig
				saveDir = savePlot(fig,'save_dir',saveDir,'guiSave',false,'fname',figName);
			end
		end
	end


	% combine the corrFlat and distFlat from all a recordings together
	corrFlatAllCell = {corrAndDist.corrFlat};
	distFlatAllCell = {corrAndDist.distFlat};

	% convert corrFlatAllCell and distFlatAllCell to vectors
	corrFlatAll = vertcat(corrFlatAllCell{:});
	distFlatAll = vertcat(distFlatAllCell{:});

	varargout{1} = corrFlatAll;
	varargout{2} = distFlatAll;

	% plot the relationship between activity correlation and roi distances using the combined data
	if visualizeData
		fCorrDistAllName = sprintf('corr-vs-distance all-data');
		fCorrDistAll = fig_canvas(1,'unit_width',0.3,'unit_height',0.4,'column_lim',1,'fig_name',fCorrDistAllName);
		scatterHandle = stylishScatter(distFlatAll, corrFlatAll,'plotWhere',gca,...
			'xlabelStr','Distance','ylabelStr','Correlation',...
			'titleStr',fCorrDistAllName);

		if saveFig
			savePlot(fCorrDistAll,'save_dir',saveDir,'guiSave',false,'fname',fCorrDistAllName);

			% save data in the same folder
		    save(fullfile(saveDir, 'corrAndDistData'), 'corrAndDist','corrFlatAll','distFlatAll');
		end
	end

	varargout{3} = saveDir;
end