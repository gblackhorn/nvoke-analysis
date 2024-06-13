% Workflow_for_genertating_figures for VIIO manuscript 
% nRIM, Da Guo

% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);


%% ==========
% Figure 1
% Plot the recording field and draw ROIs as overlay using the data processed with CNMFe
% Plot the raw traces of ROIs from CNMFe result. These traces are background subtracted (including neuropil)

saveFig = false; % true/false
showYtickRight = true;
save_dir = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\figures\VIIO_paper_figure\VIIO_Fig1_method_recExample';
save_dir = fullfile(FolderPathVA.ventralApproach,'figures\VIIO_paper_figure\VIIO_Fig1_method_recExample');
% Load the example recording data
exampleRecFile = fullfile(FolderPathVA.ventralApproach,'figures\VIIO_paper_figure\ProcessedData_VIIO_Fig1_example.mat');
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

% Figure 2: Plot the calcium events as scatter and show the events number in a histogram (2 plots)
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
% 2.2 

%% ==========
% 2.3 Create the mean spontaneous traces in DAO and PO
% Note: 'event_type' for alignedData must be 'detected_events'
save_fig = true; % true/false
save_dir = FolderPathVA.fig;
at.normMethod = 'highpassStd'; % 'none', 'spon', 'highpassStd'. Indicate what value should be used to normalize the traces
at.stimNames = ''; % If empty, do not screen recordings with stimulation, instead use all of them
at.eventCat = 'spon'; % options: 'trig','trig-ap','rebound','spon', 'rebound'
at.subNucleiTypes = {'DAO','PO'}; % Separate ROIs using the subnuclei tag.
at.plot_combined_data = true; % mean value and std of all traces
at.showRawtraces = false; % true/false. true: plot every single trace
at.showMedian = false; % true/false. plot raw traces having a median value of the properties specified by 'at.medianProp'
at.medianProp = 'FWHM'; % 
at.shadeType = 'std'; % plot the shade using std/ste
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
% 2.4 Extract properties of spontaneous events and group them according to ROIs' subnuclous location

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


% Create grouped_event for plotting ROI properties
ggSetting.entry = 'roi'; % options: 'roi' or 'event'. The entry type in eventProp
[roiStructForPlot] = getAndGroup_eventsProp(alignedData_allTrials,...
	'entry',ggSetting.entry,'modify_stim_name',ggSetting.modify_stim_name,...
	'ggSetting',ggSetting,'adata',adata,'debug_mode',debug_mode);

% Keep spontaneous events and discard all others
% tags_keep = {'spon'}; % Keep groups containing these words. {'trig','trig-ap','rebound [og-5s]','spon'}
[roiStructForPlotFiltered] = filter_entries_in_structure(roiStructForPlot,'group',...
	'tags_keep',tags_keep);

%% ==========
% 2.5 Plot event properties

% Settings
save_fig = false; % true/false
plot_combined_data = false;
parNames = {'FWHM','sponNorm_peak_mag_delta','peak_delta_norm_hpstd','peak_mag_delta'}; 
    % 'rise_duration','FWHM','sponNorm_peak_mag_delta','peak_mag_delta'
stat = true; % Set it to true to run anova when plotting bars

close all

% Setup parameters for linear-mixed-model (LMM) or generalized-mixed-model (GLMM) analysis
mmModel = 'GLMM'; % LMM/GLMM
mmGroup = 'subNuclei'; % LMM/GLMM
mmHierarchicalVars = {'trialName', 'roiName'};
mmDistribution = 'gamma'; % For continuous, positively skewed data
mmLink = 'log'; % For continuous, positively skewed data

% Generate and save figures
[save_dir, plot_info] = plot_event_info(eventStructForPlotFiltered,'entryType',ggSetting.entry,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVars,...
	'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'fname_preffix','event','save_fig', save_fig, 'save_dir', FolderPathVA.fig);

% Create a UI table displaying the n numberss
fNum = nNumberTab(eventStructForPlotFiltered,'event');

% Save data
if save_fig
	% Save the fNum
	savePlot(fNum,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'event nNumInfo');
	% savePlot(fMM,'guiSave', 'off', 'save_dir', save_dir, 'fname', fMM_name);

	% Save the statistics info
	eventPropStatInfo.eventStructForPlotFiltered = eventStructForPlotFiltered;
	eventPropStatInfo.plot_info = plot_info;
	% dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, 'event propStatInfo'), 'eventPropStatInfo');
end

% Update the folder path 
if save_dir~=0
	FolderPathVA.fig = save_dir;
end


%%% ==========
% 2.6 Plot ROI properties. 
% Use data organized in section 2.3
% close all
% plot_combined_data = false;
% stat = true; % Set it to true to run anova when plotting bars
parNamesROI = {'sponfq','sponInterval','cv2'}; % 'sponfq', 'sponInterval'
mmHierarchicalVarsROI = {'trialName'};

if save_fig
	close all
end

[save_dir, plot_info] = plot_event_info(roiStructForPlotFiltered,'entryType','roi',...
	'plot_combined_data', plot_combined_data, 'parNames', parNamesROI, 'stat', stat,...
	'mmModel', mmModel, 'mmGroup', mmGroup, 'mmHierarchicalVars', mmHierarchicalVarsROI,...
	'mmDistribution', mmDistribution, 'mmLink', mmLink,...
	'fname_preffix','ROI','save_fig', save_fig, 'save_dir', save_dir);

% Create a UI table displaying the n numberss
fNumROI = nNumberTab(eventStructForPlotFiltered,'roi');


% Save the statistics info
if save_fig
	% Save the fNumROI
	savePlot(fNumROI,'guiSave', 'off', 'save_dir', save_dir, 'fname', 'ROI nNumInfo');

	roiPropStatInfo.roiStructForPlotFiltered = roiStructForPlotFiltered;
	roiPropStatInfo.plot_info = plot_info;
	% dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, 'ROI propStatInfo'), 'roiPropStatInfo');
end



%% ==========
% 3.1 Peri-stimulus event frequency analysis
close all
save_fig = false; % true/false
gui_save = true;

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
subNucleiFilter = 'DAO';
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
[barStat,diffStat,FolderPathVA.fig] = periStimEventFreqAnalysisSubnucleiVIIO(alignedData_allTrials,'propName',propName,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'diffPair',diffPair,'binWidth',binWidth,'stimIDX',stimIDX,'normToBase',normToBase,...
	'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
	'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim,...
	'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
	'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,...
	'save_fig',save_fig,'saveDir',FolderPathVA.fig,'gui_save',gui_save,'debug_mode',debug_mode);

