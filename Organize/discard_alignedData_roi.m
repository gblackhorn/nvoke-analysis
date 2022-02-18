function [alignedData_filtered] = discard_alignedData_roi(alignedData,varargin)
	% Discard ROIs/neurons in alignedData based on whether they have certain events

	% Find all the event categories with func [event_category_names]
	% event categories in 'OG-LED-5s GPIO-1-1s' are two categories combined with '-' in between

	% Defaults
	stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
	eventCats = {{'trigger'},...
			{'trigger', 'rebound'},...
			{'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'}};
	num_stims = numel(stims); 
	num_eventCats = numel(eventCats); 
	if num_stims~=num_eventCats
		error('func discard_alignedData_roi: \nNumber of compnents in stims and eventCats must be same')
	end

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('stims', varargin{ii})
	        stims = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventCats', varargin{ii})
	        eventCats = varargin{ii+1};
        % elseif strcmpi('stimStart_err', varargin{ii})
        %     stimStart_err = varargin{ii+1};
        % elseif strcmpi('nonstimMean_pos', varargin{ii})
        %     nonstimMean_pos = varargin{ii+1};
	    end
	end	


	%% Content
	alignedData_filtered = alignedData;
	num_trials = numel(alignedData_filtered);
	disIdx_trial = [];
	for nt = 1:num_trials
		ad_trial = alignedData_filtered(nt);
		stim_name = ad_trial.stim_name;
		stimIdx = find(strcmpi(stim_name, stims));
		if ~isempty(stimIdx)
			roiData = ad_trial.traces;
			num_rois = numel(roiData);
			disIdx_roi = [];
			for nr = 1:num_rois
				eventProp = roiData(nr).eventProp;
				eventCats_roi = {eventProp.peak_category};
				[C,ia,ib] = intersect(eventCats_roi, eventCats{stimIdx}, 'stable');
				if isempty(C)
					disIdx_roi = [disIdx_roi; nr];
				end
			end

			alignedData_filtered(nt).traces(disIdx_roi) = [];
			if isempty(alignedData_filtered(nt).traces)
				disIdx_trial = [disIdx_trial; nt];
			end
		end
	end
	alignedData_filtered(disIdx_trial) = [];
end