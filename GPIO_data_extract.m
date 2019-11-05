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

% nVoke has a bug to generate a bigger time value. The delayed starting time should be corrected
SYNC_table = GPIO_table(ismember(GPIO_table.ChannelName, 'SYNC'), :);
time_stamp_start = SYNC_table.Time_s_(1);
if time_stamp_start ~= 0
	GPIO_table.Time_s_ = GPIO_table.Time_s_ - time_stamp_start;
end

% find out active channels. SYNC is always active
channel_list = {'SYNC'; 'ExLED'; 'GPIO1'; 'GPIO2'; 'GPIO3'; 'GPIO4'; 'OgLED'};
active_channels = []; % location of channel in the list

p = 1; % p is the position of each active channel info in channel structure
for n = 1 : length(channel_list)
	channel_table = GPIO_table(ismember(GPIO_table.ChannelName, channel_list(n)), :);
	channel_value = find(channel_table.Value(:) ~= 0);
	if ~isempty(channel_value)
		active_channels = [active_channels n];
		channel(p).name = channel_list(n);
		channel(p).time_value(:, 1) = table2array(GPIO_table(ismember(GPIO_table.ChannelName, channel(p).name), 1)); % time info
		channel(p).time_value(:, 2) = table2array(GPIO_table(ismember(GPIO_table.ChannelName, channel(p).name), 3)); % value info
		p = p+1; 
	else
		p = p; % do not generated empty arrays in channel structure
	end
end

% outputs. varible 'channel' is not listed below, but it is outputed primarily
EX_LED_power = max(channel(2).time_value(:, 2)); % EX_LED power for imaging
GPIO_duration = channel(1).time_value(end, 1); % end point of SYNC channel time, the duration of recording
stimulation = channel_list(active_channels(3 : end)); % name of stimulation channel. 1-SYNC， 2-EX_LED

varargout{1} = EX_LED_power;
varargout{2} = GPIO_duration;
varargout{3} = stimulation;

if nargin == 2
	if draw == 1
		channel_no = length(active_channels) - 1; % SYNC channel is not plotted, thus -1
		figure
		for n = 1 : channel_no
			subplot(channel_no, 1, n)
			struct_loc = active_channels(n+1); % channel location in 'channel' structure. SYNC is skipped
			x = channel(struct_loc).time_value(:, 1); % time axis
			y = channel(struct_loc).time_value(:, 2); % value
			stairs(x, y);
			axis([0 GPIO_duration 0 max(y)*1.1]); % limit of x is 0 to the end. limit of y is 110% of max y
			title(channel(struct_loc).name);
		end
	end
end
end

