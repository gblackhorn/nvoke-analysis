function [alignedData_allTrials,varargout] = get_event_trace_allTrials(allTrialsData,varargin)
% Collect the event traces from all trials in a [recdata_organized]. Return a struct
%   Utilize the func 'get_event_trace_trial' if the event_spec_table is used to pick detected events

	% Defaults
	event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
	traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
	event_data_group = 'peak_lowpass'; % options: 'peak_lowpass', 'peak_smooth', 'peak_decon'
										% keep this consistent with 'traceData_type'

	event_filter = 'none'; % options are: 'none', 'timeWin' (not setup yet), 'event_cat'
	event_align_point = 'rise'; % options: 'rise', 'peak'
	pre_event_time = 1; % unit: s. event trace starts at 1s before event onset
	post_event_time = 2; % unit: s. event trace ends at 2s after event onset
	stim_section = false; % true: use a specific section of stimulation. For example the last 1s
	ss_range = 2; % single number (last n second) or a 2-element array (start and end. 0s is stimulation onset)
	stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
	eventTimeType = 'peak_time'; % rise_time/peak_time. pick one of the for event time.
	rebound_duration = 1;
	scale_data = false; % only work if [event_type] is detected_events
	align_on_y = true; % subtract data with the values at the align points
	% win_range = []; 
	cat_keywords =[]; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
	mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
	debug_mode = false; % true/false


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('event_type', varargin{ii})
	        event_type = varargin{ii+1}; 
	    elseif strcmpi('traceData_type', varargin{ii})
	        traceData_type = varargin{ii+1}; 
	    elseif strcmpi('event_data_group', varargin{ii})
	        event_data_group = varargin{ii+1}; 
	    elseif strcmpi('event_filter', varargin{ii})
	        event_filter = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    % elseif strcmpi('win_range', varargin{ii})
	    %     win_range = varargin{ii+1}; % nx2 array. stim_range in the gpio info (4th column of recdata_organized) can be used for this
	    elseif strcmpi('cat_keywords', varargin{ii})
	        cat_keywords = varargin{ii+1}; % can be a cell array containing multiple keywords
	    elseif strcmpi('event_align_point', varargin{ii})
	        event_align_point = varargin{ii+1}; % 'rise' or 'peak'
	    elseif strcmpi('pre_event_time', varargin{ii})
	        pre_event_time = varargin{ii+1};
	    elseif strcmpi('post_event_time', varargin{ii})
	        post_event_time = varargin{ii+1};
	    elseif strcmpi('stim_section', varargin{ii}) % used for calcium level delta calculation. True: use specific seciton
	        stim_section = varargin{ii+1};
	    elseif strcmpi('ss_range', varargin{ii}) % used for calcium level delta calculation. True: use specific seciton
	        ss_range = varargin{ii+1};
	    elseif strcmpi('stim_time_error', varargin{ii})
	        stim_time_error = varargin{ii+1};
	    elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1};
	    elseif strcmpi('rebound_duration', varargin{ii})
	        rebound_duration = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    elseif strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
        elseif strcmpi('mod_pcn', varargin{ii})
        	mod_pcn = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
        	debug_mode = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	trial_num = size(allTrialsData, 1);
	data_cell = cell(1, trial_num);

	for n = 1:trial_num
		if debug_mode
			fprintf('trial %d: %s\n', n, allTrialsData{n, 1})
			if n == 5
				pause
			end
		end

		trialData = allTrialsData(n, :);
		[data_cell{n}] = get_event_trace_trial(trialData, 'event_type', event_type,...
		'traceData_type', traceData_type, 'event_data_group', event_data_group,...
		'event_filter', event_filter, 'event_align_point', event_align_point, 'cat_keywords', cat_keywords,...
		'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
		'stim_section',stim_section,'ss_range',ss_range,'stim_time_error',stim_time_error,...
		'eventTimeType',eventTimeType,'rebound_duration', rebound_duration, 'mod_pcn', mod_pcn,'debug_mode',debug_mode);
	end

	alignedData_allTrials = [data_cell{:}];
end
