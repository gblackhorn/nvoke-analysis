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