function [peak_par,varargout] = find_peaks_with_existing_peakinfo(roi_trace,existing_peakInfo,varargin)
    % Locate peaks/transients with existing peak information and export new peak
    % information
    %   roi_trace: It must be a column vector
    %		- 1st col: time infomation
    %		- 2nd-end col: traces
    %   existing_peakInfo: a table variable including peak/transient information (the locations of peak, rise and decay)

    % TransientProperties_col_names = {'peak_loc', 'peak_mag', 'rise_loc', 'decay_loc','peak_time',...
	% 'rise_time', 'decay_time', 'rise_duration', 'decay_duration', 'peak_mag_relative',...
	% 'peak_loc_25percent', 'peak_mag_25percent', 'peak_time_25percent', 'peak_loc_75percent', 'peak_mag_75percent',...
	% 'peak_time_75percent', 'peak_slope', 'peak_zscore'};

    % Defaults
    peakErrTime = 0.4; % time (s). When using 'find_peaks_in_windows', this is the max distance between the existing peak and found peak 
    filter_chosen = 'none';
    % prominence_factor = 4;
    filter_parameter = 1; % default Hz for lowpass filter
    rec_fq = 20; % recording frequency in Hz
    decon = 0;
    time_info = (1:length(roi_trace))'/rec_fq; % Use default recording frequency "rec_fq" to create a time_info vector 
    smooth_method = 'loess';
    existing_peak_duration_extension_time_pre  = 0; % duration in second, before existing peak rise 
    existing_peak_duration_extension_time_post = 1; % duration in second, after peak

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('filter', varargin{ii})
    		filter_chosen = varargin{ii+1};
    	% elseif strcmpi('prom_par', varargin{ii})
    	% 	prominence_factor = varargin{ii+1};
    	elseif strcmpi('peakErrTime', varargin{ii})
    		peakErrTime = varargin{ii+1};
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
        % elseif strcmpi('merge_peaks', varargin{ii}) % needed for smooth process
        %     merge_peaks = varargin{ii+1};
        % elseif strcmpi('merge_time_interval', varargin{ii})
        %     merge_time_interval = varargin{ii+1};
    	end
    end

    % peakErrVal used in the function 'find_peaks_in_windows' below
    peakErrVal = peakErrTime*rec_fq;


    % smooth data: process trace with filter if needed
    [roi_trace_processed,filter_info] = process_roi_trace_with_filter(roi_trace,...
                'filter', filter_chosen, 'filter_par', filter_parameter,...
                'recording_fq', rec_fq, 'time_info', time_info); % 'decon', decon



    if ~isempty(existing_peakInfo)
        % Get a window for every existing peak
        [eventWin,eventWin_idx] = get_event_win(existing_peakInfo.peak_loc,...
            time_info,'riseLoc', existing_peakInfo.rise_loc);

        window_start_time_index = eventWin_idx(:, 1);
        window_end_time_index = eventWin_idx(:, 2);



        % Get trace data in event windows and concatenate them. Short windows are padded with NaN
    	[roi_trace_window] = organize_multiple_range_data_from_one_vector_in_matrix(roi_trace_processed,...
    		eventWin_idx);

    	[peak_par.peakMag, peak_par.peakLoc] = find_peaks_in_windows(roi_trace_window,window_start_time_index,...
            'existing_peakLoc', existing_peakInfo.peak_loc,'peakErrVal',peakErrVal);

        % if merge_peaks == true
        %     [peak_par.peakMag, peak_par.peakLoc] = organize_merge_peaks(peak_par.peakMag,...
        %         peak_par.peakLoc,...
        %         time_info, 'merge_time_interval', merge_time_interval); % merge 
        % end

    else
        peak_par.peakMag = [];
        peak_par.peakLoc = [];
    end
    varargout{1}.processed_trace = roi_trace_processed;
    varargout{1}.method = filter_info.method;
    varargout{1}.parameter = filter_info.parameter;
end

