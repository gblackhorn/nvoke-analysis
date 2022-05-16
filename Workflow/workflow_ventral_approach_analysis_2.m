% This script is used on office local desktop running windows 10
% Use this script after exporting motion corrected files with tiff format. 
% Process files with CNMFe with cluster. And then come back for further analysis
	% Inscopix API related process, such as spatial filter and motion correction cannot be run on VDI. 
	% CNMFe can be run here alternatively, but deigo cluster is way faster
% All files are stored on bucket

% This workflow script is modified from "workflow_ventral_approach_analysis"
% 2022.03.18 Some sections are deleted. Some are reorganized to facilitate the workflow

%% ====================
PC_name = getenv('COMPUTERNAME'); 
% set folders for different situation
DataFolder = 'G:\Workspace\Inscopix_Seagate';

if strcmp(PC_name, 'GD-AW-OFFICE')
	AnalysisFolder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
elseif strcmp(PC_name, 'LAPTOP-84IERS3H')
	AnalysisFolder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop
end

[FolderPathVA] = set_folder_path_ventral_approach(DataFolder,AnalysisFolder);
%% ====================
% Save processed data
save_dir = uigetdir(AnalysisFolder);
dt = datestr(now, 'yyyymmdd');
save(fullfile(save_dir, [dt, '_ProcessedData_ogEx']), 'recdata_organized','alignedData_allTrials','grouped_event_info');

%% ====================
% 8.4 Select a specific group of data from recdata_group for further analysis
recdata_organized = select_grouped_data(recdata_group);

%% ====================
% 9.1 Examine peak detection with plots 
close all
PauseTrial = true; % true or false
traceNum_perFig = 10; % number of traces/ROIs per figure
SavePlot = false; % true or false
SaveTo = FolderPathVA.fig;
vis = 'off'; % on/off. set the 'visible' of figures
decon = false; % true/false plot decon trace
marker = true; % true/false plot markers

[SaveTo] = plotTracesFromAllTrials(recdata_organized,...
	'PauseTrial', PauseTrial,...
	'traceNum_perFig', traceNum_perFig, 'decon', decon, 'marker', marker,...
	'SavePlot', SavePlot, 'SaveTo', SaveTo,...
	'vis', vis);
if SaveTo~=0
	FolderPathVA.fig = SaveTo;
end

%% ====================
% 9.1.1 manually discard rois or trial 
% recdata_organized_bk = recdata_organized;

trial_idx = 29; % trial index number
roi_idx = [76:78]; % roi number. 2 for 'neuron2'

[recdata_organized] = discard_data(recdata_organized,trial_idx,roi_idx);
%% ====================
% 9.1.2 discard rec if the fovID number is bigger than fov_max
fov_max = 6; % 
dis_idx = [];
recdata_organized_bk = recdata_organized;
recN = size(recdata_organized, 1);
for rn = 1:recN
	fovID = recdata_organized{rn, 2}.fovID;
	fov_num = str2num(fovID((strfind(fovID, '-')+1):end));
	if fov_num > fov_max
		dis_idx = [dis_idx; rn];
	end
end
recdata_organized(dis_idx, :) = [];
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
% 9.2.1.1 Check trace aligned to stim window
% note: 'event_type' for alignedData_allTrials must be 'stimWin'
close all
plot_combined_data = false;
plot_stim_shade = true;
y_range = [-20 30];
stimEffectType = 'excitation'; % options: 'excitation', 'inhibition', 'rebound'
section = []; % n/[]. specify the n-th repeat of stimWin. Set it to [] to plot all stimWin 
sponNorm = true; % true/false
save_fig = false;
save_dir = FolderPathVA.fig;

fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedData_allTrials,...
	'plot_combined_data',plot_combined_data,'plot_stim_shade',plot_stim_shade,'section',section,...
	'y_range',y_range,'stimEffectType',stimEffectType,'sponNorm',sponNorm);
