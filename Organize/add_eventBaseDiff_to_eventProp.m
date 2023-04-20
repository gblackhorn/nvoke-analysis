function [eventProp_new,varargout] = add_eventBaseDiff_to_eventProp(eventProp,stimRange,timeInfo,roiTrace,varargin)
	% Return a new eventProp including event baseDiff 

	% eventProp: a structure containing event properties for a single ROI
	% stimRange: a n x 2 array. n is the repeat times of a stim in a trial
	% timeInfo: time information for a single trial recording
	% roiTrace: trace data for a single roi. It has the same length as the timeInfo

	% Defaults
	eventTimeType = 'peak_time'; % peak_time/rise_time
	base_timeRange = 2; % default 2s. 
    stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stim_time_error', varargin{ii})
	        stim_time_error = varargin{ii+1};
        elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1};
	    end
	end	

	%% Content
	eventProp_new = eventProp;
	event_num = numel(eventProp_new);

	for n = 1:event_num
		eventCat = eventProp_new(n).peak_category;
		if strcmpi('spon', eventCat)
			baseDiff = [];
			baseDiff_stimWin = [];
			val_event = [];
			baseInfo = {};
		else
			eventTime = eventProp_new(n).(eventTimeType);
			stimWin= get_stimWin_for_event(eventTime,stimRange);
			stimStartTime = stimWin(:, 1);
			stimEndTime = stimWin(:, 2);
			[baseDiff,val_event,baseInfo, baseDiff_stimWin] = get_event_baseDiff(eventTime,stimStartTime,timeInfo,roiTrace,...
				'base_timeRange',base_timeRange, 'stimEndTime', stimEndTime);
		end
		eventProp_new(n).baseDiff = baseDiff;
		eventProp_new(n).baseDiff_stimWin = baseDiff_stimWin; % lowest baseDiff value during stimulation window
		eventProp_new(n).val_rise = val_event;
		eventProp_new(n).baseInfo = baseInfo;
	end
end