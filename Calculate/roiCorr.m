function [corrMatrix,corrFlat,varargout] = roiCorr(alignedDataRec,binSize,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi), and calculate the activity correlation between all neuron pairs

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% corrMatrix: roi correlation paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,corrMatrix,'Colormap',jet);
	% corrFlat: Get the upper triangular part of corrMatrix and flatten it to a vector
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);

	% Example:
	%		

	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time
	% dispCorr = false;
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

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

	% get events' time from all the ROIs and create a binary matrix. Each column contains events
	% info of a single ROI. 1 if a time bin contains an event, 0 if there is no event in the bin
	[binaryMatrix,roiNames,recDateTime] = recEventBinaryMatrix(alignedDataRec,binSize,'eventTimeType',eventTimeType);

	% % get the recording data and time from the trialName
	% underScoreIDX = strfind(alignedDataRec.trialName,'_');
	% recDateTime = alignedDataRec.trialName(1:(underScoreIDX(1)-1));

	% % get the maxTime of recording
	% maxTime = alignedDataRec.fullTime(end)-alignedDataRec.fullTime(1);

	% % get the eventProps
	% eventProps = {alignedDataRec.traces.eventProp};

	% % get the roiNames
	% roiNames = {alignedDataRec.traces.roi};

	% % convert the events' time from all neurons to a binary matrix 
	% [binaryMatrix] = eventTime2binaryMatrix(eventProps,maxTime,binSize,...
	% 	'eventTimeType',eventTimeType,'roiNames',roiNames);

	% compute the correlation matrix
	corrMatrix = corr(binaryMatrix);

	% Flatten the upper triangular part (excluding the diagonal) for scatter plot
	% flattened correlation can be used to pair with flattened distances between ROI pairs
	% (using function 'roiDist')
	corrFlat = corrMatrix(triu(true(size(corrMatrix)),1));


	% Prepare the roiPairNames for 'corrFlat'
	% Calculate the number of neurons
	numNeurons = size(corrMatrix, 1);

	% Initialize a cell array to hold the neuron pair names
	roiPairNames = cell(length(corrFlat), 1);

	% Obtain the upper triangular indices
	[row, col] = find(triu(ones(numNeurons, numNeurons), 1));

	% Loop through each index to get neuron names
	for i = 1:length(row)
	    roiPairNames{i} = [roiNames{row(i)}, '-', roiNames{col(i)}];
	end


	varargout{1} = roiNames;
	varargout{2} = roiPairNames;
	varargout{3} = recDateTime;
end