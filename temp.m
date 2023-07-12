clearvars -except recdata_organized alignedData_allTrials seriesData_sync
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
ad.event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
ad.traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
ad.event_data_group = 'peak_lowpass';
ad.event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
ad.event_align_point = 'rise'; % options: 'rise', 'peak'
ad.rebound_duration = 2; % time duration after stimulation to form a window for rebound spikes
ad.cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
ad.pre_event_time = 2; % unit: s. event trace starts at 1s before event onset
ad.post_event_time = 4; % unit: s. event trace ends at 2s after event onset
ad.stim_section = true; % true: use a specific section of stimulation to calculate the calcium level delta. For example the last 1s
ad.ss_range = 1; % single number (last n second) or a 2-element array (start and end. 0s is stimulation onset)
ad.stim_time_error = 0.1; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
ad.mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
ad.debug_mode = false; % true/false
ad.caDeclineOnly = false; % true/false. Only keep the calcium decline trials (og group)

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', ad.event_type,...
	'traceData_type', ad.traceData_type, 'event_data_group', ad.event_data_group,...
	'event_filter', ad.event_filter, 'event_align_point', ad.event_align_point, 'cat_keywords', ad.cat_keywords,...
	'pre_event_time', ad.pre_event_time, 'post_event_time', ad.post_event_time,...
	'stim_section',ad.stim_section,'ss_range',ad.ss_range,...
	'stim_time_error',ad.stim_time_error,'rebound_duration',ad.rebound_duration,...
	'mod_pcn', ad.mod_pcn,'debug_mode',ad.debug_mode);

if ad.caDeclineOnly % Keep the trials in which og-led can induce the calcium decline, and discard others
	stimNames = {alignedData_allTrials.stim_name};
	[ogIDX] = judge_array_content(stimNames,{'OG-LED'},'IgnoreCase',true); % index of trials using optogenetics stimulation 
	caDe_og = [alignedData_allTrials(ogIDX).CaDecline]; % calcium decaline logical value of og trials
	[disIDX_og] = judge_array_content(caDe_og,false); % og trials without significant calcium decline
	disIDX = ogIDX(disIDX_og); 
	alignedData_allTrials(disIDX) = [];
end 

%% ====================
% Sync ROIs across trials in the same series (same FOV, same ROI set) 
sd.ref_stim = 'GPIO-1-1s'; % ROIs are synced to the trial applied with this stimulation
sd.ref_SpikeCat = {'spon','trig'}; % spike/peak/event categories kept during the syncing in ref trials
sd.nonref_SpikeCat = {'spon','rebound'}; % spike/peak/event categories kept during the syncing in non-ref trials
[seriesData_sync] = sync_rois_multiseries(alignedData_allTrials,...
	'ref_stim',sd.ref_stim,'ref_SpikeCat',sd.ref_SpikeCat,'nonref_SpikeCat',sd.nonref_SpikeCat);

%% ====================
% Group series data using ROI. Each ROI group contains events from trials using various stimulation
ngd.ref_stim = 'ap'; % reference stimulation
ngd.ref_SpikeCat = 'trig'; % reference spike/peak/event category 
ngd.other_SpikeCat = 'rebound'; % spike/peak/event category in other trial will be plot
ngd.debug_mode = false;

series_num = numel(seriesData_sync);
for sn = 1:series_num
	alignedData_series = seriesData_sync(sn).SeriesData;
	[seriesData_sync(sn).NeuronGroup_data] = group_aligned_trace_series_ROIpaired(alignedData_series,...
		'ref_stim',ngd.ref_stim,'ref_SpikeCat',ngd.ref_SpikeCat,'other_SpikeCat',ngd.other_SpikeCat,...
		'debug_mode', ngd.debug_mode);
end

%% ====================
% Plot spikes of each ROI recorded in trials received various stimulation
close all
psnt.plot_raw = true; % true/false.
psnt.plot_norm = true; % true/false. plot the ref_trial normalized data
psnt.plot_mean = true; % true/false. plot a mean trace on top of raw traces
psnt.plot_std = true; % true/false. plot the std as a shade on top of raw traces. If this is true, "plot_mean" will be turn on automatically
psnt.y_range = [-10 10];
psnt.tickInt_time = 1; % interval of tick for timeInfo (x axis)
psnt.fig_row_num = 3; % number of rows (ROIs) in each figure
psnt.save_fig = false; % true/false
psnt.fig_position = [0.1 0.1 0.85 0.85]; % [left bottom width height]

if psnt.save_fig
	psnt.save_path = uigetdir(FolderPathVA.fig,'Choose a folder to save spikes from series trials');
	if psnt.save_path~=0
		FolderPathVA.fig = psnt.save_path;
	end 
else
	psnt.save_path = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	% NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	plot_series_neuron_paired_trace(seriesData_sync(sn).NeuronGroup_data,'plot_raw',psnt.plot_raw,'plot_norm',psnt.plot_norm,...
		'plot_mean',psnt.plot_mean,'plot_std',psnt.plot_std,'y_range',psnt.y_range,'tickInt_time',psnt.tickInt_time,...
		'fig_row_num',psnt.fig_row_num,'fig_position',psnt.fig_position,'save_fig',psnt.save_path);
end

%% ====================
% Plot the spike/event properties for each neuron
close all
pei.plot_combined_data = true;
pei.parNames = {'rise_duration','peak_mag_delta','rise_duration_refNorm','peak_mag_delta_refNorm','rise_delay'}; % entry: event
pei.save_fig = true; % true/false
pei.save_dir = FolderPathVA.fig;
pei.stat = true; % true if want to run anova when plotting bars
% stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

if pei.save_fig
	pei.savepath_nogui = uigetdir(FolderPathVA.fig,'Choose a folder to save plot for spike/event prop analysis');
	if pei.savepath_nogui~=0
		FolderPathVA.fig = pei.savepath_nogui;
	else
		error('pei.savepath_nogui for saving plots is not selected')
	end 
