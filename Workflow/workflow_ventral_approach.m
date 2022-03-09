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
% 2. Crop, spatial filter, and motion corrected recordings with Inscopix API for matlab. And export them in tiff format.
% 	Export gpio (stimulation) and recording time stamp information in csv format with IDPS

% This step can be only done on local desktop installed IDPS

% Process all raw recording files in the same folder.
% This is designed for the output of nVoke2
recording_dir = uigetdir(ins_recordings_folder,...
	'Select a folder containing raw recording files (.isxd) and gpio files (.gpio)');
if recording_dir ~= 0
	ins_recordings_folder = recording_dir;
	project_dir = uigetdir(ins_projects_folder,...
		'Select a folder to save processed recording files (PP, BP, MC, DFF)');
	if project_dir ~= 0 
		ins_projects_folder = project_dir;
		process_nvoke_files(recording_dir, 'project_dir',project_dir);
	end
end

% 2.1. If recordings were created by the nVoke1 system. Use following line instead
% nvoke_file_process;


%% ==================== 
% 3.1 Export nvoke movies to tiff files
keywords = '2021-09-30*-MC.isxd'; % used to filter 
overwrite = false;

input_isxd_folder = uigetdir(project_dir,...
	'Select a folder (project folder) containing processed recording files (.isxd)');
if input_isxd_folder ~= 0
	project_dir = input_isxd_folder;
	output_tiff_folder = uigetdir(ins_tiff_folder,...
		'Select a folder to save the exported tiff files');
	if output_tiff_folder ~= 0
		ins_tiff_folder = output_tiff_folder;
		export_nvoke_movie_to_tiff(input_isxd_folder, output_tiff_folder,...
			'keyword', keywords, 'overwrite', overwrite);
	end
end

%% ==================== 
% 3.2 make subfolders for each tiff file with their date and time information for following CNMFe process
key_string = 'video'; % Key_string is used to locate the end of string used for nameing subfolder
num_idx_correct = -2; % key_string idx + num_idx_correct = idx of the end of string for subfolder name

organize_folder = uigetdir(ins_tiff_invivo_folder,...
	'Select a folder containing exported tiff files');
if organize_folder ~= 0
	ins_tiff_invivo_folder = organize_folder;
	organize_exported_tiff_files(organize_folder,...
		'key_string', key_string, 'num_idx_correct', num_idx_correct);
else
	disp('Folder not selected')
	return
end


%% ==================== 
% 3.3 Remove cnmfe generated files for a new process
dir_path_clear = ins_tiff_folder;
keywords_file = {'*contours*', '*results.mat'};
keywords_dir = {'*source_extraction*'};

dir_path_clear = uigetdir(ins_tiff_folder,...
	'Warning: about to delete objects in the subfolders!');
if dir_path_clear ~= 0
	ins_tiff_folder = dir_path_clear;

	rm_subdir_files('dir_path', dir_path_clear,...
		'keywords_file', keywords_file, 'keywords_dir', keywords_dir);
else
	fprintf('folder not selected')
	return
end



%% ==================== 
% Better use deigo cluster for this step. Prepare files in the bucket for tranfering them to deigo
% 4. Process recordings with CNMFe to extract ROI traces
% NOTE: This step can be done with VDI, but it is way slower than deigo cluster
organized_tiff_folder = ins_tiff_invivo_folder; % This is a parent folder. Each recording has its own subfolder
Fs = 20; % Hz. recording frequency
cnmfe_process_batch('folder',  organized_tiff_folder, 'Fs', Fs);




%% ==================== 
% Write code with inscopix matlab API to simplify this step
% 5. Copy *results.mat, *gpio.csv, and *ROI.csv files in each subfolders to another folder
% So recording information in each subfolder can be integrated into a single mat file later。
% Export *gpio.csv and *ROI.csv from Inscopix Data processing (ISDP) software
input_folder = uigetdir(ins_tiff_invivo_folder,...
	'Select a folder containing processed recording files organized in subfolders');
if input_folder ~= 0
	ins_tiff_invivo_folder = input_folder;
else
	disp('Input folder not selected')
	return
end

output_folder = uigetdir(ins_cnmfe_result_folder,...
	'Select a folder to save *results.mat, *gpio.csv, and *ROI.csv files from subfolders of input location');
if output_folder ~= 0
	ins_cnmfe_result_folder = output_folder;
else
	disp('Output folder not selected')
	return
end

[not_organized_recordings] = organize_processed_files(input_folder, output_folder);