if save_fig
	fname = sprintf('stimWin_aligned_traces');
	FolderPathVA.fig = savePlot(fHandle_stimAlignedTrace,'guiSave','on','save_dir',save_dir,'fname',fname);
end

%% ====================
% 9.2.1.2 Check trace aligned to stim window for calcium level change. 
% On y-axis, traces are aligned the the average of baseline before stimulation
close all
plot_combined_data = true;
plot_stim_shade = true;
y_range = [-20 10];
tickInt_time = 1;
stimEffectType = 'excitation'; % options: 'excitation', 'inhibition', 'rebound'
section = []; % n/[]. specify the n-th repeat of stimWin. Set it to [] to plot all stimWin 
sponNorm = false; % true/false
FN_trace = 'CaLevelTrace'; % field in alignedData.traces where the traces are stored
FN_time = 'timeCaLevel'; % default field in alignedData where the timeinfo is stored
save_fig = false;
save_dir = FolderPathVA.fig;

fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedData_allTrials,...
	'plot_combined_data',plot_combined_data,'plot_stim_shade',plot_stim_shade,'section',section,...
	'y_range',y_range,'tickInt_time',tickInt_time,'stimEffectType',stimEffectType,'sponNorm',sponNorm,...
	'FN_trace',FN_trace,'FN_time',FN_time);
if save_fig
	fname = sprintf('stimWin_aligned_traces');
	FolderPathVA.fig = savePlot(fHandle_stimAlignedTrace,'guiSave','on','save_dir',save_dir,'fname',fname);
end

%% ====================
% 9.2.2 Check aligned trace of events belong to the same category
% note: 'event_type' for alignedData_allTrials must be 'detected_events'
close all
plot_combined_data = true; % mean value and std of all traces
plot_raw_races = false; % true/false. true: plot every single trace
y_range = [-3 7];
eventCat = {'spon','rebound','trig'}; % options: 'trig', 'spon', 'rebound'
sponNorm = false; % true/false
save_fig = true; % true/false
save_dir = FolderPathVA.fig;

for cn = 1:numel(eventCat)
	fname = sprintf('aligned_catTraces_%s',eventCat{cn});
	fHandle_stimAlignedTrace = plot_aligned_catTraces(alignedData_allTrials,...
		'plot_combined_data',plot_combined_data,'plot_raw_races',plot_raw_races,...
		'eventCat',eventCat{cn},'y_range',y_range,'sponNorm',sponNorm); % 'fname',fname,
	if save_fig
		if cn == 1
			guiSave = 'on';
		elseif cn > 1
			save_dir = FolderPathVA.fig;
			guiSave = 'off';
		end
		FolderPathVA.fig = savePlot(fHandle_stimAlignedTrace,'guiSave',guiSave,'save_dir',save_dir,'fname',fname);
	end
end

%% ====================
% 9.3 Collect event properties from alignedData_allTrials
entry = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
dis_spon = false; % true/false

modify_eventType_name = true; % true/false
[eventProp_all] = collect_event_prop(alignedData_allTrials, 'style', entry); % only use 'event' for 'style'

% modify the stimulation name in eventProp_all
cat_setting.cat_type = 'stim_name';
cat_setting.cat_names = {'og', 'ap', 'og-ap'};
cat_setting.cat_merge = {{'OG-LED-5s'}, {'GPIO-1-1s'}, {'OG-LED-5s GPIO-1-1s'}};
[eventProp_all] = mod_cat_name(eventProp_all,...
	'cat_setting',cat_setting,'dis_extra', false,'stimType',false);

