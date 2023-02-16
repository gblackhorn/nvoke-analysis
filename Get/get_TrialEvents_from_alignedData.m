function [events,varargout] = get_TrialEvents_from_alignedData(alignedData_trial,event_type,varargin)
	% Get the events, such as rise_time, peak_time, rise_loc, peak_loc from a single trial in alignedData var

	% events can be used by plot functions such as 'plot_TemporalData_Trace' to mark the events 

	% [events] = get_TrialEvents_from_alignedData(alignedData_trial,'rise_time')

	% Defaults
	pick = nan; 

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('pick', varargin{ii})
	        pick = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    % elseif strcmpi('norm_FluorData', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	    %     norm_FluorData = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    % elseif strcmpi('guiSave', varargin{ii})
        %     guiSave = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents

	fullEventProp = {alignedData_trial.traces.eventProp};

	if ~isnan(pick)
		fullEventProp = fullEventProp(pick);
	end

	events = cellfun(@(x) [x.(event_type)],fullEventProp,'UniformOutput',false);
end