
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
% Sync ROIs across trials in the same series (same FOV, same ROI set) 
ref_stim = 'GPIO-1-1s'; % ROIs are synced to the trial applied with this stimulation
ref_SpikeCat = {'spon','trig'}; % spike/peak/event categories kept during the syncing in ref trials
nonref_SpikeCat = {'spon','rebound'}; % spike/peak/event categories kept during the syncing in non-ref trials
[seriesData_sync] = sync_rois_multiseries(alignedData_allTrials,...
	'ref_stim',ref_stim,'ref_SpikeCat',ref_SpikeCat,'nonref_SpikeCat',nonref_SpikeCat);

%% ====================
% Group series data using ROI. Each ROI group contains events from trials using various stimulation
ref_stim = 'ap'; % reference stimulation
ref_SpikeCat = 'trig'; % reference spike/peak/event category 
other_SpikeCat = 'rebound'; % spike/peak/event category in other trial will be plot
debug_mode = false;

series_num = numel(seriesData_sync);
for sn = 1:series_num
	alignedData_series = seriesData_sync(sn).SeriesData;
	[seriesData_sync(sn).NeuronGroup_data] = group_aligned_trace_series_ROIpaired(alignedData_series,...
		'ref_stim',ref_stim,'ref_SpikeCat',ref_SpikeCat,'other_SpikeCat',other_SpikeCat,...
		'debug_mode', debug_mode);
end

%% ====================
% Plot spikes of each ROI recorded in trials received various stimulation
close all
plot_raw = true; % true/false.
plot_norm = true; % true/false. plot the ref_trial normalized data
plot_mean = true; % true/false. plot a mean trace on top of raw traces
plot_std = true; % true/false. plot the std as a shade on top of raw traces. If this is true, "plot_mean" will be turn on automatically
y_range = [-10 10];
tickInt_time = 1; % interval of tick for timeInfo (x axis)
fig_row_num = 3; % number of rows (ROIs) in each figure
save_fig = false; % true/false
fig_position = [0.1 0.1 0.85 0.85]; % [left bottom width height]

if save_fig
	save_path = uigetdir(FolderPathVA.fig,'Choose a folder to save spikes from series trials');
	if save_path~=0
		FolderPathVA.fig = save_path;
	end 
else
	save_path = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	plot_series_neuron_paired_trace(NeuronGroup_data,'plot_raw',plot_raw,'plot_norm',plot_norm,...
		'plot_mean',plot_mean,'plot_std',plot_std,'y_range',y_range,'tickInt_time',tickInt_time,...
		'fig_row_num',fig_row_num,'fig_position',fig_position,'save_fig',save_path);
end

%% ====================
% Plot the spike/event properties for each neuron
close all
plot_combined_data = true;
parNames = {'rise_duration','peak_mag_delta','rise_duration_refNorm','peak_mag_delta_refNorm','rise_delay'}; % entry: event
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

if save_fig
	savepath_nogui = uigetdir(FolderPathVA.fig,'Choose a folder to save plot for spike/event prop analysis');
	if savepath_nogui~=0
		FolderPathVA.fig = savepath_nogui;
	else
		error('savepath_nogui for saving plots is not selected')
	end 
else
	savepath_nogui = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	roi_num = numel(NeuronGroup_data);
	for rn = 1:roi_num
		close all
		fname_suffix = sprintf('%s-%s', series_name, NeuronGroup_data(rn).roi);
		[~, plot_info] = plot_event_info(NeuronGroup_data(rn).eventPropData,...
			'plot_combined_data',plot_combined_data,'parNames',parNames,'stat',stat,...
			'save_fig',save_fig,'save_dir',save_dir,'savepath_nogui',savepath_nogui,'fname_suffix',fname_suffix);
		seriesData_sync(sn).NeuronGroup_data(rn).stat = plot_info;
		fprintf('Spike/event properties are from %s - %s\n', series_name, NeuronGroup_data(rn).roi);

		% pause
		% if save_fig
		% 	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
		% 	plot_stat_info.grouped_event_info_filtered = grouped_event_info_filtered;
		% 	plot_stat_info.plot_info = plot_info;
		% 	dt = datestr(now, 'yyyymmdd');
		% 	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
		% end
	end
end

%% ====================
% Save processed data
save_dir = uigetdir(AnalysisFolder);
dt = datestr(now, 'yyyymmdd');
save(fullfile(save_dir, [dt, '_seriesData_sync']), 'seriesData_sync');








