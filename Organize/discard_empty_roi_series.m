function [recdata_series_sync,varargout] = discard_empty_roi_series(recdata_series,varargin)
	% Compare series recrodings and discard roi without events

	% recdata_series: a cell array. usually called recdata_organized. Trials with different stimulations are collected from the same FOVs

	% Defaults
	eventRow = 'peak_lowpass';
	event_col = 5;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('eventRow', varargin{ii})
	        eventRow = varargin{ii+1};
        % elseif strcmpi('exepWinDur', varargin{ii})
	       %  exepWinDur = varargin{ii+1};
        % elseif strcmpi('stimStart_err', varargin{ii})
        %     stimStart_err = varargin{ii+1};
        % % elseif strcmpi('nonstimMean_pos', varargin{ii})
        % %     nonstimMean_pos = varargin{ii+1};
	    end
	end

	% ====================
	% Main content
	recdata_series_sync = recdata_series;

	[sNum,sTrialIDX] = get_series_trials(recdata_series);
	trialNum = size(recdata_series, 1);
	disNeuron = cell(trialNum, 1);

	for sn = 1:sNum
		trial_idx = find(sTrialIDX==sn); % index of trials belongs to series[sn]
		sTrialNum = numel(trial_idx);
		sDisNeuron = cell(sTrialNum, 1); % cell storing discarded neuron idx in a series

		% find ROIs without events in every trial from the same series and combine them
		for tn = 1:sTrialNum
			trial_row = trial_idx(tn);
			trialEventsAll = recdata_series{trial_row, event_col};

			[EventProp_structVar] = convert_table2struct(trialEventsAll,'RowNameField','roi'); % convert peak properties table to a structure var

			[sDisNeuron{tn}] = get_fieldA_if_fieldB_empty(EventProp_structVar,'roi',eventRow);


			% EventProp = {EventProp_structVar.(eventRow)};
			% roiNames = {EventProp_structVar.('roi')};
			% IDX_empty = find(cellfun(@isempty, EventProp));
			% sDisNeuron{tn} = roiNames(IDX_empty);

			% trialEvents = trialEventsAll{eventRow, :};
			% sDisNeuron{tn} = find(cellfun(@isempty, trialEvents));
		end
		sDisNeuron_array = unique([sDisNeuron{:}]); % Index of ROIs without events 

		% discard ROIs without events
		for tn = 1:sTrialNum
			trial_row = trial_idx(tn); % row of a single trial
			trialEvents = recdata_series_sync{trial_row, event_col}; % table of event properties of all rois from one trial
			trialROIs = trialEvents.Properties.VariableNames; % ROI names 
			[C, ia, ib]=intersect(trialROIs,sDisNeuron_array);
			recdata_series_sync{trial_row, event_col}(:, ia) = [];
		end
	end
end
