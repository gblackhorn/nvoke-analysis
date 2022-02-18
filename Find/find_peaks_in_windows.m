function [peak_mag,peak_loc] = find_peaks_in_windows(roi_trace_window,window_start_time_index)
    % find a single peak in each column of roi_trace_window, which is a matrix
    % containing data from a single roi trace. Each column contains data from a
    % window.
    %   Detailed explanation goes here

    window_num = size(roi_trace_window, 2);
    peak_mag = NaN(window_num, 1);
    peak_loc = NaN(window_num, 1);
    for wn = 1:window_num
    	[peak_mag_win, peak_loc_win] = findpeaks(roi_trace_window(:, wn));
    	if ~isempty(peak_mag_win)
    		% select the biggest peak
    		peak_mag(wn) = max(peak_mag_win);
    		peak_loc(wn) = window_start_time_index(wn)-1+peak_loc_win(find(peak_mag_win == peak_mag(wn)));
    	end
    end
    empty_peak_row = find(isnan(peak_mag));
    peak_mag(empty_peak_row) = [];
    peak_loc(empty_peak_row) = [];
end

