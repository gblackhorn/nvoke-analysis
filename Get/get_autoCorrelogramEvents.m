function [ACG_Events,varargout] = get_autoCorrelogramEvents(eventSpecTable,varargin)
	%Get the time of events around center events (auto-correlogram events)
	% 

	% Example:
	%	[ACG_Events,cEventNum] = get_autoCorrelogramEvents(eventSpecTable,...
	%		'win_range',win_range,'cat_keywords',{'spon'});

	%	[ACG_Events,cEventNum] = get_autoCorrelogramEvents(eventSpecTable,...
	%		'cat_keywords',{'rebound'});

	%	[ACG_Events,cEventNum] = get_autoCorrelogramEvents(eventSpecTable,...
	%		'cat_keywords',{'rebound'},'preEventDuration',5,'postEventDuration',5);

	
	% Defaults
	preEventDuration = 3; % unit: s. find other events in this duration before the event
	postEventDuration = 3; % unit: s. find other events in this duration after the event

	win_range = []; % input a nx2 array using varargin to replace this
	cat_keywords = {}; % input one or more strings in a cell array to replace this
	timeType = 'rise_time'; % 'rise'/'peak_time'

	remove_centerEvents = false; % true/false. Remove the center events

	% Optionals inputs. Use these using get_eventsCount_autoCorrelogram(_,'varargin_name',varargin_value)
	for ii = 1:2:(nargin-1)
		if strcmpi('win_range', varargin{ii})
		    win_range = varargin{ii+1}; % nx2 array. stim_range in the gpio info (4th column of recdata_organized) can be used for this
		elseif strcmpi('cat_keywords', varargin{ii}) 
		    filters = varargin{ii+1}; % can be a cell array containing multiple keywords
	    elseif strcmpi('timeType', varargin{ii})
            timeType = varargin{ii+1};
	    elseif strcmpi('remove_centerEvents', varargin{ii})
            remove_centerEvents = varargin{ii+1};
	    elseif strcmpi('preEventDuration', varargin{ii})
            preEventDuration = varargin{ii+1};
	    elseif strcmpi('postEventDuration', varargin{ii})
            postEventDuration = varargin{ii+1};
	    end
	end

	% Get the events time
	eventsTime = [eventSpecTable.(timeType)]; % size: 1*n
	ceventSpecTable = eventSpecTable;



	% Filter events with win_range (if it is not empty)
	if ~isempty(win_range)
		win_range(:,1) = win_range(:,1)+preEventDuration; % avoid looking for center-event in the pre-duration 
		win_range(:,2) = win_range(:,1)-postEventDuration; % avoid looking for center-event in the post-duration

		[events_info] = get_events_info(eventsTime,win_range,eventSpecTable);
		cEventsTime = events_info.events_time;
		cEventsIDX = events_info.idx_in_peak_table;
		ceventSpecTable = eventSpecTable(cEventsIDX);
	end



	% Filter events with cat_keywords (if it is not empty)
	if ~isempty(cat_keywords)
		kw_num = numel(cat_keywords); % number of keywords
		cats = {ceventSpecTable.peak_category};
		catPos_idx = [];
		for i = 1:kw_num
			spell = cat_keywords{i};
			catPos_cell = cellfun(@(x) strcmpi(x, spell), cats, 'UniformOutput', false);
			catPos_idx = [catPos_idx, find([catPos_cell{:}]==1)]; 
		end
		cEventsTime = cEventsTime(catPos_idx);
		cEventsIDX = catPos_idx;
	end



	% Loop through every event passed the filters and find other events in its pre- and
	% post-EventDuration. Reset the time, the center event time is zero. Events around a single
	% center event are stored in a cell
	cEventNum = numel(cEventsTime);
	ACG_Events = cell(1,cEventNum);
	for n = 1:cEventNum
		% set a window from which to look for the around-events
		preTime = cEventsTime(n)-preEventDuration;
		postTime = cEventsTime(n)+postEventDuration;

		% Look for around events
		aroundEventsTimeIDX = find(eventsTime>=preTime & eventsTime<=postTime);
		aroundEventsTime = eventsTime(aroundEventsTimeIDX);
		aroundEventsTime = aroundEventsTime-cEventsTime(n); % use center-event time as zero

		if remove_centerEvents
			cEventPos = find(aroundEventsTime==0);
			aroundEventsTime(cEventPos) = [];
		end
		ACG_Events{n} = aroundEventsTime;
	end

	% % Find empty cells in ACG_Events: no around events
	% emptyCells = find(cellfun(@isempty, ACG_Events));

	varargout{1} = cEventNum; % number of center events
end