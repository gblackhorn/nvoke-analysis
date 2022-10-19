function [gpio_info_organized,varargout] = organize_gpio_info(gpio_info,varargin)
    %Organize gpio_info directly outputed from nVoke. Find the channels used for stimulation. Calculate the duration of stim and intervals
    % Caution (2021.01.10): stim_ch_train_duration for airpuff is set to 1s. calculated duration is the trigger signal train duration.
    % Note: Discard 'GPIO-1' if 'GPIO-3' exists. GPIO-1 outputs trigger signal for airpuff. GPIO-3 receives the airpuff sync signal
    %	'GPIO-1' only has the stimulation start of airpuff. 'GPIO-3' has the both stimulation start and duration of airpuff. 

    %   example: 
    %		[gpio_info_organized, gpio_info_table] = organize_gpio_info(gpio_info,...
    %			'modify_ch_name',true,...
    %			'chDis_names',{'GPIO-2'},...
    %			'round_digit_sig',2);

    % Defaults
    gpio1_ap_duration = 0.1; % airpuff duration (s) when gpio1 channel of nVoke is used to activate ap machine directly
    ch_names_all = gpio_ch_names; % Get channel names from function "gpio_ch_names"

    chNonStim_names = ch_names_all.non_stim; % Exclude the channels containing these words from stimulation group
    chDis_names = ch_names_all.discard; % These channels are marked to be deleted
    chStim_names = ch_names_all.stim; % GPIO channel names from nVoke2 might be used for stimulation
    chStim_names_mod = ch_names_all.stim_mod; % alternative names for chStim_names. These names have better readibility 

    % chNonStim_names = {'sync','EX-LED'}; % Exclude the channels containing these words
    % chStim_names = {'GPIO-1','GPIO-2','GPIO-3'}; % GPIO names from nVoke2
    % chStim_names_mod = {'AP_GPIO-1','Airpuff-START','AP'};
    % channel GPIO-2 output trigger signal to the Arduino, which guides MPPI-3 machine for airpuff protocol
    % channel GPIO-3 receives input from MPPI-3 for real airpuff information
    modify_ch_name = true; % If true, replace the channel names in 'chStim_names' with the ones in 'chStim_names_mod'

    % chDis_names = {'GPIO-2'}; % GPIO-2/Airpuff-START is the nVoke2 channel to command Arduino micro-controller to start airpuff stimulation

    % stim_idx_start = 3;
    round_digit_sig = 2; % round to N significant digits (counted from the leftmost digit)

    % Optionals
    for ii = 1:2:(nargin-1)
    	% if strcmpi('stim_idx_start', varargin{ii})
    	% 	stim_idx_start = varargin{ii+1};
    	% if strcmpi('chNonStim_names', varargin{ii})
    	% 	chNonStim_names = varargin{ii+1}; % specify the names of 
    	if strcmpi('modify_ch_name', varargin{ii})
    		modify_ch_name = varargin{ii+1};
    	elseif strcmpi('chDis_names', varargin{ii})
    		chDis_names = varargin{ii+1};
    	elseif strcmpi('round_digit_sig', varargin{ii})
    		round_digit_sig = varargin{ii+1};
    	end
    end

    %% ====================
    % Main contents
    % Check if channel names are stored in 2nd level cell, such as gpio_info(1).name{:}. If so, make it to gpio_info(1).name
    ch_names = {gpio_info.name};
    if ~ischar(ch_names{1}) 
    	ch_names = cellfun(@(x) x{:},ch_names,'UniformOutput',false); 
    	[gpio_info.name] = ch_names{:};
    end

    % Discard unwanted channels
    if ~isempty(chDis_names) 
    	TF_ch_dis = contains(ch_names,chDis_names,'IgnoreCase',true);
    	loc_ch_dis = find(TF_ch_dis);
    	gpio_info(loc_ch_dis) = [];
    	ch_names = {gpio_info.name};
    end
    TF_gpio3 = contains(ch_names,'GPIO-3','IgnoreCase',true);
    if ~isempty(find(TF_gpio3)) % GPIO-1 outputs airpuff trigger. GPIO-3 inputs the airpuff sync. Discard GPIO-1 if both exist
    	TF_gpio1 = contains(ch_names,'GPIO-1','IgnoreCase',true);
    	loc_gpio1 = find(TF_gpio1);
    	gpio_info(loc_gpio1) = [];
    	ch_names = {gpio_info.name};
    end

    % Modify channel names for better readibility
    if modify_ch_name
    	for i = 1:numel(chStim_names)
    		name_loc = find(contains(ch_names,chStim_names{i},'IgnoreCase',true));
    		% name_loc = find(strcmpi(chStim_names{i},ch_names));
    		if ~isempty(name_loc)
    			ch_names{name_loc} = chStim_names_mod{i};
    		end
    	end
    	[gpio_info.name] = ch_names{:};
    	stim_name_type = 2; % stim channel names are chStim_names_mod
    else
    	stim_name_type = 1; % stim channel names are chStim_names
    end

    % Find the locations of 'SYNC' and 'EX-LED' channels. They will not be processed
    [~,gpio_ch_locs] = gpio_ch_names(ch_names,stim_name_type);
    loc_ch_nonstim = gpio_ch_locs.non_stim;
    loc_ch_stim = gpio_ch_locs.stim;

    % TF_ch_exclude = contains(ch_names,ch_exclude,'IgnoreCase',true);
    % loc_ch_nonstim = find(TF_ch_exclude);
    % % gpio_info_ch_exclude = gpio_info(loc_ch_nonstim); 
    % loc_ch_stim = find(TF_ch_exclude==0);
    % gpio_info_ch_stim = gpio_info(loc_ch_stim);

    % allocate ram to variables
    % stim_ch_num = length(gpio_info(stim_idx_start:end));
    stim_ch_num = length(loc_ch_stim);
    % gpio_info_organized = gpio_info;
    stim_ch_name = cell(stim_ch_num, 1); % stimulation channel name
    stim_ch_str = cell(stim_ch_num, 1); % stimulation channel name
    stim_ch_time_range = cell(stim_ch_num, 1); % time info of train starts and ends. (start, end)
    stim_ch_patch = cell(stim_ch_num, 1); % for plotting stimulations with patch func. (x, y)
    % stim_ch_train_duration = NaN(stim_ch_num, 1); % duration of each single stim_train
    stim_ch_train_duration = cell(stim_ch_num, 1); % duration of each single stim_train
    stim_ch_train_inter = NaN(stim_ch_num, 1); % duration of each single stim_train

    
    if stim_ch_num ~= 0
	    for cn = 1:stim_ch_num % loop through gpio channels used for stimulation
	    	% stim_ch_idx = stim_idx_start-1+cn; % index of stimulation channel in gpio_info
	    	stim_ch_idx = loc_ch_stim(cn); % index of stimulation channel in gpio_info
	    	% stim_ch_name{cn} = gpio_info(stim_ch_idx).name{1};
	    	stim_ch_name{cn} = gpio_info(stim_ch_idx).name;
	    	% gpio_signal{cn} = gpio_info(cn).time_value;
	    	time_info = gpio_info(stim_ch_idx).time_value(:, 1);
	    	gpio_value = gpio_info(stim_ch_idx).time_value(:, 2);

	    	% gpio signal from nvoke2 is not clean. need to set a threshold to not organize faulse stim_channel
	    	if ~isempty(find(contains(stim_ch_name{cn},[chStim_names chStim_names_mod])))
	    		if ~isempty(find(contains(stim_ch_name{cn},'og')))
	    		% if ~isempty(find(contains(stim_ch_name{cn},'OG-LED')))
	    			gpio_thresh = 0.15;
	    		else
	    			gpio_thresh = 30000; % 30000 for nvoke2
	    		end
	    	% elseif ~isempty(find(contains(stim_ch_name{cn},'OG-LED')))
	    	% 	gpio_thresh = 0.15;
	    	else
	    		gpio_thresh = 0.5;
	    	end

	    	% if strfind(stim_ch_name{cn}, 'GPIO-1')
	    	% 	gpio_thresh = 30000; % 30000 for nvoke2
	    	% elseif strfind(stim_ch_name{cn}, 'OG-LED')
	    	% 	gpio_thresh = 0.15;
	    	% else
	    	% 	gpio_thresh = 0.5;
	    	% end

			gpio_rise_loc = find(gpio_value>gpio_thresh);
			if ~isempty(gpio_rise_loc)
				% Find the start and end points of gpion stimulation trains
				gpio_rise_num = length(gpio_rise_loc);
				gpio_rise_inter = diff(time_info(gpio_rise_loc));
				train_inter_loc = find(gpio_rise_inter >= 5); % when gpio signal interval is longer than 5s, that's the break of trains
				train_end_loc = [(gpio_rise_loc(train_inter_loc)+1); (gpio_rise_loc(end)+1)]; % +1 to each end: gpio switch off after rise signal
				train_start_loc = [(gpio_rise_loc(1)); (gpio_rise_loc(train_inter_loc+1))]; % time of the train_start rises start
				gpio_train_start_time = round(time_info(train_start_loc),round_digit_sig);
				gpio_train_end_time = round(time_info(train_end_loc),round_digit_sig);
				% gpio_train_start_time = round(time_info(train_start_loc),round_digit_sig,'significant');
				% gpio_train_end_time = round(time_info(train_end_loc),round_digit_sig,'significant');
				stim_ch_time_range{cn} = [gpio_train_start_time gpio_train_end_time];

				% organize gpio info for plotting patches for the durations of stim_trains
				stim_ch_patch{cn} = organize_gpio_train_for_plot_patch(stim_ch_time_range{cn});

				% if strfind(stim_ch_name{cn}, 'GPIO-1') % airpuff trigger signal is 0.5s. stimulation is 1s
				if contains(stim_ch_name{cn}, 'GPIO-1') % airpuff trigger signal is 0.5s/1s. stimulation is 100ms
					stim_ch_train_duration{cn} = gpio1_ap_duration*ones(size(stim_ch_time_range{cn},1),1);
					gpio_train_end_time = gpio_train_start_time+stim_ch_train_duration{cn};
					stim_ch_time_range{cn}(:, 2) = gpio_train_end_time;
					stim_ch_patch{cn} = organize_gpio_train_for_plot_patch(stim_ch_time_range{cn});
					stim_ch_name{cn} = 'ap'; % remove '_GPIO-1' from the stim_ch_name
				else
					stim_durations = gpio_train_end_time-gpio_train_start_time;
					% stim_durations = round(stim_durations,round_digit_sig,'significant');
					stim_ch_train_duration{cn} = round(stim_durations,round_digit_sig,'significant');
					% stim_ch_train_duration{cn} = round(gpio_train_end_time(1)-gpio_train_start_time(1),round_digit_sig,'significant');
				end

				if all(stim_ch_train_duration{cn} == stim_ch_train_duration{cn}(1))
					duration_str = num2str(stim_ch_train_duration{cn}(1));
					stim_ch_str{cn} = sprintf('%s-%ss',stim_ch_name{cn},duration_str);
				else
					duration_str = 'varied';
					stim_ch_str{cn} = sprintf('%s-%s',stim_ch_name{cn},duration_str);
				end

				% stim_ch_str{cn} = sprintf('%s-%ss',stim_ch_name{cn},duration_str);
				% stim_ch_str{cn} = [stim_ch_name{cn}, '-', num2str(stim_ch_train_duration{cn}), 's'];
				if numel(gpio_train_start_time)>1
					stim_ch_train_inter(cn) = round(gpio_train_start_time(2)-gpio_train_end_time(1), 0); % round the interval to the nearest integer
				% else
				% 	stim_ch_train_inter(cn) = [];
				end

				gpio_info(stim_ch_idx).name = stim_ch_name{cn};
				gpio_info(stim_ch_idx).stim_range = stim_ch_time_range{cn};
				gpio_info(stim_ch_idx).patch_coordinats = stim_ch_patch{cn};
				gpio_info(stim_ch_idx).durations = stim_ch_train_duration{cn};
				% gpio_info_organized(stim_idx_start+cn-1).stim_range = stim_ch_time_range{cn};
				% gpio_info_organized(stim_idx_start+cn-1).patch_coordinats = stim_ch_patch{cn};
			end     
	    end
	    gpio_info_organized(numel(loc_ch_nonstim)+1:numel(loc_ch_nonstim)+stim_ch_num) = gpio_info(loc_ch_stim);
	    gpio_info_table = table(stim_ch_name, stim_ch_str, stim_ch_time_range,...
	    	stim_ch_train_duration, stim_ch_train_inter, stim_ch_patch);
	else
		gpio_info_table = [];
    end
    gpio_info_organized(1:numel(loc_ch_nonstim)) = gpio_info(loc_ch_nonstim);
    if nargout == 2
    	varargout{1} = gpio_info_table;
    end
end

