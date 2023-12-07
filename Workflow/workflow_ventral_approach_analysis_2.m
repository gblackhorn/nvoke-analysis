% This script is used on office local desktop running windows 10
% Use this script after exporting motion corrected files with tiff format. 
% Process files with CNMFe with cluster. And then come back for further analysis
	% Inscopix API related process, such as spatial filter and motion correction cannot be run on VDI. 
	% CNMFe can be run here alternatively, but deigo cluster is way faster
% All files are stored on bucket

% This workflow script is modified from "workflow_ventral_approach_analysis"
% 2022.03.18 Some sections are deleted. Some are reorganized to facilitate the workflow

%% ====================
clearvars -except recdata_organized opt alignedData_allTrials adata alignedData_event_list seriesData_sync grouped_event grouped_event_info_filtered recdata_manual_new

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
save(fullfile(save_dir, [dt, '_ProcessedData_ogEx']),...
    'recdata_organized','alignedData_allTrials','opt','adata');
% 'recdata_organized','alignedData_allTrials','grouped_event','adata','grouped_event_setting','opt','adata'

%% ====================
% 8.4 Select a specific group of data from recdata_group for further analysis
recdata_organized = select_grouped_data(recdata_group);

%% ====================
% 9.1 Examine peak detection with plots 
close all
SavePlot = false; % true or false
PauseTrial = true; % true or false
traceNum_perFig = 10; % number of traces/ROIs per figure
SaveTo = FolderPathVA.fig;
vis = 'off'; % on/off. set the 'visible' of figures
decon = true; % true/false plot decon trace
marker = false; % true/false plot markers

[SaveTo] = plotTracesFromAllTrials(recdata_organized,...
	'PauseTrial', PauseTrial,...
	'traceNum_perFig', traceNum_perFig, 'decon', decon, 'marker', marker,...
	'SavePlot', SavePlot, 'SaveTo', SaveTo,...
	'vis', vis);

[SaveTo] = plot_ROIevent_raster_from_trial_all(recdata_organized,...
	'plotInterval',5,'sz',10,'save_fig',SavePlot,'save_dir',SaveTo);
if SaveTo~=0
	FolderPathVA.fig = SaveTo;
end

%% ====================
% 8.5 manually discard rois or trial 
% recdata_organized_bk = recdata_organized;

trial_idx = 35; % trial index number
roi_idx = [5]; % roi number. 2 for 'neuron2'

[recdata_organized] = discard_data(recdata_organized,trial_idx,roi_idx);
%% ====================
% 8.6 discard rec if the fovID number is bigger than fov_max
fov_max = 6; % fov 1-6 are from the ChrimsonR positive CN axon side
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
% Discarding certain ROIs according to what calcium spikes they don't have will be executed in the next section on alignedData
% % 9.1.3 Discard rois (in recdata_organized) if they are lack of certain types of events
% dis.stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
% dis.eventCats = {{'trigger'},...
% 		{'trigger', 'rebound'},...
% 		{'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'}};
% debug_mode = false; % true/false
% recdata_organized_bk = recdata_organized;
% [recdata_organized] = discard_recData_roi(recdata_organized,'stims',dis.stims,'eventCats',dis.eventCats,'debug_mode',debug_mode);
%% ====================
% 8.7 Align traces from all trials. Also collect the properties of events
adata.event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
adata.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
adata.event_data_group = 'peak_lowpass';
adata.event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
adata.event_align_point = 'rise'; % options: 'rise', 'peak'
adata.rebound_duration = 2; % time duration after stimulation to form a window for rebound spikes
adata.cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
adata.pre_event_time = 5; % unit: s. event trace starts at 1s before event onset
adata.post_event_time = 10; % unit: s. event trace ends at 2s after event onset
adata.stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
adata.ss_range = 1; % single number (last n second) or a 2-element array (start and end. 0s is stimulation onset)
adata.stim_time_error = 0.1; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
adata.mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
adata.caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)
adata.disROI = true; % true/false. If true, Keep ROIs using the setting below, and delete the rest
adata.disROI_setting.stims = {'AP_GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s AP_GPIO-1-1s'};
adata.disROI_setting.eventCats = {{'spon'}, {'spon'}, {'spon'}};
adata.sponfreqFilter.status = true; % true/false. If true, use the following settings to filter ROIs
adata.sponfreqFilter.field = 'sponfq'; % 
adata.sponfreqFilter.thresh = 0.06; % Hz
adata.sponfreqFilter.direction = 'high';
debug_mode = false; % true/false

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', adata.event_type,...
	'traceData_type', adata.traceData_type, 'event_data_group', adata.event_data_group,...
	'event_filter', adata.event_filter, 'event_align_point', adata.event_align_point, 'cat_keywords', adata.cat_keywords,...
	'pre_event_time', adata.pre_event_time, 'post_event_time', adata.post_event_time,...
	'stim_section',adata.stim_section,'ss_range',adata.ss_range,...
	'stim_time_error',adata.stim_time_error,'rebound_duration',adata.rebound_duration,...
	'mod_pcn', adata.mod_pcn,'debug_mode',debug_mode);