else
	pei.savepath_nogui = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	% NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	roi_num = numel(seriesData_sync(sn).NeuronGroup_data);
	for rn = 1:roi_num
		close all
		fname_suffix = sprintf('%s-%s', series_name, seriesData_sync(sn).NeuronGroup_data(rn).roi);
		[~, plot_info] = plot_event_info(seriesData_sync(sn).NeuronGroup_data(rn).eventPropData,...
			'plot_combined_data',pei.plot_combined_data,'parNames',pei.parNames,'stat',pei.stat,...
			'save_fig',pei.save_fig,'save_dir',pei.save_dir,'savepath_nogui',pei.savepath_nogui,'fname_suffix',fname_suffix);
		seriesData_sync(sn).NeuronGroup_data(rn).stat = plot_info;
		fprintf('Spike/event properties are from %s - %s\n', series_name, seriesData_sync(sn).NeuronGroup_data(rn).roi);
	end
end

%% ====================
% Collect all events from series and plot their REFnorm data
[all_series_eventProp] = collect_AllEventProp_from_seriesData(seriesData_sync);
[grouped_all_series_eventProp, varargout] = group_event_info_multi_category(all_series_eventProp,...
	'category_names', {'group'});

close all
pgase.plot_combined_data = true;
pgase.parNames = {'rise_duration_refNorm','peak_mag_delta_refNorm'}; % entry: event
pgase.save_fig = false; % true/false
pgase.save_dir = FolderPathVA.fig;
pgase.stat = true; % true if want to run anova when plotting bars
pgase.stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

% grouped_event_info = grouped_event_info_bk;
[pgase.save_dir, pgase.plot_info] = plot_event_info(grouped_all_series_eventProp,...
	'plot_combined_data', pgase.plot_combined_data, 'parNames', pgase.parNames, 'stat', pgase.stat,...
	'save_fig', pgase.save_fig, 'save_dir', pgase.save_dir);
if pgase.save_dir~=0
	FolderPathVA.fig = pgase.save_dir;
end

% if pgase.save_fig
% 	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
% 	plot_stat_info.grouped_event_info_filtered = grouped_all_series_eventProp;
% 	plot_stat_info.plot_info = plot_info;
% 	dt = datestr(now, 'yyyymmdd');
% 	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
% end


%% ====================
% Save processed data
save_dir = uigetdir(FolderPath.analysis);
dt = datestr(now, 'yyyymmdd');
save(fullfile(save_dir, [dt, '_seriesData_sync']), 'seriesData_sync');




%% ====================
% Get the neuron number from a eventProp var
eventProp_temp = grouped_event_info_filtered(7).event_info;
trial_names = {eventProp_temp.trialName};
trial_unique = unique(trial_names);
trial_num = numel(trial_unique);
neuron_num = 0;
trial_roi_list = empty_content_struct({'trialName','roi_list','roi_num','neg_roi_list','neg_roi_num'},trial_num);
for tn = 1:trial_num
	tf_trial = strcmp(trial_names,trial_unique{tn});
	idx_trial = find(tf_trial);
	trial_eventProp = eventProp_temp(idx_trial);
	roi_unique = unique({trial_eventProp.roiName});
	roi_num = numel(roi_unique);
	neuron_num = neuron_num+roi_num;

	trial_roi_list(tn).trialName = trial_unique{tn};
	trial_roi_list(tn).roi_list = roi_unique;
	trial_roi_list(tn).roi_num = roi_num;
end

%% ====================
% Get the stim event possibility
roilist = trial_roi_list_rb;
alignedData = alignedData_allTrials;

rbPoss_trial = cell(1,numel(roilist));

for tn = 1:numel(roilist)
	trial_idx = find(strcmp({alignedData_allTrials.trialName},roilist(tn).trialName));
	alignedData_rois = {alignedData(trial_idx).traces.roi};

	roilist_trial_roi = roilist(tn).roi_list;

	rbPoss_roi = cell(1, numel(roilist_trial_roi));
	for rn = 1:numel(roilist_trial_roi)
		possiStruct = alignedData(trial_idx).traces(rn).stimEvent_possi;
		possiidx = find(strcmp({possiStruct.cat_name},'rebound'));
		rbPoss_roi{rn} = alignedData(trial_idx).traces(rn).stimEvent_possi(possiidx);
	end
	rbPoss_trial{tn} = [rbPoss_roi{:}];

	roilist(tn).neg_roi_list = setdiff(alignedData_rois,roilist_trial_roi);
	roilist(tn).neg_roi_num = numel(roilist(tn).neg_roi_list);

	neg_roi_num = neg_roi_num+roilist(tn).neg_roi_num;
end
all_possi = [rbPoss_trial{:}];


% rb_neuron_num = 52;
% rbex_neuron_num = 20;


%% ====================
% Choose a trial_roi_list and compare the rois in it with the ones in alignedData_allTrials to find difference
roilist = trial_roi_list_rb_all;
alignedData = alignedData_allTrials;

neg_roi_num = 0;
for tn = 1:numel(roilist)
	trial_idx = find(strcmp({alignedData_allTrials.trialName},roilist(tn).trialName));
	alignedData_rois = {alignedData(trial_idx).traces.roi};

	roilist_trial_roi = roilist(tn).roi_list;
	roilist(tn).neg_roi_list = setdiff(alignedData_rois,roilist_trial_roi);
	roilist(tn).neg_roi_num = numel(roilist(tn).neg_roi_list);

	neg_roi_num = neg_roi_num+roilist(tn).neg_roi_num;
end


%% ====================
% plot and paired ttest of spike frequency change during og stimulation
% alignedData_allTrials = alignedData_allTrials_all; % all data
save_fig = true; % true/false

og_fq_data{1} = [grouped_event(3).event_info.sponfq];
og_fq_data{2} = [grouped_event(3).event_info.stimfq];
[barInfo_ogfq] = barplot_with_stat(og_fq_data,'group_names',{'sponfq','stimfq'},...
	'stat','pttest','save_fig',save_fig);

