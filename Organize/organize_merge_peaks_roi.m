function [peak_properties_table_updated,varargout] = organize_merge_peaks_roi(peak_properties_table,time_info,roi_trace,varargin)
    % merge adjacent peaks
    
    %
    
    % Defaults
    merge_time_interval = 0.5; % default: 0.5s. peak to peak interval.

    % Optionals for inputs
    for ii = 1:2:(nargin-3)
    	if strcmpi('merge_time_interval', varargin{ii})
    		merge_time_interval = varargin{ii+1};
        elseif strcmpi('slope_per_low', varargin{ii})
            slope_per_low = varargin{ii+1};
        elseif strcmpi('slope_per_high', varargin{ii})
            slope_per_high = varargin{ii+1};
        end
    end

    % Main contents
    peak_properties_table_updated = peak_properties_table;

    peakMag = peak_properties_table_updated.peak_mag;
    peakLoc = peak_properties_table_updated.peak_loc;
    peak_num = length(peakLoc);

    peak_time = time_info(peakLoc);
    peak_time_interval = diff(peak_time);

    short_intervals = find(peak_time_interval<=merge_time_interval);
    if ~isempty(short_intervals)
        for n = 1:length(short_intervals)
            peak1_idx = short_intervals(n);
            peak2_idx = peak1_idx+1;

            if peakMag(n) < peakMag(n+1) % when 2 peaks are too close (interval shorter than merge_time_interval), and second peak is bigger than first one
                peak1 = peak_properties_table_updated(peak1_idx, :);
                peak2 = peak_properties_table_updated(peak2_idx, :);
                [merged_peak] = calculate_merged_peak_properties(peak1, peak2,...
                    roi_trace, time_info,...
                    'slope_per_low', slope_per_low, 'slope_per_high', slope_per_high);
                peak_properties_table_updated{peak1_idx, :} = NaN;
                peak_properties_table_updated(peak2_idx, :) = merged_peak;
            end
        end
    end

    discard_nan_idx = find(isnan(peak_properties_table_updated{:, 1}));
    peak_properties_table_updated(discard_nan_idx, :) = [];
end

