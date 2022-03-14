function [grouped_alignedTrace_trial,varargout] = group_aligned_eventTrace_trial(alignedData_trial,varargin)
	% Get the index of events belongs to different categories

	% alignedData_trial: aligned data of a single trial

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

	for n = 1:num_roi
		alignedTrace = roiData(n).value;
		peakCategories = {roiData(n).eventProp.peak_category};
		amp_data = [roiData(n).eventProp.peak_mag_delta];

		[grouped_alignedTrace] = group_aligned_eventTrace(alignedTrace,peakCategories,...
			'amp_data', amp_data);

		if n == 1
			grouped_alignedTrace_trial = grouped_alignedTrace;
		else
			groups_trial = {grouped_alignedTrace_trial.group};
			groups_roi = {grouped_alignedTrace.groups};

			num_groups_trial = numel(groups_trial);
			num_groups_roi = numel(groups_roi);
			for gn = 1:num_groups_roi
				group_loc = find(strcmpi(groups_roi{gn}, groups_trial));
				if ~isempty(group_loc) % concatenate roi aligned trace to existing trial data if groups exist in trial data
					grouped_alignedTrace_trial(group_loc).alignedTrace = [grouped_alignedTrace_trial(group_loc).alignedTrace grouped_alignedTrace(gn).alignedTrace];
				else
					num_groups_trial = num_groups_trial+1;
					grouped_alignedTrace_trial(num_groups_trial).group = groups_roi{gn};
					grouped_alignedTrace_trial(num_groups_trial).alignedTrace = grouped_alignedTrace(gn).idx;
				end
			end
		end
	end
end