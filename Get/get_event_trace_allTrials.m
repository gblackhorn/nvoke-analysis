function [alignedData_allTrials,varargout] = get_event_trace_allTrials(allTrialsData,varargin)
% Collect the event traces from all trials in a [recdata_organized]. Return a struct
%   Utilize the func 'get_event_trace_trial' if the event_spec_table is used to pick detected events

	% Defaults
	event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
	traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
	event_data_group = 'peak_lowpass'; % options: 'peak_lowpass', 'peak_smooth', 'peak_decon'.
										% keep this consistent with 'traceData_type'
	event_filter = 'none'; % options are: 'none', 'timeWin' (not setup yet), 'event_cat'
	event_align_point = 'rise'; % options: 'rise', 'peak'
	eventTimeType = 'peak_time'; % rise_time/peak_time. pick one of the for event time.
	decay_eventCat = {'rebound','trig-ap'}; % add decay tau and calcium level change to the eventProp of these events

	trial_name_col = 1; % Find trial name from the first column of trialData
	traceData_col = 2;
	stim_name_col = 3;
	gpio_col = 4;
	event_spec_fulltable_col = 5;

	pre_event_time = 1; % unit: s. event trace starts at 1s before event onset
	post_event_time = 2; % unit: s. event trace ends at 2s after event onset
	scale_data = false; % only work if [event_type] is detected_events
	align_on_y = true; % subtract data with the values at the align points
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
	exAP_eventCat = {'trig-ap'}; % event category string used to define excitation caused by airpuff during og stimulation. 
	rb_eventCat = {'rebound'}; % event category string used to define rebound. May contain multiple strings
	in_thresh_stdScale = 2; % n times of std lower than baseline level. Last n s during stimulation is used
	in_calLength = 1; % calculate the last n s trace level during stimulation to 

	rsquareThresh = 0.7; % used for fitting the decay of traces during OG

	% Defaults for filtering out data
	caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)
	disROI = true; % true/false. If true, Keep ROIs using the setting below, and delete the rest
	disROI_setting.stims = {'AP_GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s AP_GPIO-1-1s'};
	disROI_setting.eventCats = {{'spon'}, {'spon'}, {'spon'}};
	sponfreqFilter.status = true; % true/false. If true, use the following settings to filter ROIs
	sponfreqFilter.field = 'sponfq'; % 
	sponfreqFilter.thresh = 0.05; % Hz. default 0.06
	sponfreqFilter.direction = 'high';


	debug_mode = false; % true/false


	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('event_type', varargin{ii})
	        event_type = varargin{ii+1}; 
	    elseif strcmpi('traceData_type', varargin{ii})
	        traceData_type = varargin{ii+1}; 
	    elseif strcmpi('event_data_group', varargin{ii})
	        event_data_group = varargin{ii+1}; 
	    elseif strcmpi('event_filter', varargin{ii})
	        event_filter = varargin{ii+1}; % options are: 'none', 'stim', 'event_cat'
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
	    elseif strcmpi('stim_time_error', varargin{ii})
	        stim_time_error = varargin{ii+1};
	    elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1};
	    elseif strcmpi('rebound_duration', varargin{ii})
	        rebound_duration = varargin{ii+1};
	    elseif strcmpi('align_on_y', varargin{ii})
	        align_on_y = varargin{ii+1};
	    elseif strcmpi('scale_data', varargin{ii})
	        scale_data = varargin{ii+1};
        elseif strcmpi('mod_pcn', varargin{ii})
        	mod_pcn = varargin{ii+1};
        elseif strcmpi('caDeclineOnly', varargin{ii})
        	caDeclineOnly = varargin{ii+1};
        elseif strcmpi('disROI', varargin{ii})
        	disROI = varargin{ii+1};
        elseif strcmpi('disROI_setting', varargin{ii})
        	disROI_setting = varargin{ii+1};
        elseif strcmpi('sponfreqFilter', varargin{ii})
        	sponfreqFilter = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
        	debug_mode = varargin{ii+1};
	    end
	end

	% Get the number of trials (recordings) and prepare data_cell, an empty cell var, to store data
	% for every trial
	trial_num = size(allTrialsData, 1);
	data_cell = cell(1, trial_num);

	% Loop through trials (recordings)
	for tn = 1:trial_num
		if debug_mode
			fprintf('trial %d: %s\n', tn, allTrialsData{tn, 1})
			% if n == 44
			% 	pause
			% end
		end

		% Get data from a single trial
		trialData = allTrialsData(tn, :);

		% Clear some variables used in the loop
		clear alignedData combine_stimRange


		% Organize data 
		alignedData.trialName = trialData{trial_name_col};
		alignedData.event_type = event_type;
		alignedData.cat_keywords = cat_keywords;
		alignedData.data_type = traceData_type;
		alignedData.stim_name = char(trialData{stim_name_col});
		alignedData.roi_map = trialData{traceData_col}.roi_map;
		if isfield(trialData{traceData_col}, 'fovID')
			alignedData.fovID = trialData{traceData_col}.fovID;
			alignedData.fovLoc = trialData{traceData_col}.FOV_loc;
		else
			alignedData.fovID = 'NA';
			alignedData.fovLoc = 'NA';
		end

		% Get the time info and calcium signal (usually 'lowpass' data and 'decon' data)
		timeTraceData = trialData{traceData_col}.(traceData_type);
		fullTime = timeTraceData.Time;
		duration_fullTime = fullTime(end)-fullTime(1);
		fullTracesData = timeTraceData(:, 2:end);
		timeTraceDataDecon = trialData{traceData_col}.decon;
		fullTracesDataDecon = timeTraceDataDecon(:, 2:end);


		event_spec_fulltable = trialData{event_spec_fulltable_col};
		roi_num = size(event_spec_fulltable, 2);
		
		% Organize the stimulation information and store them in alignedData.stimInfo
		ch_names = {trialData{gpio_col}.name};
		[~,gpio_ch_locs] = gpio_ch_names(ch_names,2); % 2: use the modified channel names, such as {'AP_GPIO-1','Airpuff-START','AP'}
		gpio_info = trialData{gpio_col}(gpio_ch_locs.stim);
		if ~isempty(gpio_info)
			[alignedData.stimInfo.StimDuration,alignedData.stimInfo.UnifiedStimDuration,ExtraInfo] = get_stimInfo(gpio_info);
			% [alignedData.stimInfo,combine_stimRange,combine_stimDuration] = get_stimInfo(gpio_info);
			alignedData.stimInfo.multistim = ExtraInfo.multistim; % true if multiple types of stimulation applied
			alignedData.stimInfo.stimtype_num = ExtraInfo.stimtype_num; % number of stimulation types
			alignedData.stimInfo.type_order = ExtraInfo.type_order; % onset order of stimulation types which are shown in alignedData.stimInfo.StimDuration
			combine_stimRange(:,1) = alignedData.stimInfo.UnifiedStimDuration.range(:,1)-stim_time_error;
			combine_stimRange(:,2) = alignedData.stimInfo.UnifiedStimDuration.range(:,2)+stim_time_error; %
			combine_stimDuration = alignedData.stimInfo.UnifiedStimDuration.fixed+stim_time_error*2;
			if strcmpi(event_type, 'stimWin')
				stimStart = combine_stimRange(:, 1);
				post_event_time_trial = post_event_time+combine_stimDuration;
			end
			[stimEventCatPairs] = setStimEventCatPairs(alignedData.stimInfo.StimDuration); % the pairs of stimulations and their related event category
		else
			alignedData.stimInfo = 'NA';
			combine_stimRange = [];
			if strcmpi(event_type, 'stimWin')
				stimStart = [];
			end
		end


		% event_spec_fulltable = trialData{event_spec_fulltable_col};
		aligned_time = [];

		% Create an empty structure to store the ROI information
		% Update this using the function 'empty_content_struct'. Add all the fieldnames
		fieldNamesOfDataTraces = {'roi','value','mean_val','std_val','roi_coor','roiEdge',...
		'subNuclei','eventProp'};
		alignedData.traces = empty_content_struct(fieldNamesOfDataTraces,roi_num);
		% alignedData.traces =  struct('roi', cell(1, roi_num), 'value', cell(1, roi_num),...
		% 	'mean_val', cell(1, roi_num), 'std_val', cell(1, roi_num),...
		% 	'roi_coor', cell(1, roi_num), 'eventProp', cell(1, roi_num));

		% Add roi names to the 'roi' field in alignedData.traces
		[alignedData.traces.roi] = event_spec_fulltable.Properties.VariableNames{:};

		% Add roi location tag to the 'subNuclei' field in alignedData.traces
		if isfield(trialData{traceData_col},'locTag')
			[alignedData.traces.subNuclei] = trialData{traceData_col}.locTag(:).locTags;
		end
		
		empty_idx = []; % roi idx in alignedData.traces does not contain any event info
		for n = 1:roi_num
			% roiName = fullTracesData.Properties.VariableNames{n};
			roiName = event_spec_fulltable.Properties.VariableNames{n};
			roiTraceData = fullTracesData.(roiName);
			roiTraceDataDecon = fullTracesDataDecon.(roiName);
			alignedData.traces(n).roi = roiName;
			roi_event_spec_table = event_spec_fulltable{event_data_group, roiName}{:};

			% Temporal solution: event spec table can be not empty, but the number will be 1 and value is NaN
			if numel(roi_event_spec_table.peak_loc) == 1 && isnan(roi_event_spec_table.peak_loc)
				roi_event_spec_table = [];
			end

			if debug_mode
				fprintf(' - roi %d/%d %s\n', n, roi_num, roiName)
				if n == 17
	% 				pause
				end
			end

			if ~isempty(roi_event_spec_table)
				switch event_type
					case 'detected_events'
						if ~isempty(roi_event_spec_table)
							[aligned_time,traceValue,traceMean_val,traceStd_val,eventProp,alignedTrace_scaled] = get_event_trace_roi(fullTime,roiTraceData,roi_event_spec_table,...
								'event_align_point', event_align_point, 'event_filter', event_filter,...
								'cat_keywords', cat_keywords,...
								'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
								'align_on_y', align_on_y, 'scale_data', scale_data);
							alignedData.traces(n).value = traceValue; 
							alignedData.traces(n).mean_val = traceMean_val; 
							alignedData.traces(n).std_val = traceStd_val; 
							alignedData.traces(n).eventProp = eventProp; 
							alignedData.traces(n).roi_coor = trialData{traceData_col}.roi_center(n,:); % coordinate of roi (unit: pixel)
							alignedData.traces(n).roiEdge = trialData{traceData_col}.roi_edge{n}; % coordinate of roi (unit: pixel)
						else
							% aligned_time = [];
						end

					case 'stimWin'
						if ~isempty(stimStart)
							[aligned_time,traceValue,traceMean_val,traceStd_val] = get_event_trace(stimStart,fullTime,roiTraceData,...
								'pre_event_time', pre_event_time, 'post_event_time', post_event_time_trial,...
								'align_on_y', align_on_y, 'scale_data', scale_data);
							alignedData.traces(n).value = traceValue; 
							alignedData.traces(n).mean_val = traceMean_val; 
							alignedData.traces(n).std_val = traceStd_val;

							condition_win = combine_stimRange;
							condition_win(:, 2) = condition_win(:, 2)+rebound_duration;
							events_time = roi_event_spec_table.(eventTimeType);
							if ~isempty(events_time)
								% [eventProp] = get_events_info(events_time,condition_win,roi_event_spec_table,'style','event');
								[eventProp] = get_events_info(events_time,[],roi_event_spec_table,'style','event');
		                        alignedData.traces(n).eventProp = eventProp;
		                        alignedData.traces(n).roi_coor = trialData{traceData_col}.roi_center(n,:); 
		                        alignedData.traces(n).roiEdge = trialData{traceData_col}.roi_edge{n}; % coordinate of roi (unit: pixel)
		                    else
		                        alignedData.traces(n).eventProp = [];
							end
							
						else
							% aligned_time = [];
						end
					otherwise
						fprintf('Warning: only use [detected_events] or [stimWin] for var [event_type]\n')
				end
				alignedData.traces(n).fullTrace = roiTraceData;
				alignedData.traces(n).fullTraceDecon = roiTraceDataDecon;

				% Add the std of highpass filtered trace
				alignedData.traces(n).hpStd = event_spec_fulltable{'highpass_std', roiName}{:};

				% modify the names of peak categories 
				if ~isempty(alignedData.traces(n).eventProp) && mod_pcn 
					[cat_setting] = CaImg_char_pat('event_group');
					[alignedData.traces(n).eventProp] = mod_str_TBLorSTRUCT(alignedData.traces(n).eventProp,'peak_category',...
						cat_setting.old,cat_setting.new);	

					% Set the unified stimulation range to empty, if stimulation is not applied
					if ~strcmpi(alignedData.stimInfo,'NA');
						unifiedStimRange = alignedData.stimInfo.UnifiedStimDuration.range;
					else
						unifiedStimRange = [];
					end

					% Create tag for stimulation related events
					StimTags = CreateStimTagForEvents(unifiedStimRange,...
						[alignedData.traces(n).eventProp.(eventTimeType)],'EventCat',{alignedData.traces(n).eventProp.peak_category},...
						'StimType',alignedData.stimInfo.UnifiedStimDuration.type,...
						'SkipTag_keyword','spon','NoTag_char',''); % Create stimulation tags for each events for further sorting
					[alignedData.traces(n).eventProp.stim_tags] = StimTags{:}; % Add stimulation tags


					% [alignedData.traces(n).eventProp] = mod_cat_name(alignedData.traces(n).eventProp,'cat_setting',cat_setting,'dis_extra',false);
					[alignedData.traces(n).eventProp] = add_eventBaseDiff_to_eventProp(alignedData.traces(n).eventProp,...
						combine_stimRange,fullTime,roiTraceData);
					[alignedData.traces(n).eventProp,newFieldName,NFNtag] = add_tfTag_to_eventProp(alignedData.traces(n).eventProp,...
						'peak_category','trig','newFieldName','stimTrig');


					[alignedData.traces(n).eventProp] = add_riseDelay_to_eventProp(alignedData.traces(n).eventProp,...
						combine_stimRange,'eventType',eventTimeType,'errCali',0,'stimEventCatPairs',stimEventCatPairs);

					% Get the possibility of stimulation related events: spike_num/stimulation number
					% Each category of spikes is calculated separately.
					eventProp_stim = dis_struct_entry(alignedData.traces(n).eventProp,'peak_category',...
						'spon','discard');
					[alignedData.traces(n).stimEvent_possi] = get_stimEvent_possibility({eventProp_stim.peak_category},...
						alignedData.stimInfo.UnifiedStimDuration.repeats);
				end

				% get the event number and frequency (spontaneous events and event during stimulation)
				events_time = [alignedData.traces(n).eventProp.(eventTimeType)];
				if contains(alignedData.stim_name, 'GPIO-1', 'IgnoreCase',true)
					exclude_duration = 0; % exclude the duration after stimulation window from "spontaneuous window"
					exepWinDur = 0; % exclude a time window with the specified duration after stimulation window in case the stimulation has a prolonged effect 
				else
					exclude_duration = 1; % exclude the duration after stimulation window from "spontaneuous window"
					exepWinDur = rebound_duration;
					if exclude_duration < exepWinDur % the exclude duration should be at least as long as the window for the "rebound events"
						exclude_duration = exepWinDur;
					end
				end
				[stimWin,sponWin,~,stimDuration,sponDuration] = get_condition_win(combine_stimRange,fullTime,...
					'err_duration', 0, 'exclude_duration', exclude_duration); % add 1s exclude duration after opto stimulation
				[~,sponfq,stimfq,sponEventNum,stimEventNum,exepEventNum] = stim_effect_compare_eventFreq_roi2(events_time,...
					combine_stimRange,duration_fullTime,'exepWinDur',exepWinDur);
				[sponfq,sponInterval,sponIdx,sponEventTime,sponEventNum,~,allIntervals] = get_event_freq_interval(events_time,sponWin);
				[cv2,cv2Vector] = calculateCV2(events_time,stimWin);

				% Get the effect of stimulation on each ROI
				[alignedData.traces(n).stimEffect] = get_stimEffect(fullTime,roiTraceData,combine_stimRange,...
					{alignedData.traces(n).eventProp.peak_category},'ex_eventCat',ex_eventCat,'exAP_eventCat',exAP_eventCat,...
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
				[CaLevel,CaLevelTrace,CaLevel_cal_range] = get_CaLevel_delta(combine_stimRange,fullTime,roiTraceData,...
					'base_timeRange',base_timeRange,'postStim_timeRange',base_timeRange,...
					'stim_section',stim_section,'ss_range',ss_range,'stim_time_error',stim_time_error);

				alignedData.traces(n).(newFieldName) = NFNtag;
				alignedData.traces(n).sponfq = sponfq;
				alignedData.traces(n).sponInterval = sponInterval;
				alignedData.traces(n).allIntervals = allIntervals;
				alignedData.traces(n).cv2 = cv2;
				alignedData.traces(n).cv2Vector = cv2Vector;
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
				alignedData.traces(n).CaLevelMinDelta = CaLevel.mean_delta;
				alignedData.traces(n).CaLevelMinDeltaData = CaLevel.mean_delta_data;
				alignedData.traces(n).CaLevelDecline = CaLevel.decline; % Logical val. True if CaLevelDelta is beyond the base_mean-2*base_std
				% alignedData.traces(n).CaLevelTrace.timeInfo = CaLevelTrace.timeInfo;
				% alignedData.traces(n).CaLevelTrace.yAlign = CaLevelTrace.yAlign;
				aligned_time_CaLevel = CaLevelTrace.timeInfo;
				alignedData.traces(n).CaLevelTrace = CaLevelTrace.yAlign;

				% Fit data during stimulation to negative exponantial curve
				[alignedData.traces(n).StimCurveFit,StimCurveFit_TauInfo] = GetDecayFittingInfo_neuron(fullTime,roiTraceData,...
					combine_stimRange,[alignedData.traces(n).eventProp.peak_time],rsquareThresh); % 0.7 is the threshold for rsquare
				alignedData.traces(n).StimCurveFit_TauMean = StimCurveFit_TauInfo.mean;
				alignedData.traces(n).StimCurveFit_TauNum = StimCurveFit_TauInfo.num;

				% Add tau and caLevelDelta to rebound events
				if ~isempty(alignedData.traces(n).StimCurveFit)
					tauStimIDX = [alignedData.traces(n).StimCurveFit.SN];
					tauVal = [alignedData.traces(n).StimCurveFit.tau];
				else
					tauStimIDX = [];
					tauVal = [];
				end
				for en = 1:numel(decay_eventCat)
					alignedData.traces(n).eventProp = add_tau_for_specificEvents(alignedData.traces(n).eventProp,...
						decay_eventCat{en},combine_stimRange(:,2),tauStimIDX,tauVal);
					alignedData.traces(n).eventProp = add_caLevelDelta_for_specificEvents(alignedData.traces(n).eventProp,...
						decay_eventCat{en},combine_stimRange(:,2),alignedData.traces(n).CaLevelMinDeltaData);
				end
				% alignedData.traces(n).eventProp = add_tau_for_specificEvents(alignedData.traces(n).eventProp,...
				% 	'rebound',combine_stimRange(:,2),tauStimIDX,tauVal);
				% alignedData.traces(n).eventProp = add_caLevelDelta_for_specificEvents(alignedData.traces(n).eventProp,...
				% 	'rebound',combine_stimRange(:,2),alignedData.traces(n).CaLevelMinDeltaData);
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
		alignedData.fullTime = fullTime;

		data_cell{tn} = alignedData;
	end

	alignedData_allTrials = [data_cell{:}];

	if caDeclineOnly
		stimNames = {alignedData_allTrials.stim_name};
		[ogIDX] = judge_array_content(stimNames,{'OG-LED'},'IgnoreCase',true); % index of trials using optogenetics stimulation 
		caDe_og = [alignedData_allTrials(ogIDX).CaDecline]; % calcium decaline logical value of og trials
		[disIDX_og] = judge_array_content(caDe_og,false); % og trials without significant calcium decline
		disIDX = ogIDX(disIDX_og); 
		alignedData_allTrials(disIDX) = [];
	end

	if disROI
		alignedData_allTrials = discard_alignedData_roi(alignedData_allTrials,...
			'stims',disROI_setting.stims,'eventCats',disROI_setting.eventCats);
	end

	% Filter ROIs using their spontaneous event freq
	if sponfreqFilter.status
		[alignedData_allTrials] = Filter_AlignedDataTraces_eventFreq_multiTrial(alignedData_allTrials,...
			'freq_field',sponfreqFilter.field,'freq_thresh',sponfreqFilter.thresh,'filter_direction',sponfreqFilter.direction);
	end

	% Create a list showing the numbers of various events in each ROI
	[alignedData_event_list] = eventcat_list(alignedData_allTrials);
	varargout{1} = alignedData_event_list;
end
