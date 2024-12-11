% Workflow_for_genertating_figures for VIIO manuscript 
% nRIM, Da Guo

% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);

%% ==========
% 0.1 (optional): Update the 'alignedData_allTrials' using the 'recdata_organized'

% Settings
adata.event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
adata.eventTimeType = 'peak_time'; % rise_time/peak_time. Pick one for event time
adata.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
adata.event_data_group = 'peak_lowpass';
adata.event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
adata.event_align_point = 'rise'; % options: 'rise', 'peak'
adata.rebound_duration = 1; % time duration after stimulation to form a window for rebound spikes. Exclude these events from 'spon'
adata.cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
adata.pre_event_time = 10; % unit: s. duration before stimulation in the aligned traces
adata.post_event_time = 10; % unit: s. duration after stimulation in the aligned traces
adata.stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
adata.ss_range = 1; % range of stim_section (compare the cal-level in baseline and here to examine the effect of the stimulation). single number (last n second during stimulation) or a 2-element array (start and end. 0s is stimulation onset)
adata.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
adata.mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
adata.caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)
adata.disROI = true; % true/false. If true, Keep ROIs using the setting below, and delete the rest
adata.disROI_setting.stims = {'AP_GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s AP_GPIO-1-1s'};
adata.disROI_setting.eventCats = {{'spon'}, {'spon'}, {'spon'}}; % Discard ROIs without these events. Categories paired with stims above
adata.sponfreqFilter.status = true; % true/false. If true, use the following settings to filter ROIs
adata.sponfreqFilter.field = 'sponfq'; % 
adata.sponfreqFilter.thresh = 0.05; % Hz. default 0.05
adata.sponfreqFilter.direction = 'high';
debug_mode = true; % true/false

% Create structure data for further analysis (event traces are aligned to event rises)
[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', adata.event_type,...
	'traceData_type', adata.traceData_type, 'event_data_group', adata.event_data_group,'eventTimeType',adata.eventTimeType,...
	'event_filter', adata.event_filter, 'event_align_point', adata.event_align_point, 'cat_keywords', adata.cat_keywords,...
	'pre_event_time', adata.pre_event_time, 'post_event_time', adata.post_event_time,...
	'stim_section',adata.stim_section,'ss_range',adata.ss_range,...
	'stim_time_error',adata.stim_time_error,'rebound_duration',adata.rebound_duration,...
	'mod_pcn', adata.mod_pcn,'caDeclineOnly',adata.caDeclineOnly,...
	'disROI',adata.disROI,'disROI_setting',adata.disROI_setting,'sponfreqFilter',adata.sponfreqFilter,...
	'debug_mode',debug_mode);

% Replace rebound (AP) to spon
[alignedData_allTrials] = changeEventCatInAlignedData(alignedData_allTrials,'ap-0.1s','rebound','spon');

% Add sync info to the alignedData
[alignedData_allTrials(:).synchFoldValue] = deal([]);
synchWindow = 1;
minROIspikes = 2;
for n = 1:numel(alignedData_allTrials)
	fprintf('Recording %d/%d: %s\n', n, numel(alignedData_allTrials), alignedData_allTrials(n).trialName)
	alignedData_allTrials(n) = setSynchValuesTrialAllEvents(alignedData_allTrials(n),...
		'minROIspikes', minROIspikes, 'synchWindow', synchWindow);
end
% [alignedData_allTrials, cohensDPO, cohensDDAO] = clusterSpikeAmplitudeAnalysis(alignedData_allTrials,...
% 	'synchTimeWindow', synchTimeWindow, 'minROIsCluster', minROIsCluster);

% Show the subnuclei information of the recordings
dispRecSubnucleiLoc(alignedData_allTrials)


% Create structure data for further analysis (Peri-stim windows are aligned)
adata.event_type = 'stimWin'; % options: 'detected_events', 'stimWin'
[alignedData_stimWin] = get_event_trace_allTrials(recdata_organized,'event_type', adata.event_type,...
	'traceData_type', adata.traceData_type, 'event_data_group', adata.event_data_group,'eventTimeType',adata.eventTimeType,...
	'event_filter', adata.event_filter, 'event_align_point', adata.event_align_point, 'cat_keywords', adata.cat_keywords,...
	'pre_event_time', adata.pre_event_time, 'post_event_time', adata.post_event_time,...
	'stim_section',adata.stim_section,'ss_range',adata.ss_range,...
	'stim_time_error',adata.stim_time_error,'rebound_duration',adata.rebound_duration,...
	'mod_pcn', adata.mod_pcn,'caDeclineOnly',adata.caDeclineOnly,...
	'disROI',adata.disROI,'disROI_setting',adata.disROI_setting,'sponfreqFilter',adata.sponfreqFilter,...
	'debug_mode',debug_mode);

% Replace rebound (AP) to spon
[alignedData_stimWin] = changeEventCatInAlignedData(alignedData_stimWin,'ap-0.1s','rebound','spon');


%% ==========
% 0.2 (optional) Display the frequency of ROIs' spontaneous events in every recording using bar+scatter plot
close all
titleSubfix = 'ogInDataset'; 
[~, saveDir] = plotRecSponEventFreq(alignedData_allTrials,...
	'saveFig', true, 'saveDir', FolderPathVA.fig, 'guiSave', true, 'titleSubfix', titleSubfix); 

% Update the folder path 
if saveDir~=0
	FolderPathVA.fig = saveDir;
end

%% ==========
% Figure 1
% Plot the recording field and draw ROIs as overlay using the data processed with CNMFe
% Plot the raw traces of ROIs from CNMFe result. These traces are background subtracted (including neuropil)

