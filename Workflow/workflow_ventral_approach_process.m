% This script is used on office local desktop running windows 10
% Use this script after exporting motion corrected files with tiff format. 
% Process files with CNMFe with cluster. And then come back for further analysis
	% Inscopix API related process, such as spatial filter and motion correction cannot be run on VDI. 
	% CNMFe can be run here alternatively, but deigo cluster is way faster
% All files are stored on bucket


% % 1. set folders for different situation
% inscopix_folder = 'G:\Workspace\Inscopix_Seagate';

% % ins_analysis_folder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
% ins_analysis_folder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop

% ins_projects_folder = fullfile(inscopix_folder, 'Projects'); % processed imaging data, including isxd, gpio, tiff, and csv files 
% ins_recordings_folder = fullfile(inscopix_folder, 'recordings'); % processed imaging data, including isxd, gpio, tiff, and csv files 

% FolderPathVA.ventralApproach = fullfile(ins_analysis_folder, 'nVoke_ventral_approach'); % processed imaging data, including isxd, gpio, tiff, and csv files 
% ins_analysis_ventral_fig_folder = fullfile(FolderPathVA.ventralApproach, 'figures'); % figure folder for ventral approach analysis
% ins_analysis_invitro_folder = fullfile(ins_analysis_folder, 'Kevin_calcium_imaging_slice'); % processed imaging data, including isxd, gpio, tiff, and csv files 

% FolderPathVA.ExportTiff = fullfile(ins_projects_folder, 'Exported_tiff'); % motion corrected recordings in tiff format
% FolderPathVA.ExportTiff = fullfile(FolderPathVA.ExportTiff, 'IO_ventral_approach'); % motion corrected recordings in tiff format
% FolderPathVA.cnmfe = fullfile(ins_projects_folder, 'Processed_files_for_matlab_analysis'); % cnmfe result files, gpio and roi csv files etc.

% ins_rec_ventral_folder = fullfile(ins_recordings_folder, 'IO_virus_ventral approach'); % processed imaging data, including isxd, gpio, tiff, and csv files 

%% ====================
clearvars -except recdata_organized alignedData_allTrials seriesData_sync

PC_name = getenv('COMPUTERNAME'); 
% set folders for different situation
DataFolder = 'G:\Workspace\Inscopix_Seagate';

if strcmp(PC_name, 'GD-AW-OFFICE')
	AnalysisFolder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
elseif strcmp(PC_name, 'LAPTOP-84IERS3H')
	AnalysisFolder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop
end

[FolderPathVAVA] = set_folder_path_ventral_approach(DataFolder,AnalysisFolder);


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
	output_tiff_folder = uigetdir(FolderPathVA.ExportTiff,...
		'Select a folder to save the exported tiff files');
	if output_tiff_folder ~= 0
		FolderPathVA.ExportTiff = output_tiff_folder;
		export_nvoke_movie_to_tiff(input_isxd_folder, output_tiff_folder,...
			'keyword', keywords, 'overwrite', overwrite);
	end
end

%% ==================== 
% 3.2 make subfolders for each tiff file with their date and time information for following CNMFe process
key_string = 'video'; % Key_string is used to locate the end of string used for nameing subfolder
num_idx_correct = -2; % key_string idx + num_idx_correct = idx of the end of string for subfolder name

organize_folder = uigetdir(FolderPathVA.ExportTiff,...
	'Select a folder containing exported tiff files');
if organize_folder ~= 0
	FolderPathVA.ExportTiff = organize_folder;
	organize_exported_tiff_files(organize_folder,...
		'key_string', key_string, 'num_idx_correct', num_idx_correct);
else
	disp('Folder not selected')
	return
end


%% ==================== 
% 3.3 Remove cnmfe generated files for a new process
dir_path_clear = FolderPathVA.ExportTiff;
keywords_file = {'*contours*', '*results.mat'};
keywords_dir = {'*source_extraction*'};

dir_path_clear = uigetdir(FolderPathVA.ExportTiff,...
	'Warning: about to delete objects in the subfolders!');
