function [event_freq_results,varargout] = analyze_event_freq_trials(recdata,varargin)
    % Return a table with recording name, roi name, event frequency information in it. (multiple rois)
    %   recdata: the organized data with recording names, gpio info, peak properties, etc.

    % variable_names = {'recording_name', 'roi_name',...
    %     'all_freq','stimoff_freq', 'stim_freq', 'rebound_freq',...
    %     'all_count', 'stimoff_count', 'stim_count', 'rebound_count',...
    %     'all_duration', 'stimoff_duration', 'stim_duration', 'rebound_duration'};

    [event_freq_table] = organize_event_freq_trials(recdata);

    all_freq = event_freq_table.allfreq;
    stimoff_freq = event_freq_table.stimoff_freq;
    stim_freq = event_freq_table.stim_freq;
    rebound_freq = event_freq_table.rebound_freq;

    stimoff_freq_delta = stimoff_freq-all_freq;
    stim_freq_delta = stim_freq-all_freq;
    rebound_freq_delta = rebound_freq-all_freq;

    event_freq_results.stimoff_freq_delta_mean = mean(stimoff_freq_delta);
    event_freq_results.stim_freq_delta_mean = mean(stim_freq_delta);
    event_freq_results.rebound_freq_delta_mean = mean(rebound_freq_delta);
end
