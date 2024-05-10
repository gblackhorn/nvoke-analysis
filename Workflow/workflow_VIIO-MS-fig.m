% Workflow for genertating figures for VIIO manuscript 
% nRIM, Da Guo

% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);

%% ==========
% Figure 2
% The properties of spontaneous events in IO subnuclei (DAO vs PO)
% Load the stimEffectFiltered 'recdata_organized' and 'alignedData_allTrials' variables

%% ==========
% 2.1 (optional): Update the 'alignedData_allTrials' using the 'recdata_organized'

% Settings
adata.event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
adata.eventTimeType = 'peak_time'; % rise_time/peak_time. Pick one for event time
adata.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
adata.event_data_group = 'peak_lowpass';
adata.event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
adata.event_align_point = 'rise'; % options: 'rise', 'peak'
adata.rebound_duration = 2; % time duration after stimulation to form a window for rebound spikes. Exclude these events from 'spon'
adata.cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
adata.pre_event_time = 5; % unit: s. duration before stimulation in the aligned traces
adata.post_event_time = 10; % unit: s. duration after stimulation in the aligned traces
adata.stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
adata.ss_range = 1; % range of stim_section (compare the cal-level in baseline and here to examine the effect of the stimulation). single number (last n second during stimulation) or a 2-element array (start and end. 0s is stimulation onset)
adata.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
adata.mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
adata.caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)
adata.disROI = true; % true/false. If true, Keep ROIs using the setting below, and delete the rest
adata.disROI_setting.stims = {'AP_GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s AP_GPIO-1-1s'};
adata.disROI_setting.eventCats = {{'spon'}, {'spon'}, {'spon'}};
adata.sponfreqFilter.status = true; % true/false. If true, use the following settings to filter ROIs
adata.sponfreqFilter.field = 'sponfq'; % 
adata.sponfreqFilter.thresh = 0.05; % Hz. default 0.06
adata.sponfreqFilter.direction = 'high';
debug_mode = false; % true/false

% Create structure data for further analysis
[alignedData_allTrials,alignedData_event_list] = get_event_trace_allTrials(recdata_organized,'event_type', adata.event_type,...
	'traceData_type', adata.traceData_type, 'event_data_group', adata.event_data_group,'eventTimeType',adata.eventTimeType,...
	'event_filter', adata.event_filter, 'event_align_point', adata.event_align_point, 'cat_keywords', adata.cat_keywords,...
	'pre_event_time', adata.pre_event_time, 'post_event_time', adata.post_event_time,...
	'stim_section',adata.stim_section,'ss_range',adata.ss_range,...
	'stim_time_error',adata.stim_time_error,'rebound_duration',adata.rebound_duration,...
	'mod_pcn', adata.mod_pcn,'caDeclineOnly',adata.caDeclineOnly,...
	'disROI',adata.disROI,'disROI_setting',adata.disROI_setting,'sponfreqFilter',adata.sponfreqFilter,...
	'debug_mode',debug_mode);


%% ==========
% 2.2 Extract properties of spontaneous events and group them according to ROIs' subnuclous location

% Get and group (gg) Settings
ggSetting.entry = 'event'; % options: 'roi' or 'event'. The entry type in eventProp
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
ggSetting.modify_stim_name = true; % true/false. Change the stimulation name, 
ggSetting.sponOnly = false; % true/false. If eventType is 'roi', and ggSetting.sponOnly is true. Only keep spon entries
ggSetting.seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
ggSetting.dis_spon = false; % true/false. Discard spontaneous events
ggSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'
ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
ggSetting.sort_order_plus = {'ap', 'EXopto'};
debug_mode = false; % true/false

% Create grouped_event for plotting event properties
[eventStructForPlot] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Keep spontaneous events and discard all others
tags_keep = {'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[eventStructForPlotFiltered] = filter_entries_in_structure(eventStructForPlot,'group',...
	'tags_keep',tags_keep);

%% ==========
% 2.3 Plot event properties

% Settings
save_fig = true; % true/false
plot_combined_data = false;
parNames = {'rise_duration','FWHM','sponNorm_peak_mag_delta'}; 
    % 'rise_duration','FWHM','sponNorm_peak_mag_delta','peak_mag_delta'
stat = true; % Set it to true to run anova when plotting bars

close all
% % Modify the group name for labeling the plots
% [newStimNameEventCatCell] = modStimNameEventCat({grouped_event_info_filtered.group});
% [grouped_event_info_filtered.group] = newStimNameEventCatCell{:};

% Generate and save figures
[save_dir, plot_info] = plot_event_info(eventStructForPlotFiltered,'entryType',ggSetting.entry,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'fname_suffix','event','save_fig', save_fig, 'save_dir', save_dir);

% Create a UI table displaying the n numberss
fNum = nNumberTab(eventStructForPlotFiltered,ggSetting.entry);

% Save data
if save_fig
	% Save the fNum
	savePlot(fNum,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'nNumInfo-events');

	% Save the statistics info
	eventPropStatInfo.eventStructForPlotFiltered = eventStructForPlotFiltered;
	eventPropStatInfo.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_eventPropStatInfo']), 'eventPropStatInfo');
end

% Update the folder path 
if save_dir~=0
	FolderPathVA.fig = save_dir;
end


%% ==========
% 2.4 Get and group data using ROI as entry and plot spontaneous event frequency in DAO and PO

% Get and group data
ggSetting.entry = 'roi'; % options: 'roi' or 'event'. The entry type in eventProp

% Create grouped_event for plotting event properties
[roiStructForPlot] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Keep spontaneous events and discard all others
tags_keep = {'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[roiStructForPlotFiltered] = filter_entries_in_structure(roiStructForPlot,'group',...
	'tags_keep',tags_keep);

% Generate figures for spontaneous event frequency
% Change parNames and keep other setting the same as in 2.3
parNames = {'sponfq'}; 
[save_dir, plot_info] = plot_event_info(roiStructForPlotFiltered,'entryType',ggSetting.entry,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'fname_suffix','ROI','save_fig', save_fig, 'save_dir', save_dir);

% Create a UI table displaying the n numberss
fNum = nNumberTab(eventStructForPlotFiltered,ggSetting.entry);


% Save the statistics info
if save_fig
	% Save the fNum
	savePlot(fNum,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'nNumInfo-ROI');

	roiPropStatInfo.roiStructForPlotFiltered = roiStructForPlotFiltered;
	roiPropStatInfo.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_roiPropStatInfo']), 'roiPropStatInfo');
end
