function [traceMatrix,varargout] = recTrace(alignedDataRec,varargin)
	% Get ROIs' traces from a single recording as a alignedData form

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);

	% Example:
	%		

	% Defaults
	% dispCorr = false;
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     % if strcmpi('eventTimeType', varargin{ii}) 
	%     %     eventTimeType = varargin{ii+1}; 
	%     % elseif strcmpi('plotWhere', varargin{ii})
    %     %     plotWhere = varargin{ii+1};
	%     % elseif strcmpi('dispCorr', varargin{ii})
    %     %     dispCorr = varargin{ii+1};
	% end


	traceMatrix = [alignedDataRec.traces.fullTrace];

	roiNames = {alignedDataRec.traces.roi};



	% get the recording data and time from the trialName
	underScoreIDX = strfind(alignedDataRec.trialName,'_');
	recDateTime = alignedDataRec.trialName(1:(underScoreIDX(1)-1));

	varargout{1} = roiNames;
	varargout{2} = recDateTime;
end