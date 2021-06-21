function [roi_trace_processed,varargout] = process_roi_trace_with_filter(roi_trace,varargin)
    % process a single roi trace with filter, such as 'lowpass' and 'smooth'
    %   roi_trace: a trace data of a single roi
    %   varargin string-value pairs: 'filter', 'filter_par', 'prom_par', 'recording_fq', 'decon', 'time_info', 'smooth_method'
    %   'filter': 'none', 'lowpass', 'smooth', 'highpass'
    %   'prom_par': value of prominence_factor. not needed for 'highpass'. prominence = (max(roi_trace)-min(roi_trace))/prominence_factor
    %   'filter_par': value in Hz for filter 'lowpass' and 'highpass', or span if 'smooth' is choosen
    %   'recording_fq': recording frequency. needed for lowpass and highpass process
    %   'time_info': an array including time information paired with roi_trace
    %   'smooth_method': for smooth process, default = 'loess'

    % Defaults
    filter_chosen = 'none';
    filter_parameter = 1; % default Hz for lowpass filter
    rec_fq = 10; % recording frequency in Hz
    time_info = (1:length(roi_trace))'/10; % default for 10 Hz
    smooth_method = 'loess';

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('filter', varargin{ii})
    		filter_chosen = varargin{ii+1};
    	elseif strcmpi('filter_par', varargin{ii})
    		filter_parameter = varargin{ii+1};
		elseif strcmpi('recording_fq', varargin{ii})
			rec_fq = varargin{ii+1};
		elseif strcmpi('time_info', varargin{ii}) % needed for smooth process
			time_info = varargin{ii+1};
    	end
    end

    filter_name = filter_chosen;

    % process trace and find peaks
    if strcmpi('highpass', filter_chosen)
    	roi_trace_processed = highpass(roi_trace, filter_parameter, rec_fq);
    	peak_par.std = std(roi_trace);
    	look_for_peaks = 0; % Don't look for peak if traces are highpass filtered
    else
    	if strcmpi('none', filter_chosen)
    		roi_trace_processed = roi_trace;
    		filter_parameter = NaN;
    	elseif strcmpi('lowpass', filter_chosen)
    		roi_trace_processed = lowpass(roi_trace, filter_parameter, rec_fq);
	    elseif strcmpi('smooth', filter_chosen)
	    	roi_trace_processed = smooth(time_info, roi_trace, filter_parameter, smooth_method);
	    	filter_name = [filter_name, '_', smooth_method];
	    end
    end

	if nargout == 2 % return the processed trace data and processing method
		varargout{1}.method = filter_name;
		varargout{1}.parameter = filter_parameter;
	end
end


