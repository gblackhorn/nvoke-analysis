function [sponEventData,varargout] = get_sponFreq_everyStim_roi(EventsTime,sponTimeRanges,varargin)
	% Return a list containing the sponEventNum, sponEventFreq, curveFit_tf(if there is a curvefit),
	% etc. before each stimulation in a ROI

	% Note: EventsTime is a vector (rise/peak_time). sponTimeRanges is a n*2 array. n is the number
	% of stimulations. First and second cols are the starts and ends of spontaneous time ranges

	% Example:
	% sponTimeRanges(:,1) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1)-15;   
	% sponTimeRanges(:,2) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1);   
	% EventsTime = [alignedData_allTrials(7).traces(1).eventProp.rise_time];  
	% stimIDX_curvefit = [alignedData_allTrials(7).traces(1).StimCurveFit.SN];
	% [sponFreqList] = get_sponFreq_everyStim_roi(EventsTime,sponTimeRanges,'stimIDX_curvefit',stimIDX_curvefit);


	% Defaults
	stimIDX_curvefit = [];
	sponTimeRanges_direction = 1; % 1: row number is the stimulation number. 2: col number is the stimulation number


	% Optional
	for ii = 1:2:(nargin-2)
	    if strcmpi('stimIDX_curvefit', varargin{ii})
	        stimIDX_curvefit = varargin{ii+1}; % the idx of stimulation with a curve fit
	    elseif strcmpi('sponTimeRanges_direction', varargin{ii})
	        sponTimeRanges_direction = varargin{ii+1};
	    % elseif strcmpi('save_fig', varargin{ii})
	    %     save_fig = varargin{ii+1};
	    % elseif strcmpi('save_dir', varargin{ii})
	    %     save_dir = varargin{ii+1};
	    % elseif strcmpi('gui_save', varargin{ii})
	    %     gui_save = varargin{ii+1};
	    end
	end


	% transpose the sponTimeRanges if necessary
	if sponTimeRanges_direction == 2
		sponTimeRanges = sponTimeRanges';
	end

	% Create a structure for sponEventData
	stimNum = size(sponTimeRanges,1);
	sponEventData = empty_content_struct({'stimIDX','sponNum','timeDur','sponFreq','curvefit_tf'},stimNum);


	% Find the spontaneous events using the EventsTime for each sponTimeRanges
	% Calculate the sponEventFreqs and fill the sponEventData with this and other info
	for sn = 1:stimNum
		sponEventData(sn).stimIDX = sn; % idx of stimulation
		eventIDX = find(EventsTime>=sponTimeRanges(sn,1) & EventsTime<sponTimeRanges(sn,2));
		sponEventData(sn).sponNum = numel(eventIDX); % number of spontaneous number
		sponEventData(sn).timeDur = sponTimeRanges(sn,2)-sponTimeRanges(sn,1); % time duration for spontaneous events
		sponEventData(sn).sponFreq = sponEventData(sn).sponNum/sponEventData(sn).timeDur;
		if ~isempty(find(sn==stimIDX_curvefit)) % if the stimulation idx is found in the curvefitIDX
			sponEventData(sn).curvefit_tf = 1;
		else
			sponEventData(sn).curvefit_tf = 0;
		end
	end
end