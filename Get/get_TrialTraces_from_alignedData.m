function [timeData,FluroData,varargout] = get_TrialTraces_from_alignedData(alignedData_trial,varargin)
	% Get timeData and Fluorescence value data from alignedData variable

	% timeData and FluroData can be used by plot functions such as 'plot_TemporalData_Trace' 

	% Example:
	%	[timeData,FluroData] = get_TrialTraces_from_alignedData(alignedData_trial,'pick',[1 3 5 7],'norm_FluorData',true); 
	%		get the 1st, 3rd, 5th and 7th roi traces from alignedData_trial and normalize them with their
	% 		max values

	% Defaults
	pick = nan; 
	norm_FluorData = false; % true/false. whether to normalize the FluroData

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('pick', varargin{ii})
	        pick = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('norm_FluorData', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        norm_FluorData = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    % elseif strcmpi('guiSave', varargin{ii})
        %     guiSave = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	timeData = alignedData_trial.fullTime;

	fullTraceCell = {alignedData_trial.traces.fullTrace};
	fullTraceCellDecon = {alignedData_trial.traces.fullTraceDecon};

	if ~isnan(pick)
		fullTraceCell = fullTraceCell(pick);
		fullTraceCellDecon = fullTraceCellDecon(pick);
	end

	if norm_FluorData
		fullTraceCell = cellfun(@(x) x./max(x),fullTraceCell,'UniformOutput',false); % normalize the trace with max value
		fullTraceCellDecon = cellfun(@(x) x./max(x),fullTraceCellDecon,'UniformOutput',false); % normalize the trace with max value
	end

	FluroData = [fullTraceCell{:}];
	fullTraceCell = fullTraceCell';

	varargout{1} = [fullTraceCellDecon{:}];
end