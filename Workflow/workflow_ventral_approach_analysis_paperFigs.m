% This script is used on office local desktop running windows 10
% Use this script after exporting motion corrected files with tiff format. 
% Process files with CNMFe with cluster. And then come back for further analysis
	% Inscopix API related process, such as spatial filter and motion correction cannot be run on VDI. 
	% CNMFe can be run here alternatively, but deigo cluster is way faster
% All files are stored on bucket

% This workflow script is modified from "workflow_ventral_approach_analysis"
% 2022.03.18 Some sections are deleted. Some are reorganized to facilitate the workflow

%% ====================
% Clear Workspace
clearvars -except recdata_organized opt alignedData_allTrials adata alignedData_event_list seriesData_sync grouped_event grouped_event_info_filtered recdata_manual_new

%% ====================
% 7 Setup folders 
% This section is necessary for most sections in this workflow script. 
% Even if you don't want to save the plots, FolderPathVA should exist to avoid bug

GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder

if GUI_chooseFolder
	DataFolder = uigetdir(matlabroot,'Choose a folder containing data and project folders');
	AnalysisFolder = uigetdir(matlabroot,'Choose a folder containing analysis');
else
	PC_name = getenv('COMPUTERNAME'); 
	% set folders for different situation
	DataFolder = 'G:\Workspace\Inscopix_Seagate';

	if strcmp(PC_name, 'GD-AW-OFFICE')
		AnalysisFolder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
	elseif strcmp(PC_name, 'LAPTOP-84IERS3H')
		AnalysisFolder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop
	else
		error('set var GUI_chooseFolder to true to select default folders using GUI')
	end
end

[FolderPathVA] = set_folder_path_ventral_approach(DataFolder,AnalysisFolder);
%% ====================
% Save processed data
save_dir = uigetdir(AnalysisFolder);
dt = datestr(now, 'yyyymmdd');
% save(fullfile(save_dir, [dt, '_ProcessedData_ogEx']),...
%     'recdata_organized','alignedData_allTrials','opt','adata');
uisave({'recdata_organized','alignedData_allTrials','opt','adata'},...
	fullfile(save_dir, [dt, '_ProcessedData_ogEx']));
% 'recdata_organized','alignedData_allTrials','grouped_event','adata','grouped_event_setting','opt','adata'


% %% ====================
% % 8.5 manually discard rois or trial 
% % recdata_organized_bk = recdata_organized;

% trial_idx = 35; % trial index number
% roi_idx = [5]; % roi number. 2 for 'neuron2'

% [recdata_organized] = discard_data(recdata_organized,trial_idx,roi_idx);
% %% ====================
% % 8.6 discard rec if the fovID number is bigger than fov_max
% fov_max = 6; % fov 1-6 are from the ChrimsonR positive CN axon side
% dis_idx = [];
% recdata_organized_bk = recdata_organized;
% recN = size(recdata_organized, 1);
% for rn = 1:recN
% 	fovID = recdata_organized{rn, 2}.fovID;
% 	fov_num = str2num(fovID((strfind(fovID, '-')+1):end));
% 	if fov_num > fov_max
% 		dis_idx = [dis_idx; rn];
% 	end
% end
% recdata_organized(dis_idx, :) = [];


%% ====================
% 8 Align traces from all trials. Also collect the properties of events
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
adata.sponfreqFilter.thresh = 0.06; % Hz
adata.sponfreqFilter.direction = 'high';
debug_mode = false; % true/false

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', adata.event_type,...
	'traceData_type', adata.traceData_type, 'event_data_group', adata.event_data_group,'eventTimeType',adata.eventTimeType,...
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
% Fig 2
% 9.1.1 Plot calcium signal as traces and color array, and calcium events with hist-count.
% Note: ROIs of all trials in alignedData_allTrials can be plotted. 
%	Use 'filter' to screen ROIs based on the effect of stimulation
close all
save_fig = true; % true/false

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

