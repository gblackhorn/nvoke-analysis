function [grouped_traces,varargout] = group_event_trace_trial(alignedData_allTrials,varargin)
% group roi traces in a single trial
%   Options: - group traces from all ROIs in a single trial
%			 - group traces from all trials
% cat_keyword, stim_name are used to organize events into different groups

	% Defaults
	group_level = 'roi'; % options: 'roi' (all rois in a single trial)
%						  			'trial' (all trials)
	use_catKeyword = true; % use cat_keyword field to seperated groups
	use_stimName = true; % use stim_name field to seperated groups


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('group_level', varargin{ii})
	        group_level = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('use_catKeyword', varargin{ii})
	        use_catKeyword = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('use_stimName', varargin{ii})
	        use_stimName = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    end
	end

	% ====================
	% Main contents
	trial_num = size(allTrialsData, 1);
	data_cell = cell(1, trial_num);

	for n = 1:trial_num
		trialData = allTrialsData(n, :);
		[data_cell{n}] = get_event_trace_trial(trialData, 'event_type', event_type,...
		'traceData_type', traceData_type, 'event_data_group', event_data_group,...
		'event_filter', event_filter, 'event_align_point', event_align_point, 'cat_keywords', cat_keywords,...
		'pre_event_time', pre_event_time, 'post_event_time', post_event_time);
	end

	alignedData_allTrials = [data_cell{:}];
end