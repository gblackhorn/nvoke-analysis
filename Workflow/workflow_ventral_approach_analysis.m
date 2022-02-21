% This script is used on office local desktop running windows 10
% Use this script after exporting motion corrected files with tiff format. 
% Process files with CNMFe with cluster. And then come back for further analysis
	% Inscopix API related process, such as spatial filter and motion correction cannot be run on VDI. 
	% CNMFe can be run here alternatively, but deigo cluster is way faster
% All files are stored on bucket


% 1. set folders for different situation
inscopix_folder = 'G:\Workspace\Inscopix_Seagate';

% ins_analysis_folder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
ins_analysis_folder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop

ins_projects_folder = fullfile(inscopix_folder, 'Projects'); % processed imaging data, including isxd, gpio, tiff, and csv files 
ins_recordings_folder = fullfile(inscopix_folder, 'recordings'); % processed imaging data, including isxd, gpio, tiff, and csv files 

ins_analysis_ventral_folder = fullfile(ins_analysis_folder, 'nVoke_ventral_approach'); % processed imaging data, including isxd, gpio, tiff, and csv files 
ins_analysis_ventral_fig_folder = fullfile(ins_analysis_ventral_folder, 'figures'); % figure folder for ventral approach analysis
ins_analysis_invitro_folder = fullfile(ins_analysis_folder, 'Kevin_calcium_imaging_slice'); % processed imaging data, including isxd, gpio, tiff, and csv files 

ins_tiff_folder = fullfile(ins_projects_folder, 'Exported_tiff'); % motion corrected recordings in tiff format
ins_tiff_invivo_folder = fullfile(ins_tiff_folder, 'IO_ventral_approach'); % motion corrected recordings in tiff format
ins_cnmfe_result_folder = fullfile(ins_projects_folder, 'Processed_files_for_matlab_analysis'); % cnmfe result files, gpio and roi csv files etc.

ins_rec_ventral_folder = fullfile(ins_recordings_folder, 'IO_virus_ventral approach'); % processed imaging data, including isxd, gpio, tiff, and csv files 

%% ====================
% Save processed data
save_dir = uigetdir(ins_analysis_folder);
dt = datestr(now, 'yyyymmdd');
save(fullfile(save_dir, [dt, '_ProcessedData_optoEx']), 'recdata_organized','alignedData_allTrials','grouped_event_info');

%% ====================
% 8.4 Select a specific group of data from recdata_group for further analysis
recdata_organized = select_grouped_data(recdata_group);

%% ====================
% 9.1 Examine peak detection with plots 
PauseTrial = false; % true or false
traceNum_perFig = 10; % number of traces/ROIs per figure
SavePlot = true; % true or false
SaveTo = ins_analysis_ventral_fig_folder;
vis = 'off'; % set the 'visible' of figures
decon = false; % true/false plot decon trace
marker = true; % true/false plot markers

[SaveTo] = plotTracesFromAllTrials (recdata_organized,...
	'PauseTrial', PauseTrial,...
	'traceNum_perFig', traceNum_perFig, 'decon', decon, 'marker', marker,...
	'SavePlot', SavePlot, 'SaveTo', SaveTo,...
	'vis', vis);
if SaveTo~=0
	ins_analysis_ventral_fig_folder = SaveTo;
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
recdata_organized_bk = recdata_organized;
[recdata_organized] = discard_recData_roi(recdata_organized,'stims',stims,'eventCats',eventCats);
%% ====================
% 9.2 Align traces from all trials. Also collect the properties of events
event_type = 'stimWin'; % options: 'detected_events', 'stimWin'
traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
event_data_group = 'peak_lowpass';
event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
event_align_point = 'rise';
cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
pre_event_time = 5; % unit: s. event trace starts at 1s before event onset
post_event_time = 5; % unit: s. event trace ends at 2s after event onset
mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', event_type,...
	'traceData_type', traceData_type, 'event_data_group', event_data_group,...
	'event_filter', event_filter, 'event_align_point', event_align_point, 'cat_keywords', cat_keywords,...
	'pre_event_time', pre_event_time, 'post_event_time', post_event_time, 'mod_pcn', mod_pcn);

