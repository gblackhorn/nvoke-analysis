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
	freq_spon_stim = []; 
	logRatio_threshold = 0; % threshold for log(stimfq/sponfq);
	perc_meanInDiff = 0.25; % stimEffect is considered to be inhibition when significant different mean_in_diff found in "perc_meanInDiff"*stim number

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('ex_eventCat', varargin{ii})
	        ex_eventCat = varargin{ii+1};
        elseif strcmpi('rb_eventCat', varargin{ii})
	        rb_eventCat = varargin{ii+1};
        elseif strcmpi('in_thresh_stdScale', varargin{ii})
	        in_thresh_stdScale = varargin{ii+1};
        elseif strcmpi('in_calLength', varargin{ii})
	        in_calLength = varargin{ii+1};
        elseif strcmpi('freq_spon_stim', varargin{ii})
	        freq_spon_stim = varargin{ii+1}; % 1*2 vec. frequencies of spon and stim events
	    end
	end	

	%% Content
	excitation = false; % pre-set
	inhibition = false; % pre-set
	rebound = false; % pre-set

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

		% Check for inhibition
		% Compare the calcium level at baseline (prior to stim) and during stimulation
		repeat_num = numel(mean_in);
		tfRepeat_in = logical(zeros(size(mean_in)));
		mean_in_diff = NaN(size(mean_in));
		mean_in_diff = mean_in-(mean_base-std_base*in_thresh_stdScale);
		in_loc = find(mean_in_diff<0);
		tfRepeat_in(in_loc) = true;
		% for rn = 1:repeat_num
		% 	mean_in_diff(rn) = mean_in(rn)-(mean_base(rn)-std_base(rn)*in_thresh_stdScale);
		% 	if mean_in_diff(rn) < 0
		% 		tfRepeat_in(rn) = true;
		% 		% inhibition = true;
		% 		% break
		% 	end
		% end
		% If the calcium level decreases in (perc_meanInDiff)% of the stimulation, confirm the decrease calcium level 
		if numel(find(tfRepeat_in)) >= perc_meanInDiff*repeat_num
			inhibition = true;
		end
		% check the event frequency to confirm the inhibition effect
		if ~isempty(freq_spon_stim) 
			for fn = 1:numel(freq_spon_stim)
				if freq_spon_stim(fn) == 0; % if spontaneous/stimulation event frequency is 0
					freq_spon_stim(fn) = 1e-5;
				end
			end
			logRatio = log(freq_spon_stim(2)/freq_spon_stim(1));
			if logRatio >= 0+logRatio_threshold
				inhibition = false;
			end
		end

		% Check for excitation
		for n_exCat = 1:numel(ex_eventCat)
			tf = strcmpi(ex_eventCat{n_exCat}, eventCats);
			if ~isempty(find(tf))
				excitation = true;
				break
			end
		end

		% check for rebound
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

	avg_meanInDiff = mean(mean_in_diff);
	varargout{1}.meanIn = mean_in_diff;
	varargout{1}.meanIn_average = avg_meanInDiff;
	varargout{1}.base_timeLength = base_timeRange;
	varargout{1}.in_timeLength = in_calLength;
	varargout{1}.sponStim_logRatio = logRatio;
end