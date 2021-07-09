function [closest_loc] = FindClosest_multiWindows(roi_trace,ideal_value,window_range)
    % find locations of points close to the given values (ideal_value) in every
    % window in roi_trace
    %   roi_trace: trace information of a single roi
    %   ideal_value: a single column array of numbers
    %   window_range: 2-column array. Has the same number of rows like ideal_value
    
    closest_loc = NaN(size(ideal_value));
    for n = 1:length(ideal_value)
    	[diff_value, loc_in_window] = min(abs(roi_trace(window_range(n, 1):window_range(n, 2))-ideal_value(n)));
    	closest_loc(n) = window_range(n, 1)-1+loc_in_window;
    end
end

