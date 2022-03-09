function [baseline_timeRange,varargout] = get_baseline_timeRange(stimTimeStarts,timeInfo,varargin)
	% Return the time range of baseline according to stimulation time
	% baseline ends at (stimulation_start_index-1)
	% baseline starts are baseline_ends-base_timeRange

	% stimTimeInfo: a column vector var (starts of stimulation)
	% timeInfo: column vector. Full time information of a trial recording

	% Defaults
	base_timeRange = 2; % default 2s. 

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    end
	end	

	%% Content
	baseline_timeRange = NaN(numel(stimTimeStarts), 2); % time range of baseline for each stimulation
	[~, idx_stimStarts] = find_closest_in_array(stimTimeStarts(:, 1), timeInfo);
	baseline_timeRange(:, 2) = timeInfo(idx_stimStarts-1);
	baseline_timeRange(:, 1) = baseline_timeRange(:, 2)-base_timeRange;
	[baseline_timeRange(:, 1)] = find_closest_in_array(baseline_timeRange(:, 1), timeInfo);
end