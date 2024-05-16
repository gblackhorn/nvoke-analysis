function [freq,meanInterval,varargout] = get_event_freq_interval(all_events_time,condition_win,varargin)
	% Get the frequency and interval of events in specified condition window(s)

	% all_events_time: a vector. 
	% condition_win: a 2-col array. 1st col contains the starts of the windows, 2nd col contains the ends

	% Defaults
	% pc_norm = 'spon'; % alignedTrace will be normalized to the average value of this event category
	% amp_data = []; % a vector array having the same length as peakCategories
	% normData = true; % whether normalize alignedTrace with average value of pc_norm data

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('pc_norm', varargin{ii})
	%         pc_norm = varargin{ii+1}; 
	%     elseif strcmpi('amp_data', varargin{ii})
	%         amp_data = varargin{ii+1};
	%     elseif strcmpi('normData', varargin{ii})
	%         normData = varargin{ii+1};
	%     end
	% end	

	% Ensure the all_events_time is a vertical vector
	if size(all_events_time, 2) > 1
		all_events_time = all_events_time(:);
	end 

	% Pre-llocate memory
	win_num = size(condition_win, 1);
	idx_cell = cell(win_num, 1); % idx of events in each condition window
	event_time_cell = cell(win_num, 1);
	event_interval_time_cell = cell(win_num, 1);

	% Loop through all the condition windows
	for n = 1:win_num
		% Get the events in this condition window. Ensure the vector in idx_cell{n} is verticle
	    idx_cell{n} = find(all_events_time>=condition_win(n, 1) & all_events_time<condition_win(n, 2))';
	    if size(idx_cell{n}, 2) > 1
	    	idx_cell{n} = idx_cell{n}(:);
	    end

	    % Get the time of events in this window
	    event_time_cell{n} = all_events_time(idx_cell{n});

	    % Get the interval time between the events
	    event_interval_time_cell{n} = diff(event_time_cell{n});
	end

	% Concatenate the entries in cell arrays 
	idx = vertcat(idx_cell{:});
	events_time = vertcat(event_time_cell{:});
	events_interval_time = vertcat(event_interval_time_cell{:});

	% Count the number of events
	event_num = numel(events_time);

	% Get the sum of all the condition windows
	sumConWin = sum(condition_win(:, 2)-condition_win(:, 1)); % full duration of condition windows 

	% Calculate the event frequency
	freq = event_num/sumConWin;

	% Calculate the mean 
	meanInterval = mean(events_interval_time);

	varargout{1} = idx;
	varargout{2} = events_time;
	varargout{3} = event_num;
	varargout{4} = sumConWin;
	varargout{5} = events_interval_time;
end