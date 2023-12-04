function [ROIeventProp_new,varargout] = add_caLevelDelta_for_specificEvents(ROIeventProp,eventCat,stimTime,caLevelDelta,varargin)
	% This function is used to get the calcium level delta (lowest point/largest value) during
	% stimulations for a specific type of events, such as 'rebound'

	% Note: ROIeventProp is a structure var. Fields 'rise_time' and 'peak_category' are used in this
	% function. eventCat is a character var (such as 'rebound'). StimTime is a vector (the ends of stimulation for
	% rebound events). caLevelDelta is an double vector with the same length as the stimTime.

	% Example:


	% Defaults


	
	% Options
	% for ii = 1:2:(nargin-3)
	%     if strcmpi('xlabel_str', varargin{ii})
	%         xlabel_str = varargin{ii+1};
	%     elseif strcmpi('ylabel_str', varargin{ii})
	%         ylabel_str = varargin{ii+1};
	%     % elseif strcmpi('title_str', varargin{ii})
	%     %     title_str = varargin{ii+1};
	%     end
	% end


	% Create 2 NaN arrays having the same length as the events. 
	% One for largest calcium level delta, and another one for decay constant (tau) during stimulations
	ROIeventProp_new = ROIeventProp;
	
	if ~isfield(ROIeventProp_new,'caLevelDelta')
		defaultValue = {[]}; % create a cell array with the default value for the new field
		[ROIeventProp_new(:).caLevelDelta] = deal(defaultValue{:}); % use deal to assign the default value to each structure
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
			ROIeventProp_new(idx_events(n)).caLevelDelta = caLevelDelta(idxStim_event);
		end
	end
end