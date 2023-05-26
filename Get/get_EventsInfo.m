function [event_info,varargout] = get_EventsInfo(eventsProps,event_type,varargin)
	% Get the event_info, such as rise_time, peak_time, rise_loc, peak_loc 

	% inputs:
		% eventsProps: a cell array. Each cell contains event properties from a single ROI
		% event_type: field names used to fetch specific event info. 'peak_time','peak_category','rise_time'

	% event_info can be used by plot functions such as 'plot_TemporalData_Trace' to mark the events 

	% [event_info] = get_TrialEvents_from_alignedData(alignedData_trial,'rise_time')

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


	if ~isnan(pick)
		eventsProps = eventsProps(pick);
	end

	% decide if the the eventsProps.(event_type) are numbers or characters
	firstContent = eventsProps{1}(1).(event_type);
	if isnumeric(firstContent)
		event_info = cellfun(@(x) [x.(event_type)],eventsProps,'UniformOutput',false);
	elseif ischar(firstContent)
		event_info = cellfun(@(x) {x.(event_type)},eventsProps,'UniformOutput',false);
	end
end