if dir_path_clear ~= 0
	FolderPathVA.ExportTiff = dir_path_clear;

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
organized_tiff_folder = FolderPathVA.ExportTiff; % This is a parent folder. Each recording has its own subfolder
Fs = 20; % Hz. recording frequency
cnmfe_process_batch('folder',  organized_tiff_folder, 'Fs', Fs);




%% ==================== 
% Write code with inscopix matlab API to simplify this step
% 5. Copy *results.mat, *gpio.csv, and *ROI.csv files in each subfolders to another folder
% So recording information in each subfolder can be integrated into a single mat file later。
% Export *gpio.csv and *ROI.csv from Inscopix Data processing (ISDP) software
input_folder = uigetdir(FolderPathVA.ExportTiff,...
	'Select a folder containing processed recording files organized in subfolders');
if input_folder ~= 0
	FolderPathVA.ExportTiff = input_folder;
else
	disp('Input folder not selected')
	return
end

output_folder = uigetdir(FolderPathVA.cnmfe,...
	'Select a folder to save *results.mat, *gpio.csv, and *ROI.csv files from subfolders of input location');
if output_folder ~= 0
	FolderPathVA.cnmfe = output_folder;
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
input_dir = FolderPathVA.cnmfe;
output_dir = FolderPathVA.ventralApproach;

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
uisave('recdata', fullfile(FolderPathVA.ventralApproach, 'recdata'));


%% ====================
% 8. Organize peaks and gpio information to data
clear opt
% Defaults
opt.lowpass_fpass = 1;
opt.highpass_fpass = 4;   
opt.smooth_method = 'loess';
opt.smooth_span = 0.1;
opt.prominence_factor = 4; % prominence_factor doesn't influence peak finding in decon data
opt.existing_peak_duration_extension_time_pre  = 1; % duration in second, before existing peak rise 
opt.existing_peak_duration_extension_time_post = 1; % duration in second, after decay
opt.criteria_rise_time = [0 1]; % unit: second. filter to keep peaks with rise time in the range of [min max]
opt.criteria_slope = [3 2000]; % default: slice-[50 2000]
							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
							% ventral approach default: [3 80]
							% slice default: [50 2000]
% criteria_mag = 3; % default: 3. peak_mag_normhp
opt.criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
opt.criteria_excitated = 1; % If a peak starts to rise in 0.5 sec since stimuli, it's a excitated peak
opt.criteria_rebound = 2; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end
opt.stim_time_error = 0.2; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
% use_criteria = true; % true or false. choose to use criteria or not for picking peaks
opt.stim_pre_time = 10; % time (s) before stimuli start
opt.stim_post_time = 10; % time (s) after stimuli end
opt.merge_peaks = true;
opt.merge_time_interval = 0.3; % default: 0.5s. peak to peak interval.
opt.discard_noisy_roi = false;
opt.std_fold = 10; % used as criteria to discard noisy_rois
plot_traces = 0; % 0: do not plot. 1: plot. 2: plot with pause
save_traces = 0; % 0: do not save. 1: save
debug_mode = false; % true/false.

% recdata=recdata_organized;

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
	'plot_traces', plot_traces, 'save_traces', save_traces,'debug_mode',debug_mode); 


%% ====================
% 8.1.1 Copy the FOV_loc struct-field from a sourceData, if exists, to a newly formed recdata_organized
recdata_target = recdata_organized;
recdata_source = recdata_old;

[recdata_target_with_fov,trial_list_wo_fov] = copy_fovInfo(recdata_source,recdata_target);
recdata_organized = recdata_target_with_fov;


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
data_fullpath = fullfile(FolderPathVA.ventralApproach, '*.mat');
[data_filename, FolderPathVA.ventralApproach] = uiputfile(data_fullpath,...
            'Select a folder to save data');
if isequal(data_filename, 0)
	disp('User selected Cancel')
else
	data_fullpath = fullfile(FolderPathVA.ventralApproach, data_filename);
	disp(['User selected ', data_fullpath]);
	% save(data_fullpath, 'recdata_organized', 'opt')
	save(data_fullpath, 'recdata_group', 'opt')
end



