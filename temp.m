
%% ====================
% Get recData for series recordings (recording sharing the same ROI sets but using different stimulations)

%% ====================
% 9.1.3 Discard rois (in recdata_organized) if they are lack of certain types of events
stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
eventCats = {{'trigger'},...
		{'trigger', 'rebound'},...
		{'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'}};
debug_mode = false; % true/false
recdata_organized_bk = recdata_organized;
[recdata_organized] = discard_recData_roi(recdata_organized,'stims',stims,'eventCats',eventCats,'debug_mode',debug_mode);

%% ====================
% Get the alignedData from the recdata_organized after tidying up
% 9.2 Align traces from all trials. Also collect the properties of events
event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
event_data_group = 'peak_lowpass';
event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
event_align_point = 'rise'; % options: 'rise', 'peak'
rebound_duration = 2; % time duration after stimulation to form a window for rebound spikes
cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
pre_event_time = 2; % unit: s. event trace starts at 1s before event onset
post_event_time = 4; % unit: s. event trace ends at 2s after event onset
stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
ss_range = 1; % single number (last n second) or a 2-element array (start and end. 0s is stimulation onset)
stim_time_error = 0.1; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
debug_mode = false; % true/false
caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', event_type,...
	'traceData_type', traceData_type, 'event_data_group', event_data_group,...
	'event_filter', event_filter, 'event_align_point', event_align_point, 'cat_keywords', cat_keywords,...
	'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
	'stim_section',stim_section,'ss_range',ss_range,...
	'stim_time_error',stim_time_error,'rebound_duration',rebound_duration,...
	'mod_pcn', mod_pcn,'debug_mode',debug_mode);

if caDeclineOnly
	stimNames = {alignedData_allTrials.stim_name};
	[ogIDX] = judge_array_content(stimNames,{'OG-LED'},'IgnoreCase',true); % index of trials using optogenetics stimulation 
	caDe_og = [alignedData_allTrials(ogIDX).CaDecline]; % calcium decaline logical value of og trials
	[disIDX_og] = judge_array_content(caDe_og,false); % og trials without significant calcium decline
	disIDX = ogIDX(disIDX_og); 
	alignedData_allTrials(disIDX) = [];
end 

%% ====================
[alignedData_allTrials_sync] = sync_rois_multiseries(alignedData_allTrials);