og_Calevel_data{1} = [grouped_event_info_filtered(3).event_info.CaLevelmeanBase];
og_Calevel_data{2} = [grouped_event_info_filtered(3).event_info.CaLevelmeanStim];
[barInfo_ogCalevel] = barplot_with_stat(og_Calevel_data,'group_names',{'Ca-base','Ca-stim'},...
	'stat','pttest','save_fig',save_fig);


event_groups = {grouped_event_info_filtered.group};
event_pb_cell = cell(1,numel(event_groups));
for gn = 1:numel(event_groups)
	event_pb_cell{gn} = [grouped_event_info_filtered(gn).eventPbList.event1_pb];
end
[barInfo_eventPb] = barplot_with_stat(event_pb_cell,'group_names',event_groups,...
	'stat','pttest','save_fig',save_fig);


%% ====================
% plot mean traces of ap-trig and og-rebound together
% Run 9.2.2 in workflow_ventral_approach_analsyis_2 first and get the variable "stimAlignedTrace_means"
trace_type(1).tag = {'trig','GPIO-1-1s-trig'}; % search 1st entry in {stimAlignedTrace_means.event_group};
%												search 2nd entry in {stimAlignedTrace_means(3).trace.group}
trace_type(2).tag = {'rebound','OG-LED-5s-rebound'};

mean_line_color = {'#2942BA','#BA3C4F'};
shade_color = {'#4DBEEE','#C67B86'};

f_mean_trace = figure('Name','mean trace');
set(gcf, 'Units', 'normalized', 'Position', [0.1 0.1 0.9 0.6]);
% legendStr = {};
for tn = 1:numel(trace_type)
	event_pos = find(strcmp(trace_type(tn).tag{1},{stimAlignedTrace_means.event_group}));
	event_data = stimAlignedTrace_means(event_pos).trace;
	group_pos = find(strcmp(trace_type(tn).tag{2},{event_data.group}));
	plot_trace(event_data(group_pos).timeInfo,[],'plotWhere', gca,'plot_combined_data', true,...
		'mean_trace', event_data(group_pos).mean_val, 'mean_trace_shade', event_data(group_pos).ste_val,...
		'plot_raw_races',false,'y_range', [-3 7],'tickInt_time',0.5,...
		'mean_line_color',mean_line_color{tn},'shade_color',shade_color{tn});
	hold on
	% legendStr = [legendStr, {'',trace_type(tn).tag{2}}];
end
% legend(legendStr, 'location', 'northeast')
% legend('boxoff')


%% ====================
% Collect all CaLevelDeltaData (base-col and stim-col) into a 2-col vector
% caLevelData_cell = {grouped_event(2).event_info.CaLevelDeltaData};
caLevelData = cell2mat(caLevelData_cell(:));
[barInfo] = barplot_with_stat(caLevelData,'group_names',{'baseline','stim'},...
	'stat','pttest','save_fig',true,'save_dir',FolderPathVA.fig,'gui_save',true);


%% ====================
% event list grouped to event category
[event_list] = eventcat_list(alignedData_allTrials);

[TrialRoiList] = get_roiNum_from_eventProp(eventProp_all);

PosAndAllCellNum = [25 54; 32 113; 72 113]; % AP, OG-evoke, OG-rebound
PosCellNum = PosAndAllCellNum(:,1);
AllCellNum = PosAndAllCellNum(:,2);
NegCellNum = PosAndAllCellNum(:,2)-PosAndAllCellNum(:,1);
% PosAndNegCellNum = [PosAndAllCellNum(:,1) NegCellNum];
NegAndPosCellNum = [NegCellNum PosCellNum];
% PosAndNegPercentage = PosAndNegCellNum./AllCellNum;
NegAndPosPercentage = NegAndPosCellNum./AllCellNum;
bar(NegAndPosPercentage,'stacked')

%% ====================
% Get the numbers of ROIs exhibiting certain event category in specific FOVs, and add them to grouped_event_info_filtered
% Note: set eprop.entry to 'roi' when creating grouped_event
GroupNum = numel(grouped_event_info_filtered);
% GroupName = {grouped_event_info_filtered.group};
for gn = 1:GroupNum
	EventInfo = grouped_event_info_filtered(gn).event_info;
	fovIDs = {EventInfo.fovID};
	fovIDs_unique = unique(fovIDs);
	fovIDs_unique_num = numel(fovIDs_unique);
	fovID_count_struct = empty_content_struct({'fovID','numROI'},fovIDs_unique_num);
	[fovID_count_struct.fovID] = fovIDs_unique{:};
	for fn = 1:fovIDs_unique_num
		fovID_count_struct(fn).numROI = numel(find(contains(fovIDs,fovID_count_struct(fn).fovID)));
	end
	grouped_event_info_filtered(gn).fovCount = fovID_count_struct;
end


%% ====================
% plot stim event probability
trig_ap_eventpb = grouped_event(1).eventPb{3,'eventPb_val'};
trig_ogrb_eventpb = grouped_event(2).eventPb{2,'eventPb_val'};
trig_og_eventpb = grouped_event(2).eventPb{3,'eventPb_val'};

eventpb_cell = [trig_ap_eventpb,trig_ogrb_eventpb,trig_og_eventpb];

[barInfo] = barplot_with_stat(eventpb_cell,'group_names',{'ap','ogrb','og'},...
	'stat','anova','save_fig',true,'save_dir',FolderPathVA.fig,'gui_save',true);

%% ====================
% Correct stimulation name in recdata for proper processing of gpio info
for tn = 1:size(recdata,1)
	if strcmpi(recdata{tn,3},'og-5s ap-0.5s')
		recdata{tn, 4}(4).name = 'GPIO-1';
	end
end