%% ====================
% 6.1 Convert ROI info to matlab file (.m). 
% Place results.m from CNMFe, ROI info (csv files) and GPIO info (csv) from IDPS to the same folder, and run this
% function
% [ROIdata, recording_num, cell_num] = ROIinfo2matlab; % for data without CNMFe process
input_dir = ins_cnmfe_result_folder;
output_dir = ins_analysis_ventral_folder;

[recdata, recording_num, cell_num] = ROI_matinfo2matlab('input_dir', input_dir,...
	'output_dir', output_dir); % for CNMFe processed data


% Check the gpio channel information and delete the false stimulation channels. 
% nVoke2 generated gpio may include channel activity from unsed channels
rec_num = size(recdata, 1);
for i = 1:rec_num
	gpio_info = recdata{i, 4};

	% Check and delete the false gpio channels
	[gpio_info] = delete_false_gpio_info(gpio_info);

	recdata{i, 4} = gpio_info;
end


%% ====================
% 6.2 If trials are from nvoke2, expecially when they are mixed with nvoke1 data. rename the nvoke 2 trials
recdata_backup = recdata;
[recdata] = renameFileNamesInROI(recdata);

%% ====================
% 6.3 Save recdata before applying further processes
uisave('recdata', fullfile(ins_analysis_ventral_folder, 'recdata'));


%% ====================
% 8. Organize peaks and gpio information to data
clear opt
% Defaults
opt.lowpass_fpass = 1;
opt.highpass_fpass = 4;   
opt.smooth_method = 'loess';
opt.smooth_span = 0.1;
opt.prominence_factor = 4; % prominence_factor doesn't influence peak finding in decon data
opt.existing_peak_duration_extension_time_pre  = 0; % duration in second, before existing peak rise 
opt.existing_peak_duration_extension_time_post = 1; % duration in second, after decay
opt.criteria_rise_time = [0 2]; % unit: second. filter to keep peaks with rise time in the range of [min max]
opt.criteria_slope = [3 1000]; % default: slice-[50 2000]
							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
							% ventral approach default: [3 80]
							% slice default: [50 2000]
% criteria_mag = 3; % default: 3. peak_mag_normhp
opt.criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
opt.criteria_excitated = 2; % If a peak starts to rise in 2 sec since stimuli, it's a excitated peak
opt.criteria_rebound = 1; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end
opt.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
% use_criteria = true; % true or false. choose to use criteria or not for picking peaks
opt.stim_pre_time = 10; % time (s) before stimuli start
opt.stim_post_time = 10; % time (s) after stimuli end
opt.merge_peaks = true;
opt.merge_time_interval = 0.5; % default: 0.5s. peak to peak interval.
opt.discard_noisy_roi = false;
opt.std_fold = 10; % used as criteria to discard noisy_rois
plot_traces = 0; % 0: do not plot. 1: plot. 2: plot with pause
save_traces = 0; % 0: do not save. 1: save
[recdata_organized] = organize_add_peak_gpio_to_recdata(recdata,...
	'lowpass_fpass', opt.lowpass_fpass, 'highpass_fpass', opt.highpass_fpass,...
	'smooth_method', opt.smooth_method, 'smooth_span', opt.smooth_span,...
	'prominence_factor', opt.prominence_factor,...
	'existing_peak_duration_extension_time_pre', opt.existing_peak_duration_extension_time_pre,...
	'existing_peak_duration_extension_time_post', opt.existing_peak_duration_extension_time_post,...
	'criteria_rise_time', opt.criteria_rise_time, 'criteria_slope', opt.criteria_slope, 'criteria_pnr', opt.criteria_pnr,...
	'criteria_excitated', opt.criteria_excitated, 'criteria_rebound', opt.criteria_rebound,...
	'stim_time_error', opt.stim_time_error, 'stim_pre_time', opt.stim_pre_time, 'stim_post_time', opt.stim_post_time,...
	'merge_peaks', opt.merge_peaks, 'merge_time_interval', opt.merge_time_interval,...
	'discard_noisy_roi', opt.discard_noisy_roi, 'std_fold', opt.std_fold,...
	'plot_traces', plot_traces, 'save_traces', save_traces); 


%% ====================
% 8.1.1 Copy the FOV_loc struct-field from a sourceData, if exists, to a newly formed recdata_organized
recdata_target = recdata_organized_new;
recdata_source = recdata_organized;

[recdata_target_with_fov,trial_list_wo_fov] = copy_fovInfo(recdata_source,recdata_target);