if adata.caDeclineOnly
	adata.stimNames = {alignedData_allTrials.stim_name};
	[adata.ogIDX] = judge_array_content(adata.stimNames,{'OG-LED'},'IgnoreCase',true); % index of trials using optogenetics stimulation 
	adata.caDe_og = [alignedData_allTrials(adata.ogIDX).CaDecline]; % calcium decaline logical value of og trials
	[adata.disIDX_og] = judge_array_content(adata.caDe_og,false); % og trials without significant calcium decline
	adata.disIDX = adata.ogIDX(adata.disIDX_og); 
	alignedData_allTrials(adata.disIDX) = [];
end

if adata.disROI
	alignedData_allTrials = discard_alignedData_roi(alignedData_allTrials,...
		'stims',adata.disROI_setting.stims,'eventCats',adata.disROI_setting.eventCats);
end

% Filter ROIs using their spontaneous event freq
if adata.sponfreqFilter.status
	[alignedData_allTrials] = Filter_AlignedDataTraces_eventFreq_multiTrial(alignedData_allTrials,...
		'freq_field',adata.sponfreqFilter.field,'freq_thresh',adata.sponfreqFilter.thresh,'filter_direction',adata.sponfreqFilter.direction);
end

% Create a list showing the numbers of various events in each ROI
[alignedData_event_list] = eventcat_list(alignedData_allTrials);


