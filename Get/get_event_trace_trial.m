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
	stim_section = false; % true: use a specific section of stimulation. For example the last 1s
	ss_range = 2; % single number (last n second) or a 2-element array (start and end. 0s is stimulation onset)
	stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
	decline_per = 0.5; % percentage of neurons (ROIs) with declined calcium during stimulation
	spon_norm_field = {'rise_duration','peak_mag_delta'}; % calculate the normalized data to spon spikes of given field in "eventProp" 

	% Defaults for [get_stimEffect]
	base_timeRange = 2; % default 2s. 
	ex_eventCat = {'trig'}; % event category string used to define excitation. May contain multiple strings
	rb_eventCat = {'rebound'}; % event category string used to define rebound. May contain multiple strings
	in_thresh_stdScale = 2; % n times of std lower than baseline level. Last n s during stimulation is used
	in_calLength = 1; % calculate the last n s trace level during stimulation to 

	debug_mode = false; % true/false

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
	    elseif strcmpi('stim_section', varargin{ii}) % used for calcium level delta calculation. True: use specific seciton
	        stim_section = varargin{ii+1};
	    elseif strcmpi('ss_range', varargin{ii}) % used for calcium level delta calculation. True: use specific seciton
	        ss_range = varargin{ii+1};
	    elseif strcmpi('rebound_duration', varargin{ii})
	        rebound_duration = varargin{ii+1};
	    elseif strcmpi('stim_time_error', varargin{ii})
	        stim_time_error = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    elseif strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
	    elseif strcmpi('mod_pcn', varargin{ii})
	        mod_pcn = varargin{ii+1};
	    elseif strcmpi('debug_mode', varargin{ii})
	        debug_mode = varargin{ii+1};
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
	duration_full_time = full_time(end)-full_time(1);
	full_traces_data = time_trace_data(:, 2:end);
	% roi_num = size(full_traces_data, 2);

	event_spec_fulltable = trialData{event_spec_fulltable_col};
	roi_num = size(event_spec_fulltable, 2);
	
	ch_names = {trialData{gpio_col}.name};
	[~,gpio_ch_locs] = gpio_ch_names(ch_names,2); % 2: use the modified channel names, such as {'AP_GPIO-1','Airpuff-START','AP'}
	gpio_info = trialData{gpio_col}(gpio_ch_locs.stim);
	if ~isempty(gpio_info)
		[alignedData.stimInfo,combine_stimRange,combine_stimDuration] = get_stimInfo(gpio_info);
		combine_stimRange(:,1) = combine_stimRange(:,1)-stim_time_error;
		combine_stimRange(:,2) = combine_stimRange(:,2)+stim_time_error;
		combine_stimDuration = combine_stimDuration+stim_time_error+stim_time_error;
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
	empty_idx = []; % roi idx in alignedData.traces does not contain any event info
	for n = 1:roi_num
		% roiName = full_traces_data.Properties.VariableNames{n};
		roiName = event_spec_fulltable.Properties.VariableNames{n};
		roi_trace_data = full_traces_data.(roiName);
		alignedData.traces(n).roi = roiName;
		roi_event_spec_table = event_spec_fulltable{event_data_group, roiName}{:};

		if debug_mode
			fprintf(' - roi %d/%d %s\n', n, roi_num, roiName)
			if n == 15
