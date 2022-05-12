function [grouped_alignedTrace_trial,varargout] = group_aligned_eventTrace_trial(alignedData_trial,varargin)
	% Group the aligned event traces in a single trial according to the event category

	% alignedData_trial: structure var. aligned data of a single trial

	% Defaults
	pc_norm = 'spon'; % alignedTrace will be normalized to the average value of this event category
	normData = true; % whether normalize alignedTrace with average value of pc_norm data

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('pc_norm', varargin{ii})
	        pc_norm = varargin{ii+1}; 
	    elseif strcmpi('normData', varargin{ii})
	        normData = varargin{ii+1};
	    end
	end	

	%% Content
	roiData = alignedData_trial.traces;
	num_roi = numel(roiData);

	num_disROI = 0;
	for n = 1:num_roi
		alignedTrace = roiData(n).value;
		peakCategories = {roiData(n).eventProp.peak_category};
		amp_data = [roiData(n).eventProp.peak_mag_delta];

		[grouped_alignedTrace,catNum_roi] = group_aligned_eventTrace(alignedTrace,peakCategories,...
			'pc_norm', pc_norm,'amp_data', amp_data, 'normData', normData);

		if normData && ~grouped_alignedTrace(1).normalization 
			% if normalization is required, but data in grouped_alignedTrace could not be normalized
			% Do not assign the value to grouped_alignedTrace_trial
			num_disROI = num_disROI+1;
		else
			if ~exist('grouped_alignedTrace_trial', 'var') % n == 1
				grouped_alignedTrace_trial = grouped_alignedTrace;
				for cn = 1:catNum_roi
					grouped_alignedTrace_trial(cn).timeInfo = alignedData_trial.time;
				end
			else
				groups_trial = {grouped_alignedTrace_trial.group};
				groups_roi = {grouped_alignedTrace.group};

				num_groups_trial = numel(groups_trial);
				num_groups_roi = numel(groups_roi);
				for gn = 1:num_groups_roi
					group_loc = find(strcmpi(groups_roi{gn}, groups_trial));
					if ~isempty(group_loc) % concatenate roi aligned trace to existing trial data if groups exist in trial data
						grouped_alignedTrace_trial(group_loc).alignedTrace = [grouped_alignedTrace_trial(group_loc).alignedTrace grouped_alignedTrace(gn).alignedTrace];
					else
						num_groups_trial = num_groups_trial+1;
						grouped_alignedTrace_trial(num_groups_trial).group = groups_roi{gn};
						grouped_alignedTrace_trial(num_groups_trial).alignedTrace = grouped_alignedTrace(gn).alignedTrace;
						grouped_alignedTrace_trial(num_groups_trial).normalization = grouped_alignedTrace(gn).normalization;
						grouped_alignedTrace_trial(num_groups_trial).timeInfo = alignedData_trial.time;
					end
				end
			end
		end
	end

	varargout{1} = num_disROI; % number of discarded ROIs (because they are lack of normalized data)
end