saveFig = false; % true/false
showYtickRight = true;
% save_dir = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_Fig1_method_recExample';
save_dir = fullfile(FolderPathVA.ventralApproach,'VIIO_paper_figure\VIIO_Fig1_method_recExample');
% Load the example recording data
exampleRecFile = fullfile(FolderPathVA.ventralApproach,'VIIO_paper_figure\ProcessedData_VIIO_Fig1_example.mat');
load(exampleRecFile); % Load data
shortRecName = extractDateTimeFromFileName(alignedData_allTrials.trialName); % Get he yyyyddmm-hhmmss from recording file name
imageMatrix = alignedData_allTrials.roi_map; % Get the 2D matrix for plotting the FOV
roiBoundaries = {alignedData_allTrials.traces.roiEdge}; % Get the ROI edges
roiNames = {alignedData_allTrials.traces.roi}; % Get the ROI names
shortRoiNames = cellfun(@(x) x(7:end),roiNames,'UniformOutput',false); % Remove 'neuron' from the roi names

% Plot FOV and label ROIs
close all
nameExampleRecFOV = [shortRecName,' FOV'];
fExampleRecFOV = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameExampleRecFOV); % Create a figure for plots
plotCalciumImagingWithROIs(imageMatrix, roiBoundaries, shortRoiNames,...
	'Title',nameExampleRecFOV,'AxesHandle',gca);

% Get the raw data of CNMFe (BG and neuropil subtracted), and plot the traces
timeData = alignedData_allTrials.fullTime;
tracesData = [alignedData_allTrials.traces.fullTrace];
eventTime = get_TrialEvents_from_alignedData(alignedData_allTrials,'peak_time'); % Get the time of event peaks
nameCNMFeTrace = [shortRecName,' CNMFe result raw traces'];
fCNMFeTrace = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameCNMFeTrace); % Create a figure for plots
plot_TemporalData_Trace(gca,timeData,tracesData,'ylabels',shortRoiNames,'showYtickRight',showYtickRight,...
	'titleStr',nameCNMFeTrace,'plot_marker',true,'marker1_xData',eventTime);
set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
trace_xlim = xlim;


% Read the IDPS exported csv file and plot the trace using the data in it
nameIDPStrace = [shortRecName,' IDPS exported traces'];
fIDPStrace = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameIDPStrace); % Create a figure for plots
[csvTraceTitle,csvFolder] = plotCalciumTracesFromIDPScsv('AxesHandle',gca,'folderPath',save_dir,...
	'showYtickRight',showYtickRight,'Title',nameIDPStrace);
set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output


% Example traces and event scatters for figure 2. Use the loaded 'exampleRecFile' at the beginning
% of this section

% Example traces for Figure 2: Plot the calcium events as scatter and show the events number in a
% histogram (2 plots)
nameEventScatter = [shortRecName,' eventScatter colorful'];

% Get the amplitude of event peaks
colorData = get_TrialEvents_from_alignedData(alignedData_allTrials,'sponnorm_peak_mag_delta'); 

% Create a raster plot
fEventScatter = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'fig_name',nameEventScatter); % Create a figure for plots
plot_TemporalRaster(eventTime,'plotWhere',gca,'colorData',colorData,'norm2roi',true,...
	'rowNames',shortRoiNames,'x_window',trace_xlim,'xtickInt',25,...
	'yInterval',5,'sz',20); % Plot raster
set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
title(nameEventScatter)


% Save figures
if saveFig
	% Save the fNum
	savePlot(fExampleRecFOV,'guiSave', 'off', 'save_dir', save_dir,'fname', nameExampleRecFOV);
	savePlot(fCNMFeTrace,'guiSave', 'off', 'save_dir', save_dir,'fname', nameCNMFeTrace);
	savePlot(fIDPStrace,'guiSave', 'off', 'save_dir', save_dir,'fname', nameIDPStrace);
	savePlot(fEventScatter,'guiSave', 'off', 'save_dir', save_dir,'fname', nameEventScatter);
end


%% ==========
% Figure 2
% The properties of spontaneous events in IO subnuclei (DAO vs PO)
% Load the stimEffectFiltered 'recdata_organized' and 'alignedData_allTrials' variables



%% ==========
% 2.2 

%% ==========
% 2.3 Create the mean spontaneous traces in DAO and PO
% Note: 'event_type' for alignedData must be 'detected_events'
save_fig = false; % true/false
save_dir = FolderPathVA.fig;
at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
at.stimNames = ''; % If empty, do not screen recordings with stimulation, instead use all of them
at.eventCat = 'spon'; % options: 'trig','trig-ap','rebound','spon', 'rebound'
at.subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.
at.plot_combined_data = true; % mean value and std of all traces
at.showRawtraces = false; % true/false. true: plot every single trace
at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
at.medianProp = 'FWHM'; % 
at.shadeType = 'ste'; % plot the shade using std/ste
at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]
% at.sponNorm = true; % true/false
% at.normalized = false; % true/false. normalize the traces to their own peak amplitudes.

close all

% Create a cell to store the trace info
traceInfo = cell(1,numel(at.subNucleiTypes));

% Loop through the subNucleiTypes
for i = 1:numel(at.subNucleiTypes)
	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedData_allTrials,at.stimNames,at.eventCat,...
		'normMethod',at.normMethod,'subNucleiType',at.subNucleiTypes{i},...
		'showRawtraces',at.showRawtraces,'showMedian',at.showMedian,'medianProp',at.medianProp,...
		'plot_combined_data',at.plot_combined_data,'shadeType',at.shadeType,'y_range',at.y_range);
	% 'sponNorm',at.sponNorm,'normalized',at.normalized,

	if i == 1
		guiSave = 'on';
	else
		guiSave = 'off';
	end
	if save_fig
		save_dir = savePlot(gcf,'guiSave', guiSave, 'save_dir', save_dir, 'fname', traceInfo{i}.fname);
	end