%% ====================
% Common settings for 9.1.1 - 9.1.2
filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan nan nan], [nan nan nan], [nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound


%% ====================
% 9.1.1 Plot calcium signal as traces and color array, and calcium events with hist-count.
% Note: ROIs of all trials in alignedData_allTrials can be plotted. 
%	Use 'filter' to screen ROIs based on the effect of stimulation
close all
save_fig = false; % true/false

norm_FluorData = false; % true/false. whether to normalize the FluroData
sortROI = true; % true/false. Sort ROIs according to the event number: high to low
hist_binsize = 5; % the size of the histogram bin, used to calculate the edges of the bins
xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale. Use by figure 2
debug_mode = false;

FolderPathVA.fig = plot_calcium_signals_alignedData_allTrials(alignedData_allTrials,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'norm_FluorData',norm_FluorData,'sortROI',sortROI,...
	'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'debug_mode',debug_mode);


%% ==================== 
%9.1.2 Plot the event frequency in specified time bins to examine the effect
% of stimulation and compare each pair of bins
close all
save_fig = true; % true/false

binWidth = 1; % the width of histogram bin. the default value is 1 s.

PropName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
stimIDX = []; % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
postStim_duration = 10; % unit: second. include events happened after the end of stimulations

normToBase = true; % true/false. normalize the data to baseline (data before baseBinEdge)
baseBinEdgestart = -preStim_duration; % where to start to use the bin for calculating the baseline. -1
baseBinEdgeEnd = -2; % 0
apCorrection = false; % true/false.

debug_mode = false; % true/false

[barStat,FolderPathVA.fig] = plot_event_freq_alignedData_allTrials(alignedData_allTrials,'PropName',PropName,...
    'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,'stimIDX',stimIDX,...
    'normToBase',normToBase,'apCorrection',apCorrection,...
    'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,'binWidth',binWidth,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','on','debug_mode',debug_mode);

% plot the difference between 'og-5s ap-0.1s' and 'og5s'
[xData,meanVal_og,steVal_og,binEdges,ogData] = get_mean_ste_from_barStat(barStat,'og-5s');
[~,meanVal_ogap,steVal_ogap,~,ogapData] = get_mean_ste_from_barStat(barStat,'og-5s ap-0.1s');
[~,meanVal_ap,steVal_ap,~,apData] = get_mean_ste_from_barStat(barStat,'ap-0.1s');

if apCorrection
	apCorrectionStr = ' apBaseBinShift'; 
else
	apCorrectionStr = '';
end
% indicate that the data are normalized to baseline
if normToBase
	normToBaseStr = ' normToBase';
else
	normToBaseStr = '';
end
figTitleStr_1 = sprintf('diff between og-5s and og-5s ap-0.1s in %gs bins%s%s',binWidth,normToBaseStr,apCorrectionStr);
figTitleStr_2 = sprintf('diff between og-5s and ap-0.1s in %gs bins%s%s',binWidth,normToBaseStr,apCorrectionStr);
figTitleStr_3 = sprintf('diff between ap-0.1s and og-5s ap-0.1s in %gs bins%s%s',binWidth,normToBaseStr,apCorrectionStr);


[ttest_p_1,diffVal_1,scatterNum_1]=plot_diff_usingRawData(xData,ogData,ogapData,...
	'legStrA','og-5s','legStrB','og-5s ap-0.1s','new_xticks',binEdges,'figTitleStr',figTitleStr_1,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig);

[ttest_p_2,diffVal_2,scatterNum_2]=plot_diff_usingRawData(xData,ogData,apData,...
	'legStrA','og-5s','legStrB','ap-0.1s','new_xticks',binEdges,'figTitleStr',figTitleStr_2,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig);

% shift ogap data to 1 s left, so its ap is aligned with ap tirals ap
ogapData_shift = ogapData(2:end);
[ttest_p_3,diffVal_3,scatterNum_3]=plot_diff_usingRawData(xData,apData,ogapData_shift,...
	'legStrA','ap-0.1s','legStrB','og-5s ap-0.1s','new_xticks',binEdges,'figTitleStr',figTitleStr_3,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig);


%% ==================== 
% 9.1.3 Plot the auto-correlogram of events and the probability density function of inter-event time
close all
saveFig = true; % true/false
% gui_save = false;
timeType = 'peak_time'; % rise_time/peak_time
preEventDuration = 3;
postEventDuration = 5;
remove_centerEvents = true;
binWidth = 0.1;
normData = true;
ACG_stimEvents(1).stim = 'ap-0.1s'; 
ACG_stimEvents(1).eventCat = 'trig'; 
ACG_stimEvents(2).stim = 'og-5s'; 
ACG_stimEvents(2).eventCat = 'rebound'; 
ACG_stimEvents(3).stim = 'og-5s ap-0.1s'; 
ACG_stimEvents(3).eventCat = 'rebound'; 
ACG_stimEvents(4).stim = 'og-5s ap-0.1s'; 
ACG_stimEvents(4).eventCat = 'interval-trigger'; 

if saveFig
	save_dir = uigetdir(FolderPathVA.fig,'Choose a folder to save autoCorrelograms');
end

% auto-correlogram of events
binnedACG_cell = cell(numel(ACG_stimEvents),1);
for n = 1:numel(ACG_stimEvents)
	[binnedACG_cell{n},FolderPathVA.fig] = plot_autoCorrelogramEvents(alignedData_allTrials,...
				'timeType',timeType,'stimName',ACG_stimEvents(n).stim,'stimEventCat',ACG_stimEvents(n).eventCat,...
				'remove_centerEvents',remove_centerEvents,'binWidth',binWidth,'normData',normData,...
				'preEventDuration',preEventDuration,'postEventDuration',postEventDuration,...
				'saveFig',saveFig,'save_dir',save_dir,'gui_save',false);
end
binnedACG = vertcat(binnedACG_cell{:});

% probability density function of inter-event time

binsOrEdges = [0:binWidth:10];
plot_eventTimeInt_alignedData_allTrials(alignedData_allTrials,timeType,binsOrEdges,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'saveFig',saveFig,'save_dir',save_dir,'gui_save',false);


%% ==================== 
% 9.1.4 Get decay curve taus and plot them in histogram
close all
filter_roi_tf = true;
stimName = 'og-5s';
stimEffect_filter = [nan 1 nan]; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
rsquare_thresh = 0.7;
norm_FluorData = false; % true/false. whether to normalize the FluroData

[roi_tauInfo] = get_decayCurveTau(alignedData_allTrials,'rsquare_thresh',rsquare_thresh,...
 	'filter_roi_tf',filter_roi_tf,'stimName',stimName,'stimEffect_filter',stimEffect_filter);
histogram([roi_tauInfo.tauMean],20);
FolderPathVA.fig = savePlot(gcf,'guiSave','on','save_dir',FolderPathVA.fig,'fname','hist_tau_mean');

%% ====================
% 9.1.5 Plot traces and stim-aligned traces
% Note: set adata.event_type to 'stimWin' when creating alignedData_allTrials
close all
save_fig = false; % true/false
pause_after_trial = true;
TraceType = 'aligned'; % 'full'/'aligned'. Plot the full trace or stimulation aligned trace
plotAllCombine = true; % Plot a figure combining all ROI in a recording
markers_name = {}; % of which will be labled in trace plot: 'peak_loc', 'rise_loc'
if save_fig
	save_dir = uigetdir(FolderPathVA.fig,'Choose a folder to save plots');
	if save_dir~=0
		FolderPathVA.fig = save_dir;
	end 
end
trial_num = numel(alignedData_allTrials);
for tn = 1:trial_num
	alignedData = alignedData_allTrials(tn);
	PlotTraceFromAlignedDataVar(alignedData,'TraceType',TraceType,'markers_name',markers_name,...
		'plotAllCombine',plotAllCombine,'save_fig',save_fig,'save_dir',save_dir);
	if pause_after_trial
		pause
	end
end


%% ====================
% Note: plot_stimAlignedTraces does not work properly if there are trials
% applied with varied stim durations
% 9.2.1.1 Check trace aligned to stim window
% note: 'event_type' for alignedData_allTrials must be 'stimWin'
close all
tplot.save_fig = false; % true/false
tplot.plot_combined_data = false; % true/false
tplot.plot_stim_shade = true; % true/false
tplot.y_range = [-20 30];
tplot.stimEffectType = 'rebound'; % options: 'excitation', 'inhibition', 'rebound'
tplot.section = []; % n/[]. specify the n-th repeat of stimWin. Set it to [] to plot all stimWin 
tplot.sponNorm = false; % true/false
stimNames = {'ap-0.1s','ap-0.1s og-5s','og-5s'};
tplot.save_dir = FolderPathVA.fig;

fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedData_allTrials,...
	'plot_combined_data',tplot.plot_combined_data,'plot_stim_shade',tplot.plot_stim_shade,'section',tplot.section,...
	'y_range',tplot.y_range,'stimEffectType',tplot.stimEffectType,'sponNorm',tplot.sponNorm);
if tplot.save_fig
	tplot.fname = sprintf('stimWin_aligned_traces');
	FolderPathVA.fig = savePlot(fHandle_stimAlignedTrace,'guiSave','on','save_dir',tplot.save_dir,'fname',tplot.fname);
end

%% ====================
% 9.2.1.2 Check trace aligned to stim window for calcium level change. 
% On y-axis, traces are aligned the the average of baseline before stimulation
close all
tplot.save_fig = false;
tplot.plot_combined_data = true;
tplot.plot_stim_shade = true;
tplot.y_range = [-20 10];
tplot.tickInt_time = 1;
tplot.stimEffectType = 'excitation'; % options: 'excitation', 'inhibition', 'rebound'
tplot.section = []; % n/[]. specify the n-th repeat of stimWin. Set it to [] to plot all stimWin 
tplot.sponNorm = false; % true/false
tplot.FN_trace = 'CaLevelTrace'; % field in alignedData.traces where the traces are stored
tplot.FN_time = 'timeCaLevel'; % default field in alignedData where the timeinfo is stored
tplot.save_dir = FolderPathVA.fig;

fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedData_allTrials,...
	'plot_combined_data',tplot.plot_combined_data,'plot_stim_shade',tplot.plot_stim_shade,'section',tplot.section,...
	'y_range',tplot.y_range,'tickInt_time',tplot.tickInt_time,'stimEffectType',tplot.stimEffectType,'sponNorm',tplot.sponNorm,...
	'FN_trace',tplot.FN_trace,'FN_time',tplot.FN_time);
