function [stimFollowEventsPair,varargout] = getStimEventFollowEventROI(alignedData,stimEventCat,followEventCat,varargin)
	% Get the stimulation-related events and the first following events after them in ROIs

	% alignedData: Data of a single recording. get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'

	% Defaults
	sortROI = false; % true/false. Sort ROIs according to the event number: high to low
	sortDirection = 'descend'; % ascend/decend
	eventTimeType = 'peak_time'; % rise_time/peak_time
	maxDiff = 5; % the max difference between the stim-related and the following events
	% debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('sortROI', varargin{ii})
	        sortROI = varargin{ii+1}; 
        elseif strcmpi('sortDirection', varargin{ii})
	        sortDirection = varargin{ii+1};
	    elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('maxDiff', varargin{ii})
	        maxDiff = varargin{ii+1}; 
        % elseif strcmpi('fname', varargin{ii})
	    %     fname = varargin{ii+1};
	    end
	end

	% get the ROI number
	roiNum = numel(alignedData.traces);
	roiNames = {alignedData.traces.roi};

	% Get the events' times and categories
	[event_riseTime] = get_TrialEvents_from_alignedData(alignedData,'rise_time');
	[event_peakTime] = get_TrialEvents_from_alignedData(alignedData,'peak_time');
	[event_eventCat] = get_TrialEvents_from_alignedData(alignedData,'peak_category');


	% Calculate the numbers of events in each roi and sort the order of roi according to this
	% (descending)
	if sortROI
		eventNums = cellfun(@(x) numel(x),event_riseTime);
		[~,sortIDX] = sort(eventNums,sortDirection);
		roiNames = roiNames(sortIDX);
		% FluroData = FluroData(:,sortIDX);
		event_riseTime = event_riseTime(sortIDX);
		event_peakTime = event_peakTime(sortIDX);
        event_eventCat = event_eventCat(sortIDX);
		% event_eventCat = event_eventCat(sortIDX);
	else
		sortIDX = [1:roiNum];
	end


	% chose the event time
	if strcmpi(eventTimeType,'peak_time');
		eventTime = event_peakTime;
	else
		eventTime = event_riseTime;
	end


	% get the index of stimEvents and followEvent in all the ROIs by comparing events' category
	% to the 'stimEventCat' and the 'followEventCat'
	stimEventIDX = cellfun(@(x) find(strcmpi(x,stimEventCat)),event_eventCat,'UniformOutput',false);
	followEventCatIDX = cellfun(@(x) find(strcmpi(x,followEventCat)),event_eventCat,'UniformOutput',false); % the index of events categorized to 'followEventCat'
	followEventIDX = cellfun(@(x) x+1,stimEventIDX,'UniformOutput',false); % the index of events after the stim-related events

	% create cells to store the stimEventTime and the followEventsTime for each roi
	StimEventsTime = cell(1,roiNum);
	followEventsTime = cell(1,roiNum);
	stimFollowDiffTime = cell(1,roiNum);
	stimFollowDiffTimeROI = cell(1,roiNum);

	% loop through ROIs and examine if there is a following event for a stim-related event
	for rn = 1:roiNum
		% get the time of stimulation-related events
		StimEventsTime{rn} = eventTime{rn}(stimEventIDX{rn});
		followEventsTime{rn} = NaN(size(StimEventsTime{rn}));
		stimFollowDiffTime{rn} = NaN(size(StimEventsTime{rn}));

		% if there are stimEvents
		% if there are events with 'followEventCat' in the ROI, get the following events time for each StimEventsTime 
		if ~isempty(stimEventIDX) && ~isempty(followEventCatIDX{rn})

			% check every candidate following event: does it exist? Does it apear in the window of 'maxDiff' after the stimEvent
			disEventIDX = [];
			for m = 1:numel(followEventIDX{rn})
				if ~isempty(find(followEventCatIDX{rn}==followEventIDX{rn}(m)))
					followEventsTime{rn}(m) = eventTime{rn}(followEventIDX{rn}(m));
					stimFollowDiffTime{rn}(m) = followEventsTime{rn}(m)-StimEventsTime{rn}(m);

					% check if the time difference between paired stimEvent and followEvent is <= maxDiff
					if followEventsTime{rn}(m)-StimEventsTime{rn}(m) > maxDiff
					 	disEventIDX = [disEventIDX m];
					end
				else
					disEventIDX = [disEventIDX m];
				end
			end

			% discard the pairs of stimEvent and followEvent do not meet the standard
			StimEventsTime{rn}(disEventIDX) = [];
			followEventsTime{rn}(disEventIDX) = [];
			stimFollowDiffTime{rn}(disEventIDX) = [];
			% stimFollowDiffTimeROI{rn}(disEventIDX) = [];

			% calculate the mean in each ROI
			stimFollowDiffTimeROI{rn} = mean(stimFollowDiffTime{rn});

		end
	end

	% store the data in a structure for output
	stimFollowEventsPair = struct('roiName',roiNames,...
		'stimEventsTime',StimEventsTime,...
		'followEventsTime',followEventsTime,...
		'stimFollowDiffTime',stimFollowDiffTime,...
		'stimFollowDiffTimeROI',stimFollowDiffTimeROI);

	varargout{1} = sortIDX;
end