%% ====================
% Draw roi manually and extract calcium data using FIJI. Replace cnmfe data with this and plot traces
folder = 'G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff\IO_ventral_approach\2021-03-29_dff_crop';
file = '2021-03-29-14-19-43_video_sched_0-PP-BP-MC_crop.csv';
% recdata_manual_new = recdata_manual;
% Get the tbl data
csvpath = fullfile(folder,file);
opts = detectImportOptions(csvpath);
tbl = readtable(csvpath,opts);
%% ====================
% Process the tbl to replace the existing cnmfe data
[new_tbl] = ConvertFijiTbl(tbl);

% Replace cnmfe data
trial_loc = 1;
DataStruct = recdata_manual{trial_loc,2};
[DataStruct_new] = Replace_decon_raw_data(DataStruct,new_tbl);
recdata_manual_new{trial_loc,2} = DataStruct_new;


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
% barPlot to show the event frequencies in time bins 
close all
[EventFreqInBins] = get_EventFreqInBins_AllTrials(alignedData_allTrials,'og-5s'); % 'ap-0.1s', 'og-5s', 'og-5s ap-0.1s'
ef_cell = {EventFreqInBins.EventFqInBins};
ef_cell = ef_cell(:);
ef = vertcat(ef_cell{:});
[barInfo] = barplot_with_stat(ef);

%% ====================
% Plot the the calcium fluorescence with color
close all
trial_loc = 1;
x_window = [alignedData_allTrials(trial_loc).fullTime(1), alignedData_allTrials(trial_loc).fullTime(end)];
fullTraceCell = {alignedData_allTrials(trial_loc).traces.fullTrace};
fullTraceCell_norm = cellfun(@(x) x./max(x),fullTraceCell,'UniformOutput',false); % normalize the trace with max value
TemporalData = [fullTraceCell_norm{:}];
TemporalData = TemporalData';
plot_TemporalData_Color(gca,TemporalData,'x_window',x_window)
colorbar

%% ====================
% fit the data to exponential curve
% [curvefit,gof,output] = fit(tdata',ydata','exp1');

alignedData = alignedData_allTrials(7);
[TimeInfo,FluroData] = get_TrialTraces_from_alignedData(alignedData,...
		'norm_FluorData',false); 
fVal = FluroData(:,1);
TimeRanges = alignedData_allTrials(7).stimInfo.StimDuration.range  ;
EventTime = [alignedData_allTrials(7).traces(1).eventProp.rise_time];
[curvefit,tauInfo] = GetDecayFittingInfo_neuron(TimeInfo,fVal,TimeRanges,EventTime);
PlotCurveFitting_neuron(curvefit);

%% ==================== 
FitStimIDX = [alignedData_allTrials(7).traces(13).StimCurveFit.SN];
stimTime = alignedData_allTrials(7).stimInfo.StimDuration.range(:,2);
ROIeventProp = alignedData_allTrials(7).traces(13).eventProp;
eventCat = 'rebound';

[stimNum,decayNum,eventIDX,eventFitNum,eventNoFitNum] = get_StimEvents_CloseToFit_roi(FitStimIDX,stimTime,ROIeventProp,eventCat)

%% ==================== 

[List_curveFitNum_eventNum] = get_StimEvents_CloseToFit_trials(alignedData_allTrials,'rebound',2);

%% ====================
% Generate some sample data
x = 1:10;
y = 2*x + 3 + randn(size(x));

% Fit a line to the data using polyfit
coeffs = polyfit(x, y, 1);
yfit = polyval(coeffs, x);

% Calculate R^2
yresid = y - yfit;
SSresid = sum(yresid.^2);
SStotal = (length(y)-1) * var(y);
rsq = 1 - SSresid/SStotal;
fprintf('R^2 = %f\n', rsq);

% Calculate RMSE
rmse = sqrt(mean(yresid.^2));
fprintf('RMSE = %f\n', rmse);

% Plot the data and the fitted line
plot(x, y, 'o', x, yfit, '-')
legend('Data', 'Fitted line')

% %% ==================== 
% To perform frequency power analysis on calcium imaging data in MATLAB, you can follow these steps: 

% 1. Load the data into MATLAB. The data should be in a matrix format, with time on one axis and the
% fluorescence intensity of each neuron on the other axis. 

% 2. Select the time intervals corresponding to the optogenetic stimulations. You can do this by
% creating a vector of logical values that is true during the time intervals when the stimulation
% was delivered. 

% 3. Separate the data into two groups based on whether the stimulation was delivered or not. You
% can do this using the logical vector created in step 2.
    
% 4. Perform frequency power analysis on each group separately. You can use the fft function to
% compute the Fourier transform of the data, and then calculate the power spectrum as the square of
% the absolute value of the Fourier coefficients. 

% 5. Compare the power between the two groups. You can use a statistical test, such as a t-test or
% Wilcoxon rank-sum test, to determine if there is a significant difference in power between the
% stimulated and non-stimulated groups. 

% Here is some example code that demonstrates these steps:

% Load the data
data = load('calcium_data.mat');

% Set the stimulation interval
stim_interval = [1000:2000, 3000:4000, 5000:6000];

% Separate the data into two groups based on the stimulation interval
stim_data = data(:, stim_interval);
nonstim_data = data(:, ~ismember(1:size(data, 2), stim_interval));

% Perform frequency power analysis on each group
stim_power = abs(fft(stim_data)).^2;
nonstim_power = abs(fft(nonstim_data)).^2;

% Calculate the mean power across neurons for each group
stim_mean_power = mean(stim_power, 2);
nonstim_mean_power = mean(nonstim_power, 2);

% Compare the power between the two groups using a t-test
[h, p] = ttest2(stim_mean_power, nonstim_mean_power);
disp(['p-value: ' num2str(p)]);


%% ==================== 
sponTimeRanges(:,1) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1)-15;   
sponTimeRanges(:,2) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1);   
EventsTime = [alignedData_allTrials(7).traces(1).eventProp.rise_time];  
stimIDX_curvefit = [alignedData_allTrials(7).traces(1).StimCurveFit.SN];
[sponFreqList] = get_sponFreq_everyStim_roi(EventsTime,sponTimeRanges,'stimIDX_curvefit',stimIDX_curvefit);