end
traceInfo = [traceInfo{:}];

if save_fig
	save(fullfile(save_dir,'alignedCalTracesInfo'), 'traceInfo');
	FolderPathVA.fig = save_dir;
end



%% ==========
% 2.4 Extract properties of events and group them according to ROIs' subnuclous location

% Get and group (gg) Settings
ggSetting.modify_stim_name = false; % true/false. Change the stimulation name, 
ggSetting.sponOnly = false; % true/false. If eventType is 'roi', and ggSetting.sponOnly is true. Only keep spon entries
ggSetting.dis_spon = false; % true/false. Discard spontaneous events
ggSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'
ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
ggSetting.sort_order_plus = {'ap', 'EXopto'};
disOgEx = true; % true/false. If true, screen ROIs
ogStimTags = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
debug_mode = false; % true/false

% Discard those without sync tag in the eventProp (Due to single neuron)
mustHaveField = 'type';
[alignedData_withSynchInfo] = validateAlignedDataStructForEventAnalysis(alignedData_allTrials, mustHaveField);


% a. Create grouped_event struct for plotting event properties
ggSetting.entry = 'event';  % 'event': events are seperated (struct length = events_num). mean values were not calculated
ggSetting.separateSpon = false; % true/false. Whether to seperated spon according to stimualtion