%% ====================
% 8.1.2 Add FOV location information in second column of recdata
% chrimsonR-pos vs neg, lateral vs medial, posterior vs anterior vs intermediate
loc_opt.hemi = {'left', 'right'}; % hemisphere: IO with chrimsonR (pos) or without (neg)
loc_opt.hemi_ext = {'chR-pos', 'chR-neg'}; % hemisphere: IO with chrimsonR (pos) or without (neg)
loc_opt.ml = {'medial', 'lateral'}; % medial lateral
loc_opt.ap = {'anterior', 'intermediate', 'posterior'}; % anterior poterior. intermediate is not well defined in the experiment
modify_info = 'no'; % yes, no or ask. modify the FOV location information if it exists

fov_info_col = 2;

% recordings = recdata_group.all;
recordings = recdata_organized;
rec_num = size(recordings, 1);

nrec = 1;
while nrec <= rec_num
	fprintf('- %d/%d ', nrec, rec_num);
	single_recording = recordings(nrec, :);
	[~, FOV_loc] = organize_add_fov_loc_info(single_recording, 'loc_opt', loc_opt, 'modify_info', modify_info);
	recordings{nrec, fov_info_col}.FOV_loc = FOV_loc;
	direct_input = input(sprintf('\n(c)continue, (r)re-input or (b)go back to previous one? [default-c]\n'), 's');
	if isempty(direct_input)
		direct_input = 'c';
	end
	if strcmpi(direct_input, 'c')
	    nrec = nrec+1; 
	elseif strcmpi(direct_input, 'r')
	    nrec = nrec; 
	elseif strcmpi(direct_input, 'b')
	    nrec = nrec-1; 
	end
end



%% ====================
% 8.2 Generate mouseID and fovID base on recording date from trial names and FOV_loc in recording data 
% 
% Add FOV category code to FOV_loc
% [recdata_organized] = add_fov_category(recdata_organized,...
% 	'hemi_sort', hemi_sort, 'fov_contents', fov_contents);
overwrite = true; %options: true/false
[recdata_organized,mouseIDs,fovIDs] = auto_gen_mouseID_fovID(recdata_organized,'overwrite',overwrite);



