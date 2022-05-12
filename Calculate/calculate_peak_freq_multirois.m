function [event_freq_multirois,varargout] = calculate_peak_freq_multirois(peak_properties_tables,stimulation_win,recording_time,varargin)
    % Return event number sorted with conditions for the whole recording (multiple rois)
    % Caution (2021.01.10): only works with up to 2 stimulation channels so far 
    %   peak_properties_tables: multiple roi table
    %   gpio_info_table: output of function "organize_gpio_info". multiple stim_ch can be used
    
    % Defaults
    stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1);
    rebound_winT = 1; % second. rebound window duration
    sortout_event = 'rise'; % use rise location to sort peak

    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('stim_time_error', varargin{ii})
            stim_time_error = varargin{ii+1};
        elseif strcmpi('stim_winT', varargin{ii})
            stim_winT = varargin{ii+1};
        elseif strcmpi('rebound_winT', varargin{ii})
            rebound_winT = varargin{ii+1};
        elseif strcmpi('sortout_event', varargin{ii})
            sortout_event = varargin{ii+1};
        end
    end

    % main contents
    % peak_properties_tables_with_cat = peak_properties_tables;
    event_freq_multirois = cell(size(peak_properties_tables));

    roi_num = size(peak_properties_tables, 2);
    for rn = 1:roi_num
        if size(peak_properties_tables{1, rn}, 2) ~= 1
            peak_properties_table_single = peak_properties_tables{1, rn};
        else
            peak_properties_table_single = peak_properties_tables{1, rn}{:};
        end

        if ~isempty(peak_properties_table_single)
            [event_freq_multirois{1, rn}] = calculate_peak_freq(peak_properties_table_single,stimulation_win,recording_time);
        end
    end
    event_freq_multirois = cell2table(event_freq_multirois,...
        'VariableNames', peak_properties_tables.Properties.VariableNames);
end

