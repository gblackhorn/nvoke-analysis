function [ca_level_info_array,roi_spont_event_table,varargout] = ca_level_analysis_events_info_trial(trial_data,varargin)
    % Return calcium level info (table) of multiple rois from the same trial
    %   trial_data: a cell array containing information of 1 single trial 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    %   recording_time: single column array from decon or raw data   
    % Note: peak info from lowpassed data is used

    % Extract useful info from trial data
    rec_name_col = 1;
    trace_col = 2;
    stim_str_col = 3;
    gpio_col = 4;
    peak_info_col = 5;

    recording_name = trial_data{rec_name_col};
    recording_traces = trial_data{trace_col}.lowpass;
    recording_time = recording_traces.Time;
    stimulation_win = trial_data{gpio_col}(3).stim_range; % 3 is the first gpio channel used for stimulation. if 2 stimuli were used, 4 is the second
    stimulation_repeat = size(stimulation_win, 1);
    peak_info_table = trial_data{peak_info_col};
    
    % settings
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    setting.sortout_event = 'rise'; % use rise location to sort peak
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds
    setting.sample_freq = 10; % if recording has different sampling frequency, resample it to this value 

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
    	elseif strcmpi('rebound_winT', varargin{ii})
    		setting.rebound_winT = varargin{ii+1};
    	elseif strcmpi('sortout_event', varargin{ii})
    		setting.sortout_event = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
        elseif strcmpi('sample_freq', varargin{ii})
            setting.sample_freq = varargin{ii+1};
        end
    end

    % Main contents
    roi_num = size(peak_info_table, 2);
    roi_spont_event_info = cell(roi_num, 1);
    ca_level_info = cell(roi_num, 1);
    % stim_num_array = NaN(1, roi_num);
    for n = 1:roi_num
        roi_name = peak_info_table.Properties.VariableNames{n};
        peak_properties_table = peak_info_table{'peak_lowpass', roi_name}{:}; 
        trace_data = recording_traces{:, {'Time', roi_name}};
        if ~isempty(peak_properties_table)

            [ca_level_info{n}] = ca_level_analysis_events_info_roi(trace_data,stimulation_win,...
                'stim_time_error', setting.stim_time_error,...
                'pre_stim_duration', setting.pre_stim_duration, 'post_stim_duration', setting.post_stim_duration,...
                'sample_freq', setting.sample_freq);
            roi_names_cell = repelem({roi_name}, size(ca_level_info{n}, 1), 1);
            roi_names_table = table(roi_names_cell, 'VariableNames', {'roi_name'});

            [spont_event] = freq_analysis_spontaneous_freq_roi(peak_properties_table,...
                stimulation_win,recording_time,...
                'stim_time_error', setting.stim_time_error, 'stim_winT', setting.stim_winT,...
                'sortout_event', setting.sortout_event,'rebound_winT', setting.rebound_winT);
            spont_ca_level_info_cell = repelem(spont_event.freq, size(ca_level_info{n}, 1), 1);
            spont_ca_level_info_table = table(spont_ca_level_info_cell, 'VariableNames', {'spont_event_freq'});


            % ca_level_info_roi_table = struct2table(ca_level_info);
            % roi_spont_event_info{n} = [roi_names_table struct2table(ca_level_info) spont_ca_level_info_table];
            roi_spont_event_info{n} = [roi_names_table spont_ca_level_info_table];
            % stim_num_array(n) = stimulation_repeat;
        end
    end
    ca_level_info_array = cat(1, ca_level_info{:});
    roi_spont_event_table = cat(1, roi_spont_event_info{:});
    recording_names_cell = repelem({recording_name}, size(roi_spont_event_table, 1), 1);
    recording_names_table = table(recording_names_cell, 'VariableNames', {'recording_name'});
    stim_num_roi_array = repelem(stimulation_repeat, size(roi_spont_event_table, 1), 1);
    stim_num_roi_table = table(stim_num_roi_array, 'VariableNames', {'stim_num_per_roi'});
    roi_spont_event_table = [recording_names_table roi_spont_event_table];

    % stim_num = sum(stim_num_array, 'omitnan');
    varargout{1} = setting;
end