%% ====================
% 9.2.0.1 Check trace aligned to stim window
% note: 'event_type' for alignedData_allTrials must be 'stimWin'
plot_combined_data = true;
plot_stim_shade = true;
y_range = [-20 30];
stimEffectType = 'excitation'; % options: 'excitation', 'inhibition', 'rebound'
fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedData_allTrials,...
	'plot_combined_data',plot_combined_data,'plot_stim_shade',plot_stim_shade,'y_range',y_range,'stimEffectType',stimEffectType);

% if filter_alignedData 
% 	alignedData_bk = alignedData_allTrials;
% 	stims = {'GPIO-1-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
% 	eventCats = {{'trigger'},...
% 			{'trigger'},... % 'trigger', 'rebound'
% 			{'delay-trigger'}}; % 'trigger-beforeStim', 'trigger-interval', 'delay-trigger', 'rebound-interval'
% 
% 	[alignedData_allTrials] = discard_alignedData_roi(alignedData_allTrials,'stims',stims,'eventCats',eventCats);
% end

%% ====================
% 9.2.1
mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
keep_catNames = {'spon','trig', 'trig-AP', 'opto-delay', 'rebound'}; % 'spon'. event will be kept if its peak-cat is one of these
criteria_excitated = 0.5;
criteria_rebound = 1;
stim_time_error = 0;
debug_mode = false;
alignedData_allTrials_bk = alignedData_allTrials;
[alignedData_allTrials] = org_alignData(alignedData_allTrials,'keep_catNames', keep_catNames,...
	'mod_pcn', mod_pcn, 'criteria_excitated', criteria_excitated, 'criteria_rebound', criteria_rebound,...
	'debug_mode', false);

%% ====================
% 9.3.1 Collect event properties for plotting
entry = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
dis_spon = false; % true/false
screenEventProp = true;

modify_eventType_name = true; % true/false
[eventProp_all] = collect_event_prop(alignedData_allTrials, 'style', 'event'); % only use 'event' for 'style'

% modify the stimulation name in eventProp_all
cat_setting.cat_type = 'stim_name';
cat_setting.cat_names = {'opto', 'ap', 'opto-ap'};
cat_setting.cat_merge = {{'OG-LED-5s'}, {'GPIO-1-1s'}, {'OG-LED-5s GPIO-1-1s'}};
[eventProp_all] = mod_cat_name(eventProp_all,...
	'cat_setting',cat_setting,'dis_extra', false,'stimType',false);

% Rename stim name for opto if opto-5s exhibited excitation effect
if screenEventProp 
	tag_check = {'opto', 'opto-ap'};
	idx_check = cell(1, numel(tag_check));
	for n = 1:numel(tag_check)
		[~,idx_check{n}] = filter_structData(eventProp_all,'stim_name',tag_check{n},[]);
	end
	idxAll_check = [idx_check{:}];
	eventProp_check = eventProp_all(idxAll_check);
	eventProp_uncheck = eventProp_all;
	eventProp_uncheck(idxAll_check) = [];
	[~,idx_optoEx] = filter_structData(eventProp_check,'stimTrig',1,[]);
	cat_setting.cat_type = 'stim_name';
	cat_setting.cat_names = {'EXopto', 'EXopto-ap'};
	cat_setting.cat_merge = {{'opto'}, {'opto-ap'}};
	[eventProp_check(idx_optoEx)] = mod_cat_name(eventProp_check(idx_optoEx),...
		'cat_setting',cat_setting,'dis_extra', false,'stimType',false);
	eventProp_all = [eventProp_uncheck eventProp_check];
end

[eventProp_all_norm] = norm_eventProp_with_spon(eventProp_all,'entry',entry,'dis_spon',dis_spon);
% modify the peak category names
if modify_eventType_name % Note: when style is 'roi', there will be more data number, if noStim and interval are categorized as spon
	dis_extra = true;
	[eventProp_all_norm] = mod_cat_name(eventProp_all_norm,'dis_extra', dis_extra,'seperate_spon',true);
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

grouped_event_info_option.event_type = event_type;
grouped_event_info_option.traceData_type = traceData_type;
grouped_event_info_option.event_data_group = event_data_group;
grouped_event_info_option.event_filter = event_filter;
grouped_event_info_option.event_align_point = event_align_point;
grouped_event_info_option.cat_keywords = cat_keywords;

%% ====================
% screen groups based on tags
keywords = {'spon'}; % options: spon, trig, delay, rebound
k_num = numel(keywords);
group_num = numel(grouped_event_info);
% grouped_event_info = grouped_event_info_bk;
grouped_event_info_bk = grouped_event_info;
% 
disIdx = [];
for n = 1:group_num
	tag = grouped_event_info(n).tag;
	for kn = 1:k_num
		if find(strfind(tag, keywords{kn}))
			dis_tf = false;
			break
		else
			dis_tf = true;
		end
	end
	if dis_tf
		disIdx = [disIdx; n];
	end
end
grouped_event_info(disIdx) = [];

%% ====================
% 9.3.2 plot event properties
close all
plot_combined_data = true;
parNames = {'rise_duration','sponNorm_rise_duration','peak_mag_delta',...
	'sponNorm_peak_mag_delta','baseDiff','baseDiff_stimWin','val_rise','rise_delay'};
        % {'sponNorm_rise_duration', 'sponNorm_peak_delta_norm_hpstd', 'sponNorm_peak_slope_norm_hpstd'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
		% 'sponNorm_rise_duration', 'sponNorm_peak_mag_delta', 'sponNorm_peak_delta_norm_hpstd'
		% 'sponNorm_peak_slope', 'sponNorm_peak_slope_norm_hpstd'
save_fig = false; % true/false
save_dir = ins_analysis_ventral_fig_folder;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

% grouped_event_info = grouped_event_info_bk;
[save_dir, plot_info] = plot_event_info(grouped_event_info,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir~=0
	ins_analysis_ventral_fig_folder = save_dir;
end

if save_fig
	plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info.grouped_event_info = grouped_event_info;
	plot_stat_info.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
end
% bar_data.data can be used to run one-way anova. bar_stat contains results of anova and the following multi-comparison 



%% ====================
% 9.4.1 Collect spontaneous event properties for plotting
sortout_event = 'rise'; % options: 'rise', 'peak'
rebound_winT = 1;
stim_time_error = 0;
[spont_event_info] = get_spontaneous_event_info_alltrial(recdata_organized,...
	'sortout_event', sortout_event, 'rebound_winT', rebound_winT);

category_names = {'fovID'}; % options: 'fovID', 'stim_name', 'peak_category'
[grouped_spon_event_info, grouped_spon_event_opt] = group_event_info_multi_category(spont_event_info,...
	'category_names', category_names);

%% ====================
% 9.4.2 Plot spontaneous event properties
close all
plot_combined_data = true;
stat = true;
save_fig = true;
save_dir = ins_analysis_ventral_fig_folder;
[fig_dir, stat_info] = plot_spon_event_info(grouped_spon_event_info,...
	'plot_combined_data', plot_combined_data, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if fig_dir ~= 0
	ins_analysis_ventral_fig_folder = fig_dir;
end

%% ====================
% 9.5 Examine traces with plots. Center data to event starts or stimulation
% starts
close all
plot_combined_data = true;
plot_stim_shade = true;
save_fig = false; % true/false

if save_fig 
	save_dir = uigetdir(ins_analysis_ventral_fig_folder,...
		'Choose a folder to save plots');
	if save_dir == 0
		disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false')
		return
	else
		ins_analysis_ventral_fig_folder = save_dir;
    end
else
    save_dir = [];
end 

trial_num = numel(alignedData_allTrials);
for n = 1:trial_num
	plot_trace_trial(alignedData_allTrials(n),...
		'plot_combined_data', plot_combined_data, 'save_fig', save_fig, 'save_dir', save_dir);
end

%% ====================
% 9.6 Examine traces from a trial. group events from all ROIs
close all
save_fig = false; % true/false
save_dir = ins_analysis_ventral_fig_folder;
plot_combined_data = true;
plot_trace_allTrials(alignedData_allTrials,...
	'plot_combined_data', plot_combined_data, 'save_fig', save_fig, 'save_dir', save_dir);


%% ====================
% 10.1 Plot spontaneous events
[spont_event_info] = get_spontaneous_event_info_alltrial(recdata_organized); % get spon events from trials (events in the intervals of stimuli)

category_names = {'fovID'}; % Cell array used to group events. optional components: {'fovID','mouseID','stim'}
[grouped_event_info, grouped_event_info_option] = group_event_info_multi_category(spont_event_info, 'category_names', category_names); % group events

plot_combined_data = false;
save_fig = false;
save_dir = ins_analysis_ventral_fig_folder;
event_plot_dir = plot_event_info(grouped_event_info,...
	'plot_combined_data', plot_combined_data, 'save_fig', save_fig, 'save_dir', save_dir);
if ~isempty(event_plot_dir)
	ins_analysis_ventral_fig_folder = event_plot_dir;
end


%% ====================
% 11.1 opto inhibition analysis: ratio of event-freq (inside_stim-outside_stem)/outside_stem. box plot
% To use this section:
% 	- Prepare [recdata_organized] generated by step 8
%	- Prepare [alignedData_allTrials] generated by step 9.2 (fun: get_event_trace_allTrials)
%       - event_type = 'stimWin';
close all
save_fig = true; % true/false. save plot and calculation options
stat = true; % true/false. If run anova in boxPlot_with_scatter
stat_fig = false; % if plot anova analysis when using anova1 in boxPlot_with_scatter

stimFreq_win = [1 1.5]; % unit:s. if stim_duration is 5s, consider every stim is [0 5]. only use event during the stimFreq_win 
afterStim_exepWin = true; % true/false. use exemption win or not. if true, events in this win not counted as outside stim
exepWinDur = 1; % length of exemption window
stimStart_err = 0; % default=0. modify the start of the stim range, in case low sampling rate causes error
ratio_disp = 'log'; % log/zscore
[stimSponRall,stimSponR_opt] = stim_effect_compare_eventFreq_alltrial(recdata_organized,...
	'stimFreq_win', stimFreq_win, 'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
	'stimStart_err', stimStart_err, 'ratio_disp', ratio_disp); % collect events inside and outside the stim, and calculate their log ratio

stimMean_dur = [1 2]; % unit: s. duration of time to calculate the mean value of trace inside of stimulation
nonstimMean_dur = 2; % duration of time to calculate the mean value of trace outside of stimulation
stimMean_start_time = 'first'; % options: 'first', 'last'. start from stim start with stimMean_dur, 
								% or start from (stimDuration-stimMean_dur)
nonstimMean_pos = 'pre'; % options: 'pre', 'post', 'both'.
							% pre: [(0-nonstimMean_dur) : 0]
							% post: [stimDuration : (stimDuration+nonstimMean_dur)]  
							% both: pre and post
[traceMeanAll,traceMean_opt] = stim_effect_compare_trace_mean_alltrial(alignedData_allTrials,...
	'stimMean_dur', stimMean_dur, 'nonstimMean_dur', nonstimMean_dur,...
	'stimMean_start_time', stimMean_start_time, 'nonstimMean_pos', nonstimMean_pos);
% traceMeanAll calculated above will be used to group scatter plot data in boxPlot_with_scatter

% Plot data. Group data in the same trials
trialNum = numel(stimSponRall);
CellArrayData = cell(1, trialNum);
CellArrayData_traceMeanCom = cell(1, trialNum);
% CellArrayData_sponfq = cell(1, trialNum);
CellArrayData_traceDiff = cell(1, trialNum);
for ii = 1:trialNum
	CellArrayData{ii} = [stimSponRall(ii).FqRatio.Ratio_StimSpon]';
	CellArrayData_traceMeanCom{ii} = [traceMeanAll(ii).stat.h]';
	CellArrayData_traceDiff{ii} = [traceMeanAll(ii).stat.diff_zscore]';
end

groupNames = {stimSponRall.trialName}';
groupNames = cellfun(@(x) x(1:15), groupNames, 'UniformOutput',false); % only use the data and time info for group names
fovIDs = {stimSponRall.fovID}';
stimNames = {stimSponRall.stimName}';
groupNames = strcat(groupNames, '-', fovIDs, ' [', stimNames, ']');

[fig_boxPlot_freq] = boxPlot_with_scatter(CellArrayData,...
    'traceMeanCom', CellArrayData_traceMeanCom, 'groupNames', groupNames); % plot the log ratio in a box plot
set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.4 0.9])
titlestr = sprintf('Stimulation Effect');
title(gca, titlestr, 'Event frequency ratio');
xlabel(gca, 'trials');
ylabel(gca, '(insideStim-outsideStim)/outsideStim');

[fig_boxPlot_traceDiff] = boxPlot_with_scatter(CellArrayData_traceDiff,...
    'traceMeanCom', CellArrayData_traceMeanCom, 'groupNames', groupNames); 
set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.4 0.9])
title(gca, 'Diff of trace value');
xlabel(gca, 'trials');
ylabel(gca, '(insideStim-outsideStim)/outsideStimStd');