if tplot.save_fig
	tplot.fname = sprintf('stimWin_aligned_traces');
	FolderPathVA.fig = savePlot(fHandle_stimAlignedTrace,'guiSave','on','save_dir',tplot.save_dir,'fname',tplot.fname);
end

%% ====================
% 9.2.2 Check aligned trace of events belong to the same category
% note: 'event_type' for alignedData_allTrials must be 'detected_events'
close all
tplot.save_fig = false; % true/false
tplot.plot_combined_data = true; % mean value and std of all traces
tplot.plot_raw_races = false; % true/false. true: plot every single trace
tplot.y_range = [-3 7];
tplot.eventCat = {'spon','rebound','trig'}; % options: 'trig', 'spon', 'rebound'
tplot.sponNorm = false; % true/false
tplot.save_dir = FolderPathVA.fig;

stimAlignedTrace_means = empty_content_struct({'event_group','trace'},numel(tplot.eventCat));
for cn = 1:numel(tplot.eventCat)
	stimAlignedTrace_means(cn).event_group = tplot.eventCat{cn};
	tplot.fname = sprintf('aligned_catTraces_%s',tplot.eventCat{cn});
	[fHandle_stimAlignedTrace,stimAlignedTrace_means(cn).trace] = plot_aligned_catTraces(alignedData_allTrials,...
		'plot_combined_data',tplot.plot_combined_data,'plot_raw_races',tplot.plot_raw_races,...
		'eventCat',tplot.eventCat{cn},'y_range',tplot.y_range,'sponNorm',tplot.sponNorm); % 'fname',fname,
	if tplot.save_fig
        
		if cn == 1
			tplot.guiSave = 'on';
		elseif cn > 1
			tplot.save_dir = FolderPathVA.fig;
			tplot.guiSave = 'off';
		end
		FolderPathVA.fig = savePlot(fHandle_stimAlignedTrace,'guiSave',tplot.guiSave,'save_dir',tplot.save_dir,'fname',tplot.fname);
	end
end



%% ====================
% 9.5.1.1 Create 'eventProp_all' according to stimulation and category 

eprop.entry = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
eprop.modify_stim_name = true; % true/false. Change the stimulation name, 
                            % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)

[eventProp_all]=collect_events_from_alignedData(alignedData_allTrials,...
	'entry',eprop.entry,'modify_stim_name',eprop.modify_stim_name);


% Rename stim name of og to EXog if og-5s exhibited excitation effect
eventType = eprop.entry; % 'roi' or 'event'. The entry type in eventProp
mgSetting.sponOnly = false; % true/false. If eventType is 'roi', and mgSetting.sponOnly is true. Only keep spon entries
mgSetting.seperate_spon = true; % true/false. Whether to seperated spon according to stimualtion
mgSetting.dis_spon = false; % true/false. Discard spontaneous events
mgSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
mgSetting.groupField = {'stim_name', 'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 

% if strcmp('stim_name',mgSetting.groupField) && strcmp('roi',eprop.entry)
% 	keep_eventcat = 'spon'; % only keep spon events to avoid duplicated values when eprop.entry is "roi"
% 	eventProp_all = filter_structData(eventProp_all,'peak_category','spon',1);
% end

% rename the stimulation tag if og evokes spike at the onset of stimulation
mgSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
mgSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'

% arrange the order of group entries using function [sort_struct_with_str] with settings below. 
mgSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
mgSetting.sort_order_plus = {'ap', 'EXopto'};
debug_mode = false; % true/false

[grouped_event,grouped_event_setting] = mod_and_group_eventProp(eventProp_all,eventType,adata,...
	'mgSetting',mgSetting,'debug_mode',debug_mode);
[grouped_event_setting.TrialRoiList] = get_roiNum_from_eventProp_fieldgroup(eventProp_all,'stim_name'); % calculate all roi number
if strcmpi(eprop.entry,'roi')
	GroupNum = numel(grouped_event);
	% GroupName = {grouped_event.group};
	for gn = 1:GroupNum
		EventInfo = grouped_event(gn).event_info;
		fovIDs = {EventInfo.fovID};
		roi_num = numel(fovIDs);
		fovIDs_unique = unique(fovIDs);
		fovIDs_unique_num = numel(fovIDs_unique);
		fovID_count_struct = empty_content_struct({'fovID','numROI','perc'},fovIDs_unique_num);
		[fovID_count_struct.fovID] = fovIDs_unique{:};
		for fn = 1:fovIDs_unique_num
			fovID_count_struct(fn).numROI = numel(find(contains(fovIDs,fovID_count_struct(fn).fovID)));
			fovID_count_struct(fn).perc = fovID_count_struct(fn).numROI/roi_num;
		end
		grouped_event(gn).fovCount = fovID_count_struct;
	end
end

%% ====================
% 9.5.1.2 screen groups based on tags. Delete unwanted groups for event analysis

% {'trig [EXog]','EXog','trig-AP',}
tags_discard = {'spon','rebound [ap','ap-0.25s','ap-0.5s','og-0.96s'}; % Discard groups containing these words. 'opto-delay','og&ap'
tags_keep = {'trig','trig [og','rebound','opto-delay [og-5s]','trig-ap'}; % Keep groups containing these words
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_info_filtered] = filter_entries_in_structure(grouped_event,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry);

