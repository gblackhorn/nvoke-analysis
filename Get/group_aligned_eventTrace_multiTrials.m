function [grouped_alignedTrace_all,varargout] = group_aligned_eventTrace_multiTrials(alignedData,varargin)
	% Group the aligned event traces from multiple trials according to the event category

	% alignedData: structure var. aligned data of a multiple trials

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
	stim_names = {alignedData.stim_name};
	[stimGroupInfo,stimGroupNum,stimGroupName] = get_category_idx(stim_names);

	grouped_alignedTrace_all = struct('stimGroup', cell(1, stimGroupNum), 'eventTrace', cell(1, stimGroupNum));

	for n = 1:stimGroupNum
		grouped_alignedTrace_all(n).stimGroup = stimGroupName{n};

		data_stimSpecific = alignedData(stimGroupInfo(n).idx);
		num_trial = numel(data_stimSpecific);

		for tn = 1:num_trial
			data_trial = data_stimSpecific(tn);

			[grouped_alignedTrace_trial] = group_aligned_eventTrace_trial(data_trial,...
				'pc_norm', pc_norm, 'normData', normData);

			if isempty(grouped_alignedTrace_all(n).eventTrace)
				grouped_alignedTrace_all(n).eventTrace = grouped_alignedTrace_trial;
			else
				eventTypes_exist = {grouped_alignedTrace_all(n).eventTrace.group};
				eventTypes_new = {grouped_alignedTrace_trial.group};

				num_eventTypes_exist = numel(eventTypes_exist);
				num_eventTypes_new = numel(eventTypes_new);
				for en = 1:num_eventTypes_new
					typeLoc = find(strcmpi(eventTypes_new{en}, eventTypes_exist));
					if ~isempty(typeLoc)
						grouped_alignedTrace_all(n).eventTrace(typeLoc).alignedTrace = [grouped_alignedTrace_all(n).eventTrace(typeLoc).alignedTrace grouped_alignedTrace_trial(en).alignedTrace];
					else
						num_eventTypes_exist = num_eventTypes_exist+1;
						grouped_alignedTrace_all(n).eventTrace(typeLoc).group = eventTypes_new{en};
						grouped_alignedTrace_all(n).eventTrace(typeLoc).alignedTrace = grouped_alignedTrace_trial(gn).alignedTrace;
						grouped_alignedTrace_all(n).eventTrace(typeLoc).normalization = grouped_alignedTrace_trial(gn).normalization;
						grouped_alignedTrace_all(n).eventTrace(typeLoc).timeInfo = grouped_alignedTrace_trial(gn).timeInfo;
					end
				end
			end
		end
	end
end