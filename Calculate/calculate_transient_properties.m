function [transient_properties,varargout] = calculate_transient_properties(roi_trace,time_info,peakMag,peakLoc,varargin)
    % find and calculate transient/peak properties 
    %   Detailed explanation goes here

    % Defaults
    slope_per_low  = 0.1; % percentage of peak value (low) to calculate slope
    slope_per_high = 0.9; % percentage of peak value (high) to calculate slope
    extension_time_pre = 0.5; % extend the time window by subtracting rise_time with this
    extension_time_post = 1; % extend the time window by adding decay_time with this

    % Optionals
    for ii = 1:2:(nargin-4)
    	if strcmpi('slope_per_low', varargin{ii})
    		slope_per_low = varargin{ii+1};
    	elseif strcmpi('slope_per_high', varargin{ii})
    		slope_per_high = varargin{ii+1};
    	elseif strcmpi('existing_peakInfo', varargin{ii})
            existing_peakInfo = varargin{ii+1};
        elseif strcmpi('extension_time_pre', varargin{ii})
            extension_time_pre = varargin{ii+1};
        elseif strcmpi('extension_time_post', varargin{ii})
            extension_time_post = varargin{ii+1};
        end
    end

    recFreq = 1/(time_info(10)-time_info(9)); % recording sampling frequency
    [eventWin,eventWin_idx] = get_event_win(peakLoc,time_info,'pre_peakTime',2,'post_peakTime',5); % get time windows for each peak
    if ~isempty(peakLoc) % if there are peak(s) in the trace
        if ~exist('existing_peakInfo', 'var')
    	   [rise_decay_loc] = FindRiseandDecay(roi_trace,peakLoc); % find the locations of rise, decay, check_start and check_end for every peak
        else
            [rise_decay_loc] = FindRiseandDecay_with_existing_peakinfo(roi_trace,peakLoc,existing_peakInfo,...
                'eventWin_idx',eventWin_idx);    
        end
    	rise_loc = rise_decay_loc.rise_loc;
    	decay_loc = rise_decay_loc.decay_loc;

        % Discard events in which rise_loc bigger than peakLoc
        invalid_idx = rise_loc >= peakLoc;
        peakLoc(invalid_idx) = [];
        peakMag(invalid_idx) = [];
        rise_loc(invalid_idx) = [];
        decay_loc(invalid_idx) = [];

        if ~isempty(peakLoc)
            % Extract other event properties
            peak_time = time_info(peakLoc);
        	rise_time = time_info(rise_loc);
        	decay_time = time_info(decay_loc);
        	rise_duration = peak_time-rise_time;
        	decay_duration = decay_time-peak_time;

        	peakMag_delta = peakMag-roi_trace(rise_loc); % delta peakmag: subtract rising point value
        	peakMag_10per_target = peakMag_delta*slope_per_low+roi_trace(rise_loc); % 10% peakmag value
        	peakMag_90per_target = peakMag_delta*slope_per_high+roi_trace(rise_loc); % 90% peakmag value

        	peakLoc_10per = FindClosest_multiWindows(roi_trace, peakMag_10per_target, [rise_loc peakLoc]);
        	peakLoc_90per = FindClosest_multiWindows(roi_trace, peakMag_90per_target, [rise_loc peakLoc]);
        	peakMag_10per = roi_trace(peakLoc_10per);
        	peakMag_90per = roi_trace(peakLoc_90per);
        	peakTime_10per = time_info(peakLoc_10per);
        	peakTime_90per = time_info(peakLoc_90per);

        	value_diff_10_90per = peakMag_90per-peakMag_10per; % differences of 10per and 90per peak in magnitude
        	time_diff_10_90per = peakTime_90per-peakTime_10per; % differences of 10per and 90per peak in time
        	peakSlope = value_diff_10_90per./time_diff_10_90per;

        	transient_properties = [peakLoc, peakMag, rise_loc, decay_loc, peak_time,...
        	rise_time, decay_time, rise_duration, decay_duration, peakMag_delta,...
        	peakLoc_10per, peakMag_10per, peakTime_10per, peakLoc_90per, peakMag_90per,...
        	peakTime_90per, peakSlope];

        	if nargout == 2
        		varargout{1} = rise_decay_loc;
        	end
        else
            transient_properties = double.empty(0, 17);
            transient_properties = num2cell(transient_properties);
            if nargout == 2
                varargout{1} = [];
            end
        end
	else
		transient_properties = double.empty(0, 17);
		transient_properties = num2cell(transient_properties);
		if nargout == 2
    		varargout{1} = [];
    	end
    end
end