%% ====================
% 9.5.2.1 Plot event parameters. Grouped according to categories
% [9.3] eventProp_all: entry is 'events'
close all
save_fig = true; % true/false
plot_combined_data = false;
parNames = {'rise_duration','FWHM','peak_mag_delta','sponNorm_peak_mag_delta',...
    'baseDiff','baseDiff_stimWin','val_rise','rise_delay','peak_delay'}; % entry: event
        % 'rise_duration','sponNorm_rise_duration','peak_mag_delta',...
        % 'sponNorm_peak_mag_delta','baseDiff','baseDiff_stimWin','val_rise',
    
    	% baseDiff = EventRiseVal-BaselineVal
    	% baseDiff_stimWin = min_stimWinVal-BaselineVal
        % {'sponNorm_rise_duration', 'sponNorm_peak_delta_norm_hpstd', 'sponNorm_peak_slope_norm_hpstd'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
		% 'sponNorm_rise_duration', 'sponNorm_peak_mag_delta', 'sponNorm_peak_delta_norm_hpstd'
		% 'sponNorm_peak_slope', 'sponNorm_peak_slope_norm_hpstd'
save_dir = FolderPathVA.fig;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

% grouped_event = grouped_event_bk;
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
% 9.5.2.2 
close all
save_fig = true; % true/false
% Show the relationship between decayTau/caLevelDecrease and various rebound event properties
fieldNames_rb_prop = {'rise_duration','FWHM','peak_mag_delta','sponNorm_peak_mag_delta',...
	'rise_delay','peak_delay'}; % properties of rebound events.
GroupedEventTags = {grouped_event_info_filtered.tag}; % Get the tags containing event catergory and stimulation
pos_OG5sRB = find(strcmpi('rebound [og-5s]', GroupedEventTags)); % Get the idx of rebound events in og-5s recordings
rbEventInfo = grouped_event_info_filtered(pos_OG5sRB).event_info;
BarInfo_rbEvents = plot_reboundEvent_analysis(rbEventInfo,'fieldNames_rb_prop',fieldNames_rb_prop,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','on');

% if filter_roi_tf == true
% 	[alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
% 			'stim_names',stim_names,'filters',filters); % check section before 9.1.1
% else 
% 	alignedData = alignedData_allTrials;
% end

[List_curveFitNum_eventNum_ogRB,~,save_dir] = plot_stimNum_fitNum_eventNum(alignedData,'rebound','og-5s',...
	'stimTimeCol',2,'save_fig',save_fig,'save_dir',save_dir,'gui_save',true);
[List_curveFitNum_eventNum_ogTrig] = plot_stimNum_fitNum_eventNum(alignedData,'trig','og-5s',...
	'stimTimeCol',1,'save_fig',save_fig,'save_dir',save_dir,'gui_save',false);
[List_curveFitNum_eventNum_apTrig] = plot_stimNum_fitNum_eventNum(alignedData,'trig','ap-0.1s',...
	'stimTimeCol',1,'save_fig',save_fig,'save_dir',save_dir,'gui_save',false);

%% ====================
% 9.5.2.3
close all
save_fig = true; % true/false
gui_save = true;
filter_roi_tf = false;
excludeWinPre = 1; % exclude the specified duration (unit: s) before stimulation
excludeWinPost = 3; % exclude the specified duration (unit: s) after stimulation
[sponFreqList,sponFreqStat] = plot_sponFreq_everyStim_trials(alignedData_allTrials,'og-5s',...
	'excludeWinPre',excludeWinPre,'excludeWinPost',excludeWinPost,'filter_roi_tf',filter_roi_tf,...
	'save_fig',save_fig,'save_dir',save_dir,'gui_save',gui_save);
%% ====================
% 9.5.3 screen groups based on tags. Delete unwanted groups for roi analysis
tags_discard = {'opto-delay','rebound-ap','rebound-og-0.96s','varied','og-5s ap-0.1s','ap-0.1s og-5s'}; % Discard groups containing these words. 'spon','EXopto','trig-ap',
% tags_keep = {'og-5s','ap-0.1s'}; % Keep groups containing these words: {'trig-ap','trig','rebound'}
tags_keep = {'og-5s-spon'}; % Keep groups containing these words: {'trig-ap','trig','rebound'}
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_info_filtered] = filter_entries_in_structure(grouped_event,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry);

%% ====================
% 9.5.4 Plot roi parameters. Grouped according to categories
% [9.3] eventProp_all: entry is 'roi'. mgSetting.groupField = {'stim_name','peak_category'};
close all
plot_combined_data = true;
parNames = {'sponfq','stimfq','stimfqNorm','stimfqDeltaNorm',...
'CaLevelDelta','CaLevelMinDelta','stimEvent_possi','StimCurveFit_TauMean'}; % entry: roi
save_fig = false; % true/false
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

% temproal solution: plot fov percentage and save
% fov_bar = figure('Name','FOV percentage');
fov_bar = fig_canvas(1,'fig_name','FOV percentage','unit_width',0.6,'unit_height',0.3);
% eventPb_bar = figure('Name','event probability','Position',[0.1 0.1 0.4 0.2],'Units','Normalized');

fovID_plot_info = empty_content_struct({'group','fovCount'},numel(grouped_event_info_filtered));
[fovID_plot_info.group] = grouped_event_info_filtered.group;
[fovID_plot_info.fovCount] = grouped_event_info_filtered.fovCount;
tlo_fov_bar = tiledlayout(fov_bar,ceil(numel(grouped_event_info_filtered)/4),4);
for gn = 1:numel(grouped_event_info_filtered)
	group_name = grouped_event_info_filtered(gn).group;
	fovInfo = grouped_event_info_filtered(gn).fovCount;
	fovIDs = {fovInfo.fovID};
	fovPerc = [fovInfo.perc];
	ax_fov_bar = nexttile(tlo_fov_bar);
	bar(categorical(fovIDs),fovPerc);
	set(gca, 'box', 'off')
	title(group_name);
	if save_dir
		savePlot(fov_bar,'save_dir',save_dir,'fname','fovID_perc');
	end
	% [eventPb_plot_info(gn).plotinfo] = barplot_with_stat(fovPerc,'group_names',fovIDs,...
	% 	'plotWhere',ax_fov_bar,'title_str',group_name,'save_fig',save_fig,'save_dir',save_dir);
end

if save_fig
	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info.grouped_event_info_filtered = grouped_event_info_filtered;
	plot_stat_info.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info','fovID_plot_info');
end

%% ====================
% 9.5.4.1 Plot the event probability
% Create grouped_event_info with the following settings and filter it
% [9.3] eventProp_all: entry is 'roi'. mgSetting.groupField = {'stim_name'};
% If save, save to the existing save_dir
close all
save_fig = false; % true/false
eventPb_bar = fig_canvas(1,'fig_name','event probability','unit_width',0.6,'unit_height',0.3);
eventPb_plot_info = empty_content_struct({'group','plotinfo'},numel(grouped_event_info_filtered));
[eventPb_plot_info.group] = grouped_event_info_filtered.group;
tlo_eventPb_bar = tiledlayout(eventPb_bar,ceil(numel(grouped_event_info_filtered)/4),4);
for gn = 1:numel(grouped_event_info_filtered)
	group_name = grouped_event_info_filtered(gn).group;
	eventPbInfo = grouped_event_info_filtered(gn).eventPb;
	eventCats = (eventPbInfo.eventCat);
	eventPbCell = eventPbInfo{:,'eventPb_val'};
	ax_eventPb_bar = nexttile(tlo_eventPb_bar);
	[eventPb_plot_info(gn).plotinfo] = barplot_with_stat(eventPbCell,'group_names',eventCats,...
		'plotWhere',ax_eventPb_bar,'title_str',group_name,'save_fig',save_fig,'save_dir',save_dir);
end


%% ====================
% 9.5.5 comparison within cells. 
% Note: eprop.entry = 'roi'; mgSetting.groupField = {'stim_name'}; mgSetting.sponOnly = true;
% plot for paired parameters in same ROIs and run paired ttest
close all
save_fig = true; % true/false
paired_fields = {{'sponfq','stimfq'}, {'CaLevelmeanBase','CaLevelmeanStim'}};
stat = 'pttest';
plotdata = true; % true/false
group_num = numel(grouped_event_info_filtered);
if save_fig
	save_dir = uigetdir(FolderPathVA.fig);
	if save_dir~=0
		FolderPathVA.fig = save_dir;
	end
end
withinCellComp_stat = empty_content_struct({'group','stat'},group_num);
for gn = 1:group_num
	withinCellComp_stat(gn).group = grouped_event_info_filtered(gn).group;
	[withinCellComp_stat(gn).stat] = comparison_within_strutEntry(grouped_event_info_filtered(gn).event_info,paired_fields,...
		'stat',stat,'plotdata',plotdata,'save_fig',save_fig,'save_dir',save_dir,...
		'title_str',grouped_event_info_filtered(gn).group);
end

%% ====================
% 9.5.5 Compare baseline and stimulation calcium signal change (one type of stimulaiton) using boxplot
stim_name = 'og-5s';
box_duration = 1; % unit: second. one box show the calcium signal in the specified duration
filter = [0 1 nan]; % [ex in rb].
[alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
			'stim_names',stim_name,'filters',filter);
[CaLevelData,CaLevelData_n_num] = GetCalLevelInfoFromAlignedData(alignedData_filtered,stim_name);
freq = get_frame_rate(CaLevelData.time);
box_DataPoint = box_duration*freq; % time point number in a singla box 
box_num = floor(max(CaLevelData.time)-min(CaLevelData.time))/box_duration;
xData = [CaLevelData.time(1):box_duration:(CaLevelData.time(1)+box_duration*(box_num-1))]+box_duration/2; % the x-axis location of data in the plot 
box_data_cellarray = cell(box_num,1);
data_groupName = cell(box_num,1);
for bn = 1:box_num
	start_loc = (bn-1)*box_DataPoint+1;
	end_loc = bn*box_DataPoint;
	single_box_data = mean(CaLevelData.data(start_loc:end_loc,:));
	box_data_cellarray{bn} = single_box_data(:);
end
[~,CaLevel_box_statInfo] = boxPlot_with_scatter(box_data_cellarray,'groupNames',NumArray2StringCell(xData),...
	'stat',true,'plotScatter',false);
title('CaLevel box')
ylim([-4 4]);
FolderPathVA.fig = savePlot(gcf,'guiSave','on','save_dir',FolderPathVA.fig,'fname','CaLevel box');
save(fullfile(save_dir, ['CaLevel_data_stat']),'CaLevelData','CaLevelData_n_num','CaLevel_box_statInfo');

violinData = [box_data_cellarray{:}]; % convert cell data to matrix
violinplot(violinData,NumArray2StringCell(xData));
savePlot(gcf,'guiSave','off','save_dir',FolderPathVA.fig,'fname','CaLevel violin');
%% ====================
% 9.6.1 Get the stimulation effect info, such as inhibition, excitation for each ROI
% Scatter plot the rois (inhibition/excitation/... vs meanTraceLevel) 'meanTraceLevel' is output by func [get_stimEffect]
stim = 'og'; % data will be collected from trials applied with this stimulation
[stimEffectInfo,meanTrace_stim,logRatio_SponStim] = get_stimEffectInfo_all_roi(alignedData_allTrials,'stim',stim);

% plot
save_fig = true; % true/false
close all
colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};

