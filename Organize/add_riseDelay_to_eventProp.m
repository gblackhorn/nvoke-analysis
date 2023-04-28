function [eventProp_new,varargout] = add_riseDelay_to_eventProp(eventProp,stimRange,varargin)
	% Return a new eventProp including event baseDiff 

	% eventProp: a structure containing event properties for a single ROI
	% stimRange: a n x 2 array. n is the repeat times of a stim in a trial
	% timeInfo: time information for a single trial recording
	% roiTrace: trace data for a single roi. It has the same length as the timeInfo

	% Defaults
	errCali = 0; % calibrate the time if it was used to categorize events
	eventType = 'peak_time'; % use rise_time/peak_time for event time

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('errCali', varargin{ii})
	        errCali = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventType', varargin{ii})
	        eventType = varargin{ii+1};
	    end
	end	

	%% Content
	eventProp_new = eventProp;
	event_num = numel(eventProp_new);

	for n = 1:event_num
		eventCat = eventProp_new(n).peak_category;
		eventTime = eventProp_new(n).(eventType);
		eventTime_rise = eventProp_new(n).rise_time;
		eventTime_peak = eventProp_new(n).peak_time;
		if strcmpi('spon', eventCat) 
			rise_delay = [];
			peak_delay = [];
		else
			stimWin= get_stimWin_for_event(eventTime,stimRange);
			stimStartTime = stimWin(:, 1);
			stimEndTime = stimWin(:, 2);

			if strcmpi('rebound', eventCat) 
				ref = stimEndTime;
			else
				ref = stimStartTime;
			end

			rise_delay = eventTime_rise-ref;
			peak_delay = eventTime_peak-ref;
		end
		eventProp_new(n).rise_delay = rise_delay;
		eventProp_new(n).peak_delay = peak_delay;
	end
end