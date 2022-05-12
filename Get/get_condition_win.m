function [conWin,non_conWin,excludeWin,varargout] = get_condition_win(condition_range,recording_time,varargin)
	% Return the time windows for condition related events and non-condition related events

	% condition_range: a 2-col array. 1st col contains the starts of the windows, 2nd col contains the ends
	% recording_time: vector. length >= 2. The first and end elements are used to set the start and end of some windows

	% Defaults
	err_duration = 0; % used to expand the conditon_range. start-err_duration; end+err_duration
	exclude_duration = 1; % exclude the n second(s) after conWin. Generate another kind of window different from the non-conWin
	% normData = true; % whether normalize alignedTrace with average value of pc_norm data

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('err_duration', varargin{ii})
	        err_duration = varargin{ii+1}; 
	    elseif strcmpi('exclude_duration', varargin{ii})
	        exclude_duration = varargin{ii+1};
	    % elseif strcmpi('normData', varargin{ii})
	    %     normData = varargin{ii+1};
	    end
	end	

	%% Content
	conWin(:, 1) = condition_range(:, 1)-err_duration;
	conWin(:, 2) = condition_range(:, 2)+err_duration;

	non_conWin(:, 1) = [recording_time(1); (conWin(:, 2)+exclude_duration)]; % starts of windows
	non_conWin(:, 2) = [conWin(:, 1); recording_time(end)]; % ends of windows

	excludeWin(:, 1) = conWin(:, 2);
	excludeWin(:, 2) = conWin(:, 2)+exclude_duration;

	% full durations of various window types
	conWin_duration = sum(conWin(:, 2)-conWin(:, 1));
	non_conWin_duration = sum(non_conWin(:, 2)-non_conWin(:, 1)); % full duration of spont windows
	excludeWin_duration = sum(excludeWin(:, 2)-excludeWin(:, 1)); % full duration of spont windows

	varargout{1} = conWin_duration;
	varargout{2} = non_conWin_duration;
	varargout{3} = excludeWin_duration;
end