% Plot data. Group data using the same stimulation
stims_col_content = recdata_organized(:, 3);
stims = unique(stims_col_content);
stims_num = numel(stims);

groupMergeInfo = struct('groupName', cell(1, stims_num), 'trials', cell(1, stims_num));
CellArrayData_merge = cell(1, stims_num);
CellArrayData_traceMeanCom_merge = cell(1, stims_num);
CellArrayData_traceDiff_merge = cell(1, stims_num);
for n = 1:stims_num
	stim = stims{n};
	trials_idx = find(strcmp(stim, stims_col_content));
	groupMergeInfo(n).groupName = stim;
	groupMergeInfo(n).trials = recdata_organized(trials_idx, 1);

	CellArrayData_merge{n} = cat(1, CellArrayData{trials_idx});
	CellArrayData_traceMeanCom_merge{n} = cat(1, CellArrayData_traceMeanCom{trials_idx});
	CellArrayData_traceDiff_merge{n} = cat(1, CellArrayData_traceDiff{trials_idx});
end

groupNames_merge = stims;
[fig_boxPlot_freq_merge, stat_freq_merge] = boxPlot_with_scatter(CellArrayData_merge,...
    'traceMeanCom', CellArrayData_traceMeanCom_merge, 'groupNames', groupNames_merge,...
    'stat', stat); 
