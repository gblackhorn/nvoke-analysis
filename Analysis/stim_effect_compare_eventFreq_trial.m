function [stimSponR,varargout] = stim_effect_compare_eventFreq_trial(recdata,varargin)
	% Return the zscore of stim event frequencies ((outside_stim-inside_stim)/outside_stim) in all ROIs from a single trial

	% recdata: a cell array. usually called recdata_organized

	% Defaults
	afterStim_exepWin = true; % true/false. use exemption win or not. if true, events in this win not counted as outside stim
	exepWinDur = 1; % length of exemption window
	stimStart_err = 0; % modify the start of the stim range, in case low sampling rate causes error
	stimFreq_win = [];

	trialName_col = 1;
	stimName_col = 3;
	traceInfo_col = 2;
	event_prop_col = 5;
	eventData_cat = 'peak_lowpass';
	stimInfo_col = 4;

	stim_idx = 3; % stimulation index in stimulation info. first 2 are BNC-sync and EX-LED
	eventTimeType = 'rise_time';
	ratio_disp = 'zscore'; % log/zscore
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
	stimSponR.trialName = recdata{trialName_col};
	stimSponR.stimName = recdata{stimName_col};
	stimSponR.fovID = recdata{traceInfo_col}.fovID;

	event_prop = recdata{event_prop_col};
	roiNum = size(event_prop, 2);
	stim_range = recdata{stimInfo_col}(stim_idx).stim_range;
	if ~isempty(stimFreq_win)
		stim_dur = stim_range(1, 2)-stim_range(1, 1); % duration of a stimulation
		if stimFreq_win(1)<=stim_dur && stimFreq_win(2)<=stim_dur
			stim_range(1) = stim_range(1)+stimFreq_win(1);
			stim_range(2) = stim_range(1)+stimFreq_win(2);
		end
	end

	timeInfo = recdata{traceInfo_col}.raw.Time;
	timeDuration = timeInfo(end)-timeInfo(1);

	stimSponR.FqRatio =  struct('roi', cell(1, roiNum), 'Ratio_zscore_StimSpon', cell(1, roiNum),...
		'sponfq', cell(1, roiNum), 'stimfq', cell(1, roiNum));

	for n = 1:roiNum
		roiEventProp = event_prop{(eventData_cat), n}{:};
		roiName = event_prop.Properties.VariableNames{n};
		if ~isempty(roiEventProp)
			events_time = roiEventProp{:, eventTimeType};

			switch ratio_disp
				case 'log'
					[Ratio_StimSpon,sponfq,stimfq] = stim_effect_compare_eventFreq_roi(events_time,stim_range,timeDuration,...
						'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
						'stimStart_err', stimStart_err);
				case 'zscore'
					[Ratio_StimSpon,sponfq,stimfq] = stim_effect_compare_eventFreq_roi2(events_time,stim_range,timeDuration,...
						'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
						'stimStart_err', stimStart_err);

			end
			% [logRatio,sponfq,stimfq] = stim_effect_compare_eventFreq_roi(events_time,stim_range,timeDuration,...
			% 	'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
			% 	'stimStart_err', stimStart_err);

			% [Ratio_zscore,sponfq,stimfq] = stim_effect_compare_eventFreq_roi2(events_time,stim_range,timeDuration,...
			% 	'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
			% 	'stimStart_err', stimStart_err);

			stimSponR.FqRatio(n).roi = roiName;
			% stimSponR.logR(n).logRatio_StimSpon = logRatio;
			stimSponR.FqRatio(n).Ratio_StimSpon = Ratio_StimSpon;
			stimSponR.FqRatio(n).sponfq = sponfq;
			stimSponR.FqRatio(n).stimfq = stimfq;
		end
	end
end
