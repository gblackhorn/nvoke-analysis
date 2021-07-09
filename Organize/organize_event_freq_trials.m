function [event_freq_table,varargout] = organize_event_freq_trials(recdata,varargin)
    % Return a table with recording name, roi name, event frequency information in it. (multiple rois)
    %   recdata: the organized data with recording names, gpio info, peak properties, etc.

    recording_name_col = 1;
    peak_properties_col = 5;
    
    recording_num = size(recdata, 1);
    for n = 1:recording_num
        recording_name = recdata{n, recording_name_col};
        event_frequency_rois = recdata{n, peak_properties_col}('event_freq', :);
        event_freq_table_trial = organize_event_freq_multirois(event_frequency_rois,recording_name);

        if ~exist('event_freq_table', 'var')
            event_freq_table = event_freq_table_trial;
        else
            event_freq_table = [event_freq_table; event_freq_table_trial];
        end
    end
end

