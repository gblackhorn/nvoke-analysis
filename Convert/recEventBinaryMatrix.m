function [binaryMatrix,varargout] = recEventBinaryMatrix(alignedDataRec,binSize,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi)

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
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

	% get the recording data and time from the trialName
	underScoreIDX = strfind(alignedDataRec.trialName,'_');
	recDateTime = alignedDataRec.trialName(1:(underScoreIDX(1)-1));

	% get the maxTime of recording
	maxTime = alignedDataRec.fullTime(end)-alignedDataRec.fullTime(1);

	% get the eventProps
	eventProps = {alignedDataRec.traces.eventProp};

	% get the roiNames
	roiNames = {alignedDataRec.traces.roi};

	% convert the events' time from all neurons to a binary matrix 
	[binaryMatrix] = eventTime2binaryMatrix(eventProps,maxTime,binSize,...
		'eventTimeType',eventTimeType,'roiNames',roiNames);

	varargout{1} = roiNames;
	varargout{2} = recDateTime;
end