%% ====================
% 9.4.1 Collect spontaneous events from 'eventProp_all' for comparison among FOVs
% "entryStyle" field in "eventProp_all" must be 'event'. The field "event_type" in alignedData_allTrials used 
% to produce eventProp_all must be 'detected_events' 
[category_idx] = get_category_idx({eventProp_all.peak_category}); % get the idex of events belong to various categories
spon_field_idx = find(strcmpi('spon', {category_idx.name})); % the location of spon idx in structure category_idx
spon_idx = category_idx(spon_field_idx).idx;
spon_eventProp = eventProp_all(spon_idx); % get properties of all spon events in eventProp_all
[grouped_spon_event_info, grouped_spon_event_opt] = group_event_info_multi_category(spon_eventProp,...
	'category_names', {'fovID'}); % one entry for one event

% Get the spon frequency and average interval time. Spon events in single ROIs will be used
mod_pcn = false; % true/false modify the peak category names with func [mod_cat_name]
keep_catNames = {'spon'}; % 'spon'. event will be kept if its peak-cat is one of these
debug_mode = false;
[alignedData_allTrials_spon] = org_alignData(alignedData_allTrials,'keep_catNames', keep_catNames,...
	'mod_pcn', mod_pcn, 'debug_mode', false); % only keep spon events in the event properties
[eventProp_all_spon] = collect_event_prop(alignedData_allTrials_spon, 'style', 'roi'); % only use 'event' for 'style'

category_names = {'fovID'}; % options: 'fovID', 'stim_name', 'peak_category'
[grouped_spon_roi_info, grouped_spon_roi_opt] = group_event_info_multi_category(eventProp_all_spon,...
	'category_names', category_names);

