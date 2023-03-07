function [sponWindows,varargout] = get_sponWindowsBeforeStim(stimWindows,varargin)
	% Use stimulation windows (n*2 array. 1-col: starts. 2-col: ends) to decide the ranges of
	% spontaneous event windows (without stimulation) before stimulations


	% Example:
	% sponTimeRanges(:,1) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1)-15;   
	% sponTimeRanges(:,2) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1);   
	% EventsTime = [alignedData_allTrials(7).traces(1).eventProp.rise_time];  
	% stimIDX_curvefit = [alignedData_allTrials(7).traces(1).StimCurveFit.SN];
	% [sponFreqList] = get_sponFreq_everyStim_roi(EventsTime,sponTimeRanges,'stimIDX_curvefit',stimIDX_curvefit);


	% Defaults
	excludeWinPre = 0; % exclude the specified duration (unit: s) before stimulation
	excludeWinPost = 0; % exclude the specified duration (unit: s) after stimulation
	timeInfo = [];

	% Optional
	for ii = 1:2:(nargin-1)
	    if strcmpi('excludeWinPost', varargin{ii})
	        excludeWin = varargin{ii+1}; % the idx of stimulation with a curve fit
	    elseif strcmpi('excludeWinPre', varargin{ii})
	        excludeWinPre = varargin{ii+1};
	    elseif strcmpi('timeInfo', varargin{ii})
	        timeInfo = varargin{ii+1};
	    % elseif strcmpi('save_fig', varargin{ii})
	    %     save_fig = varargin{ii+1};
	    % elseif strcmpi('save_dir', varargin{ii})
	    %     save_dir = varargin{ii+1};
	    % elseif strcmpi('gui_save', varargin{ii})
	    %     gui_save = varargin{ii+1};
	    end
	end


	% repeats of stimulation
	stimRepeats = size(stimWindows,1);

	% Get the interval between the first stimulation end and the second stimulation start
	if stimRepeats >1
		intDur = stimWindows(2,1)-stimWindows(1,2); 
	else
		intDur = stimWindows(1,1);
	end

	% Calculate the spontaneous windows 
	sponWindows = nan(size(stimWindows));
	for n = 1:stimRepeats
		if n == 1
			sponWindows(n,1) = stimWindows(n,1)-intDur+excludeWin;
		else
			sponWindows(n,1) = stimWindows(n-1,2)+excludeWin;
		end
		sponWindows(n,2) = stimWindows(n,1)-excludeWinPre;

		% Aligne the sponWindows to timeInfo if it is not empty
		if ~isempty(timeInfo)
			sponWindows(n,:) = find_closest_in_array(sponWindows(n,:),timeInfo);
		end
	end
end