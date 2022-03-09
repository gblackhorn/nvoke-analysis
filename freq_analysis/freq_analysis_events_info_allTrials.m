function [event_info_all_trials,varargout] = freq_analysis_events_info_allTrials(all_trial_data,varargin)
    % Return event_info (table) of all  trials
    %   all_trial_data: a cell array containing information of multiple trials 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    % Note: peak info from lowpassed data is used

    gpio_col = 4;
    
    
    % settings
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    % setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    setting.sortout_event = 'rise'; % use rise location to sort peak
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
    	elseif strcmpi('sortout_event', varargin{ii})
    		setting.sortout_event = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
        end
    end

    % Main contents
    trial_num = size(all_trial_data, 1);
    events_cell = cell(trial_num, 1);
    stim_num_array = NaN(trial_num, 1);
    for n = 1:trial_num

        % disp(['trial_num: ', num2str(n)]) % debug line
        % if n == 3
        %     pause
        %     disp('pause for debug')
        % end

        trial_data = all_trial_data(n, :);

        gpio_info = trial_data{gpio_col}(3);
        if numel(gpio_info) > 0 % if stimulation was applied
            stimulation_win = gpio_info.stim_range; % 3 is the first gpio channel used for stimulation. if 2 stimuli were used, 4 is the second
            stimulation_repeat = size(stimulation_win, 1);
            setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
        else
            stimulation_win = [];
            stimulation_repeat = [];
            setting.stim_winT = [];
        end

        [event_info_trial] = freq_analysis_events_info_trial(trial_data,...
            'stim_time_error', setting.stim_time_error, 'stim_winT', setting.stim_winT,...
            'sortout_event', setting.sortout_event,...
            'pre_stim_duration', setting.pre_stim_duration, 'post_stim_duration', setting.post_stim_duration);
        events_cell{n} = event_info_trial;
    end
    non_empty_idx = find(~cellfun(@isempty, events_cell));
    events_cell = events_cell(non_empty_idx);
    event_info_all_trials = cat(1, events_cell{:});

    varargout{1} = setting;
end


