function [alignedData_filtered,varargout] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,varargin)
	% Filter the ROIs in alignedData_allTrials(x).traces with the field of "stimEffect"
	% Stimulation_name is used to adjust the filter
	% 'stimEffect' field contains 3 fields: 'excitation', 'inhibition' and 'rebound'

	% Example:
	%	[alignedData_allTrials_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials) 
	%		

	% Defaults
	stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('stim_names', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        stim_names = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('filters', varargin{ii})
            filters = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents

	% If stim_names only contain one name, such as 'og-5s'. Put this character var into a cell.
	if isa(stim_names,'char')
		stim_names = {stim_names}; 
	end

	% if filters only has a 1*4 numerica array. Put the filters in a cell array
	if isa(filters,'numeric')
		filters = {filters};
	end 


	alignedData_filtered = alignedData;
	trial_num = numel(alignedData_filtered);

	roiNum_all = 0;
	roiNum_kept = 0;
	roiNum_dis = 0;

	% Filter the trials one by one
	for tn = 1:trial_num
		trialData = alignedData_filtered(tn); % data of a single trial
		roiNum_all = roiNum_all+numel(trialData.traces);

		% Check the stimulation used in a trial and decide what filter to use
		stimName = trialData.stim_name; % stimulation used in this trial
		filter_idx = find(strcmpi(stim_names,stimName)); % look for stimName in the stim_names
		if ~isempty(filter_idx) 
			filter_chosen = filters{filter_idx}; % Get the filter logical array
			screen_data_tf = true; % run filter
		else
			screen_data_tf = false; % do not run filter
		end


		% Filter the ROIs in the trials using a specific filter 
		if screen_data_tf
			[trialData.traces,roi_idx] = Filter_AlignedDataTraces_withStimEffect(trialData.traces,...
				'ex',filter_chosen(1),'in',filter_chosen(2),'rb',filter_chosen(3),'exApOg',filter_chosen(4));

			% Assign the filtered ROIs to alignedData_filtered.traces
			alignedData_filtered(tn) = trialData;
			roiNum_kept = roiNum_kept+numel(roi_idx);
		end
	end
	roiNum_dis = roiNum_all-roiNum_kept;

	varargout{1} = roiNum_all;
	varargout{2} = roiNum_kept;
	varargout{3} = roiNum_dis;
end