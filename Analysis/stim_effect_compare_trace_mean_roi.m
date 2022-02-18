function [h,p,varargout] = stim_effect_compare_trace_mean_roi(alignedTrace,alignedTrace_time,stimDuration,varargin)
	% calculate the mean of a specific duration inside the stimuli range and compare that to 
	% mean values outside the stimuli range. Used for a single ROI

	% alignedTrace: matrix. each column is a repeat of stimulation. 
	% alignedTrace_time: a column vector. time info for the aligned traces. Time zero is when the stimuli starts
	% stimDuration: a number describing the duration of the stimulation

	% Defaults
	stimMean_dur = 2; % unit: s. duration of time to calculate the mean value of trace inside of stimulation
	nonstimMean_dur = 2; % duration of time to calculate the mean value of trace outside of stimulation
	stimMean_start_time = 'last'; % options: 'first', 'last'. start from stim start with stimMean_dur, 
									% or start from (stimDuration-stimMean_dur)
	nonstimMean_pos = 'pre'; % options: 'pre', 'post', 'both'.
								% pre: [(0-nonstimMean_dur) : 0]
								% post: [stimDuration : (stimDuration+nonstimMean_dur)]  
								% both: pre and post

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('stimMean_dur', varargin{ii})
	        stimMean_dur = varargin{ii+1};
        elseif strcmpi('nonstimMean_dur', varargin{ii})
	        nonstimMean_dur = varargin{ii+1};
        elseif strcmpi('stimMean_start_time', varargin{ii})
            stimMean_start_time = varargin{ii+1};
        elseif strcmpi('nonstimMean_pos', varargin{ii})
            nonstimMean_pos = varargin{ii+1};
	    % elseif strcmpi('stat', varargin{ii})
     %        stat = varargin{ii+1};
	    % elseif strcmpi('stat_fig', varargin{ii})
     %        stat_fig = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	at_time_dur = alignedTrace_time(end)-alignedTrace_time(1); % duration of the alignedTrace_time
	pre_stim_dur = abs(alignedTrace_time(1)); % full duration of pre-stimulation part of alignedTrace_time
	post_stim_dur = alignedTrace_time(end)-stimDuration; 

	stim_loc = find(alignedTrace_time==0);
	stim_end_loc = find(alignedTrace_time==stimDuration);
	[stim_end_time,stim_end_loc] = find_closest_in_array(stimDuration,alignedTrace_time);

	% if required nonstimMean_dur is longer than the aligned trace non-stim duration, use the trace info 
	switch nonstimMean_pos
		case 'pre'
			nonstim_at_dur = pre_stim_dur;
		case 'post'
			nonstim_at_dur = post_stim_dur;
		case 'both'
			nonstim_at_dur = min(pre_stim_dur, post_stim_dur);
	end
	if nonstimMean_dur>nonstim_at_dur
		nonstimMean_dur = nonstim_at_dur;
	end

	% find the start and end idx of nonstimMean_dur
	switch nonstimMean_pos
		case 'pre'
			nonstim_start = 0-nonstimMean_dur;
			[nonstim_start,nonstim_idx(1, 1)] = find_closest_in_array(nonstim_start,alignedTrace_time); % index of nonstim range start
			nonstim_idx(1, 2) = stim_loc-1; % index of nonstim range end
		case 'post'
			nonstim_idx(1, 1) = stim_end_loc+1; % index of nonstim range end
			nonstim_end = stimDuration+nonstimMean_dur;
			[nonstim_end,nonstim_idx(1, 2)] = find_closest_in_array(nonstim_end,alignedTrace_time); % index of nonstim range end
		case 'both'
			nonstim_pre_start = 0-nonstimMean_dur;
			[nonstim_pre_start,nonstim_idx(1, 1)] = find_closest_in_array(nonstim_pre_start,alignedTrace_time); % index of nonstim range start
			nonstim_idx(1, 2) = stim_loc-1; 
			nonstim_idx(2, 1) = stim_end_loc+1; 
			nonstim_post_end = stimDuration+nonstimMean_dur;
			[nonstim_post_end,nonstim_idx(2, 2)] = find_closest_in_array(nonstim_post_end,alignedTrace_time); 
	end

	% Get the start and end idx of nonstimMean_dur
	if numel(stimMean_dur) == 2
		binRange_time = stimMean_dur; % if stimMean_dur is a two-element array, it represents the range of a bin
	elseif numel(stimMean_dur) == 1
		binRange_time = [0 stimMean_dur];
	elseif numel(stimMean_dur) > 2
		error('var stimMean_dur must be a number or a 2-component array');
	end

	if binRange_time(1) >= stimDuration
		binRange_time = binRange_time-binRange_time(1); % shift the binRange to the start or the end of the stimulation window
		warning('The start of stimMean_dur exceeds the stimulation period')
	end

	if binRange_time(2) > stimDuration 
		binRange_time(2) = stimDuration;
		warning('var stimMean_dur exceeds stimulation duration (%d s)', stimDuration)
	end
	switch stimMean_start_time
		case 'first'
			% stim_idx(1, 1) = stim_loc; 
			% stim_end_time = stimMean_dur;
			[binRange_time,binRange_idx] = find_closest_in_array(binRange_time(:),alignedTrace_time); 
		case 'last'
			binRange_time = flip(stimDuration-binRange_time);
			% stim_idx(1, 2) = stim_end_loc;
			% stim_start_time = stimDuration-stimMean_dur;
			[binRange_time,binRange_idx] = find_closest_in_array(binRange_time(:),alignedTrace_time); 
	end

	% calculate the means of nonstimMean and stimMean
	nonstim_range_num = size(nonstim_idx, 1); % number of non-stim sections. if 'pre' and 'post' are both used, this is 2, otherwise 1 
	nonstim_all_cell = cell(nonstim_range_num, 1);
	for n = 1:nonstim_range_num
		nonstim_all_cell{n, 1} = alignedTrace(nonstim_idx(n, 1):nonstim_idx(n, 2), :);
	end
	nonstim_all = [nonstim_all_cell{:}]; % combine cells and make a matrix
	nonstim_all = nonstim_all(:); % convert matrix to a single column vector. all data points for nonstim range(s)

	stim_all = alignedTrace(binRange_idx(1):binRange_idx(2), :);
	% stim_all = stim_idx(:); % convert matrix to a single column vector. all data points for stim range
	stim_all = reshape(stim_all, [], 1);

	[h, p] = ttest2(nonstim_all, stim_all); % h: null hypothesis. p: p-value

	diff_zscore = (mean(stim_all)-mean(nonstim_all))/std(nonstim_all);

	varargout{1} = nonstimMean_dur;
	varargout{2} = stimMean_dur;
	varargout{3} = nonstim_all;
	varargout{4} = stim_all;
	varargout{5} = diff_zscore;
end