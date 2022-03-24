% This script is used on office local desktop running windows 10
% Use this script after exporting motion corrected files with tiff format. 
% Process files with CNMFe with cluster. And then come back for further analysis
	% Inscopix API related process, such as spatial filter and motion correction cannot be run on VDI. 
	% CNMFe can be run here alternatively, but deigo cluster is way faster
% All files are stored on bucket

% This workflow script is modified from "workflow_ventral_approach_analysis"
% 2022.03.18 Some sections are deleted. Some are reorganized to facilitate the workflow

%% ====================
% set folders for different situation
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
vis = 'on'; % on/off. set the 'visible' of figures
decon = true; % true/false plot decon trace
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
debug_mode = false; % true/false
recdata_organized_bk = recdata_organized;
[recdata_organized] = discard_recData_roi(recdata_organized,'stims',stims,'eventCats',eventCats,'debug_mode',debug_mode);
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
stim_time_error = 0.1; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
mod_pcn = true; % true/false modify the peak category names with func [mod_cat_name]
% filter_alignedData = true; % true/false. Discard ROIs/neurons in alignedData if they don't have certain event types
debug_mode = false; % true/false

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', event_type,...
	'traceData_type', traceData_type, 'event_data_group', event_data_group,...
	'event_filter', event_filter, 'event_align_point', event_align_point, 'cat_keywords', cat_keywords,...
	'pre_event_time', pre_event_time, 'post_event_time', post_event_time,...
	'stim_time_error',stim_time_error,'mod_pcn', mod_pcn,'debug_mode',false);

%% ====================
% 9.2.0.1 Check trace aligned to stim window
% note: 'event_type' for alignedData_allTrials must be 'stimWin'
plot_combined_data = true;
plot_stim_shade = true;
y_range = [-20 30];
stimEffectType = 'excitation'; % options: 'excitation', 'inhibition', 'rebound'
fHandle_stimAlignedTrace = plot_stimAlignedTraces(alignedData_allTrials,...
	'plot_combined_data',plot_combined_data,'plot_stim_shade',plot_stim_shade,'y_range',y_range,'stimEffectType',stimEffectType);

%% ====================
% 9.3 Collect event properties from alignedData_allTrials
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
save_dir = ins_analysis_ventral_fig_folder;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

[save_dir_event, plot_info_event] = plot_event_info(grouped_spon_event_info,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames_event, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir_event~=0
	ins_analysis_ventral_fig_folder = save_dir_event;
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
save_dir = ins_analysis_ventral_fig_folder;
stat = true; % true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not
[save_dir_roi, plot_info_roi] = plot_event_info(grouped_spon_roi_info,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames_roi, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
if save_dir_roi~=0
	ins_analysis_ventral_fig_folder = save_dir_roi;
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
% Rename stim name for opto if opto-5s exhibited excitation effect
seperate_spon = true; % true/false. Whether to seperated spon according to stimualtion
if screenEventProp 
	tag_check = {'opto', 'opto-ap'};
	idx_check = cell(1, numel(tag_check));
	for n = 1:numel(tag_check)
		[~,idx_check{n}] = filter_structData(eventProp_all,'stim_name',tag_check{n},[]); % accquire the idx of all opto-trial events
	end
	idxAll_check = [idx_check{:}];
	eventProp_check = eventProp_all(idxAll_check);
	eventProp_uncheck = eventProp_all;
	eventProp_uncheck(idxAll_check) = [];
	[~,idx_optoEx] = filter_structData(eventProp_check,'stimTrig',1,[]); % accquire the idx of opto triggered events
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
strCells = {'spon', 'trig', 'rebound', 'delay'};
strCells_plus = {'ap', 'EXopto'};
[grouped_event_info] = sort_struct_with_str(grouped_event_info,'group',strCells,'strCells_plus',strCells_plus);

grouped_event_info_option.event_type = event_type;
grouped_event_info_option.traceData_type = traceData_type;
grouped_event_info_option.event_data_group = event_data_group;
grouped_event_info_option.event_filter = event_filter;
grouped_event_info_option.event_align_point = event_align_point;
grouped_event_info_option.cat_keywords = cat_keywords;

%% ====================
% 9.5.1.2 screen groups based on tags. Delete unwanted groups
keywords = {'spon', 'trig', 'delay', 'rebound'}; % Keep groups with these words. options: spon, trig, delay, rebound
k_num = numel(keywords);
group_num = numel(grouped_event_info);
% grouped_event_info = grouped_event_info_bk;
grouped_event_info_bk = grouped_event_info;
% 
disIdx = [];
for n = 1:group_num
    % fprintf('n=%d\n', n)
    % if n==7
    % 	pause
    % end
	group = grouped_event_info(n).group;
	for kn = 1:k_num
		% fprintf(' kn=%d\n', kn)
		% discard 'opto-delay [ap]' and 'rebound [ap]' 
		if ~isempty(strfind(group, 'ap')) 
			if ~isempty(strfind(group, 'delay')) || ~isempty(strfind(group, 'rebound'))
				dis_tf = true;
				break
			end
		end

		if ~isempty(strfind(group, keywords{kn}))
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
% 9.5.2 Plot event parameters. Grouped according to categories
close all
plot_combined_data = true;
parNames = {'rise_duration','sponNorm_rise_duration','peak_mag_delta',...
	'sponNorm_peak_mag_delta','baseDiff','baseDiff_stimWin','val_rise','rise_delay'};
        % {'sponNorm_rise_duration', 'sponNorm_peak_delta_norm_hpstd', 'sponNorm_peak_slope_norm_hpstd'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
		% 'sponNorm_rise_duration', 'sponNorm_peak_mag_delta', 'sponNorm_peak_delta_norm_hpstd'
		% 'sponNorm_peak_slope', 'sponNorm_peak_slope_norm_hpstd'
save_fig = true; % true/false
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
	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
	plot_stat_info.grouped_event_info = grouped_event_info;
	plot_stat_info.plot_info = plot_info;
	dt = datestr(now, 'yyyymmdd');
	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
end
% bar_data.data can be used to run one-way anova. bar_stat contains results of anova and the following multi-comparison 

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
	fname = 'opto_inhibition_effect';
	[save_dir] = savePlot(gcf, 'guiSave', 'on', 'save_dir', ins_analysis_ventral_fig_folder, 'fname', fname);
	if save_dir~=0
		ins_analysis_ventral_fig_folder = save_dir;
	end
end

%% ====================
% 9.2.0.3 Plot traces, aligned traces and roi map
close all
save_fig = true; % true/false
if save_fig
	save_dir = uigetdir(ins_analysis_ventral_fig_folder,'Choose a folder to save plots');
	if save_dir~=0
		ins_analysis_ventral_fig_folder = save_dir;
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