%% ==================== 
tags = {grouped_event_info_filtered.tag};
pos_OG5sRB = find(strcmpi('rebound [og-5s]', tags));

stimNum = [List_decayFitNum_rbNum.stimNum];
fitNum = [List_decayFitNum_rbNum.fitNum];
eventFitNum = [List_decayFitNum_rbNum.eventFitNum];

% Calculate the curve_fit/stimulation_number 
PercFit = fitNum./stimNum; 
meanPercFit = mean(PercFit);
stePercFit = ste(PercFit);

% Calculate the events_with_curveFit/curve_fit
PercEventFit = eventFitNum./fitNum;
meanPercEventFit = mean(PercEventFit);
stePercEventFit = ste(PercEventFit);

% Calculate the events_with_curveFit/stimulation_number
PercEventFitToStimNum = eventFitNum./stimNum;
meanEventFitToStimNum = mean(EventFitToStimNum);
steEventFitToStimNum = ste(EventFitToStimNum);


%% ==================== 
[file_traceCSV,folder_traceCSV] = uigetfile({'*.csv', 'CSV files (*.csv)'}, 'Select a CSV file');
T = readtable(fullfile(folder_traceCSV, file_traceCSV));
timeInfo = T.var1;


[file_gpio,folder_gpio] = uigetfile({'*.csv', 'CSV files (*.csv)'}, 'Select a CSV file');
GPIO_table = readtable(fullfile(folder_gpio,file_gpio));
[channel, EX_LED_power, GPIO_duration, stimulation ] = GPIO_data_extract(GPIO_table);
[gpio_Info_organized, gpio_info_table] = organize_gpio_info(channel,...
    			'modify_ch_name', true, 'round_digit_sig', 2); 
[StimDuration,UnifiedStimDuration,ExtraInfo] = get_stimInfo(gpio_Info_organized);
patchCoor = {StimDuration.patch_coor};
stimName = {StimDuration.type};


%% ==================== 
close all
% Example data
A = rand(10,20);
B = rand(10,10);

% Calculate means and standard deviations for each group at each time point
mean_A = mean(A, 2);
% std_A = std(A, 0, 2);
std_A = zeros(size(mean_A));
mean_B = mean(B, 2);
% std_B = std(B, 0, 2);
std_B = zeros(size(mean_B));

% Set up the plot
figure
hold on
xlabel('Time Point')
ylabel('Value')
title('Group A vs Group B')

% Plot the means and error bars for each group at each time point
x = 1:10;
errorbar(x, mean_A, std_A, 'o-', 'LineWidth', 1.5, 'CapSize', 10, 'MarkerSize', 8)
errorbar(x, mean_B, std_B, 'o-', 'LineWidth', 1.5, 'CapSize', 10, 'MarkerSize', 8)

% Add legend and grid
legend('Group A', 'Group B', 'Location', 'Best')
grid on

% Show the plot
hold off

plot_diff(x,mean_A,mean_B,'errorA',std_A,'errorB',std_B);

%% ==================== 
% Define the cell array
cellArray = {'-1', '0', '1'};

% Convert the cell array to a numeric array
numArray = cellfun(@str2double, cellArray);

% Display the numeric array
disp(numArray);


%% ==================== 
figTitleStr_3 = sprintf('diff between ap-0.1s and og-5s ap-0.1s in %gs bins normToBase',binWidth);
xData_new = xData(2:end);
meanVal_ogap_new = meanVal_ogap(2:end);
diffVal_3 = plot_diff(xData_new,meanVal_ap,meanVal_ogap_new,'errorA',steVal_ap,'errorB',steVal_ogap,...
	'legStrA','ap-0.1s','legStrB','og-5s ap-0.1s','new_xticks',binEdges,'figTitleStr',figTitleStr_3,...
	'save_fig',save_fig,'save_dir',FolderPathVA.fig);

%% ==================== 
ogData = {barStat(1).data.group_data};
apData = {barStat(2).data.group_data};
ogapData = {barStat(3).data.group_data};

ogapDataShift = ogapData(2:end);

[pVal_ogVSogap] = unpaired_ttest_cellArray(ogData,ogapData);
[pVal_ogVSap] = unpaired_ttest_cellArray(ogData,apData);
[pVal_apVSogap] = unpaired_ttest_cellArray(apData,ogapDataShift);


%% ==================== 
close all
% Generate sample data
data = {randn(1,10), randn(1,10), randn(1,10), randn(1,10), randn(1,10)};
xData = 1:5;

% Calculate mean and standard error for each data set
means = cellfun(@mean, data);
stderrs = cellfun(@std, data) ./ sqrt(cellfun(@length, data));

% Plot errorbar with scatter
errorbar(xData, means, stderrs, 'o', 'DisplayName', 'Error Bars');
hold on
for i = 1:numel(xData)
    scatter(xData(i) + 0.1*randn(1,length(data{i})), data{i}, 'k');
end
hold off

% Add legend for error bars only
legend('show', 'Location', 'best', 'AutoUpdate', 'off');


%% ==================== 
% auto-correlogram

close all
% generate a sample signal
fs = 100; % sampling rate
t = 0:1/fs:10; % time vector
x = sin(2*pi*50*t) + sin(2*pi*150*t); % signal with 50Hz and 150Hz components

% calculate and plot the auto-correlogram
[acor, lag] = xcorr(x, 'coeff');
plot(lag, acor);
xlabel('Lag (samples)');
ylabel('Correlation coefficient');


% % assume you have n recordings, each with spike times in a cell array
% spike_times = {[10, 20, 30, 50, 70, 80, 90, 100, 120, 140, 150], ...
%                [15, 25, 40, 60, 75, 85, 105, 125, 130, 135, 145], ...
%                [20, 40, 55, 65, 70, 85, 95, 110, 125, 140, 155]};

% spike_times_all = cat(1, spike_times{:}); % concatenate all spike times
% max_lag = 10; % set the maximum lag to compute the autocorrelogram
% [autocorr, lags] = xcorr(spike_times_all, max_lag);
% plot(lags, autocorr);

