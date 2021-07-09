function [spont_event,varargout] = freq_analysis_spontaneous_freq_roi(peak_properties_table,stimulation_win,recording_time,varargin)
    % Return the spontaneous event frequency of a ROI
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    %   recording_time: single column array from decon or raw data   
    
    % Defaults
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    setting.sortout_event = 'rise'; % use rise location to sort peak

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
        end
    end

    % Main contents
    % starts and ends of windows (exclude stimulation and rebound period) 
    stimulation_win(:, 1) = stimulation_win(:, 1)-setting.stim_time_error;
    stimulation_win(:, 2) = stimulation_win(:, 1)+setting.stim_winT+setting.stim_time_error;

    spont_win(:, 1) = [recording_time(1); (stimulation_win(:, 2)+setting.rebound_winT)]; % starts of windows
    spont_win(:, 2) = [stimulation_win(:, 1); recording_time(end)]; % ends of windows
    spont_duration = sum(spont_win(:, 2)-spont_win(:, 1)); % full duration of spont windows 

    % Sort peaks out
    if strcmpi('rise', setting.sortout_event)
    	events_time = peak_properties_table.rise_time;
    elseif strcmpi('peak', setting.sortout_event)
    	events_time = peak_properties_table.peak_time;
    else
    	error('Use "rise" or "peak" for sortout_event')
    end

    [spont_event_info] = freq_analysis_select_events(events_time,spont_win,peak_properties_table);
    spont_event.count = length(spont_event_info.events_time);
    spont_event.duration = spont_duration; % second
    spont_event.freq = spont_event.count/spont_event.duration; % frequency of spontaneous event

    varargout{1} = setting;
end


