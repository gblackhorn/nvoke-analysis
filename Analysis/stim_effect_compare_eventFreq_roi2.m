function [Ratio_zscore,varargout] = stim_effect_compare_eventFreq_roi2(events_time,stim_range,timeDuration,varargin)
	% Return the zscore of stim event frequencies ((outside_stim-inside_stim)/outside_stim) in a single ROI

	% events_time: a column vector, ususally rise_time
	% stim_range: a two-column matrix
	% timeDuration: a number. total duration of recording

	% Defaults
	afterStim_exepWin = true; % true/false. use exemption win or not. if true, events in this win not counted as outside stim
	exepWinDur = 1; % length of exemption window
	stimStart_err = 0; % modify the start of the stim range, in case low sampling rate causes error

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('afterStim_exepWin', varargin{ii})
	        afterStim_exepWin = varargin{ii+1};
        elseif strcmpi('exepWinDur', varargin{ii})
	        exepWinDur = varargin{ii+1};
        elseif strcmpi('stimStart_err', varargin{ii})
            stimStart_err = varargin{ii+1};
        % elseif strcmpi('nonstimMean_pos', varargin{ii})
        %     nonstimMean_pos = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	eventNum = numel(events_time);
	eventCat = ones(size(events_time)); % event categorey. default all are 1: simultaneous events

	if ~isempty(stim_range)
		stimNum = size(stim_range, 1);
		stim_range(:, 1) = stim_range(:, 1)-stimStart_err;

		if afterStim_exepWin
			exepWin(:, 1) = stim_range(:, 2); 
			exepWin(:, 2) = stim_range(:, 2)+exepWinDur; 
		end

		stimDurAll = sum(stim_range(:, 2)-stim_range(:, 1));
		exepWinDurAll = sum(exepWin(:, 2)-exepWin(:, 1));
		sponDurAll = timeDuration-stimDurAll-exepWinDurAll;

		for n = 1:eventNum
			% 1-simulataneous, 2-insideStim, NaN-insideExepWin
			for ii = 1:stimNum
				if events_time(n)>=stim_range(ii, 1) && events_time(n)<stim_range(ii, 2)
					eventCat(n) = 2;
				elseif events_time(n)>=exepWin(ii, 1) && events_time(n)<exepWin(ii, 2)
					eventCat(n) = NaN;
				end
			end
		end

		sponEvent = find(eventCat==1);
		stimEvent = find(eventCat==2);
		exepEvent = find(isnan(eventCat));
		exepEventNum = numel(exepEvent);

		% use small number substitute zero for further calculation. Temperay solution
		sponEventNum = numel(sponEvent);
		stimEventNum = numel(stimEvent);

		sponfq = sponEventNum/sponDurAll;
		stimfq = stimEventNum/stimDurAll;
	else
		sponEventNum = eventNum;
		sponfq = sponEventNum/timeDuration;
		stimfq = NaN;
		stimEventNum = NaN;
		exepEventNum = NaN;
		Ratio_zscore = NaN;
	end

	if exepEventNum == 0
		exepEventNum = NaN;
	end

	Ratio_zscore = (stimfq-sponfq)/sponfq;
	varargout{1} = sponfq;
	varargout{2} = stimfq;
	varargout{3} = sponEventNum;
	varargout{4} = stimEventNum;
	varargout{5} = exepEventNum;
end