%% ==================== 
% % the probability density function (PDF)
close all
% % Generate random calcium data
% ca_data = sort(randn(1000,1)*5+50); % 1000 samples of random calcium data
% 
% % Calculate PDF using ksdensity
% [f, xi] = ksdensity(ca_data); 
% 
% % Plot PDF
% plot(xi, f);
% xlabel('Calcium Value');
% ylabel('Probability Density');
% title('Calcium Recording PDF');

% Generate some random data
t = 0:0.01:100; % time vector
firing_rate = 5*sin(t); % firing rate (in Hz)
spike_times = poissrnd(firing_rate/1000); % simulate spike times (in ms)
calcium_signal = conv(spike_times, exp(-t/1)); % convolve with exponential decay kernel
calcium_signal = calcium_signal(1:length(t)); % remove extra points


% Estimate the PDF of the calcium signal
[f, x] = ksdensity(calcium_signal);


% Plot the PDF of the calcium signal
figure
plot(x, f)
xlabel('Fluorescence intensity')
ylabel('Probability density')


%%
% close all
% Generate sample data for three ROIs
num_ROIs = 3;
event_times = cell(num_ROIs, 1);
for roi = 1:num_ROIs
    % Generate random number of events between 50 and 100
    num_events = randi([50 100]);
    % Generate random event times between 0 and 300 seconds
    event_times{roi} = sort(rand(num_events, 1)*300);
end

% Calculate inter-event times for each ROI
ieis = cell(num_ROIs, 1);
for roi = 1:num_ROIs
    ieis{roi} = diff(event_times{roi});
end

% Plot histograms of inter-event times for each ROI
figure;
for roi = 1:num_ROIs
    subplot(num_ROIs, 1, roi);
    hold on
    histogram(ieis{roi}, 20, 'Normalization', 'pdf');

    pd = fitdist(ieis{roi}, 'Kernel', 'Kernel', 'normal');
    x_values = linspace(min(ieis{roi}), max(ieis{roi}), 1000);
    y_values = pdf(pd, x_values);
    plot(x_values, y_values);

    % [f, x] = ksdensity(ieis{roi});
    % plot(x,f);

    xlabel('Inter-Event Time (s)');
    ylabel('Probability Density');
    title(sprintf('ROI %d', roi));
    hold off
end

% % Plot probability density functions (PDF) of inter-event times for each ROI
% figure;
% for roi = 1:num_ROIs
%     subplot(num_ROIs, 1, roi);
%     pd = fitdist(ieis{roi}, 'Kernel', 'Kernel', 'normal');
%     x_values = linspace(min(ieis{roi}), max(ieis{roi}), 1000);
%     y_values = pdf(pd, x_values);
%     plot(x_values, y_values);
%     xlabel('Inter-Event Time (s)');
%     ylabel('Probability Density');
%     title(sprintf('ROI %d', roi));
% end

%%
% Example data
recording1 = [0.1, 0.3, 0.8, 1.2, 2.5, 3.0, 3.5];
recording2 = [0.2, 0.5, 0.7, 1.5, 2.0, 2.5, 3.2];
recording3 = [0.4, 0.6, 1.0, 1.8, 2.2, 2.8, 3.3];
all_recordings = {recording1, recording2, recording3};

% Combine all inter-event times
all_inter_event_times = [];
for i = 1:length(all_recordings)
    inter_event_times = diff(all_recordings{i});
    all_inter_event_times = [all_inter_event_times, inter_event_times];
end

% Plot histogram of inter-event times
figure;
histogram(all_inter_event_times, 'Normalization', 'probability');
xlabel('Inter-event time (s)');
ylabel('Probability');
title('Histogram of inter-event times');

% Calculate and plot PDF of inter-event times
[f, x] = ksdensity(all_inter_event_times);
figure;
plot(x, f);
xlabel('Inter-event time (s)');
ylabel('Probability density');
title('PDF of inter-event times');

%%
close all
% create a binary vector for stimulus presentation
stim = [0 0 1 0 0 1 0 1 0 0];

% generate some random calcium event times
event_times = sort(rand(1, 50)*10);

% find closest stimulus presentation times for each event time
stim_times_before = interp1(find(stim), find(stim), event_times, 'previous');
stim_times_after = interp1(find(stim), find(stim), event_times, 'next');

% calculate time differences between event times and closest stimulus presentation times
delta_t_before = event_times - stim_times_before;
delta_t_after = stim_times_after - event_times;
delta_t = [delta_t_before delta_t_after];

% calculate auto-correlogram of delta_t
max_lag = 10; % maximum lag time
acf = xcorr(delta_t, max_lag, 'normalized');

% plot auto-correlogram
stem(-max_lag:max_lag, acf);
xlabel('Lag (s)');
ylabel('Normalized Auto-correlation');


[eventIntAll] = get_eventTimeInt(alignedData_allTrials,'peak_time',...
	'filter_roi_tf',true,'stim_names','ap-0.1s','filters',{[nan 1 nan], [1 nan nan], [nan nan nan]});

[histHandle] = plot_NormHistWithPDF(eventIntAll,[0:0.5:20],...
	'xlabelStr','time (s)','titleStr','Inter-event time [ap-0.1s ex]');




filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan 1 nan], [1 nan nan], [nan nan nan]}; % [ex in rb]
eventType = 'peak_time';
binsOrEdges = [0:0.5:20];
plot_eventTimeInt_alignedData_allTrials(alignedData_allTrials,eventType,binsOrEdges,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters);


%%
close all
eventType = 'peak_time';

trialNum = numel(alignedData_og);
eventTimeTrials = cell(1,trialNum);

for tn = 1:trialNum
	% get the events time (rise or peak) from all ROIs in a single trial
	eventsTime = get_TrialEvents_from_alignedData(alignedData_og(tn),eventType);
	
	% concatenate ROIs' event intervals 
	eventTimeTrials{tn} = eventsTime;
