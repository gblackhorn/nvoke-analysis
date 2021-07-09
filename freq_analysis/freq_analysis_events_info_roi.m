function [event_info,varargout] = freq_analysis_events_info_roi(peak_properties_table,stimulation_win,recording_time,varargin)
    % Return event_info (structure) including rise, peak information and event time relative to stimulation
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    %   recording_time: single column array from decon or raw data   
    
    % Defaults
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    setting.sortout_event = 'rise'; % use rise location to sort peak
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds

    % Optionals
    for ii = 1:2:(nargin-3)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
    	% elseif strcmpi('rebound_winT', varargin{ii})
    	% 	setting.rebound_winT = varargin{ii+1};
    	elseif strcmpi('sortout_event', varargin{ii})
    		setting.sortout_event = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
        end
    end

    % Main contents
    % start and end of windows (stimulation, rebound, stimulation_off, etc.)
    stimulation_win(:, 1) = stimulation_win(:, 1)-setting.stim_time_error;
    stimulation_win(:, 2) = stimulation_win(:, 1)+setting.stim_winT+setting.stim_time_error;
    stim_extend_win(:, 1) = stimulation_win(:, 1)-setting.pre_stim_duration;
    stim_extend_win(:, 2) = stimulation_win(:, 2)+setting.post_stim_duration;


    % Sort peaks out
    if strcmpi('rise', setting.sortout_event)
    	events_time = peak_properties_table.rise_time;
    elseif strcmpi('peak', setting.sortout_event)
    	events_time = peak_properties_table.peak_time;
    else
    	error('Use "rise" or "peak" for sortout_event')
    end

    [event_info] = freq_analysis_select_events(events_time,stim_extend_win,peak_properties_table);

    event_info.event_time_2_stim = NaN(size(event_info.events_time));
    event_info.event_time_2_stim_pre = NaN(size(event_info.events_time));
    event_info.event_time_2_stim_post = NaN(size(event_info.events_time));
    % event_info.events_time_preStim = NaN(size(event_info.events_time));
    % event_info.events_time_postStim = NaN(size(event_info.events_time));
    for n = 1:length(event_info.idx_in_peak_table)
        idx_stim_start_after_event = find(stimulation_win(:,1)>=event_info.events_time(n), 1);
        if ~isempty(idx_stim_start_after_event)
            stim_start_after_event = stimulation_win(idx_stim_start_after_event, 1);
            event_time_preStim = event_info.events_time(n)-stim_start_after_event;
            if event_time_preStim >= -setting.pre_stim_duration
                event_info.event_time_2_stim(n) = event_time_preStim;
                event_info.event_time_2_stim_pre(n) = event_time_preStim;
            end
            % event_info.events_time_preStim(n) = event_info.events_time(n)-stim_start_after_event;
        end

        idx_stim_start_before_event = find(stimulation_win(:,1)<=event_info.events_time(n), 1, 'last');
        if ~isempty(idx_stim_start_before_event)
            stim_start_before_event = stimulation_win(idx_stim_start_before_event, 1);
            event_time_postStim = event_info.events_time(n)-stim_start_before_event;
            if event_time_postStim < (setting.stim_winT+setting.post_stim_duration)
                event_info.event_time_2_stim(n) = event_time_postStim;
                event_info.event_time_2_stim_post(n) = event_time_postStim;
            end
            % event_info.events_time_postStim(n) = event_info.events_time(n)-stim_start_before_event;
        end

    end
    varargout{1} = setting;
end


