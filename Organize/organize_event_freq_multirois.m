function [event_freq_table,varargout] = organize_event_freq_multirois(event_frequency_rois,recording_name,varargin)
    % Return a table with recording name, roi name, event frequency information in it. (multiple rois)
    %   event_frequency_rois: table var. the "event_freq" row of peak property table of a single trial 
    %   recording_name: string
    
    % Defaults
    variable_names = {'recording_name', 'roi_name',...
        'all_freq','stimoff_freq', 'stim_freq', 'rebound_freq',...
        'all_count', 'stimoff_count', 'stim_count', 'rebound_count',...
        'all_duration', 'stimoff_duration', 'stim_duration', 'rebound_duration'};


    
    roi_num = size(event_frequency_rois, 2);
    roi_names = event_frequency_rois.Properties.VariableNames;
    col_num = size(variable_names, 2);
    event_freq_cell = cell(roi_num, col_num);

    for n = 1:roi_num
        event_freq_single_roi = event_frequency_rois{1, n}{:};
        event_freq_cell(n, :) = organize_event_freq_roi(event_freq_single_roi,recording_name,roi_names{n});
    end

    event_freq_table = cell2table(event_freq_cell, 'VariableNames', variable_names);
end

