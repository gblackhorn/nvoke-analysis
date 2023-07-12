function [sponEventsInt,varargout] = getSponEventsInt(alignedData,varargin)
	% Get the the intervals between spontaneous events in all the ROIs in a recording

	% alignedData: Data of a single recording. get this using the function 'get_event_trace_allTrials'

	% Defaults
	followEventCat = 'spon';
	eventTimeType = 'peak_time'; % rise_time/peak_time
	maxDiff = 5; % the max difference between the stim-related and the following events

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('followEventCat', varargin{ii})
	        followEventCat = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1}; 
	    elseif strcmpi('maxDiff', varargin{ii})
	        maxDiff = varargin{ii+1}; 
	    end
	end

	% get the full time
	timeData = alignedData.fullTime;

	% get the ROI number
	roiNum = numel(alignedData.traces);
	roiNames = {alignedData.traces.roi};


	% get the time windows without stimulation: stimOff window
	stimRanges = alignedData.stimInfo.UnifiedStimDuration.range; % get the stim ranges from the 'unified stimulation'
	offStimWinNum = size(stimRanges,1)+1;
	offStimWin = NaN(offStimWinNum,2);
	for sn = 1:offStimWinNum % loop through stimulation repeats
		if sn == 1 % get the pre-stimulation time before the 1st stimulation
			offStimWin(sn,1) = 0;
			offStimWin(sn,2) = stimRanges(sn,1);
		elseif sn > 1 && sn < size(stimRanges,1) % get the interval part between stimulations
			offStimWin(sn,1) = stimRanges(sn-1,2);
			offStimWin(sn,2) = stimRanges(sn,1);
		else % get the time after the last stimulation
			offStimWin(sn,1) = stimRanges(sn-1,2);
			offStimWin(sn,2) = timeData(end);
		end
	end


	% Get the events' times and categories
	[event_riseTime] = get_TrialEvents_from_alignedData(alignedData,'rise_time');
	[event_peakTime] = get_TrialEvents_from_alignedData(alignedData,'peak_time');
	[event_eventCat] = get_TrialEvents_from_alignedData(alignedData,'peak_category');

	% the index of events categorized to 'followEventCat'
	sponCatIDX = cellfun(@(x) find(strcmpi(x,followEventCat)),event_eventCat,'UniformOutput',false); 



	% chose the event time
	if strcmpi(eventTimeType,'peak_time');
		eventTime = event_peakTime;
	else
		eventTime = event_riseTime;
	end


	% find the events with the category 'followEventCat' in every stimOff window for every ROI
	sponEventsTime = cell(1,roiNum);
	sponEventsTimeInt = cell(1,roiNum);
	sponEventsTimeIntMean = NaN(1,roiNum);
	for rn = 1:roiNum
		% get the spon-events in the cell
		sponCatEventsTime = eventTime{rn}(sponCatIDX{rn});

		% create empty cell to store events in each off-stim window
		sponEventsTime{rn} = cell(1,offStimWinNum);
		sponEventsTimeInt{rn} = cell(1,offStimWinNum); % This is for storing the interval of spon-events in each off-stim window

		% loop through off-stim windows and collect spontaneous events
		for sn = 1:offStimWinNum
			% find the events in a off-stim window
			eventsIDX = find(sponCatEventsTime>=offStimWin(sn,1) & sponCatEventsTime<offStimWin(sn,2));
			if numel(eventsIDX>1)
				sponEventsTime{rn}{sn} = sponCatEventsTime(eventsIDX);
				sponDiff = diff(sponEventsTime{rn}{sn});
				overMaxIDX = find(sponDiff>maxDiff);
				sponDiff(overMaxIDX) = [];
				sponEventsTimeInt{rn}{sn} = sponDiff;
				% sponEventsTimeInt{rn}{sn} = diff(sponEventsTime{rn}{sn});
			end
		end

		% combine sponEventsTimeInt from all off-stim window in a ROI
		sponEventsTimeIntROI = horzcat(sponEventsTimeInt{rn}{:});

		% calculate the events' interval in every stimOff window
		if ~isempty(sponEventsTimeIntROI)
			sponEventsTimeIntMean(rn) = mean(sponEventsTimeIntROI);
		end
	end


	% store the data in a structure for output
	sponEventsInt = struct('roiName',roiNames,...
		'sponEventsTime',sponEventsTime,...
		'sponEventsTimeInt',sponEventsTimeInt,...
		'sponEventsTimeIntMean',num2cell(sponEventsTimeIntMean));


	varargout{1} = offStimWin; % time ranges without stimulation
	varargout{2} = offStimWinNum; % number of 'offStimWin'
end