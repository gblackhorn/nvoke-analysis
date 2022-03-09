function [traceMean,varargout] = stim_effect_compare_trace_mean_trial(alignedData,varargin)
	% calculate the mean of a specific duration inside the stimuli range and compare that to 
	% mean values outside the stimuli range. used for a single trial

	% alignedData: 1 entry (1 trial) of alignedData_allTrials output by get_event_trace_allTrials. a struct var

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
	for ii = 1:2:(nargin-1)
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
	traceMean.trialName = alignedData.trialName;
	traceMean.stim_name = alignedData.stim_name;
	traceMean.stimMean_start_time = stimMean_start_time;
	traceMean.nonstimMean_pos = nonstimMean_pos;

	alignedTrace_time = alignedData.time;
	stimDuration = alignedData.stimInfo.duration_sec;
	traceData = alignedData.traces;

	roi_num = numel(traceData);
	traceMean.stat =  struct('roi', cell(1, roi_num), 'h', cell(1, roi_num), 'p',cell(1, roi_num),...
		'nonStim_timeRange', cell(1, roi_num), 'stim_timeRange', cell(1, roi_num),...
		'nonstim_all', cell(1, roi_num), 'stim_all', cell(1, roi_num), 'diff_zscore', cell(1, roi_num));

	for n = 1:roi_num
		alignedTrace = traceData(n).value;
		[h,p,nonstimMean_dur,stimMean_dur,nonstim_all,stim_all,diff_zscore] = stim_effect_compare_trace_mean_roi(alignedTrace,...
			alignedTrace_time,stimDuration,...
			'nonstimMean_dur', nonstimMean_dur, 'stimMean_dur', stimMean_dur,...
			'stimMean_start_time', stimMean_start_time, 'nonstimMean_pos', nonstimMean_pos);

		traceMean.stat(n).roi = traceData(n).roi;
		traceMean.stat(n).h = h; % null hypothesis
		traceMean.stat(n).p = p; % p-value
		traceMean.stat(n).nonstimMean_dur = nonstimMean_dur;
		traceMean.stat(n).stimMean_dur = stimMean_dur;
		traceMean.stat(n).nonstim_all = nonstim_all;
		traceMean.stat(n).stim_all = stim_all;
		traceMean.stat(n).diff_zscore = diff_zscore; % (mean(nonstim_all)-mean(stim_all))/mean(stim_all)
	end
end
