function [stimEffect,varargout] = get_stimEffect(traceTimeInfo,traceData,stimTimeInfo,eventCats,varargin)
	% Output a structure var summarizing the effect of stimulation

	% traceTimeInfo: vector var. Full time information of a trial recording
	% traceData: vector var. Calcium level information from a single roi
	% stimTimeInfo: n x 2 array. 1st col contains the starts of stimulation. 2nd col contains ends of stimulation
	% eventCats: a cell var containing event categories of all event in a single roi

	% Defaults
	base_timeRange = 2; % default 2s. 
	ex_eventCat = {'trig'}; % event category string used to define excitation. May contain multiple strings
	rb_eventCat = {'rebound'}; % event category string used to define rebound. May contain multiple strings
	in_thresh_stdScale = 2; % n times of std lower than baseline level. Last n s during stimulation is used
	in_calLength = 1; % calculate the last n s trace level during stimulation to 

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('ex_eventCat', varargin{ii})
	        ex_eventCat = varargin{ii+1};
        elseif strcmpi('rb_eventCat', varargin{ii})
	        rb_eventCat = varargin{ii+1};
        elseif strcmpi('in_thresh', varargin{ii})
	        in_thresh = varargin{ii+1};
        elseif strcmpi('in_calLength', varargin{ii})
	        in_calLength = varargin{ii+1};
	    end
	end	

	%% Content
	excitation = false; % pre-set
	inhibition = false; % pre-set
	rebound = false; % pre-set

	% Check if inhibition
	if ~isempty(stimTimeInfo)
		stim_duration = stimTimeInfo(1,2)-stimTimeInfo(1,1);
		if in_calLength > stim_duration
			in_calLength = stim_duration;
		end

		in_range = stimTimeInfo; % range of time for calculating the inhibition effect
		in_range(:, 1) = in_range(:, 2)-in_calLength; % modify the start of in_range according to [in_calLength]
		[in_range] = get_realTime(in_range,traceTimeInfo); % Get the closest time info in [traceTimeInfo]

		[base_range] = get_baseline_timeRange(stimTimeInfo(:, 1),traceTimeInfo,...
			'base_timeRange', base_timeRange);

		[mean_in,std_in] = get_meanVal_in_timeRange(in_range,traceTimeInfo,traceData);
		[mean_base,std_base] = get_meanVal_in_timeRange(base_range,traceTimeInfo,traceData);

		for rn = 1:numel(mean_in)
			if mean_in < (mean_base-std_base*in_thresh_stdScale)
				inhibition = true;
				break
			end
		end

		% Check if excitation
		for n_exCat = 1:numel(ex_eventCat)
			tf = strcmpi(ex_eventCat{n_exCat}, eventCats);
			if ~isempty(find(tf))
				excitation = true;
				break
			end
		end

		% check if rebound
		for n_rbCat = 1:numel(rb_eventCat)
			tf = strcmpi(rb_eventCat{n_rbCat}, eventCats);
			if ~isempty(find(tf))
				rebound = true;
				break
			end
		end

		% assign value
		stimEffect.excitation = excitation;
		stimEffect.inhibition = inhibition;
		stimEffect.rebound = rebound;
	else
		stimEffect.excitation = [];
		stimEffect.inhibition = [];
		stimEffect.rebound = [];
	end
end