function [alignedData,varargout] = get_event_trace_trial(trialData,varargin)
% Collect the event traces from a single trial, including multiple rois. Return a struct
%   Utilize the func 'get_event_trace_roi' if the event_spec_table is used to pick detected events
%	Utilize the func 'get_event_trace' if specific window, such as stimulation, is considered as a event
%	
	% Defaults
	event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
	trial_name_col = 1; % Find trial name from the first column of trialData
	traceData_col = 2;
	traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
	stim_name_col = 3;
	gpio_col = 4;
	event_spec_fulltable_col = 5;
	event_data_group = 'peak_lowpass'; % options: 'peak_lowpass', 'peak_smooth', 'peak_decon'
										% keep this consistent with 'traceData_type'

	event_filter = 'none'; % options are: 'none', 'timeWin' (not setup yet), 'event_cat'
	event_align_point = 'rise'; % options: 'rise', 'peak'
	pre_event_time = 1; % unit: s. event trace starts at 1s before event onset
	post_event_time = 2; % unit: s. event trace ends at 2s after event onset
	scale_data = false; % only work if [event_type] is detected_events
	align_on_y = true; % subtract data with the values at the align points
	% win_range = []; 
	cat_keywords =[]; % % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}

	rebound_duration = 1; % default 1s. Used to extend events screen window when 'stimWin' is used for 'event_type'
	mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
	debug_mode = false;

	% Defaults for [get_stimEffect]
	base_timeRange = 2; % default 2s. 
	ex_eventCat = {'trig'}; % event category string used to define excitation. May contain multiple strings
	rb_eventCat = {'rebound'}; % event category string used to define rebound. May contain multiple strings
	in_thresh_stdScale = 2; % n times of std lower than baseline level. Last n s during stimulation is used
	in_calLength = 1; % calculate the last n s trace level during stimulation to 

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('event_type', varargin{ii})
	        event_type = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('traceData_type', varargin{ii})
	        traceData_type = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('event_data_group', varargin{ii})
	        event_data_group = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    elseif strcmpi('event_filter', varargin{ii})
	        event_filter = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
	    % elseif strcmpi('win_range', varargin{ii})
	    %     win_range = varargin{ii+1}; % nx2 array. stim_range in the gpio info (4th column of recdata_organized) can be used for this
	    elseif strcmpi('cat_keywords', varargin{ii})
	        cat_keywords = varargin{ii+1}; % can be a cell array containing multiple keywords
	    elseif strcmpi('event_align_point', varargin{ii})
	        event_align_point = varargin{ii+1}; % 'rise' or 'peak'
	    elseif strcmpi('pre_event_time', varargin{ii})
	        pre_event_time = varargin{ii+1};
	    elseif strcmpi('post_event_time', varargin{ii})
	        post_event_time = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    elseif strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
	    elseif strcmpi('mod_pcn', varargin{ii})
	        mod_pcn = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents
	alignedData.trialName = trialData{trial_name_col};
	alignedData.event_type = event_type;
	alignedData.cat_keywords = cat_keywords;
	alignedData.data_type = traceData_type;
	alignedData.stim_name = char(trialData{stim_name_col});
	alignedData.roi_map = trialData{traceData_col}.roi_map;
	if isfield(trialData{traceData_col}, 'fovID')
		alignedData.fovID = trialData{traceData_col}.fovID;
	else
		alignedData.fovID = 'NA';
	end

	time_trace_data = trialData{traceData_col}.(traceData_type);
	full_time = time_trace_data.Time;
	full_traces_data = time_trace_data(:, 2:end);
	% roi_num = size(full_traces_data, 2);

	event_spec_fulltable = trialData{event_spec_fulltable_col};
	roi_num = size(event_spec_fulltable, 2);
	
	gpio_info = trialData{gpio_col}(3:end);
	if ~isempty(gpio_info)
		[alignedData.stimInfo,combine_stimRange,combine_stimDuration] = get_stimInfo(gpio_info);
		if strcmpi(event_type, 'stimWin')
			stimStart = combine_stimRange(:, 1);
			post_event_time = post_event_time+combine_stimDuration;
		end
	else
		alignedData.stimInfo = 'NA';
		combine_stimRange = [];
		if strcmpi(event_type, 'stimWin')
			stimStart = [];
		end
	end


	% event_spec_fulltable = trialData{event_spec_fulltable_col};
	aligned_time = [];
	alignedData.traces =  struct('roi', cell(1, roi_num), 'value', cell(1, roi_num),...
		'mean_val', cell(1, roi_num), 'std_val', cell(1, roi_num),...
		'roi_coor', cell(1, roi_num), 'eventProp', cell(1, roi_num));
	for n = 1:roi_num
		% roiName = full_traces_data.Properties.VariableNames{n};
		roiName = event_spec_fulltable.Properties.VariableNames{n};
		roi_trace_data = full_traces_data.(roiName);
		alignedData.traces(n).roi = roiName;
		roi_event_spec_table = event_spec_fulltable{event_data_group, roiName}{:};

		if debug_mode
			fprintf(' - roi %d/%d %s\n', n, roi_num, roiName)
		end
		

		switch event_type
			case 'detected_events'
				if ~isempty(roi_event_spec_table)
					[aligned_time,traceValue,traceMean_val,traceStd_val,eventProp,events_idx] = get_event_trace_roi(full_time,roi_trace_data,roi_event_spec_table,...
						'event_align_point', event_align_point, 'event_filter', event_filter,...
						'cat_keywords', cat_keywords,...
						'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
						'align_on_y', align_on_y, 'scale_data', scale_data);
					alignedData.traces(n).value = traceValue; 
					alignedData.traces(n).mean_val = traceMean_val; 
					alignedData.traces(n).std_val = traceStd_val; 
					alignedData.traces(n).eventProp = eventProp; 
					alignedData.traces(n).roi_coor = trialData{traceData_col}.roi_center(n,:); % coordinate of roi (unit: pixel)
				else
					% aligned_time = [];
				end

			case 'stimWin'
				if ~isempty(stimStart)
					[aligned_time,traceValue,traceMean_val,traceStd_val] = get_event_trace(stimStart,full_time,roi_trace_data,...
						'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
						'align_on_y', align_on_y, 'scale_data', scale_data);
					alignedData.traces(n).value = traceValue; 
					alignedData.traces(n).mean_val = traceMean_val; 
					alignedData.traces(n).std_val = traceStd_val;

					condition_win = combine_stimRange;
					condition_win(:, 2) = condition_win(:, 2)+rebound_duration;
					events_time = roi_event_spec_table.rise_time;
					if ~isempty(events_time)
						[eventProp] = get_events_info(events_time,condition_win,roi_event_spec_table,'style','event');
                        alignedData.traces(n).eventProp = eventProp;
                        alignedData.traces(n).roi_coor = trialData{traceData_col}.roi_center(n,:); 
                    else
                        alignedData.traces(n).eventProp = [];
					end
					
				else
					% aligned_time = [];
				end
			otherwise
				fprintf('Warning: only use [detected_events] or [stimWin] for var [event_type]\n')
		end
		alignedData.traces(n).fullTrace = roi_trace_data;
		if ~isempty(alignedData.traces(n).eventProp) && mod_pcn
			[alignedData.traces(n).eventProp] = mod_cat_name(alignedData.traces(n).eventProp,'dis_extra',false);
			[alignedData.traces(n).eventProp] = add_eventBaseDiff_to_eventProp(alignedData.traces(n).eventProp,...
				combine_stimRange,full_time,roi_trace_data,varargin);
			[alignedData.traces(n).eventProp] = add_tfTag_to_eventProp(alignedData.traces(n).eventProp,...
				'peak_category','trig','newFieldName','stimTrig');
			[alignedData.traces(n).eventProp] = add_riseDelay_to_eventProp(alignedData.traces(n).eventProp,...
				combine_stimRange,'errCali',0);
		end
		[alignedData.traces(n).stimEffect] = get_stimEffect(full_time,roi_trace_data,combine_stimRange,...
			{alignedData.traces(n).eventProp.peak_category},'ex_eventCat',ex_eventCat,...
			'rb_eventCat',rb_eventCat,'in_thresh_stdScale',in_thresh_stdScale,...
			'in_calLength',in_calLength); % find the stimulation effect. stimEffect is a struct var
	end
	alignedData.time = aligned_time;
	alignedData.fullTime = full_time;
end