event_type = 'peak_time'; % rise_time/peak_time
norm_FluorData = true; % true/false. whether to normalize the FluroData
sortROI = true; % true/false. Sort ROIs according to the event number: high to low
preTime = 5; % fig3 include time before stimulation starts for plotting
postTime = 10; % fig3 include time after stimulation ends for plotting. []: until the next stimulation starts
activeHeatMap = true; % true/false. If true, only plot the traces with specified events in figure 3
stimEvents(1).stimName = 'og-5s';
stimEvents(1).eventCat = 'rebound';
stimEvents(1).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(1).stimRefType = 'end'; % The category of first event following the eventCat one
stimEvents(2).stimName = 'ap-0.1s';
stimEvents(2).eventCat = 'trig';
stimEvents(2).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(2).stimRefType = 'start'; % The category of first event following the eventCat one
stimEvents(3).stimName = 'og-5s ap-0.1s';
stimEvents(3).eventCat = 'trig-ap';
stimEvents(3).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(3).stimRefType = 'start'; % The category of first event following the eventCat one
followDelayType = 'stim'; % stim/stimEvent. Calculate the delay of the following events using the stimulation start or the stim-evoked event time
eventsTimeSort = 'all'; % 'off'/'inROI','all'. sort traces according to eventsTime
hist_binsize = 5; % the size of the histogram bin, used to calculate the edges of the bins
xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale. Use by figure 2
debug_mode = false; % true/false. 

