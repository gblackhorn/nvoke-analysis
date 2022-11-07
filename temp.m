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
% caLevelData_cell = {grouped_event(2).event_info.CaLevelDeltaData}(:);
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


% %% ====================
% % check the coexistence of OG-evoke and OG-rebound in OG trials
% % Get the number of ROIs of OG-evoke-pos, OG-rebound-pos, and double-pos
% [alignedData_event_list] = eventcat_list(alignedData_allTrials);
% [alignedData_event_list_OG,varargout] = filter_structData(alignedData_event_list,...
% 	'stim','og-5s',1);
% trial_num = numel(alignedData_event_list_OG);
% OG_roiNum.evoke_pos = 0;
% OG_roiNum.rebound_pos = 0;
% OG_roiNum.double_pos = 0;
% OG_roiNum.double_neg = 0;
% OG_roiNum.extra = 0;
% OG_roiNum.total = 0;
% for tn = 1:trial_num
% 	roi_info = alignedData_event_list_OG(tn).roi_info;
% 	roi_num = numel(roi_info);
% 	for rn = 1:roi_num
% 		if roi_info(rn).trig>0 && roi_info(rn).rebound>0
% 			OG_roiNum.double_pos = OG_roiNum.double_pos+1;
% 		elseif roi_info(rn).trig==0 && roi_info(rn).rebound==0
% 			OG_roiNum.double_neg = OG_roiNum.double_neg+1;
% 		elseif roi_info(rn).trig>0 && roi_info(rn).rebound==0
% 			OG_roiNum.evoke_pos = OG_roiNum.evoke_pos+1;
% 		elseif roi_info(rn).trig==0 && roi_info(rn).rebound>0
% 			OG_roiNum.rebound_pos = OG_roiNum.rebound_pos+1;
% 		else
% 			OG_roiNum.extra = OG_roiNum.extra+1;
% 		end
% 		OG_roiNum.total = OG_roiNum.total+1;
% 	end
% end



%% ====================
% % read metadata from .czi file
% % input the folder location
% fname_czi = dir(fullfile(folder,'*.czi'));
% fullpath_czi = fullfile(fname_czi.folder,fname_czi.name);
% czidata = czifinfo(fullpath_czi); 
% metadata = czidata.metadataXML;

% fname_csv = dir(fullfile(folder,'*.csv'));
% fullpath_csv = fullfile(fname_csv.folder,fname_csv.name);
% tb = readtable(fullpath_csv);
% st = table2struct(tb);


% %% ====================
% a = [15 18 16];
% b = [17 69 27 22];
% ab = [a b];
% ab_cell = num2cell(ab);
% [roi_val_data(11).combined_data.CellCount] = ab_cell{:};


% %% ====================
% % Box plot to show the positive neuron densities
% % Pre-requirement: Add Area and CellCount info first
% close all
% SaveFig = true;

% VA_AreaArray = [55809.936 29682.521 51289.236 37784.35];
% VA_CellCountArray = [44 21 30 27];
% VA_DensityArray = VA_CellCountArray./VA_AreaArray;
% VA_GroupNames = 'VA-22-days';

% GroupNames = {d2_area_data.label};
% for n = 1:numel(d2_area_data)
% 	CombinedData = d2_area_data(n).combined_data;
% 	AreaArray = [CombinedData.Area];
% 	CellCountArray = [CombinedData.CellCount];
% 	DensityArray = CellCountArray./AreaArray;
% 	d2_area_data(n).density = DensityArray;
% end
% density_data = [{VA_DensityArray} {d2_area_data.density}];
% GroupNames = [VA_GroupNames GroupNames];
% [f_box_density] = fig_canvas(1,'fig_name','BoxPlot VentralApproach and D2 area');
% [~, box_stat_density] = boxPlot_with_scatter(density_data, 'groupNames', GroupNames,...
% 		'plotWhere', gca, 'stat', true, 'FontSize', 18,'FontWeight','bold');  

% if SaveFig
% 	% default_fig_path = fullfile(DefaultDir.fig,'*.mat');
% 	FigFolder = uigetdir(DefaultDir.fig,'Select a folder to save box plot');
% 	% [mat_file,mat_folder] = uiputfile(default_mat_path,'Save fluorescence intensity measurement', 'FIM.mat');
% 	if mat_folder ~= 0
% 		DefaultDir.fig = FigFolder;
% 		dt = datestr(now, 'yyyymmdd-HHMM');
% 		fbox_name = sprintf('%s_area_boxplot_density',dt);
% 		savePlot(f_box_density,...
% 			'guiSave', 'off', 'save_dir', FigFolder, 'fname', fbox_name);

% 		save(fullfile(FigFolder, [dt, '_boxplot_stat']),...
% 		    'box_stat_density');
% 	end
% end

