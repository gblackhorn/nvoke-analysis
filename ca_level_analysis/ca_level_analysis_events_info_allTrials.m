function [ca_level_all_trials,roi_spont_event_all_trials,varargout] = ca_level_analysis_events_info_allTrials(all_trial_data,varargin)
    % Return calcium level info (table) of all trials
    %   all_trial_data: a cell array containing information of multiple trials 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    % Note: peak info from lowpassed data is used

    gpio_col = 4;
    stimulation_win = all_trial_data{1, gpio_col}(3).stim_range; % 3 is the first gpio channel used for stimulation. if 2 stimuli were used, 4 is the second
    
    % settings
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    % setting.sortout_event = 'rise'; % use rise location to sort peak
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds
    setting.sample_freq = 10; % if recording has different sampling frequency, resample it to this value 

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
    	% elseif strcmpi('sortout_event', varargin{ii})
    	% 	setting.sortout_event = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
        elseif strcmpi('sample_freq', varargin{ii})
            setting.sample_freq = varargin{ii+1};
        end
    end

    % Main contents
    trial_num = size(all_trial_data, 1);
    ca_level_cell = cell(trial_num, 1);
    roi_spont_event_cell = cell(trial_num, 1);

    % stim_num_array = NaN(trial_num, 1);
    for n = 1:trial_num

        % disp(['trial_num: ', num2str(n)]) % debug line
        % if n == 18
        %     pause
        %     disp('pause for debug')
        % end

        trial_data = all_trial_data(n, :);
        [ca_level_info_array, roi_spont_event_table] = ca_level_analysis_events_info_trial(trial_data,...
            'stim_time_error', setting.stim_time_error, 'stim_winT', setting.stim_winT,...
            'pre_stim_duration', setting.pre_stim_duration, 'post_stim_duration', setting.post_stim_duration,...
            'sample_freq', setting.sample_freq);
        ca_level_cell{n} = ca_level_info_array;
        roi_spont_event_cell{n} = roi_spont_event_table;
    end
    non_empty_idx = find(~cellfun(@isempty, ca_level_cell));
    ca_level_cell = ca_level_cell(non_empty_idx);
    ca_level_all_trials = cat(1, ca_level_cell{:});

    roi_spont_event_cell = roi_spont_event_cell(non_empty_idx);
    roi_spont_event_all_trials = cat(1, roi_spont_event_cell{:});

    varargout{1} = setting;
end


