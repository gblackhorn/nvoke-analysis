function [merged_peak,varargout] = calculate_merged_peak_properties(peak1,peak2,roi_trace,time_info,varargin)
    % merge adjacent peaks
    
    %
    
    % Defaults
    slope_per_low  = 0.1; % percentage of peak value (low) to calculate slope
    slope_per_high = 0.9; % percentage of peak value (high) to calculate slope

    % Optionals for inputs
    for ii = 1:2:(nargin-5)
        if strcmpi('slope_per_low', varargin{ii})
            slope_per_low = varargin{ii+1};
        elseif strcmpi('slope_per_high', varargin{ii})
            slope_per_high = varargin{ii+1};
        end
    end

    % Main contents
    merged_peak = peak2;

    merged_peak.rise_loc = peak1.rise_loc;
    merged_peak.rise_time = peak1.rise_time;
    merged_peak.rise_duration = merged_peak.peak_time-merged_peak.rise_time;

    merged_peak.peak_mag_delta = merged_peak.peak_mag-roi_trace(merged_peak.rise_loc);
    peakMag_10per_target = merged_peak.peak_mag_delta*slope_per_low+roi_trace(merged_peak.rise_loc); % 10% peakmag value
    peakMag_90per_target = merged_peak.peak_mag_delta*slope_per_high+roi_trace(merged_peak.rise_loc); % 90% peakmag value

    merged_peak.peak_loc_10percent = FindClosest_multiWindows(roi_trace, peakMag_10per_target, [merged_peak.rise_loc merged_peak.peak_loc]);
    merged_peak.peak_loc_90percent = FindClosest_multiWindows(roi_trace, peakMag_90per_target, [merged_peak.rise_loc merged_peak.peak_loc]);
    merged_peak.peak_mag_10percent = roi_trace(merged_peak.peak_loc_10percent);
    merged_peak.peak_mag_90percent = roi_trace(merged_peak.peak_loc_90percent);
    merged_peak.peak_time_10percent = time_info(merged_peak.peak_loc_10percent);
    merged_peak.peak_time_90percent = time_info(merged_peak.peak_loc_90percent);

    value_diff_10_90per = merged_peak.peak_mag_90percent-merged_peak.peak_mag_10percent; % differences of 10per and 90per peak in magnitude
    time_diff_10_90per = merged_peak.peak_time_90percent-merged_peak.peak_time_10percent; % differences of 10per and 90per peak in time
    merged_peak.peak_slope = value_diff_10_90per./time_diff_10_90per;
end

