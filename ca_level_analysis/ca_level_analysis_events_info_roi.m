function [ca_level_info,varargout] = ca_level_analysis_events_info_roi(trace_data,stimulation_win,varargin)
    % Return lowpassed data around stimuli. Each row includes a single repeat
    %   trace_data: a table including time info and a single trace info. 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    
    % Defaults
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds
    setting.sample_freq = 10; % if recording has different sampling frequency, resample it to this value 

    % Optionals
    for ii = 1:2:(nargin-2)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
        elseif strcmpi('sample_freq', varargin{ii})
            setting.sample_freq = varargin{ii+1};
        end
    end

    % Main contents
    timeInfo = trace_data(:, 1); % extract time information from data    
    sample_freq = round(1/(timeInfo(10)-timeInfo(9))); % sampling frequency  

    % start and end of windows (stimulation, rebound, stimulation_off, etc.)
    stimulation_win(:, 1) = stimulation_win(:, 1)-setting.stim_time_error;
    stimulation_win(:, 2) = stimulation_win(:, 1)+setting.stim_winT+setting.stim_time_error;
    stim_extend_win(:, 1) = stimulation_win(:, 1)-setting.pre_stim_duration;
    stim_extend_win(:, 2) = stimulation_win(:, 2)+setting.post_stim_duration; % in case some repeats have shorter data
    stim_extend_win_T = setting.pre_stim_duration+setting.stim_winT+setting.post_stim_duration;
    trace_point_num = round(stim_extend_win_T+1)*setting.sample_freq; % number of data points
    ca_level_info = NaN(size(stim_extend_win, 1), (trace_point_num)); % allocate ram

    % find the closest value in time info for stim_extend_win
    [stim_extend_win(:, 1),stim_extend_win_closestIndex(:, 1)] = find_closest_in_array(stim_extend_win(:, 1),timeInfo);
    [stim_extend_win(:, 2),stim_extend_win_closestIndex(:, 2)] = find_closest_in_array(stim_extend_win(:, 2),timeInfo);

    for r = 1:size(stim_extend_win, 1) % repeat of stimulation
        ca_trace = trace_data(stim_extend_win_closestIndex(r, 1):stim_extend_win_closestIndex(r, 2), 2);
        if sample_freq ~= setting.sample_freq
            ca_trace = resample(ca_trace, setting.sample_freq, sample_freq);
        end
        ca_level_info(r, 1:length(ca_trace)) = ca_trace;
    end
    varargout{1} = setting;
end


