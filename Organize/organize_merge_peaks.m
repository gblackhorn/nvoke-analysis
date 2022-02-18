function [peakMag_merge,peakLoc_merge,varargout] = organize_merge_peaks(peakMag,peakLoc,time_info,varargin)
    % merge adjacent peaks
    
    %	highpass_data_std: output of function "organize_transient_properties" using 'highpass' filter

    % Defaults
    merge_time_interval = 0.5; % default: 0.5s. peak to peak interval.

    % Optionals for inputs
    for ii = 1:2:(nargin-3)
    	if strcmpi('merge_time_interval', varargin{ii})
    		merge_time_interval = varargin{ii+1};
        end
    end

    % Main content
    peakMag_merge = peakMag; 
    peakLoc_merge = peakLoc; 
    peak_time = time_info(peakLoc); % find the time of peaks using time_info and peak locations (index)
    peak_time_interval = diff(peak_time);

    short_intervals = find(peak_time_interval<=merge_time_interval);
    peak_num = length(peakLoc);
    for n = 1:(peak_num-1)
        if ~isempty(find(short_intervals == n))
            if peakMag_merge(n) < peakMag_merge(n+1)
                peakMag_merge(n) = NaN;
                peakLoc_merge(n) = NaN;
            end
        end
    end
    discard_peak_idx = find(isnan(peakMag_merge));
    peakMag_merge(discard_peak_idx) = [];
    peakLoc_merge(discard_peak_idx) = [];
end

