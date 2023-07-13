function [ channel, varargout ] = GPIO_data_extract( GPIO_table, draw )
% Read GPIO_table data to find out imaging LED power, SYNC signal duration, and what channels
% were used for stimulation. This function primarily output organized channels' action and can plot them.
%   
%   
%	GPIO_table_extract(GPIO_table)  
%	GPIO_table_extract( GPIO_table, draw ) - draw EX_LED and stimulation channel stair-steps
%												with SYNC channel duration if draw is 1
%
%
%	INPUTS
%	GPIO_table: table varible including GPIO data exported by Inscopix Data Processing software.
%				Use 'readtable(filename)' to import data from .csv and spreadsheet files
%		1st column: Time (s)
%		2nd column: Channel Name
%		3rd column: value of channels.
%	draw: if 0, do not plot traces. If 1, plot the trace 
%
%   
%	OUTPUTS
%	[ channel ......] - 
%			'channel' structure is always outputed.
%			the rest are varargout. 
%			channel has field 'name' and 'time_value'. data includes 'SYNC', 'EX_LED' and activated stimulation channels.
%			channel(3) - channel(7) refer to stimulation channels. Use active one(s).
%   [ channel EX_LED_power GPIO_duration stimulation ] - 
%			EX_LED is used for imaging
%			stimulation lists the channels used for stimulation
%	
%
%	Channels:								
%		GPIO1,2,3,4 for io1,2,3,4. These channels are used for input output signal
%		SYNC channel time is used to find out the length of recording 
%		EX_LED is excitation LED for imaging
%		OG_LED is for red light optogenetic stimulation
%		

% error(narginchk(1,2));
narginchk(1,2);
% error(nargoutchk(0,2,nargout,'struct'));
channel_list = unique(GPIO_table.ChannelName);


loc_sync = find(contains(GPIO_table.ChannelName,'sync','IgnoreCase',true)); % Get the locations of 'sync' channels
if ~isempty(loc_sync) 
	% nVoke has a bug to generate a bigger time value. The delayed starting time should be corrected
	SYNC_table = GPIO_table(loc_sync, :);
	time_stamp_start = SYNC_table.Time_s_(1);
	if time_stamp_start ~= 0
		GPIO_table.Time_s_ = GPIO_table.Time_s_ - time_stamp_start;
	end


	% Delete channels not used in the recording
	% channel_list = {'SYNC'; 'EX_LED'; 'GPIO1'; 'GPIO2'; 'GPIO3'; 'GPIO4'; 'OG_LED'};
	TF_active_ch = logical(zeros(numel(channel_list),1)); % logical array of channel condition: active (true), not-active (false)
	channel = empty_content_struct({'name','time_value'},numel(channel_list));
	for n = 1 : length(channel_list)
		% channel_table = GPIO_table(ismember(GPIO_table.ChannelName, channel_list(n)), :);
		loc_channel = find(contains(GPIO_table.ChannelName,channel_list{n},'IgnoreCase',true));
		channel_table = GPIO_table(loc_channel, :);
		channel_value = find(channel_table.Value(:) ~= 0);
		KeepChannel = find(contains(channel_list{n},{'BNC Sync Output','EX-LED'},'IgnoreCase',true)); % Always keep the SYNC and EX-LED channels 
		if ~isempty(channel_value) || ~isempty(KeepChannel)
			TF_active_ch(n) = true;
			channel(n).name = channel_list{n};
			% channel(p).name = channel_list(n);
			channel(n).time_value(:, 1) = table2array(GPIO_table(loc_channel, 1)); % time info
			% channel(p).time_value(:, 1) = table2array(GPIO_table(ismember(GPIO_table.ChannelName, channel(p).name), 1)); % time info
			channel(n).time_value(:, 2) = table2array(GPIO_table(loc_channel, 3)); % value info
			% channel(p).time_value(:, 2) = table2array(GPIO_table(ismember(GPIO_table.ChannelName, channel(p).name), 3)); % value info
			% p = p+1; 
		% else
		% 	p = p; % do not generated empty arrays in channel structure
		end
	end
	channel = channel(TF_active_ch); % use logical array TF_active_ch to delete channels
	[channel] = delete_false_gpio_info(channel); % in case some channels are noisey and recogonized as used channels


	% outputs. varible 'channel' is not listed below, but it is outputed primarily
	EX_loc = find(strcmpi('EX-LED',{channel.name})); % get the location of 'EX-LED' in channel
	EX_LED_power = max(channel(EX_loc).time_value(:, 2)); % EX_LED power for imaging
	sync_loc = find(contains({channel.name},'sync','IgnoreCase',true)); % get the location of 'BNC Sync Output' in channel
	loc_last_sync_sig = find(channel(sync_loc).time_value(:, 2), 1, 'last'); % nVoke2 keeps working after scheduled rec finished. Use last sync signal to find the real recording end
	GPIO_duration = channel(sync_loc).time_value(loc_last_sync_sig, 1); % end point of SYNC channel time, the duration of recording
	stim_ch_loc = setdiff([1:numel(channel)],[EX_loc sync_loc]); % locations of stimulation channels in channel
	stim_name = {channel(stim_ch_loc).name}; % names of stimulation channel. 
	% stimulation = channel_list(active_channels(3 : end)); % name of stimulation channel. 1-SYNC， 2-EX_LED

	varargout{1} = EX_LED_power;
	varargout{2} = GPIO_duration;
	varargout{3} = stim_name;

	if nargin == 2
		if draw == 1
			channel_no = length(channel); % SYNC channel is not plotted, thus -1
			figure
			for n = 1 : channel_no
				if n~=sync_loc
					subplot(channel_no, 1, n)
					x = channel(n).time_value(:, 1); % time axis
					y = channel(n).time_value(:, 2); % value
					stairs(x, y);
					axis([0 GPIO_duration 0 max(y)*1.1]); % limit of x is 0 to the end. limit of y is 110% of max y
					title(channel(struct_loc).name);
				end
			end
		end
	end
end