end
eventTimeAll = [eventTimeTrials{:}];

% Assuming you have extracted calcium events from multiple neurons and stored them in a cell array called "events"
% events{1} contains the events from neuron 1, events{2} contains the events from neuron 2, and so on.

num_neurons = length(eventTimeAll);
corr_all = []; % initialize a matrix to store the cross-correlations

for i = 1:num_neurons
    for j = i+1:num_neurons % only calculate the cross-correlation for distinct pairs of neurons
        [corr, lags] = xcorr(eventTimeAll{i}, eventTimeAll{j}, 'none'); % calculate the cross-correlation and lags
        corr_all = [corr_all; corr]; % store the correlation coefficients in a matrix
    end
end

% Plot the average cross-correlation across all pairs of neurons
figure;
mean_corr = mean(corr_all, 1); % calculate the mean correlation across all pairs of neurons
plot(lags, mean_corr);
xlabel('Lags');
ylabel('Cross-correlation coefficient');
title('Average cross-correlation across multiple neurons');

acf = cell(1,5);
lags = cell(1,5);
bounds = cell(1,5);
for n = 1:5
	[acf{n},lags{n},bounds{n}] = autocorr(eventTimeAll{n},'NumLags',10);
end
et = eventTimeAll(1:5);


figure
hold on
for m = 1:5
	plot(acf{m})
end
hold off


%%
% Example data
event_times = {[1, 5, 10, 15, 20], [2, 6, 11, 16, 21], [3, 7, 12, 17, 22], [4, 8, 13, 18, 23], [9, 14, 19, 24]};
lags = 0:0.5:5; % specify lag bins

% Initialize histogram counts
hist_counts = zeros(length(lags)-1, 1);

% Calculate histogram counts
for i = 1:length(event_times)
    acor = xcorr(event_times{i}-mean(event_times{i}), lags, 'none');
    hist_counts = hist_counts + histcounts(acor, lags);
end

% Plot histogram
histogram(hist_counts,lags(1:end-1));
xlabel('Lags (s)');
ylabel('Counts');
title('Autocorrelation Histogram');


%% 
QTM_mat_path = 'G:\Workspace\Mocap\Mos1a_2023_03_31_matfiles_for_naming\MOS1a_S19_M5_MCL2_T2_TRE_2023_03_31.mat';
QTM_mat = matfile(QTM_mat_path);




[f,p] = uigetfile;
isxdfile = fullfile(p,f);

isdxMovie = isx.Movie.read(isxdfile);
sampling_frequency = 1/isdxMovie.timing.period.secs_float;
datetime = isdxMovie.timing.start.datetime;
frameNum = isdxMovie.timing.num_samples;

opts.downsampleFactor = 1;
opts.newFilename = fullfile(p,'2023-03-30-18-26-47_video_trig_0.hdf5');
ciapkg.inscopix.convertInscopixIsxdToHdf5(isxdfile,'options',opts)



% Define the input timestamp
timestamp = "2023-03-31, 13:04:41.533	5449.33313310";

% Extract the date and time components from the timestamp
dt = datetime(timestamp, 'InputFormat', 'yyyy-MM-dd, HH:mm:ss.SSS', 'TimeZone', 'local');

% Convert the datetime object to a string in the desired format
formatted_date = datestr(dt, 'yyyy-mm-dd-hh-MM-ss');

% Display the formatted date
disp(formatted_date);

