function [varargout] = getStimEventFollowEventROI(alignedData,stimEventCat,followEventCat,varargin)
	% Get the stimulation-related events and the spontaneous events after them in ROIs

	% alignedData: Data of a single recording. get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'

	% Defaults
	sortROI = false; % true/false. Sort ROIs according to the event number: high to low
	sortDirection = 'descend'; % ascend/decend
	eventTimeType = 'peak_time'; % rise_time/peak_time
	% debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('sortROI', varargin{ii})
	        sortROI = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    % elseif strcmpi('postStimDuration', varargin{ii})
	    %     postStimDuration = varargin{ii+1}; 
	    % elseif strcmpi('plot_raw_races', varargin{ii})
	    %     plot_raw_races = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('eventCat', varargin{ii})
	    %     eventCat = varargin{ii+1};
        % elseif strcmpi('fname', varargin{ii})
	    %     fname = varargin{ii+1};
	    end
	end

	% get the ROI number
	roiNum = numel(alignedData.traces);

	% Get the events' times and categories
	[event_riseTime] = get_TrialEvents_from_alignedData(alignedData_trial,'rise_time');
	[event_peakTime] = get_TrialEvents_from_alignedData(alignedData_trial,'peak_time');
	[event_eventCat] = get_TrialEvents_from_alignedData(alignedData_trial,'peak_category');


	% Calculate the numbers of events in each roi and sort the order of roi according to this
	% (descending)
	if sortROI
		eventNums = cellfun(@(x) numel(x),event_riseTime);
		[~,sortIDX] = sort(eventNums,sortDirection);
		rowNames = rowNames(sortIDX);
		% FluroData = FluroData(:,sortIDX);
		event_riseTime = event_riseTime(sortIDX);
		event_peakTime = event_peakTime(sortIDX);
        event_eventCat = event_eventCat(sortIDX);
		% event_eventCat = event_eventCat(sortIDX);
	else
		sortIDX = [1:roiNum];
	end


	% chose the event time
	if strcmpi(eventTimeType,'rise_time');
		eventTime = event_riseTime;
	else
		eventTime = event_peakTime;
	end


	% get the index of stimEvents and followEvent in all the ROIs by comparing events' category
	% to the 'stimEventCat' and the 'followEventCat'
	stimEventIDX = cellfun(@(x) find(strcmpi(x,stimEventCat)),event_eventCat,'UniformOutput',false);
	followEventCatIDX = cellfun(@(x) find(strcmpi(x,followEventCat)),event_eventCat,'UniformOutput',false); % the index of events categorized to 'followEventCat'
	followEventIDX = cellfun(@(x) x+1,eventsIDX,'UniformOutput',false); % the index of events after the stim-related events

	% get the stimEventTime for each roi
	StimEventsTime = cell(size(eventsIDX));
	followEventsTime = cell(size(eventsIDX));
	for 
		
	end
end