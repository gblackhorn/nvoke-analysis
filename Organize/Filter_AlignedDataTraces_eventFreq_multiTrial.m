function [alignedData_filtered,varargout] = Filter_AlignedDataTraces_eventFreq_multiTrial(alignedData,varargin)
	% Filter the ROIs in alignedData_allTrials(x).traces with the field of "stimEffect"
	% Stimulation_name is used to adjust the filter
	% 'stimEffect' field contains 3 fields: 'excitation', 'inhibition' and 'rebound'

	% Example:
	%	[alignedData_allTrials_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials) 
	%		

	% Defaults
	freq_field = 'sponfq'; % name of the default field
	freq_thresh = 0.06; % Hz. 
	filter_direction = 'high'; % high/low. If high, the freq needs to be bigger than freq_thresh.
		% filter number must be equal to stim_names

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('freq_field', varargin{ii})
	        freq_field = varargin{ii+1};
	    elseif strcmpi('freq_thresh', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        freq_thresh = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('filter_direction', varargin{ii})
            filter_direction = varargin{ii+1};
	    end
	end

	% ====================
	% Chose the sign for the filter
	switch filter_direction
		case 'high'
			filter_sign = '>=';
		case 'low'
			filter_sign = '<=';
		otherwise
			error('function "Filter_AlignedDataTraces_eventFreq_multiTrial":filter_direction can only be high or low')
	end


	% Initiate the filter
	alignedData_filtered = alignedData;
	trial_num = numel(alignedData_filtered);

	roiNum_all = 0;
	roiNum_kept = 0;
	roiNum_dis = 0;


	% Filter the trials one by one
	for tn = 1:trial_num
		trialData = alignedData_filtered(tn); % data of a single trial
		roiNum_all = roiNum_all+numel(trialData.traces);


		% Filter the ROIs in the trials with a field containing numbers
		[trialData.traces,trialROI_kept] = Filter_AlignedDataTraces_eventFreq(trialData.traces,...
			'freq_field',freq_field,'freq_thresh',freq_thresh,'filter_direction',filter_direction);

		% Assign the filtered ROIs to alignedData_filtered.traces
		alignedData_filtered(tn) = trialData;
		roiNum_kept = roiNum_kept+trialROI_kept;
	end
	roiNum_dis = roiNum_all-roiNum_kept;

	varargout{1} = roiNum_all;
	varargout{2} = roiNum_kept;
	varargout{3} = roiNum_dis;
	varargout{4} = sprintf('%d/%d ROIs from %d trials are kept (filter: %s %s %g Hz)',...
	    roiNum_kept,roiNum_all,trial_num,freq_field,filter_sign,freq_thresh);
end

function [alignedDataTraces_filtered,varargout] = Filter_AlignedDataTraces_eventFreq(alignedDataTraces,varargin)
	% Filter the alignedData_allTrials(x).traces with its field "sponfq"

	freq_field = 'sponfq'; % name of the default field
	freq_thresh = 0.06; % Hz. 
	filter_direction = 'high'; % high/low. If high, the freq needs to be bigger than freq_thresh.


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('freq_field', varargin{ii})
	        freq_field = varargin{ii+1};
	    elseif strcmpi('freq_thresh', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        freq_thresh = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('filter_direction', varargin{ii})
            filter_direction = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end

	% ====================
	roi_num = numel(alignedDataTraces);
	tf_idx = logical(ones(1,roi_num)); % default: keep all ROIs

	freq_all = [alignedDataTraces.(freq_field)]; % get the event frequencies from all ROIs


	switch filter_direction
		case 'high'
			idx_dis = find(freq_all<freq_thresh);
			filter_sign = '>=';
		case 'low'
			idx_dis = find(freq_all>freq_thresh);
			filter_sign = '<=';
		otherwise
			error('function "Filter_AlignedDataTraces_eventFreq":filter_direction can only be high or low')
	end

	tf_idx(idx_dis) = false;
	disNum = length(idx_dis);
	keptNum = roi_num-disNum;

	alignedDataTraces_filtered = alignedDataTraces(tf_idx);
	varargout{1} = keptNum;
	varargout{2} = sprintf('%d/%d ROIs are kept (filter: %s %s %g Hz)',...
	    keptNum,roi_num,freq_field,filter_sign,freq_thresh);
end