isxd_recStartTime = cellfun(@(x) x(1:19),names,'UniformOutput',false);
isxd_dt = cellfun(@(x) datetime(x,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local'),...
	isxd_recStartTime,'UniformOutput',false);
mocap1_time = datetime(x(1).recStartTime,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local')


QTMmatFolderPath = 'G:\Workspace\Mocap\Mos1a_2023_03_31_matfiles_for_naming';
nVokeRawDataFolder = 'S:\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\Moscope\Moscope_CaImg\Raw_recordings\MOS1A_2023-03-31';
nVokeRenameDataFolder = 'S:\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\Moscope\Moscope_CaImg\Raw_recordings_renamed';
[nVoke_oldNew_filenames,debriefing] = batchMod_nVoke2_filenames('QTMmatFolderPath',QTMmatFolderPath,...
	'nVokeRawDataFolder',nVokeRawDataFolder,'nVokeRenameDataFolder',nVokeRenameDataFolder);


[bin_Events] = plot_autoCorrelogramEvents(alignedData_allTrials,...
			'timeType','rise_time','stimName','ap-0.1s','stimEventCat','trig',...
			'remove_centerEvents',true,'binWidth',0.25,'normData',true,'saveFig',true);


%%
offStimData = grouped_event_info_filtered(2).event_info;
followData = grouped_event_info_filtered(1).event_info;
[pairedStat.rise_duration.h,pairedStat.rise_duration.p] = ttest([followData.rise_duration],[offStimData.rise_duration]);
[pairedStat.FWHM.h,pairedStat.FWHM.p] = ttest([followData.FWHM],[offStimData.FWHM]);
[pairedStat.peak_mag_delta.h,pairedStat.peak_mag_delta.p] = ttest([followData.peak_mag_delta],[offStimData.peak_mag_delta]);
[pairedStat.sponnorm_peak_mag_delta.h,pairedStat.sponnorm_peak_mag_delta.p] = ttest([followData.sponnorm_peak_mag_delta],[offStimData.sponnorm_peak_mag_delta]);

%% Delete the recordings with names in the trialNamesDiscard
trialNamesDiscard = {'20210326-150725_video_sched_0-PP-BP-MC-ROI.csv',...
'20210326-151454_video_sched_0-PP-BP-MC-ROI.csv','20210326-152008_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-135544_video_sched_0-PP-BP-MC-ROI.csv','20210329-140143_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-141943_video_sched_0-PP-BP-MC-ROI.csv','20210329-142437_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-142928_video_sched_0-PP-BP-MC-ROI.csv','20210405-134049_video_sched_0-PP-BP-MC-ROI.csv',...
'20210409-130356_video_sched_0-PP-BP-MC-ROI.csv'};
trialNames = recdata_organized_old_part(:,1);
trialNamesDiscardIDX = cellfun(@(x) find(strcmpi(x,trialNames)),trialNamesDiscard);
recdata_organized_old_part(trialNamesDiscardIDX,:) = [];


%% Copy the stimulation name and the gpio info from the old recdata
trialNamesDiscard = {'20210326-150725_video_sched_0-PP-BP-MC-ROI.csv',...
'20210326-151454_video_sched_0-PP-BP-MC-ROI.csv','20210326-152008_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-135544_video_sched_0-PP-BP-MC-ROI.csv','20210329-140143_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-141943_video_sched_0-PP-BP-MC-ROI.csv','20210329-142437_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-142928_video_sched_0-PP-BP-MC-ROI.csv','20210405-134049_video_sched_0-PP-BP-MC-ROI.csv',...
'20210409-130356_video_sched_0-PP-BP-MC-ROI.csv'};
trialNames = recdata_organized_old_part(:,1);
trialNamesDiscardIDX = cellfun(@(x) find(strcmpi(x,trialNames)),trialNamesDiscard);
for n = 1:numel(trialNamesDiscard)
	recdata{n,3} = recdata_organized_old{trialNamesDiscardIDX(n),3};
	recdata{n,4} = recdata_organized_old{trialNamesDiscardIDX(n),4};
end

%%
recdata_organized = [recdata_organized_old_part;recdata_organized];

% Original cell array of strings
trialNamesDiscard = {
    '20210326-150725_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210326-151454_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210326-152008_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-135544_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-140143_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-141943_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-142437_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-142928_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210405-134049_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210409-130356_video_sched_0-PP-BP-MC-ROI.csv'
};

% Extract date and time portions and convert to datetime format
datesAndTimes = cellfun(@(str) datetime(str(1:15), 'InputFormat', 'yyyyMMdd-HHmmss'), trialNamesDiscard);

% Sort the strings based on date and time
[sortedDatesAndTimes, sortedIndices] = sort(datesAndTimes);

% Sort the original cell array using the sorted indices
sortedTrialNamesDiscard = trialNamesDiscard(sortedIndices);


%% ====================
close all
save_fig = false; % true/false
gui_save = 'on';

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

propName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
binWidth = 1; % the width of histogram bin. the default value is 1 s.
stimIDX = []; % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
postStim_duration = 15; % unit: second. include events happened after the end of stimulations

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

debug_mode = false; % true/false

[violinData,statInfo] = violinplotPeriStimFreq(alignedData_allTrials);


timeData = alignedData_allTrials(1).fullTime;
stimInfo = alignedData_allTrials(1).stimInfo;
[timeRanges,timeRangesIDX,stimRanges,stimRangesIDX,timeDuration,datapointNum] = createTimeRangesUsingStimInfo(timeData,stimInfo)
eventsTime = [alignedData_allTrials(1).traces(1).eventProp.peak_time];
[posTimeRanges,posRangeIDX,negRangeIDX,rangEventsTime,rangEventsIDX] = getRangeIDXwithEvents(eventsTime,timeRanges)


alignedData = alignedData_allTrials(7);
fluroData = alignedData.traces(1).fullTrace;
timeData = alignedData.fullTime;
% eventsTime = [alignedData.traces(1).eventProp.peak_time];
roiNum = numel(alignedData.traces);
fluroData = cell(1,roiNum);
eventsTime = cell(roiNum,1);
eventCat = cell(roiNum,1);
for rn = 1:roiNum
	fluroData{rn} = alignedData.traces(rn).fullTrace;
	eventsTime{rn} = [alignedData.traces(rn).eventProp.peak_time];
	eventCat{rn} = {alignedData.traces(rn).eventProp.peak_category};
end
fluroData = horzcat(fluroData{:});
stimInfo = alignedData_allTrials(1).stimInfo;
preTime = 5;
postTime = 10;
% eventCat = {alignedData_allTrials(1).traces(1).eventProp.peak_category};
stimEventCat = 'rebound';
followEventCat = 'spon';
stimRefType = 'end';
debugMode = false;
[sortedIDX,sortedFdSection,sortedEventMarker,sortedRowNames,sortedEventNumIDX] = sortPeriStimTraces(fluroData,timeData,...
		eventsTime,stimInfo,'preTime',preTime,'postTime',postTime,...
		'eventCat',eventCat,'stimEventCat',stimEventCat,'followEventCat',followEventCat,...
		'stimRefType',stimRefType,'debugMode',debugMode);


%% ====================
timeInfo = alignedData_allTrials(2).fullTime;
stimInfo = alignedData_allTrials(2).stimInfo;

[periStimSections] = setPeriStimSectionForEventFreqCalc(timeInfo,stimInfo);

x = periStimSections(sn,:)
[y,closestIndex] = find_closest_in_array(x,timeInfo)


[stimFollowEventsPair] = getStimEventFollowEventROI(alignedData(1),'trig','spon')

[sponEventsInt,osr,osrNum] = getSponEventsInt(alignedData(1))


[intData] = stimEventSponEventIntAnalysis(alignedData,'ap-0.1s','trig')


%% ====================
figure
plot(timeInfo,traceData);

hold on

preCloseHMTime = timeInfo(HMstartLoc);
preCloseHMData = traceData(HMstartLoc);

postCloseHMTime = timeInfo(HMendLoc);
postCloseHMData = traceData(HMendLoc);

nanIDX = find(isnan(HMendLoc));
halfMax(nanIDX) = [];
preCloseHMTime(nanIDX) = [];
preCloseHMData(nanIDX) = [];
postCloseHMTime(nanIDX) = [];
postCloseHMData(nanIDX) = [];

plot(preCloseHMTime,preCloseHMData,'ko');
plot(postCloseHMTime,postCloseHMData,'k*');

plot(timeAtHM(:,1),halfMax,'ro');
plot(timeAtHM(:,2),halfMax,'r*');
