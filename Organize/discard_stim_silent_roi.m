function [recdata_filtered,varargout] = discard_stim_silent_roi(recdata,stimName,varargin)
	% Specify the stim name. This code will find ROIs lack of specified events related to the stim and discard them. 
	% Specify the event type with varargin - 'eventTypes'

	% recdata_series: a cell array. usually called recdata_organized. Trials with different stimulations are collected from the same FOVs

	% Defaults
	series_trials = true; % true/false. If true, silent ROIs in the trials taken from the same FOV and animal will be discarded as well
	eventTypes = 'trigger'; % Find event categories with func "[event_category_str] = event_category_names"

	eventRow = 'peak_lowpass';
	stimName_col = 3;
	event_col = 5;

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('eventRow', varargin{ii})
	        eventRow = varargin{ii+1};
        elseif strcmpi('series_trials', varargin{ii})
	        series_trials = varargin{ii+1};
        elseif strcmpi('eventTypes', varargin{ii})
            eventTypes = varargin{ii+1};
        % % elseif strcmpi('nonstimMean_pos', varargin{ii})
        % %     nonstimMean_pos = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	recdata_filtered = recdata;
	stimNamesAll = recdata(:, stimName_col);
	stimTrialIDX = strcmp(stimName, stimNamesAll);

	stimTrialRows = find(stimTrialIDX);
	stimTrialNum = numel(stimTrialRows);
	stimDisNeuron = cell(stimTrialNum, 1);

	if series_trials
		filterMarks = zeros(stimTrialNum, 1); % mark all trials for filtering
	else
		filterMarks = ones(stimTrialNum, 1);
		filterMarks(stimTrialRows) = 0; % mark trials applied with certain "stimName" for filtering
	end

	% Get the index of ROIs without certain event types specified by var "eventTypes" 
	% from trials applied with certain "stimName"
	for stn = 1:stimTrialNum
		trialEventsAll = recdata{stimTrialRows(stn), event_col};
		trialEvents = trialEventsAll{eventRow, :};

		stimEventIDX = cellfun(@(x) find(strcmp(eventTypes, x.peak_category)), trialEvents, 'UniformOutput',false);
		stimDisNeuron{stn} = find(cellfun(@isempty, stimEventIDX));

		recdata_filtered{stimTrialRows(stn), event_col}(:, stimDisNeuron{stn}) = []; % discard "silent" ROIs
		filterMarks(stimTrialRows(stn)) = 1; % mark the trial as filtered
	end

	if series_trials
		[sNum,sTrialIDX] = get_series_trials(recdata);

		for sn = 1:sNum
			trial_idx = find(sTrialIDX==sn); % index of trials belongs to series[sn]
			sTrialNum = numel(trial_idx);
			[series_stim_trialRow, ~, istr] = intersect(trial_idx, stimTrialRows); % the trial with specified stimualtion in the current series
			% istr: the location of series_stim_trialRow in stimTrialRows

			if isempty(series_stim_trialRow)
				error('series %d does not contain any trial applied with specific stimulation - %s', sn, stimName);
			elseif numel(series_stim_trialRow) > 1
				error('series %d contains more than one trials applied with specific stimulation - %s', sn, stimName);
			end

			for tn = 1:sTrialNum
				if trial_idx(tn) ~= series_stim_trialRow
					recdata_filtered{trial_idx(tn), event_col}(:, stimDisNeuron{istr}) = []; % discard "silent" ROIs
					filterMarks(trial_idx(tn)) = 1; % mark the trial as filtered
				end
			end
		end
	end
end
