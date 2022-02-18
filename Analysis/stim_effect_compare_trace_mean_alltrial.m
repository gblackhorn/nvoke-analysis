function [traceMeanAll,varargout] = stim_effect_compare_trace_mean_alltrial(alignedData_allTrials,varargin)
	% calculate the mean of a specific duration inside the stimuli range and compare that to 
	% mean values outside the stimuli range. used for all trials

	% alignedData_allTrials: alignedData_allTrials output by get_event_trace_allTrials. a struct var

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
	trial_num = numel(alignedData_allTrials);
	data_cell = cell(1, trial_num);

	for n = 1:trial_num
		alignedData = alignedData_allTrials(n);
		[data_cell{n}] = stim_effect_compare_trace_mean_trial(alignedData,...
			'nonstimMean_dur', nonstimMean_dur, 'stimMean_dur', stimMean_dur,...
			'stimMean_start_time', stimMean_start_time, 'nonstimMean_pos', nonstimMean_pos);
	end
	traceMeanAll = [data_cell{:}];

	traceMean_opt.stimMean_dur = stimMean_dur;
	traceMean_opt.nonstimMean_dur = nonstimMean_dur;
	traceMean_opt.stimMean_start_time = stimMean_start_time;
	traceMean_opt.nonstimMean_pos = nonstimMean_pos;
	traceMean_opt.note = sprintf('Find details about opt in fun [stim_effect_compare_trace_mean_alltrial]');

	varargout{1} = traceMean_opt;
end