% groups = {'inhibition', 'excitation', 'rebound', 'ExIn'}; % 'rebound'
groups = fieldnames(meanTrace_stim); % 'rebound'
num_groups = numel(groups);
% figure
[~] = fig_canvas(1,'fig_name','StimEffect',...
	'unit_width',0.4,'unit_height',0.6);
hold on
for gn = 1:num_groups
	if contains(groups{gn}, 'rebound')
		mSize = 10;
	else
		mSize = 50;
	end
	h(gn) = scatter(gca,meanTrace_stim.(groups{gn}), logRatio_SponStim.(groups{gn}),...
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

clear stimEffectInfo meanTrace_stim logRatio_SponStim

%% ====================
% 9.2.0.3 Plot traces, aligned traces and roi map
close all
save_fig = true; % true/false
pause_after_trial = false;
markers_name = {}; % of which will be labled in trace plot: 'peak_loc', 'rise_loc'

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
	plot_trace_roiCoor(alignedData,'markers_name',markers_name,...
		'save_fig',save_fig,'save_dir',save_dir);
	fprintf('- %d/%d: %s\n', tn, trial_num, alignedData.trialName);

	if pause_after_trial
		direct_input = input(sprintf('\n(c)continue  (b)back to previous or input the trial number [default-c]:'), 's');
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
	else
		tn = tn+1;
	end
end

%% ====================
% Plot venn diagram to show the number of ROIs of OG-evoke-pos, OG-rebound-pos, and double-neg.
close all
venndia = empty_content_struct({'stim_name','EventType1','EventType2','roi_allnum','EventType1_num','EventType2_num','Intersect_num','A','I'},1);
venndia.stim_name = 'og-5s';
keep_specified_stim = 1;
venndia.EventType1 = 'trig';
venndia.EventType2 = 'rebound';
% Get the event list from alignedData_allTrials
[alignedData_event_list] = eventcat_list(alignedData_allTrials);

% Get the trials applied with specific stimulation (input after 'stim')
[alignedData_event_list_stim,varargout] = filter_structData(alignedData_event_list,...
	'stim',venndia.stim_name,keep_specified_stim); 

% Get the total ROI num
roi_info_cell = {alignedData_event_list_stim.roi_info}; % store the roi_info field in a cell array
roi_combine = vertcat(roi_info_cell{:});
% roi_num = sum(cellfun(@numel,roi_info_cell)); % total roi_num

% Prepare a vector to plot the venn diagram
EventType1_loc=find([roi_combine.(venndia.EventType1)]>0);
EventType2_loc=find([roi_combine.(venndia.EventType2)]>0);
EventTypes_intersect = intersect(EventType1_loc,EventType2_loc);
AllRoi_loc = [1:numel(roi_combine)];
venndia.EventType1_num = numel(EventType1_loc);
venndia.EventType2_num = numel(EventType2_loc);
venndia.Intersect_num = numel(EventTypes_intersect);
venndia.roi_allnum = numel(AllRoi_loc);
venndia.A = [venndia.roi_allnum,venndia.EventType1_num,venndia.EventType2_num];
venndia.I = [venndia.EventType1_num,venndia.EventType2_num,venndia.Intersect_num,venndia.Intersect_num];

% Plot venn diagram
% F = struct('Display', 'iter');
figure
venn(venndia.A,venndia.I);
save_dir = savePlot(gcf,'guiSave','on','save_dir',FolderPathVA.fig,'fname','Venn_dia');
save(fullfile(save_dir, ['venndia_data']),'venndia');


% [H,S] = venn(A,I,F,'ErrMinMode','ChowRodgers','FaceAlpha', 0.6);
 
% %Now label each zone 
% for i = 1:7
%     text(S.ZoneCentroid(i,1), S.ZoneCentroid(i,2), ['Zone ' num2str(i)])
% end




% Analysis for spontaneous spikes
%% ====================
% 9.3 Collect event properties from alignedData_allTrials
eprop.entry = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
eprop.modify_stim_name = true; % true/false. Change the stimulation name, 
                            % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)

