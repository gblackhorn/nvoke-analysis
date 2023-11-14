function [syncPercArray,varargout] = syncRoiPerc(alignedDataRec,binSize,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi). Calculate the percentage of synchronous ROIs in every time bin

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% syncPercArray: vector. every entry is the percentage of synchronous ROIs in a time bin
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

	% Add the events from all ROIs
	sumBinary = sum(binaryMatrix,2);

	% get the total ROI number 
	roiNum = size(binaryMatrix,2);

	% calculate the percentage of synchronous ROIs at each time bin
	syncPercArray = sumBinary./roiNum;

	varargout{1} = recDateTime;
end