%% ====================
% 8.3 Group recordings according to stimulation and save vars 'recdata_group' and 'opt'
% stim_types = {'GPIO-1-1s', 'OG-LED-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
% stim_types = unique(cellfun(@(x) char(x), recdata_organized(:,3), 'UniformOutput',false));
group_info = organize_rec_group_info(recdata_organized);
stim_types = {group_info.name};
recdata_group.all = recdata_organized;

for gn = 1:numel(group_info)
	fieldName = strrep(group_info(gn).name, '-', '_');
	fieldName = strrep(fieldName, ' ', '_');
	recdata_group.(fieldName) = recdata_organized(group_info(gn).idx, :);

end


% Save organized and calculate data 
data_fullpath = fullfile(ins_analysis_ventral_folder, '*.mat');
[data_filename, ins_analysis_ventral_folder] = uiputfile(data_fullpath,...
            'Select a folder to save data');
if isequal(data_filename, 0)
	disp('User selected Cancel')
else
	data_fullpath = fullfile(ins_analysis_ventral_folder, data_filename);
	disp(['User selected ', data_fullpath]);
	% save(data_fullpath, 'recdata_organized', 'opt')
	save(data_fullpath, 'recdata_group', 'opt')
end


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
% 9.2 Align traces from all trials. Also collect the properties of events
event_type = 'detected_events'; % options: 'detected_events', 'stimWin'
traceData_type = 'lowpass'; % options: 'lowpass', 'raw', 'smoothed'
event_data_group = 'peak_lowpass';
event_filter = 'none'; % options are: 'none', 'timeWin', 'event_cat'(cat_keywords is needed)
event_align_point = 'rise';
cat_keywords ={}; % options: {}, {'noStim', 'beforeStim', 'interval', 'trigger', 'delay', 'rebound'}
%					find a way to combine categories, such as 'nostim' and 'nostimfar'
pre_event_time = 5; % unit: s. event trace starts at 1s before event onset
post_event_time = 5; % unit: s. event trace ends at 2s after event onset

[alignedData_allTrials] = get_event_trace_allTrials(recdata_organized,'event_type', event_type,...
	'traceData_type', traceData_type, 'event_data_group', event_data_group,...
	'event_filter', event_filter, 'event_align_point', event_align_point, 'cat_keywords', cat_keywords,...
	'pre_event_time', pre_event_time, 'post_event_time', post_event_time);


%% ====================
% 9.3.1 Collect event properties for plotting
style = 'event'; % options: 'roi' or 'event'
                % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                % 'event': events are seperated (struct length = events_num). mean values were not calculated
modify_eventType_name = true; % true/false. Set it to off if 'style' is 'roi';
[eventProp_all] = collect_event_prop(alignedData_allTrials, 'style', style);
if modify_eventType_name
	dis_extra = true;
	[eventProp_all] = mod_cat_name(eventProp_all,'dis_extra', dis_extra);
end

category_names = {'fovID','peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'
[grouped_event_info, grouped_event_info_option] = group_event_info_multi_category(eventProp_all,...
	'category_names', category_names);
grouped_event_info_option.event_type = event_type;
grouped_event_info_option.traceData_type = traceData_type;
grouped_event_info_option.event_data_group = event_data_group;
grouped_event_info_option.event_filter = event_filter;
grouped_event_info_option.event_align_point = event_align_point;
grouped_event_info_option.cat_keywords = cat_keywords;

%% ====================
% 9.3.2 plot event properties
close all
plot_combined_data = true;
parNames = {'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'}; 
		% % options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
save_fig = false; % true/false
save_dir = ins_analysis_ventral_fig_folder;
stat = true; % true/false. true if want to run anova when plotting bars
stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

[save_dir, plot_info] = plot_event_info(grouped_event_info,...
	'plot_combined_data', plot_combined_data, 'parNames', parNames, 'stat', stat,...
	'save_fig', save_fig, 'save_dir', save_dir);
ins_analysis_ventral_fig_folder = save_dir;

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
plot_combined_data = true;
plot_stim_shade = true;
save_fig = true; % true/false

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
ins_analysis_ventral_fig_folder=plot_trace_allTrials(alignedData_allTrials,...
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
close all
save_fig = true; % true/false. save plot and calculation options

afterStim_exepWin = true; % true/false. use exemption win or not. if true, events in this win not counted as outside stim
exepWinDur = 1; % length of exemption window
stimStart_err = 0; % default=0. modify the start of the stim range, in case low sampling rate causes error
[stimSponRall,stimSponR_opt] = stim_effect_compare_eventFreq_alltrial(recdata_organized,...
	'afterStim_exepWin', afterStim_exepWin, 'exepWinDur', exepWinDur,...
	'stimStart_err', stimStart_err); % collect events inside and outside the stim, and calculate their log ratio

stimMean_dur = [2 3]; % unit: s. duration of time to calculate the mean value of trace inside of stimulation
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
	CellArrayData{ii} = [stimSponRall(ii).FqRatio.Ratio_zscore_StimSpon]';
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
    'traceMeanCom', CellArrayData_traceMeanCom, 'groupNames', groupNames); % plot the log ratio in a box plot
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
[fig_boxPlot_freq_merge] = boxPlot_with_scatter(CellArrayData_merge,...
    'traceMeanCom', CellArrayData_traceMeanCom_merge, 'groupNames', groupNames_merge); % plot the log ratio in a box plot
set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.3 0.9])
titlestr = sprintf('Stimulation Effect');
title(gca, titlestr, 'Event frequency ratio');
xlabel(gca, 'stimulations');
ylabel(gca, '(insideStim-outsideStim)/outsideStim');

[fig_boxPlot_traceDiff_merge] = boxPlot_with_scatter(CellArrayData_traceDiff_merge,...
    'traceMeanCom', CellArrayData_traceMeanCom_merge, 'groupNames', groupNames_merge); % plot the log ratio in a box plot
set(gcf, 'Units', 'normalized', 'Position', [0.1 0 0.3 0.9])
title(gca, 'Diff of trace value');
xlabel(gca, 'stimulations');
ylabel(gca, '(insideStim-outsideStim)/outsideStimStd');


% Save plots and settings
if save_fig
	fname_box_freq = [datestr(now, 'yyyymmdd'), '_boxPlot_freq'];
	[save_dir,plotName_boxPlot_freq] = savePlot(fig_boxPlot_freq,...
		'guiSave', 'on', 'save_dir', ins_analysis_ventral_fig_folder, 'fname', fname_box_freq);
	optFileName = fullfile(save_dir, [datestr(now, 'yyyymmdd'), '_stimEffectAnalysis_opt']);
	save(optFileName, 'stimSponR_opt', 'traceMean_opt', 'groupMergeInfo');
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