FolderPathVA.fig = plot_calcium_signals_alignedData_allTrials(alignedData_allTrials,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'norm_FluorData',norm_FluorData,'sortROI',sortROI,'event_type',event_type,...
	'preTime',preTime,'postTime',postTime,'followDelayType',followDelayType,...
	'activeHeatMap',activeHeatMap,'stimEvents',stimEvents,'eventsTimeSort',eventsTimeSort,...
	'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'debug_mode',debug_mode);


%% ==================== 
% Fig 2
% 9.1.2 Plot the event frequency in specified time bins to examine the effect
% of stimulation and compare each pair of bins
close all
save_fig = false; % true/false
gui_save = 'on';

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
diffPair = {[1 3], [2 3], [1 2]}; % {[1 3], [2 3]}. binned freq will be compared between stimualtion groups. cell number = stimulation pairs. [1 3] mean stimulation 1 vs stimulation 2

propName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
binWidth = 1; % the width of histogram bin. the default value is 1 s.
stimIDX = []; % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
postStim_duration = 15; % unit: second. include events happened after the end of stimulations
customizeEdges = true; % true/false. customize the bins using function 'setPeriStimSectionForEventFreqCalc'
stimEffectDuration = 1; % unit: second. Use this to set the end for the stimulation effect range
splitLongStim = [1]; % If the stimDuration is longer than stimEffectDuration, the stimDuration 
					%  part after the stimEffectDuration will be splitted. If it is [1 1], the
					% time during stimulation will be splitted using edges below
					% [stimStart, stimEffectDuration, stimEffectDuration+splitLongStim, stimEnd] 
					
stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
stimEvents(1).stimName = 'og-5s';
stimEvents(1).eventCat = 'rebound';
stimEvents(1).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(2).stimName = 'ap-0.1s';
stimEvents(2).eventCat = 'trig';
stimEvents(2).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(3).stimName = 'og-5s ap-0.1s';
stimEvents(3).eventCat = 'rebound';
stimEvents(3).eventCatFollow = 'spon'; % The category of first event following the eventCat one

normToBase = true; % true/false. normalize the data to baseline (data before baseBinEdge)
baseBinEdgestart = -preStim_duration; % where to start to use the bin for calculating the baseline. -1
baseBinEdgeEnd = -2; % 0
apCorrection = false; % true/false. If true, correct baseline bin used for normalization. 


debug_mode = false; % true/false

% plot periStim event freq, and diff among them
[barStat,diffStat,FolderPathVA.fig] = periStimEventFreqAnalysis(alignedData_allTrials,'propName',propName,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,'diffPair',diffPair,...
	'binWidth',binWidth,'stimIDX',stimIDX,'normToBase',normToBase,...
	'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
	'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim,...
	'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
	'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','on','debug_mode',debug_mode);

% plot and compare a single bins from various stimulation groups
violinStimNames = {'og-5s ap-0.1s','og-5s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. these groups will be used for the violin plot
violinBinIDX = [4,4]; % [4,3,4]. violinPlot: the nth bin from the data listed in stimNames
normToFirst = false; % true/false. violinPlot: normalize all the data to the mean of the first group (first stimNames)

if normToFirst
	normStr = sprintf(' normTo[%s]',violinStimNames{1});
else
	normStr = '';
end

titleStr = sprintf('violinPlot of a single bin from periStim freq%s',normStr);
[violinData,statInfo] = violinplotPeriStimFreq2(barStat,violinStimNames,violinBinIDX,...
	'normToFirst',normToFirst,'titleStr',titleStr,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','off');

%% ====================
% Fig 2 violin plot of specific bins in periStim event frequency
% 9.1.3
close all
save_fig = false; % true/false
gui_save = 'on';

propName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
% binWidth = 1; % the width of histogram bin. the default value is 1 s.
preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
postStim_duration = 5; % unit: second. include events happened after the end of stimulations
normToBase = true; % true/false. normalize the data to baseline (data before baseBinEdge)
baseStart = -preStim_duration; % where to start to use the bin for calculating the baseline. -1
baseEnd = -2; % 0

filter_roi_tf = true; % true/false. If true, screen ROIs
stimTypeNum = 3;
winDuration = 2; % seconds
startTime1 = 1; % second
startTime2 = 0; % second
binRange = empty_content_struct({'stim','startTime'},stimTypeNum);
binRange(1).stim = 'og-5s';
binRange(1).filters = [0 nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
binRange(1).startTime = startTime1; % Use data in [startTime startTime+winDuration] range
binRange(2).stim = 'ap-0.1s';
binRange(2).filters = [1 nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
binRange(2).startTime = startTime2; 
binRange(3).stim = 'og-5s ap-0.1s';
binRange(3).filters = [0 nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
binRange(3).startTime = startTime1; 

stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
stimEvents(1).stimName = 'og-5s';
stimEvents(1).eventCat = 'rebound';
stimEvents(2).stimName = 'ap-0.1s';
stimEvents(2).eventCat = 'trig';
stimEvents(3).stimName = 'og-5s ap-0.1s';
stimEvents(3).eventCat = 'trig-ap';

debug_mode = false; % true/false

[violinData,statInfo,FolderPathVA.fig] = violinplotPeriStimFreq(alignedData_allTrials,...
	'filter_roi_tf',filter_roi_tf,'binRange',binRange,'PropName',propName,'winDuration',winDuration,...
	'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
	'normToBase',normToBase,'baseStart',baseStart,'baseEnd',baseEnd,...
	'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save',gui_save);



%% ====================
% Screen the ROIs in alignedData_allTrials with specific settings [stim_names and filters]
filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
[alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
			'stim_names',stim_names,'filters',filters);


%% ====================
% Fig 2
% 9.1.4 Plot traces and stim-aligned traces
% Note: set adata.event_type to 'stimWin' when creating alignedData_allTrials
close all
save_fig = false; % true/false
pause_after_trial = true;

filter_roi_tf = false; % true/false. If true, screen ROIs
TraceType = 'aligned'; % 'full'/'aligned'. Plot the full trace or stimulation aligned trace
markers_name = {}; % of which will be labled in trace plot: 'peak_loc', 'rise_loc'
if save_fig
	save_dir = uigetdir(FolderPathVA.fig,'Choose a folder to save plots');
	if save_dir~=0
		FolderPathVA.fig = save_dir;
	end 
else
	save_dir = '';
end

if filter_roi_tf
	alignedDataTrials_plot = alignedData_filtered;
else
	alignedDataTrials_plot = alignedData_allTrials;
end

trial_num = numel(alignedDataTrials_plot);
for tn = 1:trial_num
    close all
	alignedData = alignedDataTrials_plot(tn);
	% trialNameParts = split(alignedData.trialName, '_');
	% subfolderName = trialNameParts{1};
	% subfolderPath = fullfile(save_dir,subfolderName);
	% mkdir(subfolderPath);

	PlotTraceFromAlignedDataVar(alignedData,'TraceType',TraceType,'markers_name',markers_name,...
		'save_fig',save_fig,'save_dir',save_dir);
	if pause_after_trial
		pause
	end
end



%% ====================
% Fig 3 
% 9.2.1 Check aligned trace of events belong to the same category
% note: 'event_type' for alignedData_allTrials must be 'detected_events'
close all
tplot.save_fig = true; % true/false
tplot.plot_combined_data = true; % mean value and std of all traces
tplot.plot_raw_races = false; % true/false. true: plot every single trace
tplot.plot_median = false; % true/false. plot raw traces having a median value of the properties specified by 'tplot.medianProp'
tplot.medianProp = 'FWHM'; % 
tplot.shadeType = 'ste'; % plot the shade using std/ste
tplot.y_range = [-1 2]; % [-10 5],[-3 5],[-2 1]
tplot.eventCat = {'trig','trig-ap','rebound'}; % options: 'trig','trig-ap','rebound','spon', 'rebound'
tplot.combineStim = false; % true/false. combine the same eventCat from recordings applied with various stimulations
tplot.stimDiscard = {'ap-varied','og-0.96s'}; % 'og-5s',
tplot.sponNorm = false; % true/false
tplot.normalized = true; % true/false. normalize the traces to their own peak amplitudes.
tplot.save_dir = FolderPathVA.fig;

filter_roi_tf = false; % true/false
if filter_roi_tf
	alignedData = alignedData_filtered;
else
	alignedData = alignedData_allTrials;
end


if tplot.sponNorm
	sponNormStr = sprintf('sponNorm_');
else
	sponNormStr = '';
end
if tplot.normalized
	NormStr = sprintf('Norm_');
else
	NormStr = '';
end
if tplot.plot_combined_data
	meanDataStr = sprintf('_withMeanAndShade[%s]',tplot.shadeType);
else
	meanDataStr = '';
end
if tplot.plot_raw_races
	rawDataStr = sprintf('_withSingleTraces');
else
	rawDataStr = '';
end

stimAlignedTrace_means = empty_content_struct({'event_group','trace'},numel(tplot.eventCat));
for cn = 1:numel(tplot.eventCat)
	stimAlignedTrace_means(cn).event_group = tplot.eventCat{cn};
	tplot.fname = sprintf('%s%s%s-aligned_traces_%s%s%s',...
		NormStr,sponNormStr,adata.event_align_point,tplot.eventCat{cn},meanDataStr,rawDataStr);
	[fHandle_stimAlignedTrace,stimAlignedTrace_means(cn).trace] = plot_aligned_catTraces(alignedData,...
		'plot_combined_data',tplot.plot_combined_data,'plot_raw_races',tplot.plot_raw_races,...
		'plot_median',tplot.plot_median,'medianProp',tplot.medianProp,'eventCat',tplot.eventCat{cn},...
		'combineStim',tplot.combineStim,'stimDiscard',tplot.stimDiscard,'shadeType',tplot.shadeType,...
		'y_range',tplot.y_range,'sponNorm',tplot.sponNorm,'normalized',tplot.normalized,'fname',tplot.fname); % 'fname',fname,
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
% Fig 3 
% 9.2.2 Replot the averaged traces (same category) using the data in stimAlignedTrace_means
% This section can combine traces from different group
close all
save_fig = true; % true/false
tplot.y_range = [-1 2]; % [-10 5],[-3 5],[-2 1]
% {{stimName1,eventCat1},{stimName2,eventCat2}}. Combine the eventCat1 and eventCat2 from different stimNames
stimNameEventCat = {{'og-5s','trig'},{'og-5s ap-0.1s','trig'}}; 
[tracesInfo,stimCombine,eventCombine] = combineAlignedTraces(stimAlignedTrace_means,stimNameEventCat);
tickInt_time = 1;

% Create a figure name
f_AAT_name = sprintf('%s%s%s-aligned_traces_%s[%s]%s%s',...
	NormStr,sponNormStr,adata.event_align_point,tracesInfo.stim,eventCombine,meanDataStr,rawDataStr);

% create a figure for the averaged aligned trace
f_AAT = fig_canvas(3,'unit_width',0.3,'unit_height',0.2,...
	'column_lim',1,'fig_name',f_AAT_name); % create a figure

[tracesAverage,tracesShade,nNum,titleName] = plotAlignedTracesAverage(gca,tracesInfo.traces,tracesInfo.timeInfo,...
	'eventsProps',tracesInfo.eventProps,'shadeType',tplot.shadeType,...
	'plot_combined_data',tplot.plot_combined_data,'plot_raw_races',tplot.plot_raw_races,...
	'y_range',tplot.y_range,'tickInt_time',tickInt_time,'stimName',tracesInfo.stim,'eventCat',eventCombine);

if save_fig
	FolderPathVA.fig = savePlot(f_AAT,'guiSave','on','save_dir',FolderPathVA.fig,'fname',f_AAT_name);
end


%% ====================
% 9.3.1 Create 'eventProp_all' according to stimulation and category, and group them to 'grouped_event'

% This section is used to collect all ROI properties or event properties ('eprop.entry') and group
% them according to 'mgSetting.groupField'. Some analysis and plots can only be created using
% the 'grouped_event'

eprop.entry = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
eprop.modify_stim_name = true; % true/false. Change the stimulation name, 
                            % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)
filter_roi_tf = false; % true/false
if filter_roi_tf
	alignedData = alignedData_filtered;
else
	alignedData = alignedData_allTrials;
end


% Rename stim name of og to EXog if og-5s exhibited excitation effect
eventType = eprop.entry; % 'roi' or 'event'. The entry type in eventProp
mgSetting.sponOnly = false; % true/false. If eventType is 'roi', and mgSetting.sponOnly is true. Only keep spon entries
mgSetting.seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
mgSetting.dis_spon = false; % true/false. Discard spontaneous events
mgSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
mgSetting.groupField = {'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 


% rename the stimulation tag if og evokes spike at the onset of stimulation
mgSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
mgSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'

% arrange the order of group entries using function [sort_struct_with_str] with settings below. 
mgSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
mgSetting.sort_order_plus = {'ap', 'EXopto'};
debug_mode = false; % true/false

[grouped_event] = getAndGroup_eventsProp(alignedData,...
	'entry',eprop.entry,'modify_stim_name',eprop.modify_stim_name,...
	'mgSetting',mgSetting,'adata',adata,'debug_mode',debug_mode);


%% ====================
% 9.3.2 screen entries in 'grouped_event' based on tags. Delete unwanted groups for event analysis
% additional manual deletion might be needed

% {'trig [EXog]','EXog','trig-AP',}
tags_discard = {'rebound [ap','ap-0.25s','ap-0.5s','og-0.96s','opto-delay','rebound [og&ap-5s]',}; % Discard groups containing these words. 'spon','opto-delay','og&ap','rebound [og&ap-5s]'
tags_keep = {'trig','trig-ap','rebound [og-5s]','spon'}; % Keep groups containing these words. {'trig [og','rebound','opto-delay [og-5s]','spon'}
tagsForMerge = {'trig [og&ap-5s]','trig [og-5s]'};
NewGroupName = 'opto-evoked all';
NewtagName = 'opto-evoked [opto-5s opto-5s_air-0.1s]';
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_info_filtered] = filter_entries_in_structure(grouped_event,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry);
[grouped_event_info_filtered] = mergeGroupedEventEntry(grouped_event_info_filtered,tagsForMerge,...
	'NewGroupName',NewGroupName,'NewtagName',NewtagName);

%% ====================
% Fig 3
% 9.3.3 Plot event parameters. Grouped according to categories
% [9.3] eventProp_all: entry is 'events'
close all
save_fig = false; % true/false
plot_combined_data = false;
parNames = {'rise_duration','FWHM','sponNorm_peak_mag_delta'}; % entry: event
		% 'sponNorm_peak_mag_delta','rise_delay','peak_delay'
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

% Modify the group name for labeling the plots
[newStimNameEventCatCell] = modStimNameEventCat({grouped_event_info_filtered.group});
[grouped_event_info_filtered.group] = newStimNameEventCatCell{:};

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
% 9.3.4 Plot roi parameters. Grouped according to categories
box_duration = 1; % unit: second. one box show the calcium signal in the specified duration
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
% Fig 2: Plot violin of the event freq without and with OG stimulation
% 9.3.5 Compare baseline and stimulation calcium signal change (one type of stimulaiton) using boxplot
stim_name = 'og-5s';
stimFilter = [nan nan nan nan]; % [ex in rb exApOg].
[alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
			'stim_names',stim_name,'filters',stimFilter);
%% Create grouped_event using code in '9.5.1.1' after filtering alignedData_allTrials
% Using eventProp_all: entry is 'roi'. mgSetting.groupField = {'stim_name','peak_category'};

% Keep 'og-5s-spon' group and delete others
tags_discard = {'opto-delay','rebound-ap','rebound-og-0.96s','varied','og-5s ap-0.1s','ap-0.1s og-5s'}; % Discard groups containing these words. 'spon','EXopto','trig-ap',
% tags_keep = {'og-5s','ap-0.1s'}; % Keep groups containing these words: {'trig-ap','trig','rebound'}
tags_keep = {'og-5s-spon'}; % Keep groups containing these words: {'trig-ap','trig','rebound'}
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_ogExNeg] = filter_entries_in_structure(grouped_event,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry);

% Use Violin plot to show the difference of event freq without and with OG stimulation
close all
sponfq = [grouped_event_ogExNeg.event_info.sponfq];
stimfq = [grouped_event_ogExNeg.event_info.stimfq];
vData = [sponfq(:) stimfq(:)];
[~,vData_ttestPaired] = ttest(sponfq,stimfq);
vCategory = {'without OG','during OG'};
ogEventFreq.withoutOG = sponfq;
ogEventFreq.duringOG = stimfq;
ogEventFreq.ttestPaired = vData_ttestPaired;
violinplot(vData,vCategory);
titleStr = sprintf('eventFreq stim vs no-stim [%s] paired %g ROIs',stim_name,numel(ogEventFreq.withoutOG));
title(titleStr)
ylabel('frequency (Hz)')
[FolderPathVA.fig,figFileName] = savePlot(gcf,'save_dir',FolderPathVA.fig,'fname','eventFreq_in-out-OG','guiSave','on');
save(fullfile(FolderPathVA.fig,[figFileName,'_dataStat.mat']),'ogEventFreq');


%% ==================== 
% Fig 3
% Violin plot showing the difference of
% stim-related-event_to_following_event_time and the spontaneous_event_interval
close all
save_fig = false; % true/false
stimNameAll = {'og-5s','ap-0.1s'}; % 'og-5s' 'ap-0.1s'
stimEventCatAll = {'rebound','trig'}; % 'rebound', 'trig'
maxDiff = 3; % the max difference between the stim-related and the following events

% loop through different stim-event pairs

for n = 1:numel(stimNameAll) 
	stimName = stimNameAll{n};
	stimEventCat = stimEventCatAll{n};
	[intData,eventIntMean,eventInt,f,fname] = stimEventSponEventIntAnalysis(alignedData_allTrials,stimName,stimEventCat,...
	'maxDiff',maxDiff);

	if save_fig
		if n == 1 
			guiSave = 'on';
		else
			guiSave = 'off';
		end
		FolderPathVA.fig = savePlot(f,'save_dir',FolderPathVA.fig,'guiSave',guiSave,'fname',fname);
		save(fullfile(FolderPathVA.fig, [fname,' data']),'intData','eventIntMean','eventInt');
	end
end


%% ==================== 
% Fig 5 or supplementary data
% 9.1.3 Plot the auto-correlogram of events and the probability density function of inter-event time
close all
saveFig = false; % true/false
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
% Fig 5?
% 9.1.4 Get decay curve taus and plot them in histogram
close all
filter_roi_tf = true;
stimName = 'og-5s';
stimEffect_filter = [nan 1 nan nan]; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
rsquare_thresh = 0.7;
norm_FluorData = false; % true/false. whether to normalize the FluroData

[roi_tauInfo] = get_decayCurveTau(alignedData_allTrials,'rsquare_thresh',rsquare_thresh,...
 	'filter_roi_tf',filter_roi_tf,'stimName',stimName,'stimEffect_filter',stimEffect_filter);
histogram([roi_tauInfo.tauMean],20);
FolderPathVA.fig = savePlot(gcf,'guiSave','on','save_dir',FolderPathVA.fig,'fname','hist_tau_mean');


%% ==================== 
% Filter the ROIs in all trials using stimulation effect
% the filtered alignedData will be used in the following plotting sections
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[0 nan nan nan], [1 nan nan nan], [0 nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
[alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
	'stim_names',stim_names,'filters',filters);
title_prefix = 'filtered';




%% ====================
% Note: plot_stimAlignedTraces does not work properly if there are trials
% applied with varied stim durations
% 9.2.1.1 Check trace aligned to stim window
% note: 'event_type' for alignedData_allTrials must be 'stimWin'
close all
filter_roi_tf = true; % true/false. If true, screen ROIs
tplot.plot_combined_data = false; % true/false
tplot.plot_stim_shade = true; % true/false
tplot.y_range = [-20 30];
tplot.stimEffectType = 'rebound'; % options: 'excitation', 'inhibition', 'rebound'
tplot.section = []; % n/[]. specify the n-th repeat of stimWin. Set it to [] to plot all stimWin 
tplot.sponNorm = false; % true/false
tplot.save_fig = false; % true/false
tplot.save_dir = FolderPathVA.fig;

if filter_roi_tf
	alignedDataTrials_plot = alignedData_filtered;
else
	alignedDataTrials_plot = alignedData_allTrials;
end

fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedDataTrials_plot,...
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
% Fig 3. Compare off-stim(rebound) events and their following spon events
eventCat = 'rebound';
followEventCat = 'spon';
eventCatField = 'peak_category';
followEventDuration = 5; % unit: s. Following event(s) will be found in this time duration after the event with specified category
followEventNum = 1; % number of following event for each specified category event.
timeType = 'rise_time';
[alignedData_allTrials_followEvents] = filter_eventProp_followEvents_trials(alignedData_allTrials,...
	eventCat,followEventCat,'followEventDuration',followEventDuration);

eprop.entry = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
eprop.modify_stim_name = true; % true/false. Change the stimulation name, 
                            % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)
filter_roi_tf = false;
eventType = eprop.entry; % 'roi' or 'event'. The entry type in eventProp
mgSetting.sponOnly = false; % true/false. If eventType is 'roi', and mgSetting.sponOnly is true. Only keep spon entries
mgSetting.seperate_spon = true; % true/false. Whether to seperated spon according to stimualtion
mgSetting.dis_spon = false; % true/false. Discard spontaneous events
mgSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
mgSetting.groupField = {'stim_name','peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
mgSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
mgSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'
mgSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
mgSetting.sort_order_plus = {'ap', 'EXopto'};
debug_mode = false; % true/false

if filter_roi_tf
	alignedData = alignedData_filtered;
else
	alignedData = alignedData_allTrials;
end

[grouped_event] = getAndGroup_eventsProp(alignedData_allTrials_followEvents,...
	'entry',eprop.entry,'modify_stim_name',eprop.modify_stim_name,...
	'mgSetting',mgSetting,'adata',adata,'debug_mode',debug_mode);

tags_discard = {'og-5s ap-0.1s'};
tags_keep = {'og-5s'}; % Keep groups containing these words
clean_ap_entry = true; % true: discard delay and rebound categories from airpuff experiments
[grouped_event_info_filtered] = filter_entries_in_structure(grouped_event,'group',...
	'tags_discard',tags_discard,'tags_keep',tags_keep,'clean_ap_entry',clean_ap_entry); % 'tags_discard',tags_discard,

% PLot
close all
save_fig = false; % true/false
plot_combined_data = false;
parNames = {'rise_duration','FWHM','peak_mag_delta','sponNorm_peak_mag_delta'}; % entry: event
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
% Show the relationship between decayTau/caLevelDecrease and various rebound event properties

close all
save_fig = false; % true/false
filter_roi_tf = true;
fieldNames_rb_prop = {'rise_duration','FWHM','peak_mag_delta','sponNorm_peak_mag_delta',...
	'rise_delay','peak_delay'}; % properties of rebound events.
GroupedEventTags = {grouped_event_info_filtered.tag}; % Get the tags containing event catergory and stimulation
pos_OG5sRB = find(strcmpi('rebound [og-5s]', GroupedEventTags)); % Get the idx of rebound events in og-5s recordings
rbEventInfo = grouped_event_info_filtered(pos_OG5sRB).event_info;
[BarInfo_rbEvents,FolderPathVA.fig] = plot_reboundEvent_analysis(rbEventInfo,...
	'fieldNames_rb_prop',fieldNames_rb_prop,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','on');

% Filter the ROIs in all trials using stimulation effect
% the filtered alignedData will be used in the following plotting sections
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
[alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
	'stim_names',stim_names,'filters',filters);
if filter_roi_tf == true
	[alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
			'stim_names',stim_names,'filters',filters); % check section before 9.1.1
else 
	alignedData = alignedData_allTrials;
end

% alignedData = alignedData_allTrials;

[List_curveFitNum_eventNum_ogRB,~,FolderPathVA.fig] = plot_stimNum_fitNum_eventNum(alignedData,'rebound','og-5s',...
	'stimTimeCol',2,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save',true);
[List_curveFitNum_eventNum_ogTrig] = plot_stimNum_fitNum_eventNum(alignedData,'trig','og-5s',...
	'stimTimeCol',1,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save',false);
[List_curveFitNum_eventNum_apTrig] = plot_stimNum_fitNum_eventNum(alignedData,'trig','ap-0.1s',...
	'stimTimeCol',1,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save',false);

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
tplot.save_fig = false; % true/false
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
