function [event_info,varargout] = get_events_info(events_time,condition_win,peak_properties_table,varargin)
    % Return sorted event according to condition windows, such as stimulation, rebound windows, etc.
    %   events_time: a number array containing the time of events. Can be rise_time or peak_time from peak_properties_table
    %   condition_win: nx2 array. 1st col is the lower bound, 2nd col is the upper bound
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 
    %   event_idx: the idx of events in events_time/peak_properties_table

    events_time = events_time';
    % event_info.idx_in_peak_table = find(any(events_time>=condition_win(:, 1) & events_time<condition_win(:, 2)))';
    % event_info.events_time = events_time(event_info.idx_in_peak_table)';

    win_num = size(condition_win, 1);
    idx_in_peak_table_cell = cell(win_num, 1);
    event_time_cell = cell(win_num, 1);
    event_interval_time_cell = cell(win_num, 1);
    for n = 1:win_num
        idx_in_peak_table_cell{n} = find(events_time>=condition_win(n, 1) & events_time<condition_win(n, 2))';
        event_time_cell{n} = events_time(idx_in_peak_table_cell{n})';
        event_interval_time_cell{n} = diff(event_time_cell{n});
    end

    event_info.idx_in_peak_table = vertcat(idx_in_peak_table_cell{:});
    event_info.events_time = vertcat(event_time_cell{:});

    event_info.events_interval_time = vertcat(event_interval_time_cell{:});
    event_info.events_interval_time_mean = mean(event_info.events_interval_time);

    event_info.rise_time = peak_properties_table.rise_time(event_info.idx_in_peak_table);
    event_info.rise_loc = peak_properties_table.rise_loc(event_info.idx_in_peak_table);
    event_info.rise_duration = peak_properties_table.rise_duration(event_info.idx_in_peak_table);
    event_info.rise_duration_mean = mean(event_info.rise_duration);

    event_info.peak_time = peak_properties_table.peak_time(event_info.idx_in_peak_table);
    event_info.peak_loc = peak_properties_table.peak_loc(event_info.idx_in_peak_table);

    event_info.peak_mag = peak_properties_table.peak_mag(event_info.idx_in_peak_table);
    event_info.peak_mag_mean = mean(event_info.peak_mag);

    event_info.peak_mag_norm = peak_properties_table.peak_delta_norm_hpstd(event_info.idx_in_peak_table);
    event_info.peak_mag_norm_mean = mean(event_info.peak_mag_norm);

    event_info.peak_slope = peak_properties_table.peak_slope(event_info.idx_in_peak_table);
    event_info.peak_slope_mean = mean(event_info.peak_slope);
    
    event_info.peak_slope_norm_hpstd = peak_properties_table.peak_slope_norm_hpstd(event_info.idx_in_peak_table);
    event_info.peak_slope_norm_hpstd_mean = mean(event_info.peak_slope_norm_hpstd);
end