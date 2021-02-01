function [peak_par,varargout] = find_peaks_with_existing_peakinfo(roi_trace,existing_peakInfo,varargin)
    % Locate peaks/transients with existing peak information and export new peak
    % information
    %   RecInfoTable: a table variable including time and traces info from 1 single ROI
    %		- 1st col: time infomation
    %		- 2nd-end col: traces
    %   PeakInfo: a table variable including peak/transient information (the locations of peak, rise and decay)

 %    TransientProperties_col_names = {'peak_loc', 'peak_mag', 'rise_loc', 'decay_loc','peak_time',...
	% 'rise_time', 'decay_time', 'rise_duration', 'decay_duration', 'peak_mag_relative',...
	% 'peak_loc_25percent', 'peak_mag_25percent', 'peak_time_25percent', 'peak_loc_75percent', 'peak_mag_75percent',...
	% 'peak_time_75percent', 'peak_slope', 'peak_zscore'};

    % Defaults
    filter_chosen = 'none';
    prominence_factor = 4;
    filter_parameter = 1; % default Hz for lowpass filter
    rec_fq = 10; % recording frequency in Hz
    decon = 0;
    time_info = (1:length(roi_trace))'/10; % default for 10 Hz
    smooth_method = 'loess';
    existing_peak_duration_extension_time_pre  = 0.3; % duration in second, before existing peak rise 
    existing_peak_duration_extension_time_post = 0; % duration in second, after decay

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('filter', varargin{ii})
    		filter_chosen = varargin{ii+1};
    	elseif strcmpi('prom_par', varargin{ii})
    		prominence_factor = varargin{ii+1};
    	elseif strcmpi('filter_par', varargin{ii})
    		filter_parameter = varargin{ii+1};
		elseif strcmpi('recording_fq', varargin{ii})
			rec_fq = varargin{ii+1};
		elseif strcmpi('decon', varargin{ii})
			decon = varargin{ii+1};
		elseif strcmpi('time_info', varargin{ii}) % needed for smooth process
			time_info = varargin{ii+1};
		elseif strcmpi('extension_time_pre', varargin{ii}) 
			existing_peak_duration_extension_time_pre = varargin{ii+1};
		elseif strcmpi('extension_time_post', varargin{ii}) 
			existing_peak_duration_extension_time_post = varargin{ii+1};
    	end
    end

    % main content
    if ~isempty(existing_peakInfo)
    	% process trace with filter if needed
    	[roi_trace_processed,filter_info] = process_roi_trace_with_filter(roi_trace,...
    				'filter', filter_chosen, 'filter_par', filter_parameter,...
    				'recording_fq', rec_fq, 'decon', decon, 'time_info', time_info);

    	% calculate ideal time for window starts and ends
    	window_start_time_ideal = time_info(existing_peakInfo.peak_loc)-existing_peak_duration_extension_time_pre;
    	window_end_time_ideal   = time_info(existing_peakInfo.decay_loc)+existing_peak_duration_extension_time_post;

    	% If window start time is smaller than timeinfo start or if window end time is bigger than timeinfo end
    	% set them to timeinfo start and end
    	ideal_min_idx = find(window_start_time_ideal<time_info(1));
    	ideal_max_idx = find(window_end_time_ideal>time_info(end));
    	window_start_time_ideal(ideal_min_idx) = time_info(1);
    	window_end_time_ideal(ideal_max_idx) = time_info(end);

    	[window_start_time, window_start_time_index] = find_closest_in_array(window_start_time_ideal,time_info);
    	[window_end_time, window_end_time_index] = find_closest_in_array(window_end_time_ideal,time_info);

    	[roi_trace_window] = organize_multiple_range_data_from_one_vector_in_matrix(roi_trace_processed,...
    		[window_start_time_index window_end_time_index]);

    	[peak_par.peakMag, peak_par.peakLoc] = find_peaks_in_windows(roi_trace_window,window_start_time_index);


    	if nargout == 2 % return the processed trace data and processing method
    		varargout{1}.processed_trace = roi_trace_processed;
    		varargout{1}.method = filter_info.method;
    		varargout{1}.parameter = filter_info.parameter;
    	end
    end
end
