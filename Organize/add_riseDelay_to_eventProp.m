function [eventProp_new,varargout] = add_riseDelay_to_eventProp(eventProp,stimRange,varargin)
	% Return a new eventProp including event jitter (delay of the onset to the stimulation)

	% eventProp: a structure containing event properties for a single ROI
	% stimRange: a n x 2 array. n is the repeat times of a stim in a trial
	% stimEventCatPairs: a structure var created by the function 'setStimEventCatPairs'
	% 	stimEventCatPairs = setStimEventCatPairs(alignedData.stimInfo.StimDuration);

	% Defaults
	errCali = 0; % Add calibration time to the beginning and the end of the stimRange
	eventType = 'peak_time'; % use rise_time/peak_time for event time
	stimEventCatPairs = '';

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('errCali', varargin{ii})
	        errCali = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventType', varargin{ii})
	        eventType = varargin{ii+1};
        elseif strcmpi('stimEventCatPairs', varargin{ii})
	        stimEventCatPairs = varargin{ii+1};
	    end
	end	

	%% Content
	eventProp_new = eventProp;
	event_num = numel(eventProp_new);

	for n = 1:event_num
		eventCat = eventProp_new(n).peak_category;
		eventTime = eventProp_new(n).peak_time;
		% eventTime = eventProp_new(n).(eventType);
		eventTime_rise = eventProp_new(n).rise_time;
		eventTime_peak = eventProp_new(n).peak_time;
		if strcmpi('spon', eventCat) 
			rise_delay = [];
			peak_delay = [];
		else
			% if input 'stimEventCatPairs' is not empty
			if ~isempty(stimEventCatPairs)
				% get the index of eventCat in stimEventCatPairs
				idx = find(strcmpi(eventCat,{stimEventCatPairs.eventName}));

				% overwrite the input 'stimRange' with the stimRange info from stimEventCatPairs
				if ~isempty(stimEventCatPairs(idx).stimRanges)
					stimRange = stimEventCatPairs(idx).stimRanges;
				end
			end

			% Expand the stimRange by adding the errCali to the beginning and the end of it
			stimRange(:,1) = stimRange(:,1)-errCali;
			stimRange(:,2) = stimRange(:,2)+errCali;

			% Get the 
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