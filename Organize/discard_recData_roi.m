function [recData_filtered] = discard_recData_roi(recData,varargin)
	% Discard ROIs/neurons in alignedData based on whether they have certain events

	% Find all the event categories with func [event_category_names]
	% event categories in 'OG-LED-5s GPIO-1-1s' are two categories combined with '-' in between

	% Defaults
	stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
	eventCats = {{'trigger'},...
			{'trigger', 'rebound'},...
			{'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'}};

	stim_col = 3;
	eventProp_col = 5;
	eventPropGroup = 'peak_lowpass';


	num_stims = numel(stims); 
	num_eventCats = numel(eventCats); 
	if num_stims~=num_eventCats
		error('func discard_recData_roi: \nNumber of compnents in stims and eventCats must be same')
	end

	debug_mode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('stims', varargin{ii})
	        stims = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventCats', varargin{ii})
	        eventCats = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        % elseif strcmpi('nonstimMean_pos', varargin{ii})
        %     nonstimMean_pos = varargin{ii+1};
	    end
	end	


	%% Content
	recData_filtered = recData;
	num_trials = size(recData_filtered, 1);
	disIdx_trial = [];
	for nt = 1:num_trials

		if debug_mode
			fprintf('trial %d/%d \n', nt, num_trials)
			if nt==13
				pause
			end
		end

		% ad_trial = alignedData_filtered(nt);
		recData_trial = recData(nt, :);
		stim_name = recData_trial{3};
		% stim_name = ad_trial.stim_name;
		stimIdx = find(strcmpi(stim_name, stims));
		if ~isempty(stimIdx)
			eventProp_trial = recData_trial{eventProp_col};
			num_rois = size(eventProp_trial, 2);
			% roiData = ad_trial.traces;
			% num_rois = numel(roiData);
			disIdx_roi = [];
			for nr = 1:num_rois

				if debug_mode
					fprintf(' roi %d/%d \n', nr, num_rois)
				end

				eventProp_roi_table = eventProp_trial(eventPropGroup, nr); % this is a table var
				eventProp_roi = eventProp_roi_table{:, :}{:}; % table var
				if ~isempty(eventProp_roi)
					eventCats_roi = eventProp_roi{:, 'peak_category'};

					% eventProp_roi = roiData(nr).eventProp_roi;
					% eventCats_roi = {eventProp_roi.peak_category};
					[C,ia,ib] = intersect(eventCats_roi, eventCats{stimIdx}, 'stable');
					if isempty(C)
						disIdx_roi = [disIdx_roi; nr];
					end
				else
					disIdx_roi = [disIdx_roi; nr];
				end
			end

			recData_filtered{nt, eventProp_col}(:, disIdx_roi) = [];
			if isempty(recData_filtered{nt, eventProp_col})
				disIdx_trial = [disIdx_trial; nt];
			end
		end
	end
	recData_filtered(disIdx_trial, :) = [];
end