set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.3 0.9])
titlestr = sprintf('Stimulation Effect');
title(gca, titlestr, 'Event frequency ratio');
xlabel(gca, 'stimulations');
ylabel(gca, '(insideStim-outsideStim)/outsideStim');

[fig_boxPlot_traceDiff_merge, stat_traceDiff_merge] = boxPlot_with_scatter(CellArrayData_traceDiff_merge,...
    'traceMeanCom', CellArrayData_traceMeanCom_merge, 'groupNames', groupNames_merge,...
    'stat', stat); 
set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.3 0.9])
title(gca, 'Diff of trace value');
xlabel(gca, 'stimulations');
ylabel(gca, '(insideStim-outsideStim)/outsideStimStd');


% Save plots and settings
if save_fig
	fname_box_freq = [datestr(now, 'yyyymmdd'), '_boxPlot_freq'];
	[save_dir,plotName_boxPlot_freq] = savePlot(fig_boxPlot_freq,...
		'guiSave', 'on', 'save_dir', ins_analysis_ventral_fig_folder, 'fname', fname_box_freq);
	optFileName = fullfile(save_dir, [datestr(now, 'yyyymmdd'), '_stimEffectAnalysis_opt_stat.mat']);
	save(optFileName, 'stimSponR_opt', 'traceMean_opt', 'groupMergeInfo', 'stat_freq_merge', 'stat_traceDiff_merge');
	ins_analysis_ventral_fig_folder = save_dir;

	fname_box_traceDiff = [datestr(now, 'yyyymmdd'), '_boxPlot_traceDiff'];
	[save_dir, plotName_boxPlot_traceDiff] = savePlot(fig_boxPlot_traceDiff,...
		'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_box_traceDiff);

	fname_box_freq_merge = [datestr(now, 'yyyymmdd'), '_boxPlot_freq_merge'];
	[save_dir, plotName_boxPlot_freq_merge] = savePlot(fig_boxPlot_freq_merge,...
		'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_box_freq_merge);

	fname_box_traceDiff_merge = [datestr(now, 'yyyymmdd'), '_boxPlot_traceDiff_merge'];
	[save_dir, plotName_boxPlot_traceDiff_merge] = savePlot(fig_boxPlot_traceDiff_merge,...
		'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_box_traceDiff_merge);
end

% About the outliers in the box plot
% boxplot draws points as outliers if they are greater than q3 + w × (q3 – q1) or 
% less than q1 – w × (q3 – q1), where w is the maximum whisker length, 
% and q1 and q3 are the 25th and 75th percentiles of the sample data, respectively.

% The default value for 'Whisker' corresponds to approximately +/–2.7σ and 99.3 percent 
% coverage if the data are normally distributed. The plotted whisker extends to 
% the adjacent value, which is the most extreme data value that is not an outlier.

%% ====================
% 11.2 opto inhibition analysis: relationship of Freq_spon(inside_stim) and Freq_stim(outside_stem)
close all
save_fig = false; % true/false

xyLabel_1 = {'Freq stim (Hz)', 'Freq spon (Hz)'};
xyLabel_2 = {'Freq spon (Hz)', 'zscore of traceDiff'};
groupNames = {stimSponRall.trialName}';
groupNames = cellfun(@(x) x(1:15), groupNames, 'UniformOutput',false); % only use the data and time info for group names

trialNum = numel(stimSponRall);
freqDataSpon = cell(1, trialNum);
freqDataStim = cell(1, trialNum);
traceDiffData = cell(1, trialNum);
for ii = 1:trialNum
	freqDataSpon{ii} = [stimSponRall(ii).FqRatio.sponfq]';
	freqDataStim{ii} = [stimSponRall(ii).FqRatio.stimfq]';
	traceDiffData{ii} = [traceMeanAll(ii).stat.diff_zscore]'; % zscore of mean trace diff
end

[fig_freq] = scatterPlot_groups(freqDataStim, freqDataSpon,...
	'xyLabel', xyLabel_1, 'groupNames', groupNames);

[fig_sponFreq_traceDiff] = scatterPlot_groups(freqDataSpon, traceDiffData,...
	'xyLabel', xyLabel_2, 'groupNames', groupNames, 'PlotXYlinear', false);

if save_fig
	fname_freq = [datestr(now, 'yyyymmdd_HHMMSS'), '_freq_relation'];
	[save_dir,plotName_1] = savePlot(fig_freq,...
		'guiSave', 'on', 'save_dir', ins_analysis_ventral_fig_folder, 'fname', fname_freq);

	ins_analysis_ventral_fig_folder = save_dir;

	fname_sponFreq_traceDiff = [datestr(now, 'yyyymmdd_HHMMSS'), '_sponFreq_traceDiff'];
	[save_dir,plotName_2] = savePlot(fig_sponFreq_traceDiff,...
		'guiSave', 'on', 'save_dir', ins_analysis_ventral_fig_folder, 'fname', fname_sponFreq_traceDiff);
	% optFileName = fullfile(save_dir, [plot_name, '_stimEffectScatter_opt']);
	% save(optFileName, 'stimSponR_opt', 'traceMean_opt');
	
end


%% ====================
% 12.1 Prepare series data for analysis (trials taken at the same FOV from the same animal, but with different stimuli)
%	- series tiff files should be carefully cropped to have the same view and process the same x, y size
%	- CNMFe process all the tiff files: use the fun [cnmfe_process_series_cluster] packed to the [batch_series_cnmfe_process.slurm.sh]
%	- Continue the workflow from step 5 to 8
recdata_series = recdata_organized;
[recdata_series_sync] = discard_empty_roi_series(recdata_series); % delete ROIs without events
recdata_organized = recdata_series_sync;
% Continue with analysis steps (9 - 11)

%% ====================
% 12.1.2 Discard ROIs if they do not have specified event type when certain stimualtion was applied
eventTypes = 'trigger'; % Find event categories with func "[event_category_str] = event_category_names"
stimName = 'GPIO-1-1s'; % 'OG-LED-5s', 'GPIO-1-1s', 'OG-LED-5s GPIO-1-1s'
series_trials = true; % true/false. delete ROI in the trials from the same series

recdata_bk = recdata_organized;
[recdata_organized] = discard_stim_silent_roi(recdata_organized,stimName,...
	'eventTypes', eventTypes, 'stimName', stimName, 'series_trials', series_trials);


%% ====================
% 12.2 Examine the zscore of trace level during stimulation
% For series recordings: same FOV, different stimuli
% Before running this section, prepare recdata_organized, and alignedData_allTrials (from 9.2)
trace_length = 1; % unit: s. Length of trace used for calculating
nonstimMean_dur = 2; % duration of time to calculate the mean value of trace outside of stimulation
stimMean_start_time = 'first'; % options: 'first', 'last'. start from stim start with stimMean_dur, 
								% or start from (stimDuration-stimMean_dur)
nonstimMean_pos = 'pre'; % options: 'pre', 'post', 'both'.
							% pre: [(0-nonstimMean_dur) : 0]
							% post: [stimDuration : (stimDuration+nonstimMean_dur)]  
							% both: pre and post


[sNum,sTrialIDX] = get_series_trials(recdata_organized);
series_secT_cell = cell(sNum, 1);

for sn = 1:sNum
	trial_idx = find(sTrialIDX==sn); % index of trials belongs to series[sn]
	sTrialNum = numel(trial_idx);
	seriesData = recdata_organized(trial_idx, :);
	seriesAlignedData = alignedData_allTrials(trial_idx);

	trial_sRange = NaN(sTrialNum, 2);
	trial_sDuration = NaN(sTrialNum, 1);
	traceSectionRanges = cell(1, sTrialNum);
	secNum = NaN(1, sTrialNum);

	series_struct = struct('trialName', cell(1, sTrialNum), 'fovID', cell(1, sTrialNum),...
		'stimName', cell(1, sTrialNum));
	for tn = 1:sTrialNum
		series_struct(tn).trialName = seriesAlignedData(tn).trialName(1:15);
		series_struct(tn).fovID = seriesAlignedData(tn).fovID;
		series_struct(tn).stimName = seriesAlignedData(tn).stim_name;

		stimInfo = seriesAlignedData(tn).stimInfo;
		stim_num = numel(stimInfo);
		stimInfo_duration = [stimInfo.duration_sec];
		[~, idx_longStim] = max(stimInfo_duration);
		trial_sRange(tn, :) = stimInfo(idx_longStim).time_range;
		trial_sDuration(tn) = stimInfo(idx_longStim).duration_sec;

		if trial_sDuration(tn) <= trace_length
			% traceSectionRanges{tn} = trial_sDuration(tn);
			secNum(tn) = 1;
		else
			secNum(tn) = ceil(trial_sDuration(tn)/trace_length);
			traceSectionRanges{tn} = NaN(secNum(tn), 2);
		end
		trial_struct = struct('traceMeanAll', cell(1, secNum(tn)), 'traceMean_opt', cell(1, secNum(tn)),...
			'section_range', cell(1, secNum(tn)));
		for secn = 1:secNum(tn)
			if secn == 1
				traceSectionRanges{tn}(secn, 1) = trial_sRange(tn, 1);
			else
				traceSectionRanges{tn}(secn, 1) = (secn-1)*trace_length;
			end

			if secn == secNum(tn)
				traceSectionRanges{tn}(secn, 2) = trial_sRange(tn, 2);
			else
				traceSectionRanges{tn}(secn, 2) = secn*trace_length;
			end

			[trial_struct(secn).traceMeanAll,trial_struct(secn).traceMean_opt] = stim_effect_compare_trace_mean_alltrial(seriesAlignedData(tn),...
				'stimMean_dur', traceSectionRanges{tn}(secn, :), 'nonstimMean_dur', nonstimMean_dur,...
				'stimMean_start_time', stimMean_start_time, 'nonstimMean_pos', nonstimMean_pos);
			% trial_struct(secn).section_range = traceSectionRanges{tn}(secn, :);
			trial_struct(secn).traceMeanAll.section_range = traceSectionRanges{tn}(secn, :);
		end
		traceMeanAll = [trial_struct.traceMeanAll];
		traceMean_opt = [trial_struct.traceMean_opt];
		% trial_struct(secn).section_range = traceSectionRanges{tn};
		series_struct(tn).traceMeanAll = traceMeanAll;
		series_struct(tn).traceMean_opt = traceMean_opt;
	end
	series_secT_cell{sn} = series_struct;
end

%% ====================
% 12.3 plot boxplot using data from "series_secT_cell"
close all
save_fig = true; % true/false. save plot and calculation options
seriesNum = numel(series_secT_cell); % number of series. This will be the number of figures
statData = cell(seriesNum, 1); % cell used to store analysis results

for sn = 1:seriesNum
	trialNum = numel(series_secT_cell{sn}); % number of trials in a series.

	trialStruct = struct('trialNames', cell(1, trialNum), 'stimNames', cell(1, trialNum), 'fovID', cell(1, trialNum),...
		'secCell', cell(1, trialNum), 'secComCell', cell(1, trialNum), 'secNames', cell(1, trialNum),...
		'rmanova', cell(1, trialNum), 'pValueGG', cell(1, trialNum), 'multiCom', cell(1, trialNum));
	for tn = 1:trialNum
		trialTraceMean = series_secT_cell{sn}(tn).traceMeanAll;
		secNum = numel(trialTraceMean);
		secCell = cell(1, secNum);
		secNames = cell(secNum, 1);
		for ii = 1:secNum
			secCell{ii} = [trialTraceMean(ii).stat.diff_zscore]';
			secComCell{ii} = [trialTraceMean(ii).stat.h]';
			secRange = trialTraceMean(ii).section_range;
			secNames{ii} = sprintf('%g - %g s', secRange(1), secRange(2));
		end
		trialStruct(tn).secCell = secCell;
		trialStruct(tn).secNames = secNames;
		trialStruct(tn).trialNames = series_secT_cell{sn}(tn).trialName;
		trialStruct(tn).stimNames = series_secT_cell{sn}(tn).stimName;
		trialStruct(tn).fovID = series_secT_cell{sn}(tn).fovID;

		% rmANOVA
		if secNum > 1
			repeatedMeasures = [trialStruct(tn).secCell{:}];
			[trialStruct(tn).ranovatbl,trialStruct(tn).pvalueGG,trialStruct(tn).h,trialStruct(tn).pairedttesttbl] = rmanova_pairedttest(repeatedMeasures);
		else
			trialStruct(tn).ranovatbl = [];
			trialStruct(tn).pvalueGG = [];
			trialStruct(tn).h = [];
			trialStruct(tn).pairedttesttbl = [];
		end
	end
	statData{sn} = trialStruct;

	f(sn) = figure;
	set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.2 0.9])
	% set(gcf, 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.2])
	% tlo = tiledlayout(f(sn), trialNum, 1);
	tlo = tiledlayout(f(sn), 1, trialNum);

	for ii = 1:trialNum
		ax = nexttile(tlo);
		boxPlot_with_scatter(trialStruct(ii).secCell,...
		    'plotWhere', ax,...
		    'traceMeanCom', trialStruct(ii).secCell, 'groupNames', trialStruct(ii).secNames);
		titleStr = sprintf('%s \n[%s] [%s]', trialStruct(ii).trialNames, trialStruct(ii).fovID, trialStruct(ii).stimNames); 
		title([titleStr])
		% if ii == 1
		% 	yl = ylim;
		% else
		% 	ylim(yl)
		% end

		ylim([-4 8])
	end
end

if save_fig
	fname_stem = [datestr(now, 'yyyymmdd'), '_boxPlot_time_sections_traceDiff_series'];
	fname_stem = sprintf('%s_boxPlot_time_sections_%gs_traceDiff_series', datestr(now, 'yyyymmdd'), trace_length);
	for pn = 1:seriesNum
		fname = sprintf('%s_%d', fname_stem, pn);
		if pn == 1
			guiSave = 'on';
			save_dir = ins_analysis_ventral_fig_folder;
		else
			guiSave = 'off';
		end
		[save_dir,plotName_boxPlot_freq] = savePlot(f(pn),...
			'guiSave', guiSave, 'save_dir', save_dir, 'fname', fname);
	end
	% matfilePath = fullfile(save_dir, [datestr(now, 'yyyymmdd'), '_series_secT_cell']);
	matfilePath = fullfile(save_dir, sprintf('%s_series_secT_cell_%gs.mat', datestr(now, 'yyyymmdd'), trace_length));
	save(matfilePath, 'series_secT_cell', 'statData');
	ins_analysis_ventral_fig_folder = save_dir;
end