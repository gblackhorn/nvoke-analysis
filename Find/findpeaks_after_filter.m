function [peak_par,varargout] = findpeaks_after_filter(roi_trace,varargin)
    % process a single roi trace with filter, such as 'lowpass' and 'smooth',
    % and find peaks in processed trace data. Return peak parameters in peak_par. 
    % When 'highpass' filter is used, func returns std of processed trace
    % peak_par is a structure varible including peakMag, peakLoc, peakWidth and peakProm. or std ('highpass')
    %   roi_trace: a trace data of a single roi
    %   varargin string-value pairs: 'filter', 'filter_par', 'prom_par', 'recording_fq', 'decon', 'time_info', 'smooth_method'
    %   'filter': 'none', 'lowpass', 'smooth', 'highpass'
    %   'prom_par': value of prominence_factor. not needed for 'highpass'. prominence = (max(roi_trace)-min(roi_trace))/prominence_factor
    %   'filter_par': value in Hz for filter 'lowpass' and 'highpass', or span if 'smooth' is choosen
    %   'recording_fq': recording frequency. needed for lowpass and highpass process
    %   'time_info': an array including time information paired with roi_trace
    %   'smooth_method': for smooth process, default = 'loess'
    %
    % varargout： a structure variable including processed_trace, method, and parameter

    % Defaults
    filter_chosen = 'none';
    prominence_factor = 4;
    filter_parameter = 1; % default Hz for lowpass filter
    rec_fq = 10; % recording frequency in Hz
    decon = 0;
    time_info = (1:length(roi_trace))'/10; % default for 10 Hz
    smooth_method = 'loess';
    merge_peaks = false;
    merge_time_interval = 0.5;

    % Optionals
    for ii = 1:2:(nargin-1)
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
    	elseif strcmpi('merge_peaks', varargin{ii}) % needed for smooth process
            merge_peaks = varargin{ii+1};
        elseif strcmpi('merge_time_interval', varargin{ii})
            merge_time_interval = varargin{ii+1};
        end
    end

    filter_name = filter_chosen;

    % process trace and find peaks
    if decon == 1
    	% [peak_par.peakMag, peak_par.peakLoc, peak_par.peakWidth, peak_par.peakProm] = findpeaks(roi_trace);
        [peak_par.peakMag, peak_par.peakLoc] = findpeaks(roi_trace);
        if merge_peaks == true
            [peak_par.peakMag, peak_par.peakLoc] = organize_merge_peaks(peak_par.peakMag,...
                peak_par.peakLoc,...
                time_info, 'merge_time_interval', merge_time_interval); % merge 
        end
    	filter_name = 'none';
    	filter_parameter = NaN;
    elseif decon == 0
	    if strcmpi('highpass', filter_chosen)
	    	roi_trace = highpass(roi_trace, filter_parameter, rec_fq);
	    	peak_par.std = std(roi_trace);
	    	look_for_peaks = 0; % Don't look for peak if traces are highpass filtered
	    else
	    	if strcmpi('none', filter_chosen)
	    		roi_trace = roi_trace;
	    		filter_parameter = NaN;
	    	elseif strcmpi('lowpass', filter_chosen)
	    		roi_trace = lowpass(roi_trace, filter_parameter, rec_fq);
		    elseif strcmpi('smooth', filter_chosen)
		    	roi_trace = smooth(time_info, roi_trace, filter_parameter, smooth_method);
		    	filter_name = [filter_name, '_', smooth_method];
		    end
		    prominence = (max(roi_trace)-min(roi_trace))/prominence_factor;
		    % [peak_par.peakMag, peak_par.peakLoc, peak_par.peakWidth, peak_par.peakProm] = findpeaks(roi_trace, 'MinPeakProminence', prominence);
            [peak_par.peakMag, peak_par.peakLoc] = findpeaks(roi_trace, 'MinPeakProminence', prominence);
	    end
	end
	if nargout == 2 % return the processed trace data and processing method
		varargout{1}.processed_trace = roi_trace;
		varargout{1}.method = filter_name;
		varargout{1}.parameter = filter_parameter;
	end
end

