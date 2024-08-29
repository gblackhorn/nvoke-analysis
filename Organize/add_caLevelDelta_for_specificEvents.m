function [ROIeventProp_new,varargout] = add_caLevelDelta_for_specificEvents(ROIeventProp,eventCat,stimTime,caLevelData,varargin)
	% This function is used to get the calcium level delta (lowest point/largest value) during
	% stimulations for a specific type of events, such as 'rebound'

	% Note: ROIeventProp is a structure var. Fields 'rise_time' and 'peak_category' are used in this
	% function. eventCat is a character var (such as 'rebound'). StimTime is a vector (the ends of stimulation for
	% rebound events). caLevelData is an double vector with the same length as the stimTime.

	% Example:


	% Defaults


	
	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'ROIeventProp', @isstruct);
	addRequired(p, 'eventCat', @ischar);
	addRequired(p, 'stimTime', @isnumeric);
	addRequired(p, 'caLevelData', @isnumeric);

	% Add optional parameters to the input p
	addParameter(p, 'newFieldName', 'caLevelDelta', @ischar);
	addParameter(p, 'denomVal', [], @isnumeric); % highpassSTD of the ROI trace, or spon event amplitude

	% Parse inputs
	parse(p, ROIeventProp, eventCat, stimTime, caLevelData, varargin{:});

	% Retrieve parsed values
	ROIeventProp = p.Results.ROIeventProp;
	eventCat = p.Results.eventCat;
	stimTime = p.Results.stimTime;
	caLevelData = p.Results.caLevelData;
	newFieldName = p.Results.newFieldName;
	denomVal = p.Results.denomVal;


	

	% Create 2 NaN arrays having the same length as the events. 
	% One for largest calcium level delta, and another one for decay constant (tau) during stimulations
	ROIeventProp_new = ROIeventProp;
	
	if ~isfield(ROIeventProp_new,newFieldName)
		defaultValue = {[]}; % create a cell array with the default value for the new field
		[ROIeventProp_new(:).(newFieldName)] = deal(defaultValue{:}); % use deal to assign the default value to each structure
	end

	if ~isempty(denomVal) 
		% Calculate the denomVal normalized caLevelData
		caLevelDataHpStdNorm = caLevelData./denomVal;

		normValFieldName = sprintf('%sNorm', newFieldName);
		if ~isfield(ROIeventProp_new, normValFieldName)
			defaultValue = {[]}; % create a cell array with the default value for the new field
			[ROIeventProp_new(:).(normValFieldName)] = deal(defaultValue{:}); % use deal to assign the default value to each structure
		end
	end



	% Find the the idx specific type of events, such as the 'rebound' ones
	tf_idx_events = strcmpi({ROIeventProp_new.peak_category},eventCat);
	idx_events = find(tf_idx_events);



	% Find the closest stimulation (1st, 2nd, 3rd....?) for each screened events in the last step
	[~,idxStim] = find_closest_in_array([ROIeventProp_new(idx_events).rise_time],stimTime); % get a n_th stimulation for each event time
	% idxStim = find(tf_idxStim);



	% assign the calcium delta to the new fields
	if ~isempty(idx_events)
		eventNum = numel(idx_events); % number of events with specified category
		for n = 1:eventNum
			idxStim_event = idxStim(n); % stimulation idx for this single event
			ROIeventProp_new(idx_events(n)).(newFieldName) = caLevelData(idxStim_event);

			if ~isempty(denomVal) 
				ROIeventProp_new(idx_events(n)).(normValFieldName) = caLevelDataHpStdNorm(idxStim_event);
			end
		end
	end
end