% 				pause
			end
		end

		if ~isempty(roi_event_spec_table)
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
							% [eventProp] = get_events_info(events_time,condition_win,roi_event_spec_table,'style','event');
							[eventProp] = get_events_info(events_time,[],roi_event_spec_table,'style','event');
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

			% modify the names of peak categories 
			if ~isempty(alignedData.traces(n).eventProp) && mod_pcn 
				[cat_setting] = set_CatNames_for_mod_cat_name('event');
				[alignedData.traces(n).eventProp] = mod_cat_name(alignedData.traces(n).eventProp,'cat_setting',cat_setting,'dis_extra',false);
				[alignedData.traces(n).eventProp] = add_eventBaseDiff_to_eventProp(alignedData.traces(n).eventProp,...
					combine_stimRange,full_time,roi_trace_data,varargin);
				[alignedData.traces(n).eventProp,newFieldName,NFNtag] = add_tfTag_to_eventProp(alignedData.traces(n).eventProp,...
					'peak_category','trig','newFieldName','stimTrig');
				[alignedData.traces(n).eventProp] = add_riseDelay_to_eventProp(alignedData.traces(n).eventProp,...
					combine_stimRange,'errCali',0);

				% Get the possibility of stimulation related events: spike_num/stimulation number
				% Each category of spikes is calculated separately.
				eventProp_stim = dis_struct_entry(alignedData.traces(n).eventProp,'peak_category',...
					'spon','discard');
				[alignedData.traces(n).stimEvent_possi] = get_stimEvent_possibility({eventProp_stim.peak_category},...
					alignedData.stimInfo.repeats);
			end
			% get the event number and frequency (spontaneous events and event during stimulation)
			events_time = [alignedData.traces(n).eventProp.rise_time];
			if contains(alignedData.stim_name, 'GPIO-1', 'IgnoreCase',true)
				exclude_duration = 0;
				exepWinDur = 0;
			else
				exclude_duration = 1;
				exepWinDur = rebound_duration;
			end
			[stimWin,sponWin,~,stimDuration,sponDuration] = get_condition_win(combine_stimRange,full_time,...
				'err_duration', 0, 'exclude_duration', exclude_duration); % add 1s exclude duration after opto stimulation
			[~,sponfq,stimfq,sponEventNum,stimEventNum,exepEventNum] = stim_effect_compare_eventFreq_roi2(events_time,...
				combine_stimRange,duration_full_time,'exepWinDur',exepWinDur);
			[sponfq,sponInterval,sponIdx,sponEventTime,sponEventNum] = get_event_freq_interval(events_time,sponWin);


			% Get the effect of stimulation on each ROI
			[alignedData.traces(n).stimEffect] = get_stimEffect(full_time,roi_trace_data,combine_stimRange,...
				{alignedData.traces(n).eventProp.peak_category},'ex_eventCat',ex_eventCat,...
				'rb_eventCat',rb_eventCat,'in_thresh_stdScale',in_thresh_stdScale,...
				'in_calLength',in_calLength,'freq_spon_stim', [sponfq stimfq]); % find the stimulation effect. stimEffect is a struct var

			% Get the amplitude of spontaneous events
			[category_idx] = get_category_idx({alignedData.traces(n).eventProp.peak_category});
			spon_idx = find(contains({category_idx.name},'spon')); % index of spon category in category_idx
			if ~isempty(spon_idx)
				sponEvent_idx = category_idx(spon_idx).idx;
				[sponAmp] = CollectAndAverage_fielddata(alignedData.traces(n).eventProp(sponEvent_idx),'peak_mag_delta');
            else
                sponEvent_idx = [];
				sponAmp = NaN;
			end

			% Calculate the data normalized to spon spikes and store them in new fields
			[alignedData.traces(n).eventProp] = add_norm_fields(alignedData.traces(n).eventProp,spon_norm_field,...
				'ref_idx',sponEvent_idx,'newF_prefix','sponnorm');

			% Get the baseline change 
			[CaLevel,CaLevelTrace,CaLevel_cal_range] = get_CaLevel_delta(combine_stimRange,full_time,roi_trace_data,...
				'base_timeRange',base_timeRange,'postStim_timeRange',base_timeRange,...
				'stim_section',stim_section,'ss_range',ss_range,'stim_time_error',stim_time_error);

			alignedData.traces(n).(newFieldName) = NFNtag;
			alignedData.traces(n).sponfq = sponfq;
			alignedData.traces(n).sponInterval = sponInterval;
			alignedData.traces(n).stimfq = stimfq;
			alignedData.traces(n).stimfqNorm = stimfq/sponfq;
			alignedData.traces(n).stimfqDeltaNorm = (stimfq-sponfq)/sponfq;
			alignedData.traces(n).sponEventNum = sponEventNum;
			alignedData.traces(n).stimEventNum = stimEventNum;
			alignedData.traces(n).exepEventNum = exepEventNum;
			alignedData.traces(n).sponAmp = sponAmp;
			% alignedData.traces(n).baseChangeNorm = baseChange.Change_norm;
			alignedData.traces(n).CaLevelDelta = CaLevel.delta;
			alignedData.traces(n).CaLevelmeanBase = CaLevel.meanBase;
			alignedData.traces(n).CaLevelmeanStim = CaLevel.meanStim;
			alignedData.traces(n).CaLevelDeltaData = CaLevel.delta_data;
			% alignedData.traces(n).baseChangeMinNorm = baseChange.ChangeMin_norm;
			alignedData.traces(n).CaLevelMinDelta = CaLevel.min_delta;
			alignedData.traces(n).CaLevelMinDeltaData = CaLevel.min_delta_data;
			alignedData.traces(n).CaLevelDecline = CaLevel.decline; % Logical val. True if CaLevelDelta is beyond the base_mean-2*base_std
			% alignedData.traces(n).CaLevelTrace.timeInfo = CaLevelTrace.timeInfo;
			% alignedData.traces(n).CaLevelTrace.yAlign = CaLevelTrace.yAlign;
			aligned_time_CaLevel = CaLevelTrace.timeInfo;
			alignedData.traces(n).CaLevelTrace = CaLevelTrace.yAlign;
		else
			empty_idx = [empty_idx n];
		end
	end
	alignedData.traces(empty_idx) = [];

	neuronNum = length(alignedData.traces);
	CaDecline_neuronNum = numel(find([alignedData.traces.CaLevelDecline]));
	if CaDecline_neuronNum/neuronNum>=decline_per
		alignedData.CaDecline = true;
	else
		alignedData.CaDecline = false;
	end

	[~,alignedData.num_exROI] = get_struct_entry_idx(alignedData.traces,'stimEffect','excitation','req',true);
	[~,alignedData.num_inROI] = get_struct_entry_idx(alignedData.traces,'stimEffect','inhibition','req',true);
	alignedData.time = aligned_time;
	alignedData.timeCaLevel = aligned_time_CaLevel;
	alignedData.CaLevel_cal_range = CaLevel_cal_range;
	alignedData.fullTime = full_time;
end