% Grouped using peak_category and subN
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.noSyncTag] = getAndGroup_eventsProp(alignedData_allTrials,'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Grouped using peak_category. Merge events from subN
ggSetting.groupField = {'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.noSyncTagMergeSubN] = getAndGroup_eventsProp(alignedData_allTrials,'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Grouped using peak_category, subN, and type (synch/asynch = cluster/single)
ggSetting.groupField = {'peak_category','subNuclei','type'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.SyncTag] = getAndGroup_eventsProp(alignedData_withSynchInfo,'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Grouped using peak_category and type (synch/asynch = cluster/single). Merge events from subN
ggSetting.groupField = {'peak_category','type'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.SyncTagMergeSubN] = getAndGroup_eventsProp(alignedData_withSynchInfo,'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);



ggSetting.separateSpon = true; % true/false. Separated spon using stimualtion
% Grouped using peak_category and subN
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.noSyncTagSponSep] = getAndGroup_eventsProp(alignedData_allTrials,'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Grouped using peak_category. Merge events from subN
ggSetting.groupField = {'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.noSyncTagMergeSubNSponSep] = getAndGroup_eventsProp(alignedData_allTrials,'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Grouped using peak_category, subN, and type (synch/asynch = cluster/single)
ggSetting.groupField = {'peak_category','subNuclei','type'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.SyncTagSponSep] = getAndGroup_eventsProp(alignedData_withSynchInfo,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Create grouped_event (Separate the spon using stimulation) for plotting OG-SPONT and OGOFF-TRIG from both PO and DAO
ggSetting.groupField = {'peak_category','type'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[eventStruct.SyncTagMergeSubNSponSep] = getAndGroup_eventsProp(alignedData_withSynchInfo,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);


% b. Create grouped_event for plotting ROI properties
ggSetting.entry = 'roi'; % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated.
ggSetting.separateSpon = false; % true/false. Separated spon using stimualtion
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
[roiStructForPlot] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Group using stim_name: This will be used to calculate the event probability
ggSetting.groupField = {'stim_name'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
ggSetting.dis_spon = true; % true/false. Discard spontaneous events
[roiStructForEventProb] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);


%% ==========
% 2.5 Plot event properties
close all
% General Settings
saveFig = true; % true/false
props = {'FWHM','peak_delta_norm_hpstd','rise_duration', 'peak_delay'}; 
    % 'rise_duration','FWHM','sponNorm_peak_mag_delta','peak_mag_delta'
separateSpon = false; % true/false. Whether to seperated spon according to stimualtion
dataDist = 'posSkewed';
newHeaderOrder = {'Group', 'animalNum', 'recNum', 'roiNum', 'eventNum', 'Mean', 'Median', 'STD', 'SEM'};
debugMode = false;

% Use 'separateSpon' to decide which fields in eventStruct will be used to plot and analyze
if ~separateSpon
	structFieldSubN = 'noSyncTag';
	structFieldALLsubN = 'noSyncTagMergeSubN';
else
	structFieldSubN = 'noSyncTagSponSep';
	structFieldALLsubN = 'noSyncTagMergeSubNSponSep';
end

groupSettingsType = 'subN';
[mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType,...
	'dataDist', dataDist, 'separateSPONT', separateSpon);
[saveDir, eventPropDataStat] = plotEventPropMultiGroups(eventStruct.(structFieldSubN),props,organizeStruct,...
	'mmModel', mmModel, 'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'saveFig', saveFig, 'saveDir', FolderPathVA.fig, 'debugMode', debugMode);

% Update the folder path 
if saveDir~=0
	FolderPathVA.fig = saveDir;
end

groupSettingsType = 'ALLsubN for OG';
[mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType,...
	'dataDist', dataDist, 'separateSPONT', separateSpon);
[~, ~] = plotEventPropMultiGroups(eventStruct.(structFieldALLsubN),props,organizeStruct,...
	'mmModel', mmModel, 'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'saveFig', saveFig, 'saveDir', FolderPathVA.fig, 'debugMode', debugMode);

% Choose a folder and combine the meanSemTab and nNumInfo Latex tables
if saveFig
	tab1Key = 'meanSemTab';
	tab2Key = 'nNumInfo';
	filePairs = findAllTexFilePairs(FolderPathVA.fig, tab1Key, tab2Key);
	for n = 1:numel(filePairs)
		if ~isempty(filePairs(n).outputFile)
			combineLatexTables(filePairs(n).inputFile, filePairs(n).outputFile, 'saveToFile', true,...
				'combinedFileName', filePairs(n).combinedFilename, 'deleteOriginalFiles', false);
			reorderLatexTable(filePairs(n).combinedFilename, filePairs(n).combinedFilename, newHeaderOrder)
		end
	end
end

%% ==========
% 2.7 Plot event properties with 'type' tags (synch/asynch = cluster/single)
close all
% General Settings
saveFig = true; % true/false
props = {'FWHM','peak_delta_norm_hpstd', 'rise_duration'}; 
    % 'rise_duration','FWHM','sponNorm_peak_mag_delta','peak_mag_delta','sponNorm_peak_mag_delta','peak_delay'
separateSpon = false; % true/false. Whether to seperated spon according to stimualtion
newHeaderOrder = {'Group', 'animalNum', 'recNum', 'roiNum', 'eventNum', 'Mean', 'Median', 'STD', 'SEM'};
dataDist = 'posSkewed';

% Use 'separateSpon' to decide which fields in eventStruct will be used to plot and analyze
if ~separateSpon
	structFieldSubN = 'SyncTag';
	structFieldALLsubN = 'SyncTagMergeSubN';
else
	structFieldSubN = 'SyncTagSponSep';
	structFieldALLsubN = 'SyncTagMergeSubNSponSep';
end

groupSettingsType = 'syncTag subN';
[mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType,...
	'dataDist', dataDist, 'separateSPONT', separateSpon);
[saveDir, eventPropDataStat] = plotEventPropMultiGroups(eventStruct.(structFieldSubN),props,organizeStruct,...
	'mmModel', mmModel, 'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'saveFig', saveFig, 'saveDir', FolderPathVA.fig, 'debugMode', debugMode);

% Update the folder path 
if saveDir~=0
	FolderPathVA.fig = saveDir;
end

groupSettingsType = 'syncTag ALLsubN for OG';
[mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType,...
	'dataDist', dataDist, 'separateSPONT', separateSpon);
[~, ~] = plotEventPropMultiGroups(eventStruct.(structFieldALLsubN),props,organizeStruct,...
	'mmModel', mmModel, 'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'saveFig', saveFig, 'saveDir', FolderPathVA.fig, 'debugMode', debugMode);

% Choose a folder and combine the meanSemTab and nNumInfo Latex tables
if saveFig
	tab1Key = 'meanSemTab';
	tab2Key = 'nNumInfo';
	filePairs = findAllTexFilePairs(FolderPathVA.fig, tab1Key, tab2Key);
	for n = 1:numel(filePairs)
		if ~isempty(filePairs(n).outputFile)
			combineLatexTables(filePairs(n).inputFile, filePairs(n).outputFile, 'saveToFile', true,...
				'combinedFileName', filePairs(n).combinedFilename, 'deleteOriginalFiles', false);
			reorderLatexTable(filePairs(n).combinedFilename, filePairs(n).combinedFilename, newHeaderOrder)
		end
	end
end

%% ==========
% 2.7 Plot ROI properties. 
% Use data organized in section 2.3
% close all
% plot_combined_data = false;
% stat = true; % Set it to true to run anova when plotting bars
saveFig = true; % true/false
parNamesROI = {'sponfq','sponInterval','cv2'}; % 'sponfq', 'sponInterval'
mmHierarchicalVarsROI = {'trialName'};
mmModel = 'GLMM';
mmDistribution = 'gamma'; % For continuous, positively skewed data
mmLink = 'log'; % For continuous, positively skewed data

if saveFig
	close all
end

% Keep spontaneous events and discard all others
tags_keep = {'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[roiStructForPlotFiltered] = filter_entries_in_structure(roiStructForPlot,'group',...
	'tags_keep',tags_keep);

% Plot and calculate the spont event frequencies and intervals 
[saveDir, plot_info] = plot_event_info(roiStructForPlotFiltered,'entryType','roi',...
	'plot_combined_data', false, 'parNames', parNamesROI,...
	'mmModel', mmModel, 'mmGroup', 'subNuclei', 'mmHierarchicalVars', mmHierarchicalVarsROI,...
	'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'fname_preffix','ROI','save_fig', saveFig, 'save_dir', FolderPathVA.fig);

% Plot and calculate the event probability: eventNum/stimNum
% All recordings are used. Subnuclei are not separated
fieldnameGroup = 'peak_category';
fieldnameVal = 'stimEvent_possi';
eventPb_box = fig_canvas(1,'fig_name','event probability','unit_width',0.6,'unit_height',0.3);
eventPb_plot_info = empty_content_struct({'group','plotInfo'},numel(roiStructForEventProb));
[eventPb_plot_info.group] = roiStructForEventProb.group;
tlo_eventPb_box = tiledlayout(eventPb_box,ceil(numel(roiStructForEventProb)/4),4);
for gn = 1:numel(roiStructForEventProb)
	ax_eventPb_box = nexttile(tlo_eventPb_box);
	[eventPb_plot_info(gn).plotInfo] = boxPlotOfStructData(roiStructForEventProb(gn).event_info,...
	 fieldnameVal, fieldnameGroup,'plotWhere', gca, 'titleStr', fieldnameVal, 'TickAngle', 45, 'FaceColor', '#FF5733');
end
savePlot(eventPb_box,'guiSave', 'off', 'save_dir', saveDir,'fname', 'stimEventProb');


% Save the statistics info
if saveFig
	% Create a n number tab
	[~, tabNum] = nNumberTab(roiStructForPlotFiltered, 'roi');
	tabNumName = 'ROI nNumInfo.tex';
	tableToLatex(tabNum, 'saveToFile',true,'filename',...
	    fullfile(saveDir,tabNumName), 'caption', tabNumName,...
	    'columnAdjust', 'XXXX');

	% Combine the meanSemTab and nNumInfo Latex tables
	tab1Key = 'meanSemTab';
	tab2Key = 'nNumInfo';
	newHeaderOrder = {'Group', 'animalNum', 'recNum', 'roiNum', 'Mean', 'Median', 'STD', 'SEM'};
	filePairs = findAllTexFilePairs(saveDir, tab1Key, tab2Key);
	for n = 1:numel(filePairs)
		if ~isempty(filePairs(n).outputFile)
			combineLatexTables(filePairs(n).inputFile, filePairs(n).outputFile, 'saveToFile', true,...
				'combinedFileName', filePairs(n).combinedFilename, 'deleteOriginalFiles', false);
			reorderLatexTable(filePairs(n).combinedFilename, filePairs(n).combinedFilename, newHeaderOrder)
		end
	end

	% Save data in a mat file
	roiPropStatInfo.roiStructForPlotFiltered = roiStructForPlotFiltered;
	roiPropStatInfo.plot_info = plot_info;
	% dt = datestr(now, 'yyyymmdd');
	save(fullfile(saveDir, 'ROI propDataAndStat'), 'roiPropStatInfo');
	save(fullfile(saveDir, 'stimEventProb'), 'eventPb_plot_info');
end


%% ==========
% 2.8 (Temp) Compare EventProp using different settings
figFolder = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure';
saveFolder = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure';
label1 = "Combine SPONT From Same SubN"; % String array
label2 = "Separate SPONT using stimulation";    % String array
figExt = 'jpg';
textExt = 'tex';
keywordFig = '';
ignoreKeywordFig = 'bar stat';
keywordText = '';
ignoreKeywordText = '';

compareAnalysisUsingdiffSetting(figFolder, saveFolder,...
	'label1', label1, 'label2', label2, 'figExt', figExt, 'textExt', textExt,...
	'keywordFig', keywordFig, 'ignoreKeywordFig', ignoreKeywordFig,...
	'keywordText', keywordText, 'ignoreKeywordText', ignoreKeywordText);


%% ==========
% 3.1 Peri-stimulus event frequency analysis
close all
save_fig = false; % true/false
gui_save = true;
groupLevel = 'roi'; % Collect event freq on 'roi'/'stimTrial' level
customizeEdges = true; % true/false. customize the bins using function 'setPeriStimSectionForEventFreqCalc'
						% If true: Set the 'disZeroBase' to true, 'normToBase' to true
						% If false: Set the 'normToBase' to false
if customizeEdges
	disZeroBase = true; % true/false. Discard the roi/stimTrial if the baseline value is zero
	normToBase = false; % true/false. normalize the data to baseline (data before baseBinEdge). Set the disZeroBase to true if this is tru
else	
	disZeroBase = false; % true/false. Discard the roi/stimTrial if the baseline value is zero
	normToBase = false; % true/false. normalize the data to baseline (data before baseBinEdge). Set the disZeroBase to true if this is tru
end
plotDiff = false; % true/false. plot the difference of comparable bins from various stimulation recording groups

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
subNucleiFilter = 'PO';
diffPair = {[1 3], [2 3], [1 2]}; % {[1 3], [2 3]}. binned freq will be compared between stimualtion groups. cell number = stimulation pairs. [1 3] mean stimulation 1 vs stimulation 2

propName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
binWidth = 1; % the width of histogram bin. the default value is 1 s.
stimIDX = []; % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
preStim_duration = 6; % unit: second. include events happened before the onset of stimulations
postStim_duration = 7; % unit: second. include events happened after the end of stimulations
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

baseBinEdgestart = -preStim_duration; % preStim_duration. Where to start to use the bin for calculating the baseline.
baseBinEdgeEnd = 0; % 0
apCorrection = false; % true/false. If true, correct baseline bin used for normalization. 


debug_mode = false; % true/false

% plot periStim event freq, and diff among them
[barStat,diffStat,FolderPathVA.fig] = periStimEventFreqAnalysisSubnucleiVIIO(alignedData_allTrials,'propName',propName,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'plotDiff',plotDiff,'diffPair',diffPair,'binWidth',binWidth,'stimIDX',stimIDX,...
	'normToBase',normToBase,'groupLevel',groupLevel,...
	'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,'disZeroBase',disZeroBase,...
	'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim,...
	'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
	'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,...
	'save_fig',save_fig,'saveDir',FolderPathVA.fig,'gui_save',gui_save,'debug_mode',debug_mode);


%% ====================
% 3.2 Plot traces and stim-aligned traces
% Note: set adata.event_type to 'stimWin' when creating alignedData_allTrials
close all
save_fig = false; % true/false
pause_after_trial = false;

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

trial_num = numel(alignedData_stimWin);
for tn = 1:trial_num
    close all
	alignedData = alignedData_stimWin(tn);
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
% 3.3 Violin plot showing the difference of
% stim-related-event_to_following_event_time and the spontaneous_event_interval
close all
save_fig = false; % true/false
stimNameAll = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % 'og-5s' 'ap-0.1s'
stimEventCatAll = {'rebound','trig','trig-ap','rebound'}; % 'rebound', 'trig'
releventEventLoc = 'post'; % 'pre'/'post'. The location of relevent event. Pre or post to the ref event
defReleventEventCat = false; % true/false. Use spon for the relevent event cat. If false, use the closest following/preceeding event
maxDiff = 10; % the max difference between the stim-related and the following events
% subNucleiTypes = {'DAO', 'PO'};
ogStimTags = {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
[alignedDataStimEffectFiltered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
	'stim_names',ogStimTags,'filters',ogStimEffects);

for n = 1:numel(stimNameAll) 
	stimName = stimNameAll{n};
	stimEventCat = stimEventCatAll{n};
	% [intData,eventIntMean,eventInt,f,fname] = stimEventSponEventIntAnalysis(alignedData_allTrials,stimName,stimEventCat,...
	% 'maxDiff',maxDiff);

	[intData,f,fname,statsAndNnumTab,KStestTab] = stimEventSponEventIntAnalysis(alignedDataStimEffectFiltered,stimName,stimEventCat,...
	    'releventEventLoc',releventEventLoc,'defReleventEventCat',defReleventEventCat,'maxDiff',maxDiff); % ,'titlePrefix',subNucleiTypes{sn}

	if save_fig
		if n == 1 
			guiSave = 'on';
		else
			guiSave = 'off';
		end
		FolderPathVA.fig = savePlot(f,'save_dir',FolderPathVA.fig,'guiSave',guiSave,'fname',fname);
		save(fullfile(FolderPathVA.fig, [fname,' data']),'intData');

		% Save nNum table in latex format
		statsAndNnumTabName = sprintf('%s summaryStats and nNumInfo.tex', fname);
		tableToLatex(statsAndNnumTab, 'saveToFile',true,'filename', fullfile(FolderPathVA.fig,statsAndNnumTabName),...
		    'caption', statsAndNnumTabName, 'columnAdjust', 'XXXXX');

		% Save GLMM Model comparison in latex format
		MMtabName = sprintf('%s modelComp.tex', fname);
		tableToLatex(intData.GlmmReport.chiLRT, 'saveToFile',true,'filename', fullfile(FolderPathVA.fig, MMtabName),...
		    'caption', [intData.GlmmReport.modelInfoStr, ' ', fname], 'columnAdjust', 'cXccccccc');

		% Save K-S tab in latex format
		KStabName = sprintf('%s KStestTab.tex', fname);
		tableToLatex(KStestTab, 'saveToFile',true,'filename', fullfile(FolderPathVA.fig, KStabName),...
		    'caption', [KStabName,' ', fname], 'columnAdjust', 'ccc');
	end
end

% % loop through different stim-event pairs
% for sn = 1:numel(subNucleiTypes)
% 	alignedDataSubN = screenSubNucleiROIs(alignedDataStimEffectFiltered,subNucleiTypes{sn});


% end

%% ==================== 
% 3.4 Plot event properties and percentages for OG-ex neurons
% Compare DAO and PO
close all
save_fig = false; % true/false
ggSetting.entry = 'event'; % options: 'roi' or 'event'. The entry type in eventProp
ggSetting.modify_stim_name = true; % true/false. Change the stimulation name, 
ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
ggSetting.dis_spon = false; % true/false. Discard spontaneous events
ggSetting.groupField = {'peak_category','subNuclei'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 
summarizeExOgEffect(alignedData_allTrials, 'save_fig', save_fig, 'save_dir', FolderPathVA.fig);
	% 'adata', adata, 'ggSetting', ggSetting


%% ==================== 
% % 3.4 Compare the delay of OGOFF-TRIG events to spon interval
% close all
% save_fig = false; % true/false
% ogStimTags = {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
% ogStimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
% [alignedDataStimEffectFiltered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_allTrials,...
% 	'stim_names',ogStimTags,'filters',ogStimEffects);
% [stimEventJitter, f, fname] = stimEventJitterAnalysis(alignedDataStimEffectFiltered,{'ap-0.1s'},'trig');
% % 'titlePrefix', subNucleiTypes{sn}

% FolderPathVA.fig = savePlot(f,'save_dir',FolderPathVA.fig,'guiSave',true,'fname',fname);
% save(fullfile(FolderPathVA.fig, [fname,' data']),'stimEventJitter');

% % Save nNum table in latex format
% tabNumName = sprintf('%s nNumInfo.tex', fname);
% tableToLatex(stimEventJitter.numTab, 'saveToFile',true,'filename', fullfile(FolderPathVA.fig,tabNumName),...
%     'caption', tabNumName, 'columnAdjust', 'XXXXX');

% % Save GLMM Model comparison in latex format
% MMtabName = sprintf('%s modelComp.tex', fname);
% tableToLatex(stimEventJitter.GlmmReport.chiLRT, 'saveToFile',true,'filename', fullfile(FolderPathVA.fig, MMtabName),...
%     'caption', [stimEventJitter.GlmmReport.modelInfoStr, ' ', fname], 'columnAdjust', 'cXccccccc');

% % Save K-S tab in latex format
% KStabName = sprintf('%s KStestTab.tex', fname);
% tableToLatex(stimEventJitter.KStest.tab, 'saveToFile',true,'filename', fullfile(FolderPathVA.fig, KStabName),...
%     'caption', [KStabName,' ', fname], 'columnAdjust', 'ccc');



%% ==================== 
% 3.5 Compare the calcium level during OG
close all

SaveFig = false; % true/false
binWidth = 1;
shadeType = 'ste';
tickInt_time = 1;
norm2hpStd = true; % Normalize the traces with the STD of highpass filtered data from the same ROI

pairStruct(1).stimNameA = 'og-5s';
pairStruct(1).subNucleiTypeA = 'DAO';
pairStruct(1).stimEventCatA = '';
pairStruct(1).stimEventKeepOrDisA = '';
pairStruct(1).stimNameB = 'og-5s';
pairStruct(1).subNucleiTypeB = 'PO';
pairStruct(1).stimEventCatB = '';
pairStruct(1).stimEventKeepOrDisB = '';
pairStruct(1).mmGroupVar = 'subN'; % Options: stimName, subN, eventFilter

pairStruct(2).stimNameA = 'og-5s';
pairStruct(2).subNucleiTypeA = 'DAO';
pairStruct(2).stimEventCatA = 'rebound';
pairStruct(2).stimEventKeepOrDisA = 'keep';
pairStruct(2).stimNameB = 'og-5s';
pairStruct(2).subNucleiTypeB = 'DAO';
pairStruct(2).stimEventCatB = 'rebound';
pairStruct(2).stimEventKeepOrDisB = 'discard';
pairStruct(2).mmGroupVar = 'eventFilter';

pairStruct(3).stimNameA = 'og-5s';
pairStruct(3).subNucleiTypeA = 'PO';
pairStruct(3).stimEventCatA = 'rebound';
pairStruct(3).stimEventKeepOrDisA = 'keep';
pairStruct(3).stimNameB = 'og-5s';
pairStruct(3).subNucleiTypeB = 'PO';
pairStruct(3).stimEventCatB = 'rebound';
pairStruct(3).stimEventKeepOrDisB = 'discard';
pairStruct(3).mmGroupVar = 'eventFilter';

disOgEx = true; % true/false. If true, screen ROIs
ogStimTags = {'og-5s', 'og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[0 nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
if disOgEx
	titleSubfix = '[exclude OgEx]';
end

for pn = 1:numel(pairStruct)
	titlePrefix = sprintf('[%s %s %s-%s] [%s %s %s-%s]',...
		pairStruct(pn).stimNameA,pairStruct(pn).subNucleiTypeA,pairStruct(pn).stimEventCatA,pairStruct(pn).stimEventKeepOrDisA,...
		pairStruct(pn).stimNameB,pairStruct(pn).subNucleiTypeA,pairStruct(pn).stimEventCatB,pairStruct(pn).stimEventKeepOrDisB);
	[saveDir, meStatReport, caLevelData] = compareAveragedCaLevel(alignedData_allTrials,pairStruct(pn),binWidth,...
		'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
		'shadeType',shadeType,'tickInt_time',tickInt_time,'titlePrefix',titlePrefix,'titleSubfix',titleSubfix,...
		'norm2hpStd',norm2hpStd,'SaveFig',SaveFig,'saveDir',FolderPathVA.fig);

	% Update the folder path 
	if saveDir~=0
		FolderPathVA.fig = saveDir;
	end
end

%% ==================== 
% Check the correlation between caLevelDelta and peak amplitude
% close all
% figure
% caMinDeltaReboundDAO = [eventStruct(7).event_info.caLevelDeltaNorm]; 
% peakHpstdReboundDAO = [eventStruct(7).event_info.peak_delta_norm_hpstd]; 

% stylishScatter(caMinDeltaReboundDAO,peakHpstdReboundDAO, 'plotWhere', gca, 'MarkerEdgeColor', 'k');

% hold on

% caMinDeltaReboundPO = [eventStruct(8).event_info.caLevelDeltaNorm]; 
% peakHpstdReboundPO = [eventStruct(8).event_info.peak_delta_norm_hpstd]; 

% stylishScatter(caMinDeltaReboundPO,peakHpstdReboundPO, 'plotWhere', gca);

% xlabel('caLevelDelta hpStdNorm')
% ylabel('peakAmp hpStdNorm')
% legend('rebound DAO', 'rebound PO', 'FontSize', 10)


%% ==========
% 3.6 Show the distribution of various categories of events in the FOVs
close all
save_fig = false; % true/false
% Get and group (gg) Settings
ggSetting.entry = 'roi'; % options: 'roi' or 'event'. The entry type in eventProp
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
ggSetting.modify_stim_name = true; % true/false. Change the stimulation name, 
ggSetting.sponOnly = false; % true/false. If eventType is 'roi', and ggSetting.sponOnly is true. Only keep spon entries
ggSetting.seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
ggSetting.dis_spon = false; % true/false. Discard spontaneous events
ggSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
ggSetting.groupField = {'peak_category', 'stim_name'}; % options: 'fovID', 'stim_name', 'peak_category','subNuclei'; Field of eventProp_all used to group events 
ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'
ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
ggSetting.sort_order_plus = {'ap', 'EXopto'};
disOgEx = false; % true/false. If true, screen ROIs
ogStimTags = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
debug_mode = false; % true/false

% b. Create grouped_event for plotting ROI properties
[roiStructForFOV] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% temproal solution: plot fov percentage and save
% fov_bar = figure('Name','FOV percentage');
fov_bar = fig_canvas(1,'fig_name','FOV percentage','unit_width',0.6,'unit_height',0.3);
% eventPb_bar = figure('Name','event probability','Position',[0.1 0.1 0.4 0.2],'Units','Normalized');

fovID_plot_info = empty_content_struct({'group','fovCount'},numel(roiStructForFOV));
[fovID_plot_info.group] = roiStructForFOV.group;
[fovID_plot_info.fovCount] = roiStructForFOV.fovCount;
tlo_fov_bar = tiledlayout(fov_bar,ceil(numel(roiStructForFOV)/4),4);
for gn = 1:numel(roiStructForFOV)
	group_name = roiStructForFOV(gn).group;
	fovInfo = roiStructForFOV(gn).fovCount;
	fovIDs = {fovInfo.fovID};
	fovPerc = [fovInfo.perc];
	ax_fov_bar = nexttile(tlo_fov_bar);
	bar(categorical(fovIDs),fovPerc);
	set(gca, 'box', 'off')
	title(group_name);
	% if save_fig
	% end
	% [eventPb_plot_info(gn).plotinfo] = barplot_with_stat(fovPerc,'group_names',fovIDs,...
	% 	'plotWhere',ax_fov_bar,'title_str',group_name,'save_fig',save_fig,'save_dir',save_dir);
end

if save_fig
	save_dir = savePlot(fov_bar,'save_dir',FolderPathVA.fig,'fname','fovID_perc','guiSave',true);

	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info.roiStructForFOV = roiStructForFOV;
	plot_stat_info.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info','fovID_plot_info');
end


%% ==========
% 3.7 Create the mean traces of OGOFF-TRIG events after the end of OG activation of NO
% Note: 'event_type' for alignedData must be 'detected_events'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
at.stimNames = {'og-5s'}; % If empty, do not screen recordings with stimulation, instead use all of them
at.eventCat = {'rebound'}; % options: 'trig','trig-ap','rebound','spon', 'rebound', 'opto-delay'
at.subNucleiTypes = 'PO'; % Separate ROIs using the subnuclei tag.
at.plot_combined_data = true; % mean value and std of all traces
at.showRawtraces = false; % true/false. true: plot every single trace
at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
at.medianProp = 'FWHM'; % 
at.shadeType = 'ste'; % plot the shade using std/ste
at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]
disOgEx = true; % true/false. If true, screen ROIs
ogStimTags = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
screenWithPreOrPost = false; % Further screen event traces by checking if they have a specific pre/post event
preOrPost = '';
preOrPostEventCat = '';


% at.sponNorm = true; % true/false
% at.normalized = false; % true/false. normalize the traces to their own peak amplitudes.

close all

% Create a cell to store the trace info
traceInfo = cell(1,numel(at.eventCat));

% Loop through the stimNames/eventCat
for i = 1:numel(at.eventCat)

	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedData_allTrials,at.stimNames{i},at.eventCat{i},...
		'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
		'screenWithPreOrPost',screenWithPreOrPost,'preOrPost',preOrPost,'preOrPostEventCat',preOrPostEventCat,...
		'normMethod',at.normMethod,'subNucleiType',at.subNucleiTypes,...
		'showRawtraces',at.showRawtraces,'showMedian',at.showMedian,'medianProp',at.medianProp,...
		'plot_combined_data',at.plot_combined_data,'shadeType',at.shadeType,'y_range',at.y_range);
	% 'sponNorm',at.sponNorm,'normalized',at.normalized,

	if i == 1
		guiSave = 'on';
	else
		guiSave = 'off';
	end
	if save_fig
		save_dir = savePlot(gcf,'guiSave', guiSave, 'save_dir', save_dir, 'fname', traceInfo{i}.fname);
	end
end
traceInfo = [traceInfo{:}];

if save_fig
	save(fullfile(save_dir,'alignedCalTracesInfo'), 'traceInfo');
	FolderPathVA.fig = save_dir;
end


%% ==========
% 4.1 Create the mean traces of AP events caused by AP and OG-AP in PO
% Note: 'event_type' for alignedData must be 'detected_events'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
at.stimNames = {'ap-0.1s','ap-0.1s','og-5s ap-0.1s', 'og-5s ap-0.1s'}; % If empty, do not screen recordings with stimulation, instead use all of them
at.eventCat = {'trig', 'spon', 'trig-ap', 'spon'}; % options: 'trig','trig-ap','rebound','spon', 'rebound'
at.subNucleiTypes = 'PO'; % Separate ROIs using the subnuclei tag.
at.plot_combined_data = true; % mean value and std of all traces
at.showRawtraces = false; % true/false. true: plot every single trace
at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
at.medianProp = 'FWHM'; % 
at.shadeType = 'ste'; % plot the shade using std/ste
at.y_range = [-10 20]; % [-10 5],[-3 5],[-2 1]
disOgEx = true; % true/false. If true, screen ROIs
ogStimTags = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
ogStimEffects = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
% screenWithPreOrPost = true; % Further screen event traces by checking if they have a specific pre/post event

% at.sponNorm = true; % true/false
% at.normalized = false; % true/false. normalize the traces to their own peak amplitudes.

close all

% Create a cell to store the trace info
traceInfo = cell(1,numel(at.subNucleiTypes));

% Loop through the stimNames/eventCat
for i = 1:numel(at.eventCat)
	if strcmp(at.stimNames{i}, 'og-5s ap-0.1s') && strcmp(at.eventCat{i}, 'trig-ap')
		screenWithPreOrPost = false;
		preOrPost = 'pre';
		preOrPostEventCat = 'trig';
	else
		screenWithPreOrPost = false;
		preOrPost = '';
		preOrPostEventCat = '';
	end

	[~,traceInfo{i}] = AlignedCatTracesSinglePlot(alignedData_allTrials,at.stimNames{i},at.eventCat{i},...
		'filterROIs',disOgEx,'filterROIsStimTags',ogStimTags,'filterROIsStimEffects',ogStimEffects,...
		'screenWithPreOrPost',screenWithPreOrPost,'preOrPost',preOrPost,'preOrPostEventCat',preOrPostEventCat,...
		'normMethod',at.normMethod,'subNucleiType',at.subNucleiTypes,...
		'showRawtraces',at.showRawtraces,'showMedian',at.showMedian,'medianProp',at.medianProp,...
		'plot_combined_data',at.plot_combined_data,'shadeType',at.shadeType,'y_range',at.y_range);
	% 'sponNorm',at.sponNorm,'normalized',at.normalized,

	if i == 1
		guiSave = 'on';
	else
		guiSave = 'off';
	end
	if save_fig
		save_dir = savePlot(gcf,'guiSave', guiSave, 'save_dir', save_dir, 'fname', traceInfo{i}.fname);
	end
end
traceInfo = [traceInfo{:}];

if save_fig
	save(fullfile(save_dir,'alignedCalTracesInfo'), 'traceInfo');
	FolderPathVA.fig = save_dir;
end