[eventProp_all]=collect_events_from_alignedData(alignedData_allTrials,...
	'entry',eprop.entry,'modify_stim_name',eprop.modify_stim_name);

%% ====================
% 9.4.1 Collect spontaneous events from 'eventProp_all' for comparison among FOVs
% "entryStyle" field in "eventProp_all" must be 'event'. The field "event_type" in alignedData_allTrials used 
% to produce eventProp_all must be 'detected_events' 
[collectSp.category_idx] = get_category_idx({eventProp_all.peak_category}); % get the idex of events belong to various categories
collectSp.spon_field_idx = find(strcmpi('spon', {collectSp.category_idx.name})); % the location of spon idx in structure category_idx
collectSp.spon_idx = collectSp.category_idx(collectSp.spon_field_idx).idx;
collectSp.spon_eventProp = eventProp_all(collectSp.spon_idx); % get properties of all spon events in eventProp_all
[grouped_spon_event_info, grouped_spon_event_opt] = group_event_info_multi_category(collectSp.spon_eventProp,...
	'category_names', {'fovID'}); % one entry for one event

% Get the spon frequency and average interval time. Spon events in single ROIs will be used
collectSp.mod_pcn = false; % true/false modify the peak category names with func [mod_cat_name]
collectSp.keep_catNames = {'spon'}; % 'spon'. event will be kept if its peak-cat is one of these
debug_mode = false;
[alignedData_allTrials_spon] = org_alignData(alignedData_allTrials,'keep_catNames', collectSp.keep_catNames,...
	'mod_pcn', collectSp.mod_pcn, 'debug_mode', false); % only keep spon events in the event properties
