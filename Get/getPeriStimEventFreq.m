function [varargout] = getPeriStimEventFreq(alignedData,stimName,varargin)
	% Get peri-stimulation event frequency from all rois in multiple trials
	% applied with the same type stimulation 

	% alignedData: get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'

	% Defaults
	preStimDuration = 5;
	postStimDuration = 10;

	baseRange = [-preStimDuration -2];
	stimEffectStart = 'start'; % Use this to set the start for the stimulation effect range
	stimEffectDuration = 1; % unit: second. Use this to set the end for the stimulation effect range

	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('preStimDuration', varargin{ii})
	        preStimDuration = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('postStimDuration', varargin{ii})
	        postStimDuration = varargin{ii+1}; 
	    elseif strcmpi('plot_raw_races', varargin{ii})
	        plot_raw_races = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventCat', varargin{ii})
	        eventCat = varargin{ii+1};
        elseif strcmpi('fname', varargin{ii})
	        fname = varargin{ii+1};
	    end
	end

	
end

function [recNum,recDateNum,roiNum,tracesNum] = calcDataNum(eventProp_trials)
	% calculte the n numbers using the structure var 'eventProp_trials'

	% get the date and time info from trial names
	% one specific date-time (exp. 20230101-150320) represent one recording
	% one date, in general, represent one animal
	if ~isempty(eventProp_trials)
		dateTimeRoiAll = {eventProp_trials.DateTimeRoi};
		dateTimeAllRec = cellfun(@(x) x(1:15),dateTimeRoiAll,'UniformOutput',false);
		dateAllRec = cellfun(@(x) x(1:8),dateTimeRoiAll,'UniformOutput',false);
		dateTimeRoiUnique = unique(dateTimeRoiAll);
		dateTimeUnique = unique(dateTimeAllRec);
		dateUnique = unique(dateAllRec);

		% get all the n numbers
		recNum = numel(dateTimeUnique);
		recDateNum = numel(dateUnique);
		roiNum = numel(dateTimeRoiUnique);
		tracesNum = numel(dateTimeRoiAll);
	else
		recNum = 0;
		recDateNum = 0;
		roiNum = 0;
		tracesNum = 0;
	end
end