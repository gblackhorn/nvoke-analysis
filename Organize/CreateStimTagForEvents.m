function [tags,varargout] = CreateStimTagForEvents(StimRange,EventsTime,varargin)
	%Create tags, such as 'og&ap-5s'(optogenetics and airpuff for 5s), for calcium events

	% [tags] = CreateStimTagForEvents(StimRange,EventsTime,'EventCat',EventCat,'StimType','ap')
	%	- StimRange: a n*2 numeric array containing the starts and ends of stimulation. Unit: second
	%	- EventsTime: a numeric array containing event time point. Rise time is usually used for this
	%	- EventCat: optional input. A cell array containing the event categories. It has the same length as EventsTime
	%	- 'ap': use 'ap' as part of the tag. Example, if an event is stimulated by a 100ms airpuff, its tag will be ap-0.1s 

	% Defaults
	EventCat = {}; % Default event category is empty. 
	UseCat = false; % Only tag events in stimulation range when EventCat is empty
	StimType = 'stim'; % prefix of tags. For example, 'stim 1s'
	SkipTag_keyword = 'spon'; % default tag char. If EventCat element contains this char, tag the event with NoTag_char
	NoTag_char = '';
	debugMode = false;

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('EventCat', varargin{ii})
	        EventCat = varargin{ii+1}; % a cell string. event_cat and EventsTime have the same size
        elseif strcmpi('StimType', varargin{ii})
	        StimType = varargin{ii+1};
        elseif strcmpi('SkipTag_keyword', varargin{ii})
	        SponTag = varargin{ii+1};
        elseif strcmpi('NoTag_char', varargin{ii})
	        NoTag_char = varargin{ii+1};
	    end
	end	

	%% Content
	if ~isempty(EventCat)
		UseCat = true;
	end
	% if isa(StimRange_or_EventCat,'numeric') % if StimRange_or_EventCat is a double array
	% 	UseCat = false; % Do not use event category to create tags
	% 	StimRange = StimRange_or_EventCat;
	% elseif isa(StimRange_or_EventCat,'cell') % if StimRange_or_EventCat is a cell array (containing event category char)
	% 	UseCat = true; % Use event category to creat tags
	% 	EventCat = StimRange_or_EventCat;
	% else 
	% 	error('Error using CreateStimTagForEvents\n first input must be a 2-col double or a char cell array')
	% end

	% Create tags cell and fill it with 'spon'
	EventNum = numel(EventsTime);
	tags = cell(1,EventNum); 
	[tags{:}] = deal(NoTag_char);

	if ~isempty(StimRange)
		[StimDuration] = CalculateStimDuration(StimRange);
		StimNum = numel(StimDuration.array);

		if UseCat
			RangeEnds = StimDuration.range(:,2);
			for en = 1:EventNum
				if debugMode
	            	fprintf('eventNum: %g/%g\n',en,EventNum);
	            end
				if ~contains(EventCat{en},SkipTag_keyword,'IgnoreCase',true)
					[closestValue,ClosestLoc] = find_closest_in_array(EventsTime(en),RangeEnds(:));
					TagChar = sprintf('%s-%.2gs',StimType,StimDuration.array(ClosestLoc));
					tags{en} = TagChar;
				end
			end
		else
			for sn = 1:StimNum
				OneRange = StimDuration.range(sn,:);
				TagLoc = find(EventsTime>=OneRange(1) & EventsTime<OneRange(2));
				TagChar = sprintf('%s-%.2gs',StimType,StimDuration.array(sn));
				[tags{TagLoc}] = deal(TagChar);
			end
		end
	end
end

