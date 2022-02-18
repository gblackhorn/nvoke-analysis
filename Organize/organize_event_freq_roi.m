function [event_freq_cell,varargout] = organize_event_freq_roi(event_frequency,recording_name,roi_name,varargin)
    % Return a table with recording name, roi name, event frequency information in it.
    %   event_frequency: a structure variable in peak property table
    %   recording_name: string
    %   roi_name: string
    %   event_fq_table

    % Defaults
    % variable_names = {'recording_name', 'roi_name',...
    %     'stimoff_event_freq', 'stim_event_freq', 'rebound_event_freq',...
    %     'stimoff_event_count', 'stim_event_count', 'rebound_event_count'};
    col_num = 8;
    rec_col = 1; % column number of recording name
    roi_col = 2;

    all_freq_col = 3;
    stimoff_freq_col = 4;
    stim_freq_col = 5;
    rebound_freq_col = 6;

    all_count_col = 7
    stimoff_count_col = 8;
    stim_count_col = 9;
    rebound_count_col = 10;

    all_duration_col = 11;
    stimoff_duration_col = 12;
    stim_duration_col = 13;
    rebound_duration_col = 14;

    % get the indexis of various groups of event frequency and count 
    group_name_cell = {event_frequency(:).group};
    idx_all = find(strcmpi('all', group_name_cell));
    idx_stimoff = find(strcmpi('stimoff', group_name_cell));
    idx_stim = find(strcmpi('stim', group_name_cell));
    idx_rebound = find(strcmpi('rebound', group_name_cell));

    % organize information
    event_freq_cell = cell(1, col_num);

    event_freq_cell{1, rec_col} = recording_name;
    event_freq_cell{1, roi_col} = roi_name;

    event_freq_cell{1, all_freq_col} = event_frequency(idx_all).frequency;
    event_freq_cell{1, stimoff_freq_col} = event_frequency(idx_stimoff).frequency;

    event_freq_cell{1, all_count_col} = event_frequency(idx_all).event_num;
    event_freq_cell{1, stimoff_duration_col} = event_frequency(idx_stimoff).event_num;

    event_freq_cell{1, all_duration_col} = event_frequency(idx_all).duration;
    event_freq_cell{1, stimoff_duration_col} = event_frequency(idx_stimoff).duration;

    if ~isempty(idx_stim)
        event_freq_cell{1, stim_freq_col} = event_frequency(idx_stim).frequency;
        event_freq_cell{1, stim_count_col} = event_frequency(idx_stim).event_num;
        event_freq_cell{1, stim_duration_col} = event_frequency(idx_stimoff).duration;
    else
        event_freq_cell{1, stim_freq_col} = NaN;
        event_freq_cell{1, stim_count_col} = NaN;
        event_freq_cell{1, stim_duration_col} = NaN;
    end
    if ~isempty(idx_stim)
        event_freq_cell{1, rebound_freq_col} = event_frequency(idx_rebound).frequency;
        event_freq_cell{1, rebound_count_col} = event_frequency(idx_rebound).event_num;
        event_freq_cell{1, rebound_duration_col} = event_frequency(idx_rebound).duration;
    else
        event_freq_cell{1, rebound_freq_col} = NaN;
        event_freq_cell{1, rebound_count_col} = NaN;
        event_freq_cell{1, rebound_duration_col} = NaN;
    end
    % event_freq_table = table(event_freq_cell, 'VariableNames', variable_names);
end