%% ====================
% 9.4.2.1 Plot spon event parameters
close all
plot_combined_data = true;
parNames_event = {'rise_duration','peak_mag_delta'};

        % {'sponNorm_rise_duration', 'sponNorm_peak_delta_norm_hpstd', 'sponNorm_peak_slope_norm_hpstd'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
		% 'sponNorm_rise_duration', 'sponNorm_peak_mag_delta', 'sponNorm_peak_delta_norm_hpstd'
		% 'sponNorm_peak_slope', 'sponNorm_peak_slope_norm_hpstd'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

[save_dir_event, plot_info_event] = plot_event_info(grouped_spon_event_info,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames_event, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir_event~=0
	FolderPathVA.fig = save_dir_event;
end
if save_fig
% 	plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info_spon.grouped_event_info = grouped_spon_event_info;
	plot_stat_info_spon.plot_info = plot_info_event;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info_spon']), 'plot_stat_info_spon');
end

%% ====================
% 9.4.2.2 Plot spon freq and event interval
close all
plot_combined_data = true;
parNames_roi = {'sponfq', 'sponInterval'};
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not
[save_dir_roi, plot_info_roi] = plot_event_info(grouped_spon_roi_info,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames_roi, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir_roi~=0
	FolderPathVA.fig = save_dir_roi;
end
if save_fig
	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_sponfreq_info.grouped_event_info = grouped_spon_roi_info;
	plot_sponfreq_info.plot_info = plot_info_roi;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_sponfreq_info']), 'plot_sponfreq_info');
end


%% ====================
% 9.5.1.1 Collect and group events from 'eventProp_all' according to stimulation and category 
% Rename stim name of og to EXog if og-5s exhibited excitation effect
seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
dis_spon = false; % true/false
screenEventProp = true;
if screenEventProp 
	tag_check = {'og', 'og-ap'};
	idx_check = cell(1, numel(tag_check));
	for n = 1:numel(tag_check)
		[~,idx_check{n}] = filter_structData(eventProp_all,'stim_name',tag_check{n},[]); % accquire the idx of all og-trial events
	end
	idxAll_check = [idx_check{:}];
	eventProp_check = eventProp_all(idxAll_check);
	eventProp_uncheck = eventProp_all;
	eventProp_uncheck(idxAll_check) = [];
	[~,idx_ogEx] = filter_structData(eventProp_check,'stimTrig',1,[]); % accquire the idx of og triggered events
	cat_setting.cat_type = 'stim_name';
	cat_setting.cat_names = {'EXog', 'EXog-ap'};
	cat_setting.cat_merge = {{'og'}, {'og-ap'}};
	[eventProp_check(idx_ogEx)] = mod_cat_name(eventProp_check(idx_ogEx),...
		'cat_setting',cat_setting,'dis_extra', false,'stimType',false);
	eventProp_all = [eventProp_uncheck eventProp_check];
end

[eventProp_all_norm] = norm_eventProp_with_spon(eventProp_all,'entry',entry,'dis_spon',dis_spon);
% modify the peak category names
if modify_eventType_name % Note: when style is 'roi', there will be more data number, if noStim and interval are categorized as spon
	dis_extra = true;
	[eventProp_all_norm] = mod_cat_name(eventProp_all_norm,'dis_extra', dis_extra,'seperate_spon',seperate_spon);
end

category_names = {'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'
% [grouped_event_info, grouped_event_info_option] = group_event_info_multi_category(eventProp_all,...
% 	'category_names', category_names);
[grouped_event_info, grouped_event_info_option] = group_event_info_multi_category(eventProp_all_norm,...
	'category_names', category_names);
if numel(category_names)==1 && strcmpi(category_names, 'peak_category')
	[grouped_event_info] = merge_event_info(grouped_event_info); % merge some groups
end

for gn = 1:numel(grouped_event_info)
	[grouped_event_info(gn).numTrial,grouped_event_info(gn).numRoi,grouped_event_info(gn).numRoiVec] = get_num_fieldUniqueContent(grouped_event_info(gn).event_info,...
		'fn_1', 'trialName', 'fn_2', 'roiName');
end

% Sort group 
strCells = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
strCells_plus = {'ap', 'EXopto'};
[grouped_event_info] = sort_struct_with_str(grouped_event_info,'group',strCells,'strCells_plus',strCells_plus);

grouped_event_info_option.event_type = event_type;
grouped_event_info_option.traceData_type = traceData_type;
grouped_event_info_option.event_data_group = event_data_group;
grouped_event_info_option.event_filter = event_filter;
grouped_event_info_option.event_align_point = event_align_point;
grouped_event_info_option.cat_keywords = cat_keywords;


%% ====================
% 9.5.1.2 screen groups based on tags. Delete unwanted groups for event analysis
tags_discard = {'og-delay','trig-AP','trig [EXog]'}; % Discard groups containing these words. 'EXog',
tags_keep = {'spon','trig','trig [EXog]','rebound'}; % Keep groups containing these words
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_info_filtered] = filter_entries_in_structure(grouped_event_info,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry);

%% ====================
% 9.5.2 Plot event parameters. Grouped according to categories
% alignedData_allTrials: entry is 'events'
close all
plot_combined_data = true;
parNames = {'rise_duration','sponNorm_rise_duration','peak_mag_delta',...
    'sponNorm_peak_mag_delta','baseDiff','baseDiff_stimWin','val_rise','rise_delay'}; % entry: event
        % 'rise_duration','sponNorm_rise_duration','peak_mag_delta',...
        % 'sponNorm_peak_mag_delta','baseDiff','baseDiff_stimWin','val_rise',
    
        % {'sponNorm_rise_duration', 'sponNorm_peak_delta_norm_hpstd', 'sponNorm_peak_slope_norm_hpstd'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
		% 'sponNorm_rise_duration', 'sponNorm_peak_mag_delta', 'sponNorm_peak_delta_norm_hpstd'
		% 'sponNorm_peak_slope', 'sponNorm_peak_slope_norm_hpstd'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

% grouped_event_info = grouped_event_info_bk;
[save_dir, plot_info] = plot_event_info(grouped_event_info_filtered,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir~=0
	FolderPathVA.fig = save_dir;
end

if save_fig
	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info.grouped_event_info_filtered = grouped_event_info_filtered;
	plot_stat_info.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
end
% bar_data.data can be used to run one-way anova. bar_stat contains results of anova and the following multi-comparison 

%% ====================
% 9.5.1.2 screen groups based on tags. Delete unwanted groups for event analysis
tags_discard = {'spon','trig-AP','og-delay'}; % Discard groups containing these words. 'spon','EXopto',
tags_keep = {'trig [ap]','trig [EXog]','rebound'}; % Keep groups containing these words
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_info_filtered] = filter_entries_in_structure(grouped_event_info,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry);

%% ====================
% 9.5.4 Plot roi parameters. Grouped according to categories
% alignedData_allTrials: entry is 'roi'
close all
plot_combined_data = true;
parNames = {'sponfq','stimfq','stimfqNorm','stimfqDeltaNorm','CaLevelDelta','CaLevelMinDelta'}; % entry: roi
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

% grouped_event_info = grouped_event_info_bk;
[save_dir, plot_info] = plot_event_info(grouped_event_info_filtered,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir~=0
	FolderPathVA.fig = save_dir;
end

if save_fig
	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info.grouped_event_info_filtered = grouped_event_info_filtered;
	plot_stat_info.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
end

%% ====================
% 9.6.1 Get the stimulation effect info, such as inhibition, excitation for each ROI
% Scatter plot the rois (inhibition/excitation/... vs meanTraceLevel) 'meanTraceLevel' is output by func [get_stimEffect]
stim = 'OG-LED'; % data will be collected from trials applied with this stimulation
[stimEffectInfo,meanTrace_stim,logRatio_SponStim] = get_stimEffectInfo_all_roi(alignedData_allTrials,'stim',stim);

% plot
save_fig = true; % true/false
close all
colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};

% groups = {'inhibition', 'excitation', 'rebound', 'ExIn'}; % 'rebound'
groups = fieldnames(meanTrace_stim); % 'rebound'
num_groups = numel(groups);
figure
hold on
for gn = 1:num_groups
	if contains(groups{gn}, 'rebound')
		mSize = 30;
	else
		mSize = 80;
	end
	h(gn) = scatter(meanTrace_stim.(groups{gn}), logRatio_SponStim.(groups{gn}),...
		mSize, 'filled', 'MarkerFaceColor', colorGroup{gn},...
		'MarkerFaceAlpha', 0.8, 'MarkerEdgeAlpha', 0);
end
legend(h(1:num_groups), groups, 'Location', 'northeastoutside', 'FontSize', 16);
xlabel('meanTraceDiff during stimulation', 'FontSize', 16)
ylabel('log(freqStim/freqSpon)', 'FontSize', 16)
hold off

if save_fig
	fname = 'og_inhibition_effect';
	[save_dir] = savePlot(gcf, 'guiSave', 'on', 'save_dir', FolderPathVA.fig, 'fname', fname);
	if save_dir~=0
		FolderPathVA.fig = save_dir;
	end
end

%% ====================
% 9.2.0.3 Plot traces, aligned traces and roi map
close all
save_fig = true; % true/false
if save_fig
	save_dir = uigetdir(FolderPathVA.fig,'Choose a folder to save plots');
	if save_dir~=0
		FolderPathVA.fig = save_dir;
	end 
end
trial_num = numel(alignedData_allTrials);
tn = 1;
while tn <= trial_num
	close all
	alignedData = alignedData_allTrials(tn);
	plot_trace_roiCoor(alignedData,'save_fig',save_fig,'save_dir',save_dir);
	fprintf('- %d/%d: %s', tn, trial_num, alignedData.trialName);
	direct_input = input(sprintf('\n(c)continue  (b)back to previous or input the trial number [default-c]:\n'), 's');
	if isempty(direct_input)
		direct_input = 'c';
	end
	if strcmpi(direct_input, 'c')
		tn = tn+1; 
	elseif strcmpi(direct_input, 'b')
		tn = tn-1; 
	else
		tn = str2num(direct_input);
	end
end


