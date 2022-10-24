function [tags,varargout] = CreateStimTagForEvents(StimRange,EventsTime,varargin)
	%Tag calcium events with stimulation durations, such as 'ap 0.1' (airpuff 0.1s)

	% 

	% Defaults
	EventCat = {}; % Default event category is empty. 
	UseCat = false; % Only tag events in stimulation range when EventCat is empty
	StimType = 'stim'; % prefix of tags. For example, 'stim 1s'
	SponTag = 'spon'; % default tag char. Also, use this to find events not gonna be tagged.

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('EventCat', varargin{ii})
	        EventCat = varargin{ii+1}; % a cell string. event_cat and EventsTime have the same size
        elseif strcmpi('StimType', varargin{ii})
	        StimType = varargin{ii+1};
        elseif strcmpi('SponTag', varargin{ii})
	        SponTag = varargin{ii+1};
        % elseif strcmpi('in_calLength', varargin{ii})
	       %  in_calLength = varargin{ii+1};
	    end
	end	

	%% Content
	if ~isempty(EventCat)
		UseCat = true;
	end

	% Create tags cell and fill it with 'spon'
	EventNum = numel(EventsTime)
	tags = cell(1,EventNum); 
	[tags{:}] = deal(SponTag);

	[StimDuration] = CalculateStimDuration(StimRange);
	StimNum = numel(StimDuration.array);

	if UseCat
		RangeEnds = StimDuration.range(:,2);
		for en = 1:EventNum
			if ~contains(EventCat{en},SponTag)
				[closestValue,ClosestLoc] = find_closest_in_array(EventsTime(en),RangeEnds(:));
				TagChar = sprintf('%s %d',StimType,StimDuration.array(ClosestLoc));
				tags{en} = TagChar;
			end
		end


	else
		for sn = 1:StimNum
			OneRange = StimDuration.range(sn,:);
			TagLoc = find(EventsTime>=OneRange(1) & EventsTime<OneRange(2));
			TagChar = sprintf('%s %d',StimType,StimDuration.array(sn));
			[tags{TagLoc}] = deal(TagChar);
		end
	end
end

