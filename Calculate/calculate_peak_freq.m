function [event_freq,varargout] = calculate_peak_freq(peak_properties_table,stimulation_win,recording_time,varargin)
    % Return event frequency
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    %   gpio_info_table: output of function "organize_gpio_info". if multiple stim_ch exist, only input one     
    
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

    % Main contents
    % start and end of windows (stimulation, rebound, stimulation_off, etc.)
    stimulation_win(:, 1) = stimulation_win(:, 1)-stim_time_error;
    stimulation_win(:, 2) = stimulation_win(:, 2)+stim_time_error;
    rebound_win = [stimulation_win(:, 2) (stimulation_win+rebound_winT)];
    stimoff_win_start = [recording_time(1); rebound_win(:, 2)];
    stimoff_win_end = [stimulation_win(:, 1); recording_time(end)];
    stimoff_win = [stimoff_win_start stimoff_win_end];

    % Duration of various conditions in seconds
    recording_duration = recording_time(end)-recording_time(1);
    stimulation_duration = sum(stimulation_win(:,2)-stimulation_win(:,1));
    rebound_duration = sum(rebound_win(:,2)-rebound_win(:,1));
    stimoff_duration = sum(stimoff_win(:,2)-stimoff_win(:,1));

    % all events
    event_freq(1).group = 'all';
    event_freq(1).event_num = size(peak_properties_table, 1);
    event_freq(1).duration = recording_duration;
    event_freq(1).frequency = event_freq(1).event_num/event_freq(1).duration;

    % Sort peaks out
    if strcmpi('rise', sortout_event)
    	events_time = peak_properties_table.rise_time;
    elseif strcmpi('peak', sortout_event)
    	events_time = peak_properties_table.pek_time;
    else
    	error('Use "rise" or "peak" for sortout_event')
    end
    event_freq(2).group = 'stim_off';
    [event_idx_stimoff,event_freq(2)] = organize_sort_peaks(events_time,stimoff_win,peak_properties_table);

    event_freq(2).duration  = stimoff_duration
    event_freq(2).frequency = event_freq(2).event_num/event_freq(2).duration;
    if ~isempty(stimulation_win)
    	event_freq(3).group = 'stim';
    	[event_idx_stim,event_freq(3)] = organize_sort_peaks(events_time,stimulation_win,peak_properties_table);
    	event_freq(3).duration  = stimulation_duration
    	event_freq(3).frequency = event_freq(3).event_num/event_freq(3).duration;


    	event_freq(4).group = 'rebound';
	    [event_idx_rebound,event_freq(4)] = organize_sort_peaks(events_time,rebound_win,peak_properties_table);
	    event_freq(4).duration  = rebound_duration
	    event_freq(4).frequency = event_freq(4).event_num/event_freq(4).duration;
	end
end


