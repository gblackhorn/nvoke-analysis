function [StimDuration,varargout] = get_stimInfo(gpioInfo,varargin)
% Read recdata_organized gpio info and extract stimulation info (used for aligned events)

	
	% Defaults
	fn_stimName = 'name'; % field name of stimulation
	fn_range = 'stim_range'; % field name of stimulation range (n x 2 vector). n is repeat times
	round_digit_sig = 2; % round to the Nth significanat digit

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('fn_stimName', varargin{ii})
	        fn_stimName = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('fn_range', varargin{ii})
	        fn_range = varargin{ii+1};
        elseif strcmpi('round_digit_sig', varargin{ii})
	        round_digit_sig = varargin{ii+1};
        % elseif strcmpi('in_calLength', varargin{ii})
	       %  in_calLength = varargin{ii+1};
	    end
	end	

	%% Content
	stim_range_cells = {gpioInfo.(fn_range)}; % convert stim_range to cell array.
	stim_rows = find(~cellfun(@isempty, stim_range_cells)); % rows contain stim info have non-empty stim_range

	gpioInfo_stim = gpioInfo(stim_rows);

	if ~isempty(gpioInfo_stim)
		stim_ch_num = numel(gpioInfo_stim);
		stimInfo = empty_content_struct({'stim','fixed','array','time_range','time_range_notAlign'},stim_ch_num);
		% stimInfo = empty_content_struct({'stim','duration_sec','duration_array','time_range','time_range_notAlign'},stim_ch_num);
		StimRange = {gpioInfo_stim.(fn_range)};
		StimType = {gpioInfo_stim.(fn_stimName)};
		[StimDuration,UnifiedStimDuration,ExtraInfo] = ExtractStimDurationAndExtraInfo(StimRange,round_digit_sig);

		for scn = 1:stim_ch_num % assign the stimInfo to each channel
			StimDuration(scn).type = StimType{scn};
		end

		UnifiedStimDuration.type = join(StimType(ExtraInfo.type_order),'&');

		varargout{1} = UnifiedStimDuration; % combine range
		varargout{2} = ExtraInfo;
	end
end