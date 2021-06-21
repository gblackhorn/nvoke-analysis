function [peak_category,varargout] = organize_category_peaks(peak_properties_table,gpio_info_table,varargin)
    % Return peak_category
    %   peak_properties_table: a table with vary properties of peaks from a
    %       single roi. must have variable "rise_time"
    %   gpio_info_table: output of function "organize_gpio_info". if multiple stim_ch exist, only input one     
    
    % Defaults
    stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    criteria_trig = 2; % triggered peak: peak start to rise in 2s from onset of stim
    criteria_rebound = 1; % rebound peak: peak start to rise in 1s from end of stim
    peak_cat_str = {'noStim', 'noStimFar', 'triggered', 'triggered_delay', 'rebound', 'interval'};

    % Optionals
    for ii = 1:2:(nargin-2)
    	if strcmpi('stim_time_error', varargin{ii})
    		stim_time_error = varargin{ii+1};peak_cat_str;
    	end
    end

    % Main contents
    % fetch info from input
    peak_rise_time = peak_properties_table.rise_time; % at which time, peak start to rise
    peak_category = cell(length(peak_rise_time), 1); % allocate ram
    if ~isempty(gpio_info_table)
	    stim_ch_name = gpio_info_table.stim_ch_name{:};
	    stim_time_range = gpio_info_table.stim_ch_time_range{:}; % 2-col matrix. [train_start_time train_end_time]
	    stim_train_duration = gpio_info_table.stim_ch_train_duration;
	    stim_train_num = size(stim_time_range, 1);
	    stim_train_inter = gpio_info_table.stim_ch_train_inter;

	    trig_duration = min(criteria_rebound, stim_train_duration);

	    % allocate ram
	    idx_trig = cell(stim_train_num, 1);
	    idx_trig_delay = cell(stim_train_num, 1);
	    idx_rebound = cell(stim_train_num, 1);
	    idx_inter = cell(stim_train_num, 1);

	    % modify stimulation window with stim_time_error
	    stim_time_range(:, 1) = stim_time_range(:, 1)-stim_time_error;
	    stim_time_range(:, 2) = stim_time_range(:, 2)+stim_time_error;

	    % Define windows for peak category
	    inter_end(1:(stim_train_num-1), 1) = stim_time_range(2:stim_train_num, 1);
	    inter_end(stim_train_num, 1) = stim_time_range(end, 2)+stim_train_inter;
	    win_befor_1st_stim = [0, stim_time_range(1, 1)];
	    win_trig = [stim_time_range(:, 1), stim_time_range(:, 1)+trig_duration];
	    if stim_train_duration >= criteria_trig
	    	win_trig_delay = [stim_time_range(:, 1)+criteria_trig, stim_time_range(:, 2)];
	    end
	    win_rebound = [stim_time_range(:, 2), stim_time_range(:, 2)+criteria_rebound];
	    win_inter = [stim_time_range(:, 2)+criteria_rebound, inter_end];
	    time_after_last_stim = [stim_time_range(end, 2)+stim_train_inter]; % last_stim+stim_train_inter : end_of_rec

	    % Find index of peaks fall in various windows for peak category
	    idx_befor_1st_stim = find(peak_rise_time>=win_befor_1st_stim(1) & peak_rise_time<win_befor_1st_stim(2));
	    idx_after_last_stim = find(peak_rise_time>=time_after_last_stim);
	    idx_far_from_stim = [idx_befor_1st_stim; idx_after_last_stim];
	    for wn = 1:stim_train_num
	    	idx_trig{wn} = find(peak_rise_time>=win_trig(wn, 1) & peak_rise_time<win_trig(wn, 2));
	    	if stim_train_duration >= criteria_trig
		    	idx_trig_delay{wn} = find(peak_rise_time>=win_trig_delay(wn, 1) & peak_rise_time<win_trig_delay(wn, 2));
		    end
		    idx_rebound{wn} = find(peak_rise_time>=win_rebound(wn, 1) & peak_rise_time<win_rebound(wn, 2));
		    idx_inter{wn} = find(peak_rise_time>=win_inter(wn, 1) & peak_rise_time<win_inter(wn, 2));
	    end
	    idx_trig = cell2mat(idx_trig);
	    if stim_train_duration >= criteria_trig
	    	idx_trig_delay = cell2mat(idx_trig_delay);
	    else
	    	idx_trig_delay = [];
	    end
	    idx_rebound = cell2mat(idx_rebound);
	    idx_inter = cell2mat(idx_inter);

	    % Fill peak_category using index
	    if ~isempty(idx_far_from_stim)
		    peak_category(idx_far_from_stim) = peak_cat_str(2);
		end
		if ~isempty(idx_trig)
		    peak_category(idx_trig) = peak_cat_str(3);
		end
		if ~isempty(idx_trig_delay)
		    peak_category(idx_trig_delay) = peak_cat_str(4);
		end
		if ~isempty(idx_rebound)
		    peak_category(idx_rebound) = peak_cat_str(5);
		end
		if ~isempty(idx_inter)
		    peak_category(idx_inter) = peak_cat_str(6);
		end
	else
		peak_category(:) = peak_cat_str{1};
	end
end

