function [peak_mag,peak_loc] = find_peaks_in_windows(roi_trace_window,window_start_time_index,varargin)
    % find a single peak in each column of roi_trace_window, which is a matrix
    % containing data from a single roi trace. Each column contains data from a
    % window.
    %   Detailed explanation goes here

    % Defaults
    errVal = 6; % maximum idx difference between found peak and existing peak in the same window

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('existing_peakLoc', varargin{ii})
            existing_peakLoc = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('existing_riseLoc', varargin{ii})
            existing_peakLoc = varargin{ii+1};
        end
    end   

    window_num = size(roi_trace_window, 2);
    peak_mag = NaN(window_num, 1);
    peak_loc = NaN(window_num, 1);
    for wn = 1:window_num
    	[peak_mag_win, peak_loc_win] = findpeaks(roi_trace_window(:, wn));
    	if ~isempty(peak_loc_win)
    		% select the biggest peak
    		% peak_mag(wn) = max(peak_mag_win);
    		% peak_loc(wn) = window_start_time_index(wn)-1+peak_loc_win(find(peak_mag_win == peak_mag(wn)));

            % Find the closest loc of peak to existing_peakLoc
            loc = window_start_time_index(wn)-1+peak_loc_win;
            if numel(loc) > 1 
                if exist('existing_peakLoc', 'var')
                    loc_diff = abs(loc-existing_peakLoc(wn));
                    [~, idx] = min(loc_diff);
                    loc_single = loc(idx);
                    
                    if abs(loc_single-existing_peakLoc(wn)) <= errVal
                        peak_loc(wn) = loc_single;
                        peak_mag(wn) = peak_mag_win(idx);
                    end

                    if exist('existing_riseLoc', 'var')
                        if peak_loc(wn)-existing_riseLoc(wn) < 0
                            peak_loc(wn) = NaN;
                            peak_mag(wn) = NaN;
                        end
                    end
                else
                    [~, idx] = max(peak_mag_win);
                    peak_loc(wn) = loc(idx);
                    peak_mag(wn) = peak_mag_win(idx);
                end
            else
                peak_loc(wn) = loc;
                peak_mag(wn) = peak_mag_win;
            end
        else

    	end
    end
    empty_peak_row = find(isnan(peak_loc));
    peak_mag(empty_peak_row) = [];
    peak_loc(empty_peak_row) = [];
end

