function [stimSponRall,varargout] = stim_effect_compare_eventFreq_alltrial(recdataAll,varargin)
	% Return the zscore of stim event frequencies ((outside_stim-inside_stim)/outside_stim) in all ROIs from every trial

	% recdata: a cell array. usually called recdata_organized

	% Defaults
	afterStim_exepWin = true; % true/false. use exemption win or not. if true, events in this win not counted as outside stim
	exepWinDur = 1; % length of exemption window
	stimStart_err = 0; % modify the start of the stim range, in case low sampling rate causes error
	ratio_disp = 'zscore'; % log/zscore
	stimFreq_win = [];

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('afterStim_exepWin', varargin{ii})
	        afterStim_exepWin = varargin{ii+1};
        elseif strcmpi('exepWinDur', varargin{ii})
	        exepWinDur = varargin{ii+1};
        elseif strcmpi('stimStart_err', varargin{ii})
            stimStart_err = varargin{ii+1};
        elseif strcmpi('ratio_disp', varargin{ii})
            ratio_disp = varargin{ii+1};
	    elseif strcmpi('stimFreq_win', varargin{ii})
            stimFreq_win = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	trial_num = size(recdataAll, 1);
	data_cell = cell(1, trial_num);

	for n = 1:trial_num
		recdata = recdataAll(n, :);
		[data_cell{n}] = stim_effect_compare_eventFreq_trial(recdata,...
				'stimFreq_win', stimFreq_win, 'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
				'stimStart_err', stimStart_err, 'ratio_disp', ratio_disp);
	end

	stimSponRall = [data_cell{:}];

	stimSponR_opt.afterStim_exepWin = afterStim_exepWin;
	stimSponR_opt.exepWinDur = exepWinDur;
	stimSponR_opt.stimStart_err = stimStart_err;
	stimSponR_opt.note = sprintf('Find details about opt in fun [stim_effect_compare_eventFreq_alltrial]');

	varargout{1} = stimSponR_opt;
end
