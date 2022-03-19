function [eventWin,varargout] = get_event_win(peakLoc,time_info,varargin)
	% Using existing peak location, time info to find windows for all events in a trace
	% This window can be used to locate event in another trace, and find the rise and decay position of an event

	% eventWin: n*2 array. n is the number of events. idx in roi_trace is stored here
	% peakLoc: vector. evnet peak location in roi_trace
	% time_info: vector having the same length as roi_trace

	% Defaults
	pre_peakTime = 2; % time before the event peak
	post_peakTime = 5; % time after the event peak

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('pre_peakTime', varargin{ii})
	        pre_peakTime = varargin{ii+1}; % label style. 'shape'/'text'
        elseif strcmpi('post_peakTime', varargin{ii})
	        post_peakTime = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('riseLoc', varargin{ii})
	        riseLoc = varargin{ii+1}; % a column cell containing neuron lables
        % elseif strcmpi('opacity', varargin{ii})
	       %  opacity = varargin{ii+1}; % a column cell containing neuron lables
	    end
	end	

	%% Content
	peak_time = time_info(peakLoc);
	if exist('riseLoc', 'var')
		winStart_ideal = time_info(riseLoc)-pre_peakTime/2;
	else
		winStart_ideal = time_info(peakLoc)-pre_peakTime;
	end

	winEnd_ideal = time_info(peakLoc)+post_peakTime;

	% assign the 1st and the last time_info to the window border if the window time is out of time_info range 
	outRange_idx_lower = find(winStart_ideal<time_info(1));
	outRange_idx_upper = find(winEnd_ideal>time_info(end));
	winStart_ideal(outRange_idx_lower) = time_info(1);
	winEnd_ideal(outRange_idx_upper) = time_info(end);

	% compare win_end and following peak location. if win_end>=peak, assign 
	% win_end to the following event win_start
	if length(winStart_ideal) > 1
		CompareWinMatrix = [winEnd_ideal(1:end-1) peak_time(2:end) winStart_ideal(2:end)];
		idx_mod_win = CompareWinMatrix(:, 1)>=CompareWinMatrix(:, 2);
		CompareWinMatrix(idx_mod_win, 1) = CompareWinMatrix(idx_mod_win, 3);
		winEnd_ideal(1:end-1) = CompareWinMatrix(:, 1);
	end

	% Get the closest number in time_info for winStart_ideal and winEnd_ideal
	[winStart, winStart_idx] = find_closest_in_array(winStart_ideal,time_info);
	[winEnd, winEnd_idx] = find_closest_in_array(winEnd_ideal,time_info);

	eventWin = [winStart winEnd];
	eventWin_idx = [winStart_idx winEnd_idx];
	varargout{1} = eventWin_idx;
end