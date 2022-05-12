function [event_info,varargout] = get_events_info(all_events_time,condition_win,peak_properties_table,varargin)
    % Return sorted event according to condition windows, such as stimulation, rebound windows, etc.
    %   all_events_time: a number array containing the time of events. Can be rise_time or peak_time from peak_properties_table
    %   condition_win: nx2 array. 1st col is the lower bound, 2nd col is the upper bound
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 

    % Defaults
    style = 'roi'; % options: 'roi' or 'event'
                    % 'roi': All events are stored in a length-1 struct. mean values are calculated. 
                    % 'event': events are seperated (struct length = events_num). mean values are not calculated
    cal_interval = false; % calculte the events intervals or not

    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('style', varargin{ii})
            style = varargin{ii+1}; % options: 'roi' or 'event'
        elseif strcmpi('cal_interval', varargin{ii})
            cal_interval = varargin{ii+1}; 
        end
    end


    % ====================
    % Main contents
    if ~isempty(condition_win)
        [freq,events_interval_time,idx_in_peak_table,events_time] = get_event_freq_interval(all_events_time,condition_win);

        all_events_time = all_events_time';
        win_num = size(condition_win, 1);
        idx_in_peak_table_cell = cell(win_num, 1);
        event_time_cell = cell(win_num, 1);
        event_interval_time_cell = cell(win_num, 1);
        for n = 1:win_num
            idx_in_peak_table_cell{n} = find(all_events_time>=condition_win(n, 1) & all_events_time<condition_win(n, 2))';
            event_time_cell{n} = all_events_time(idx_in_peak_table_cell{n})';
            event_interval_time_cell{n} = diff(event_time_cell{n});
        end

        idx_in_peak_table = vertcat(idx_in_peak_table_cell{:});
        events_time = vertcat(event_time_cell{:});
        events_interval_time = vertcat(event_interval_time_cell{:});
    else
        idx_in_peak_table = [1:size(peak_properties_table, 1)];
        events_time = peak_properties_table.rise_time(idx_in_peak_table);
        % [~, idx_in_peak_table] = intersect(events_value, events_time, 'stable');
        % events_time = events_value;
        events_interval_time = diff(events_time);
    end

    if cal_interval && strcmp(style, 'roi')
        events_interval_time_mean = mean(events_interval_time);
    else
        clear events_interval_time
        clear freq
    end

    event_num = length(events_time);
    rise_time = peak_properties_table.rise_time(idx_in_peak_table);
    rise_loc = peak_properties_table.rise_loc(idx_in_peak_table);
    rise_duration = peak_properties_table.rise_duration(idx_in_peak_table);
    peak_time = peak_properties_table.peak_time(idx_in_peak_table);
    peak_loc = peak_properties_table.peak_loc(idx_in_peak_table);
    peak_mag_delta = peak_properties_table.peak_mag_delta(idx_in_peak_table);
    peak_delta_norm_hpstd = peak_properties_table.peak_delta_norm_hpstd(idx_in_peak_table);
    peak_slope = peak_properties_table.peak_slope(idx_in_peak_table);
    peak_slope_norm_hpstd = peak_properties_table.peak_slope_norm_hpstd(idx_in_peak_table);
    peak_category = peak_properties_table.peak_category(idx_in_peak_table);

    switch style
        case 'roi'
            % event_info.idx_in_peak_table = idx_in_peak_table;
            event_info.event_num = event_num;
            event_info.events_time = events_time;

            if exist('events_interval_time', 'var')
                event_info.events_interval_time = events_interval_time;
                event_info.events_interval_time_mean = events_interval_time_mean;
            end
            if exist('freq', 'var')
            event_info.freq = freq;
            end

            event_info.rise_time = rise_time;
            event_info.rise_loc = rise_loc;
            event_info.rise_duration = rise_duration;
            event_info.rise_duration_mean = mean(event_info.rise_duration);

            event_info.peak_time = peak_time;
            event_info.peak_loc = peak_loc;

            event_info.peak_mag_delta = peak_mag_delta;
            event_info.peak_mag_delta_mean = mean(event_info.peak_mag_delta);

            event_info.peak_delta_norm_hpstd = peak_delta_norm_hpstd;
            event_info.peak_delta_norm_hpstd_mean = mean(event_info.peak_delta_norm_hpstd);

            event_info.peak_slope = peak_slope;
            event_info.peak_slope_mean = mean(event_info.peak_slope);
            
            event_info.peak_slope_norm_hpstd = peak_slope_norm_hpstd;
            event_info.peak_slope_norm_hpstd_mean = mean(event_info.peak_slope_norm_hpstd);

            % event_info.stim = peak_properties_table.stim(event_info.idx_in_peak_table);
            event_info.peak_category = peak_category;
        case 'event'
            event_info_table = table(rise_time, rise_loc, rise_duration,...
                peak_time, peak_loc, peak_mag_delta, peak_delta_norm_hpstd,...
                peak_slope, peak_slope_norm_hpstd, peak_category);
            event_info = [table2struct(event_info_table)]';
    end
       
    varargout{1} = event_num;
end