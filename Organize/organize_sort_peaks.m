function [event_idx,varargout] = organize_sort_peaks(events_time,condition_win,peak_properties_table,varargin)
    % Return sorted event according to condition windows, such as stimulation, rebound windows, etc.
    %   events_time: a number array containing the time of events. Can be rise_time or peak_time from peak_properties_table
    %   condition_win: nx2 array. 1st col is the lower bound, 2nd col is the upper bound
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 
    %   event_idx: the idx of events in events_time/peak_properties_table

    events_time = events_time';
    event_idx = find(any(events_time>=condition_win(:, 1) & events_time<condition_win(:, 2)));
    event_info.event_num = length(event_idx);
    event_info.rise_time = peak_properties_table.rise_time(event_idx);
    event_info.rise_loc = peak_properties_table.rise_loc(event_idx);
    event_info.peak_time = peak_properties_table.peak_time(event_idx);
    event_info.peak_loc = peak_properties_table.peak_loc(event_idx);

    varargout{1} = event_info;
end