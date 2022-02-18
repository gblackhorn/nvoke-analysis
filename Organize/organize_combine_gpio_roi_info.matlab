function [varargout] = organize_combine_gpio_roi_info(gpio_info,varargin)
    % Combine gpio (and roi_trace) csv files to a single one for the analysis of combined recordings

    % Defaults
    stim_idx_start = 3;
    round_digit = 0; % round the stimulation duration time to the round_digit digits

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('stim_idx_start', varargin{ii})
    		stim_idx_start = varargin{ii+1};
    	elseif strcmpi('round_digit', varargin{ii})
    		round_digit = varargin{ii+1};
    	end
    end

    % Main contents
    stim_ch_num = length(gpio_info(stim_idx_start:end));

    % allocate ram to variables
    gpio_info_organized = gpio_info;
    stim_ch_name = cell(stim_ch_num, 1); % stimulation channel name
    stim_ch_str = cell(stim_ch_num, 1); % stimulation channel name
    stim_ch_time_range = cell(stim_ch_num, 1); % time info of train starts and ends. (start, end)
    stim_ch_patch = cell(stim_ch_num, 1); % for plotting stimulations with patch func. (x, y)
    stim_ch_train_duration = NaN(stim_ch_num, 1); % duration of each single stim_train
    stim_ch_train_inter = NaN(stim_ch_num, 1); % duration of each single stim_train

    if stim_ch_num ~= 0
	    for cn = 1:stim_ch_num % loop through gpio channels used for stimulation
	    	stim_ch_idx = stim_idx_start-1+cn; % index of stimulation channel in gpio_info
	    	stim_ch_name{cn} = gpio_info(stim_ch_idx).name{1};
	    	% gpio_signal{cn} = gpio_info(cn).time_value;
	    	time_info = gpio_info(stim_ch_idx).time_value(:, 1);
	    	gpio_value = gpio_info(stim_ch_idx).time_value(:, 2);

	    	% gpio signal from nvoke2 is not clean. need to set a threshold to not organize faulse stim_channel
	    	if strfind(stim_ch_name{cn}, 'GPIO-1')
	    		gpio_thresh = 30000; % 30000 for nvoke2
	    	elseif strfind(stim_ch_name{cn}, 'OG-LED')
	    		gpio_thresh = 0.15;
	    	else
	    		gpio_thresh = 0.5;
	    	end

			gpio_rise_loc = find(gpio_value>gpio_thresh);
			if ~isempty(gpio_rise_loc)
				% Find the start and end points of gpion stimulation trains
				gpio_rise_num = length(gpio_rise_loc);
				gpio_rise_inter = diff(time_info(gpio_rise_loc));
				train_inter_loc = find(gpio_rise_inter >= 5); % when gpio signal interval is longer than 5s, that's the break of trains
				train_end_loc = [(gpio_rise_loc(train_inter_loc)+1); (gpio_rise_loc(end)+1)]; % +1 to each end: gpio switch off after rise signal
				train_start_loc = [(gpio_rise_loc(1)); (gpio_rise_loc(train_inter_loc+1))]; % time of the train_start rises start
				gpio_train_start_time = time_info(train_start_loc);
				gpio_train_end_time = time_info(train_end_loc);
				stim_ch_time_range{cn} = [gpio_train_start_time gpio_train_end_time];

				% organize gpio info for plotting patches for the durations of stim_trains
				stim_ch_patch{cn} = organize_gpio_train_for_plot_patch(stim_ch_time_range{cn});

				if strfind(stim_ch_name{cn}, 'GPIO-1') % airpuff trigger signal is 0.5s. stimulation is 1s
					stim_ch_train_duration(cn) = 1;
					gpio_train_end_time = gpio_train_start_time+stim_ch_train_duration(cn);
					stim_ch_time_range{cn}(:, 2) = gpio_train_end_time;
					stim_ch_patch{cn} = organize_gpio_train_for_plot_patch(stim_ch_time_range{cn});
				else
					stim_ch_train_duration(cn) = round(gpio_train_end_time(1)-gpio_train_start_time(1), round_digit);
				end

				stim_ch_str{cn} = [stim_ch_name{cn}, '-', num2str(stim_ch_train_duration(cn)), 's'];
				stim_ch_train_inter(cn) = round(gpio_train_start_time(2)-gpio_train_end_time(1), round_digit);

				gpio_info_organized(stim_idx_start+cn-1).stim_range = stim_ch_time_range{cn};
				gpio_info_organized(stim_idx_start+cn-1).patch_coordinats = stim_ch_patch{cn};
			end     
	    end
	    gpio_info_table = table(stim_ch_name, stim_ch_str, stim_ch_time_range,...
	    	stim_ch_train_duration, stim_ch_train_inter, stim_ch_patch);
	else
		gpio_info_table = [];
    end
    if nargout == 2
    	varargout{1} = gpio_info_table;
    end
end

