function [stimInfo,varargout] = get_stimInfo(gpioInfo,varargin)
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
        % elseif strcmpi('in_thresh', varargin{ii})
	       %  in_thresh = varargin{ii+1};
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
		stimInfo = empty_content_struct({'stim','duration_sec','duration_array','time_range','time_range_notAlign'},stim_ch_num);
		% stimInfo = struct('stim', cell(1, stim_ch_num), 'duration_sec', NaN(1, stim_ch_num),...
		% 	'time_range', cell(1, stim_ch_num), 'time_range_notAlign', cell(1, stim_ch_num));
		stim_start_time = NaN(1, stim_ch_num);

		for scn = 1:stim_ch_num
			stimInfo(scn).stim = gpioInfo_stim(scn).(fn_stimName);

			stim_durations = round(gpioInfo_stim(scn).(fn_range)(:, 2)-gpioInfo_stim(scn).(fn_range)(:, 1),round_digit_sig,'significant');
			if all(stim_durations == stim_durations(1)) 
				varied_duration = false;
				stimInfo(scn).duration_sec = stim_durations(1);
				stimInfo(scn).repeats = size(gpioInfo_stim(scn).(fn_range), 1); % number of repeats
			else
				varied_duration = true;
				stimInfo(scn).duration_sec = stim_durations;
				stimInfo(scn).repeats = NaN;
			end
			stimInfo(scn).time_range_notAlign = gpioInfo_stim(scn).(fn_range);
			
			stim_start_time(scn) = gpioInfo_stim(scn).(fn_range)(1, 1);
		end

		[~, stim_start_order] = sort(stim_start_time); % When various stim applied, use the one start early as the stim_start
		stim_start_first_idx = stim_start_order(1);
		stim_start_first = stim_start_time(stim_start_first_idx);
		stims_start = stim_start_time-stim_start_first; % align stimulation start points
		stims_end = stims_start+[stimInfo.duration_sec]; % get stimulation end points after alignment
		[~, stim_end_order] = sort(stim_start_time+[stimInfo.duration_sec], 'descend'); % use the stim ending later as stim_end
		stim_end_last_idx = stim_end_order(1);
		for scn = 1:stim_ch_num
			stimInfo(scn).time_range = [stims_start(scn) stims_end(scn)];
		end

		% combine value: Use the stim starting first as start, use the stim ending last as the last
		combine_start = stimInfo(stim_start_first_idx).time_range_notAlign(:, 1);
		combine_end = stimInfo(stim_end_last_idx).time_range_notAlign(:, 2);

		if varied_duration
			combine_duration = combine_end - combine_start;
		else
			combine_duration = combine_end(1) - combine_start(1);
		end
	end

	varargout{1} = [combine_start combine_end]; % combine range
	varargout{2} = combine_duration;

end