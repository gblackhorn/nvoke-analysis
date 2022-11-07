function [peak_category,varargout] = organize_category_peaks(peak_properties_table,gpio_info_table,varargin)
    % Return peak_category
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. must have variable "rise_time"
    %   gpio_info_table: output of function "organize_gpio_info". if multiple stim_ch exist, only input one     

    % {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'};
    % noStim: events from recordings without any stimulations
	% beforeStim: events appearing before applying the first stim in a recording
	% interval: events appearing between stimulations
	% trigger: events appearing immediatly after the onset of a stim
	% delay: events appearing during a stim but not immediatly after its onset
	% rebound: events appearing immediatly after the end of a stim
    
    % Defaults
    stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    criteria_excitated = 2; % triggered peak: peak start to rise in 2s from onset of stim
    criteria_rebound = 1; % rebound peak: peak start to rise in 1s from end of stim
    % peak_cat_str = {'noStim', 'noStimFar', 'triggered', 'triggered_delay', 'rebound', 'interval'};
    % peak_cat_str = eventCatStr;
    [peak_cat_str] = event_category_names;

    % Optionals
    for ii = 1:2:(nargin-2)
    	if strcmpi('stim_time_error', varargin{ii})
    		stim_time_error = varargin{ii+1}; %
		elseif strcmpi('criteria_excitated', varargin{ii})
		    criteria_excitated = varargin{ii+1};
		elseif strcmpi('criteria_rebound', varargin{ii})
		    criteria_rebound = varargin{ii+1};
    	end
    end

    % Main contents
    % fetch info from input
    peak_rise_time = peak_properties_table.rise_time; % at which time, peak start to rise
    peak_category = cell(length(peak_rise_time), 1); % allocate ram
    if ~isempty(gpio_info_table)
	    stim_ch_name = gpio_info_table.stim_ch_name{:};
	    stim_time_range = gpio_info_table.stim_ch_time_range{:}; % 2-col matrix. [train_start_time train_end_time]
        stim_train_duration = gpio_info_table.stim_ch_train_duration{:};
        stim_time_range(:,2) = stim_time_range(:,1)+stim_train_duration; % old airpuff gpio data had wrong ending points. used the updated duration to correct the ends
	    stim_train_num = size(stim_time_range, 1);
	    stim_train_inter = gpio_info_table.stim_ch_train_inter;

	    

	    % allocate ram
	    idx_trig = cell(stim_train_num, 1);
	    idx_delay = cell(stim_train_num, 1);
	    idx_rebound = cell(stim_train_num, 1);
	    idx_inter = cell(stim_train_num, 1);

	    % modify stimulation window with stim_time_error
	    stim_time_range(:, 1) = stim_time_range(:, 1)-stim_time_error;
	    stim_time_range(:, 2) = stim_time_range(:, 2)+stim_time_error;

	    % Define windows for peak category
	    inter_end(1:(stim_train_num-1), 1) = stim_time_range(2:stim_train_num, 1);
	    inter_end(stim_train_num, 1) = stim_time_range(end, 2)+stim_train_inter;
	    win_befor_1st_stim = [0, stim_time_range(1, 1)];

	    % find stimulations longer than the criteria_excitated, and use the (stim_start+criteria_excitated) as the win_trig
		    % trig_duration = min(criteria_excitated, stim_train_duration);
		    % win_trig = [stim_time_range(:, 1), stim_time_range(:, 1)+trig_duration];
	    loc_big_win = find(stim_train_duration>criteria_excitated); % stimulation windows longer than criteria_excitated
	    loc_small_win = find(stim_train_duration<criteria_excitated); % stimulation windows shorter than criteria_excitated
		win_trig = stim_time_range;
	    win_trig(loc_big_win,2) = stim_time_range(loc_big_win, 1)+criteria_excitated;
	    win_trig(loc_small_win,2) = stim_time_range(loc_small_win, 1)+criteria_excitated;
	    win_trig_delay = [stim_time_range(:,2) stim_time_range(:,2)];
	    win_trig_delay(loc_big_win,1) = stim_time_range(loc_big_win, 1)+criteria_excitated;

	    % if stim_train_duration >= criteria_excitated
	    % 	win_trig_delay = [stim_time_range(:, 1)+criteria_excitated, stim_time_range(:, 2)];
	    % end
	    win_rebound = [stim_time_range(:, 2), stim_time_range(:, 2)+criteria_rebound];
	    win_rebound(loc_small_win,1) = win_trig(loc_small_win,2);
	    win_rebound(loc_small_win,2) = win_rebound(loc_small_win,1)+criteria_rebound;
	    win_inter = [win_rebound(:, 2), inter_end];
	    time_after_last_stim = [stim_time_range(end, 2)+stim_train_inter]; % last_stim+stim_train_inter : end_of_rec

	    % Find index of peaks fall in various windows for peak category
	    idx_befor_1st_stim = find(peak_rise_time>=win_befor_1st_stim(1) & peak_rise_time<win_befor_1st_stim(2));
	    idx_after_last_stim = find(peak_rise_time>=time_after_last_stim);
	    % idx_beforeStim = [idx_befor_1st_stim; idx_after_last_stim];
	    idx_beforeStim = idx_befor_1st_stim;
	    for wn = 1:stim_train_num
	    	idx_trig{wn} = find(peak_rise_time>=win_trig(wn, 1) & peak_rise_time<win_trig(wn, 2));
	    	if stim_train_duration(wn) >= criteria_excitated
		    	idx_delay{wn} = find(peak_rise_time>=win_trig_delay(wn, 1) & peak_rise_time<win_trig_delay(wn, 2));
		    end
		    idx_rebound{wn} = find(peak_rise_time>=win_rebound(wn, 1) & peak_rise_time<win_rebound(wn, 2));
		    idx_inter{wn} = find(peak_rise_time>=win_inter(wn, 1) & peak_rise_time<win_inter(wn, 2));
	    end
	    idx_trig = cell2mat(idx_trig);
	    idx_delay = cell2mat(idx_delay);
	    % if stim_train_duration >= criteria_excitated
	    % 	idx_delay = cell2mat(idx_delay);
	    % else
	    % 	idx_delay = [];
	    % end
	    idx_rebound = cell2mat(idx_rebound);
	    % idx_inter = cell2mat(idx_inter);
	    idx_inter = [cell2mat(idx_inter); idx_after_last_stim];

	    % Fill peak_category using index
	    if ~isempty(idx_beforeStim)
		    peak_category(idx_beforeStim) = peak_cat_str(2);
		end
		if ~isempty(idx_trig)
		    peak_category(idx_trig) = peak_cat_str(4);
		end
		if ~isempty(idx_delay)
		    peak_category(idx_delay) = peak_cat_str(5);
		end
		if ~isempty(idx_rebound)
		    peak_category(idx_rebound) = peak_cat_str(6);
		end
		if ~isempty(idx_inter)
		    peak_category(idx_inter) = peak_cat_str(3);
		end
		% varargout{1} = stim_ch_name;
	else
		peak_category(:) = peak_cat_str(1);
	end
end