[eventProp_all_spon] = collect_event_prop(alignedData_allTrials_spon, 'style', 'roi'); % only use 'event' for 'style'

collectSp.category_names = {'fovID'}; % options: 'fovID', 'stim_name', 'peak_category'
[grouped_spon_roi_info, grouped_spon_roi_opt] = group_event_info_multi_category(eventProp_all_spon,...
	'category_names', collectSp.category_names);

%% ====================
% 9.4.2.1 Plot spon event parameters
close all
tplot.plot_combined_data = true;
tplot.parNames_event = {'rise_duration','peak_mag_delta'};

        % {'sponNorm_rise_duration', 'sponNorm_peak_delta_norm_hpstd', 'sponNorm_peak_slope_norm_hpstd'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
		% 'sponNorm_rise_duration', 'sponNorm_peak_mag_delta', 'sponNorm_peak_delta_norm_hpstd'
		% 'sponNorm_peak_slope', 'sponNorm_peak_slope_norm_hpstd'
tplot.save_fig = false; % true/false
tplot.save_dir = FolderPathVA.fig;
tplot.stat = true; % true if want to run anova when plotting bars
tplot.stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

[tplot.save_dir_event, plot_info_event] = plot_event_info(grouped_spon_event_info,...
	'plot_combined_data', tplot.plot_combined_data, 'parNames', tplot.parNames_event, 'stat', tplot.stat,...
	'save_fig', tplot.save_fig, 'save_dir', tplot.save_dir);
if tplot.save_dir_event~=0
	FolderPathVA.fig = tplot.save_dir_event;
end
if tplot.save_fig
% 	plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info_spon.grouped_event_info = grouped_spon_event_info;
	plot_stat_info_spon.plot_info = plot_info_event;
	tplot.dt = datestr(now, 'yyyymmdd');
	save(fullfile(tplot.save_dir, [tplot.dt, '_plot_stat_info_spon']), 'plot_stat_info_spon');
end

%% ====================
% 9.4.2.2 Plot spon freq and event interval
close all
tplot.plot_combined_data = true;
tplot.parNames_roi = {'sponfq', 'sponInterval'};
tplot.save_fig = true; % true/false
tplot.save_dir = FolderPathVA.fig;
tplot.stat = true; % true if want to run anova when plotting bars
tplot.stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not
[tplot.save_dir_roi, plot_info_roi] = plot_event_info(grouped_spon_roi_info,...
	'plot_combined_data', tplot.plot_combined_data, 'parNames', tplot.parNames_roi, 'stat', tplot.stat,...
	'save_fig', tplot.save_fig, 'save_dir', tplot.save_dir);
if tplot.save_dir_roi~=0
	FolderPathVA.fig = tplot.save_dir_roi;
end
if tplot.save_fig
	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_sponfreq_info.grouped_event_info = grouped_spon_roi_info;
	plot_sponfreq_info.plot_info = plot_info_roi;
	tplot.dt = datestr(now, 'yyyymmdd');
	save(fullfile(tplot.save_dir, [tplot.dt, '_plot_sponfreq_info']), 'plot_sponfreq_info');
end
