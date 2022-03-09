function [stimWin,varargout] = get_stimWin_for_event(eventTime,stimRange,varargin)
	% Return the stimulation window for an event 
	% The stimulation window containing/prior the eventTime willl be output

	% eventTime: default value is the event rise time
	% stimRange: a n x 2 array. n is the repeat times of a stim in a trial
	% stimWin: a 1 x 2 array. 1st number is the start of the stim, second number is the end

	% % Defaults
	% eventTime_type = 'rise_time'; % default: 'rise_time'. 'peak_time' may be used as well

	% % Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('eventTime_type', varargin{ii})
	%         eventTime_type = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
 %        % elseif strcmpi('timeInfo', varargin{ii})
	%        %  timeInfo = varargin{ii+1};
	%     end
	% end	


	%% Content
	Tdiff = eventTime-stimRange(:, 1); % time differences between event and starts of stimulation
	idx_stim = find(Tdiff>=0, 1, 'last');
	stimWin = stimRange(idx_stim, :);
	stim_repeats = size(stimRange, 1);
	varargout{1} = stim_repeats;
end