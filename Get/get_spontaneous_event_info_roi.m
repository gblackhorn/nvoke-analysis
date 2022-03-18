function [spont_event_info,varargout] = get_spontaneous_event_info_roi(peak_properties_table,stimulation_win,recording_time,varargin)
    % Return the spontaneous event frequency of a ROI
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    %   recording_time: single column array from decon or raw data   
    
    % Defaults
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    if ~isempty(stimulation_win)
        setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    else
        setting.stim_winT = [];
    end
    setting.rebound_winT = 1; % second. rebound window duration
    setting.sortout_event = 'rise'; % use rise location to sort peak
    trace_data = [];

    % Optionals
    for ii = 1:2:(nargin-3)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
    	elseif strcmpi('rebound_winT', varargin{ii})
    		setting.rebound_winT = varargin{ii+1};
    	elseif strcmpi('sortout_event', varargin{ii})
    		setting.sortout_event = varargin{ii+1};
        elseif strcmpi('trace_data', varargin{ii})
            trace_data = varargin{ii+1};
        end
    end

    % Main contents
    % starts and ends of windows (exclude stimulation and rebound period) 
    if ~isempty(peak_properties_table)
        if ~isempty(stimulation_win)
            [stimulation_win,spont_win,~,stimulation_duration,spont_duration] = get_condition_win(stimulation_win,recording_time,...
                'err_duration',setting.stim_time_error,'exclude_duration',setting.rebound_winT);

            % stimulation_win(:, 1) = stimulation_win(:, 1)-setting.stim_time_error;
            % stimulation_win(:, 2) = stimulation_win(:, 1)+setting.stim_winT+setting.stim_time_error;

            % spont_win(:, 1) = [recording_time(1); (stimulation_win(:, 2)+setting.rebound_winT)]; % starts of windows
            % spont_win(:, 2) = [stimulation_win(:, 1); recording_time(end)]; % ends of windows
            % spont_duration = sum(spont_win(:, 2)-spont_win(:, 1)); % full duration of spont windows 
        else % if no stimulation was applied
            spont_win(1, 1) = recording_time(1);
            spont_win(1, 2) = recording_time(end);
            spont_duration = spont_win(1, 2)-spont_win(1, 1);
        end

        % Sort peaks out
        if strcmpi('rise', setting.sortout_event)
        	events_time = peak_properties_table.rise_time;
        elseif strcmpi('peak', setting.sortout_event)
        	events_time = peak_properties_table.peak_time;
        else
        	error('Use "rise" or "peak" for sortout_event')
        end

        [spont_event_info] = get_events_info(events_time,spont_win,peak_properties_table,...
            'style', 'roi', 'cal_interval', true);
        if ~isempty(spont_event_info.events_time)
            % spont_event_info.event_num = length(spont_event_info.events_time);
            spont_event_info.duration = spont_duration; % second
            spont_event_info.freq = spont_event_info.event_num/spont_event_info.duration; % frequency of spontaneous event

            if ~isempty(trace_data)
                [alignedTime,alignedValue,alignedValue_mean,alignedValue_std] = get_event_trace(spont_event_info.events_time, recording_time, trace_data);
                spont_event_info.traces.time = alignedTime;
                spont_event_info.traces.value = alignedValue;
                spont_event_info.traces.value_mean = alignedValue_mean;
                spont_event_info.traces.value_std = alignedValue_std;
            end
        else
            spont_event_info = [];
        end
    else
        spont_event_info = [];
    end

    varargout{1} = setting;
end


