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
% 0. clear varibles
clearvars -except recdata_organized alignedData_allTrials seriesData_sync

%% ====================
% 1. Locate the folders to find and save data 
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
	elseif strcmp(PC_name,'DESKTOP-DVGTQ1P')
	    AnalysisFolder = 'C:\Users\nRIM_lab\Documents\ExampleData_nVoke\Analysis'; % Ana
	else
		error('set var GUI_chooseFolder to true to select default folders using GUI')
	end
end

[FolderPathVA] = set_folder_path_ventral_approach(DataFolder,AnalysisFolder);


%% ==================== 
% % 2.1 Preprocess (Down-sampling is possible), spatial filter, and motion corrected recordings with Inscopix API for matlab. And export them in tiff format.
% % 	Export gpio (stimulation) and recording time stamp information in csv format with IDPS

% % This step can be only done on local desktop installed IDPS

% % Process all raw recording files in the same folder.
% % This is designed for the output of nVoke2
% recording_dir = uigetdir(FolderPathVA.recordingVA,...
% 	'Select a folder containing raw recording files (.isxd) and gpio files (.gpio)');
% if recording_dir ~= 0
% 	FolderPathVA.recordingVA = recording_dir;
% 	project_dir = uigetdir(FolderPathVA.project,...
% 		'Select a folder to save processed recording files (PP, BP, MC, DFF)');
% 	if FolderPathVA.project ~= 0 
% 		FolderPathVA.project = project_dir;
% 		process_nvoke_files(recording_dir, 'project_dir',project_dir);
% 	end
% end

%% ==================== 
% 2.1.1 Crop isxd files in a chosen folder and saved to another folder
% crop info will be saved together with the cropped video files

% M8: 
% Left = 389;
% Top = 136;
% Width = 474;
% Height = 400;
% movieKeyword = 'M9'; % no need to add .isxd
% Left = 607;
% Top = 176;
% Width = 424;
% Height = 444;
movieKeyword = '2021-03-29-13-48-34_video_sched_0.isxd'; % crop file with names like this
Left = 352;
Top = 186;
Width = 647;
Height = 425;
Bottom = Top+Height;
Right = Left+Width;
cropRectangle = [Top Left Bottom Right]; % [top, left, bottom, right]

[FolderPathVA.recordingVA,FolderPathVA.project,chosenStatus] = getInputOutputFolders('inputFolder',FolderPathVA.recordingVA,...
	'outputFolder',FolderPathVA.project,'inputMSG','Chose a recording folder');

if chosenStatus
	crop_nVokeRec(FolderPathVA.recordingVA,FolderPathVA.project,cropRectangle,...
		'keyword',movieKeyword,'overwrite',false);
end

%% ==================== 
% 2.1.2 Spatial filter and motion correct the movies
movieKeyword = '*sched_0.isxd'; % Code will search for files with names like this and motion-correct them
rmBPfile = true; % true/false. Remove the spatial filtered file ('bp_file') after creating the motion-corrected video
[movieFolder,~,chosenStatus] = getInputOutputFolders('inputFolder',FolderPathVA.project,...
	'outputFolder',FolderPathVA.project,'inputMSG','Chose a folder containing cropped files');

if chosenStatus
	motionCorrect_nVokeRec(movieFolder,'keyword',movieKeyword,'overwrite',false,'rmBPfile',rmBPfile);
end

%% ==================== 
% 2.2 (Optional) Create DFF files from motion corrected files in a specified folder
% DFF files can be examined in IDPS
% Use keyword to filter MC files
movieKeyword = '2021-03-29-13-48-34_video_sched_0-crop-BP-MC.isxd'; % Use file name like this to look for motion corrected files
overwrite = false; % true/false. Create new DFF files if this is true.

MC_fileFolder = uigetdir(FolderPathVA.project,...
	'Select a folder containing motion corrected files');
if MC_fileFolder ~= 0
	FolderPathVA.project = MC_fileFolder;
	% batchMod_fileName(FolderPathVA.project,'MC-PP','MC-crop','keyword','MC-PP','overwrite',overwrite);
	batchProcess_MC2DFF_nvokeFiles(FolderPathVA.project,'keyword',movieKeyword,'overwrite',overwrite);
end

%% ==================== 
% 3.1.1 Export nvoke movies to tiff files for further work using ImageJ, matlab, etc.
movieKeyword = '2024-01*-MC.isxd'; % used to filter 
overwrite = false;

input_isxd_folder = uigetdir(FolderPathVA.project,...
	'Select a folder (project folder) containing processed recording files (.isxd)');
if input_isxd_folder ~= 0
	FolderPathVA.project = input_isxd_folder;
	output_tiff_folder = uigetdir(FolderPathVA.ExportTiff,...
		'Select a folder to save the exported tiff files');
	if output_tiff_folder ~= 0
		FolderPathVA.ExportTiff = output_tiff_folder;
		export_nvoke_movie_to_tiff(input_isxd_folder, output_tiff_folder,...
			'keyword', movieKeyword, 'overwrite', overwrite);
	end
end

%% ==================== 
% 3.1.2 Delete some .isxd files to release the space in the hard disk
movieKeyword = '*BP.isxd';
showFileList = true;
FolderPathVA.project = rmFilesWithKeywords(FolderPathVA.project,movieKeyword,...
	'showFileList',showFileList);



%% ==================== 
% 3.2 Create subfolders for each tiff file with their date and time information for following CNMFe process
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
% Caution: This code will delete the files output be CNMFe! Backup data!
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


%% ==========
% If ROI signal is directly extracted from IDPS, following code can be used to plot the traces
% 3.4 Plot calcium traces by reading the csv file exported by the IDPS software
close all
saveFig = true; % true/false
showYtickRight = true; % Show the ROI signal value on the right Y axis. Left Y contain ROI names
[timeFluorTab,csvFolder,csvName] = readInscopixTraceCsv; % csvName does not contain the file extension
timeFluorTab{:,2:end} = timeFluorTab{:,2:end} .* 100; % Convert the deltaF/F to deltaF/F %
plot_TemporalData_Trace([],timeFluorTab{:,1},timeFluorTab{:,2:end},...
	'ylabels',timeFluorTab.Properties.VariableNames,'showYtickRight',showYtickRight)

if saveFig
	msg = 'Save the ROI traces';
	savePlot(gcf,'save_dir',csvFolder,'guiSave',true,...
		'guiInfo',msg,'fname',csvName);
end


%% ==================== 
% Better use deigo cluster for this step. Prepare files in the bucket for tranfering them to deigo
% Check file 'command_for_cluster.sh' for useful lines to run CNMFe on cluster

% % 4. Process recordings with CNMFe to extract ROI traces
% % NOTE: This step can be done with VDI, but it is way slower than deigo cluster
% organized_tiff_folder = FolderPathVA.ExportTiff; % This is a parent folder. Each recording has its own subfolder
% Fs = 20; % Hz. recording frequency
% cnmfe_process_batch('folder',  organized_tiff_folder, 'Fs', Fs);


%% ==================== 
% 5.1 Copy *results.mat, *gpio.csv, and *ROI.csv files in each subfolders to another folder
% So recording information in each subfolder can be integrated into a single mat file later
% Manually Export *gpio.csv and *ROI.csv from Inscopix Data processing
% (ISDP) software (Write code with inscopix matlab API to simplify this step)
[FolderPathVA.ExportTiff,FolderPathVA.cnmfe] = getInputOutputFolders('inputFolder',FolderPathVA.ExportTiff,...
	'outputFolder',FolderPathVA.cnmfe,...
	'inputMSG','Select a folder containing CNMFe results in its subfolders',...
	'outputMSG','Select a folder to save mat files and its related csv files for further analysis');

[not_organized_recordings] = organize_processed_files(FolderPathVA.ExportTiff, FolderPathVA.cnmfe);





%% ====================
% 5.2 Convert ROI info to matlab file (.m). 
% Place results.m from CNMFe, ROI info (csv files) and GPIO info (csv) from IDPS to the same folder,
% and run this function
% [ROIdata, recording_num, cell_num] = ROIinfo2matlab; % for data without CNMFe process
input_dir = FolderPathVA.cnmfe;
output_dir = FolderPathVA.ventralApproach;
debug_mode = false; % true/false.

[recdata, recording_num, cell_num] = ROI_matinfo2matlab('input_dir', input_dir,...
	'output_dir', output_dir,'debug_mode',debug_mode); % for CNMFe processed data


%% ====================
% 5.3 If trials are from nvoke2, expecially when they are mixed with nvoke1 data. rename the nvoke 2 trials
recdata_backup = recdata; %recdata
[recdata] = renameFileNamesInROI(recdata);

%% ====================
% 5.4 Save recdata before applying further processes
uisave('recdata', fullfile(FolderPathVA.ventralApproach, 'recdata'));


%% ====================
% 6.1 Organize peaks and gpio information to data
% Note: Signal processing toolbox and curve fitting toolbox are needed for this section
clear opt
% Defaults
opt.lowpass_fpass = 1;
opt.highpass_fpass = 4;   
opt.smooth_method = 'loess';
opt.smooth_span = 0.1;
opt.prominence_factor = 4; % default: 4. prominence_factor doesn't influence peak finding in decon data
opt.existing_peak_duration_extension_time_pre  = 1; % duration in second, before existing peak rise 
opt.existing_peak_duration_extension_time_post = 1; % duration in second, after decay
opt.criteria_rise_time = [0 1]; % unit: second. filter to keep peaks with rise time in the range of [min max]
opt.criteria_slope = [3 2000]; % default: slice-[50 2000]
							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
							% ventral approach default: [3 80]
							% slice default: [50 2000]
% criteria_mag = 3; % default: 3. peak_mag_normhp
opt.criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
opt.eventTimeType = 'peak_time'; % peak_time/rise_time. Use this value to categorize event
opt.peakErrTime = 0.3; % unit: second. The max difference between existing peak and found peak
opt.criteria_excitated = opt.criteria_rise_time(2); % If an event found in this time range after the onset of stimulation, it will be categorized as an exitated/trig event
opt.criteria_rebound = 1+opt.criteria_rise_time(2); % If an event found in this time range after the end of stimualtion, it will be categorized as an rebound/off-stim event
opt.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start time point of stimuli can be extended
% use_criteria = true; % true or false. choose to use criteria or not for picking peaks
opt.stim_pre_time = 10; % time (s) before stimuli start
opt.stim_post_time = 10; % time (s) after stimuli end
opt.merge_peaks = false; % true/false. Merge peaks too close to each other. The first peak must be smaller than the second one
opt.merge_time_interval = 0.3; % default: 0.3s. peak to peak interval.
opt.discard_noisy_roi = false;
opt.std_fold = 10; % used as criteria to discard noisy_rois
plot_traces = 0; % 0: do not plot. 1: plot. 2: plot with pause
save_traces = 0; % 0: do not save. 1: save
debug_mode = false; % true/false.

% recdata=recdata_organized;

[recdata_organized] = organize_add_peak_gpio_to_recdata(recdata,...
	'lowpass_fpass', opt.lowpass_fpass, 'highpass_fpass', opt.highpass_fpass,...
	'smooth_method', opt.smooth_method, 'smooth_span', opt.smooth_span,...
	'prominence_factor', opt.prominence_factor,'peakErrTime',opt.peakErrTime,...
	'existing_peak_duration_extension_time_pre', opt.existing_peak_duration_extension_time_pre,...
	'existing_peak_duration_extension_time_post', opt.existing_peak_duration_extension_time_post,...
	'criteria_rise_time', opt.criteria_rise_time, 'criteria_slope', opt.criteria_slope, 'criteria_pnr', opt.criteria_pnr,...
	'eventTimeType',opt.eventTimeType,'criteria_excitated', opt.criteria_excitated, 'criteria_rebound', opt.criteria_rebound,...
	'stim_time_error', opt.stim_time_error, 'stim_pre_time', opt.stim_pre_time, 'stim_post_time', opt.stim_post_time,...
	'merge_peaks', opt.merge_peaks, 'merge_time_interval', opt.merge_time_interval,...
	'discard_noisy_roi', opt.discard_noisy_roi, 'std_fold', opt.std_fold,...
	'plot_traces', plot_traces, 'save_traces', save_traces,'debug_mode',debug_mode); 


%% ====================
% 6.2 Save the newly created 'recdata_organized'
uisave('recdata_organized', fullfile(FolderPathVA.ventralApproach, 'recdata_organized'));


%% ====================
% 6.3 Add FOV location information in second column of recdata
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
	fprintf('\n- %d/%d ', nrec, rec_num);
	single_recording = recordings(nrec, :);
	[~, FOV_loc] = organize_add_fov_loc_info(single_recording, 'loc_opt', loc_opt, 'modify_info', modify_info);
	recordings{nrec, fov_info_col}.FOV_loc = FOV_loc;
	direct_input = input(sprintf('\n\t(c)continue, (r)re-input or (b)go back to previous one? [default-c]:'), 's');
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
recdata_organized = recordings;


%% ====================
% 6.4 Generate mouseID and fovID base on recording date from trial names and FOV_loc in recording data 
% 
% Add FOV category code to FOV_loc
% [recdata_organized] = add_fov_category(recdata_organized,...
% 	'hemi_sort', hemi_sort, 'fov_contents', fov_contents);
overwrite = false; %options: true/false
[recdata_organized] = auto_gen_mouseID_fovID(recdata_organized,'overwrite',overwrite);
% [recdata_organized,mouseIDs,fovIDs] = auto_gen_mouseID_fovID(recdata_organized,'overwrite',overwrite);


%% ====================
% This section requires old recdata_organized containing FOV ID information
% Assign the new 'recdata_organized' to 'recdata_target': The data receiving FOV info
% Load old 'recdata_organized' from a saved file

% 6.5 Copy the FOV_loc struct-field from a sourceData, if exists, to a newly formed recdata_organized
% recdata_target = recdata_organized; % The data receiving FOV info
recdata_source = recdata_organized; % The data giving FOV info

[recdata_target_with_fov,trial_list_wo_fov] = copy_fovInfo(recdata_source,recdata_target);
recdata_organized = recdata_target_with_fov;

clear recdata_target recdata_source recdata_target_with_fov


%% ====================
% 6.6 Add the location tag (subnuclei information) to ROIs
overwrite = false; %options: true/false
recdata_organized = addRoiLocTag2recdata(recdata_organized,'overwrite',overwrite);


%% ====================
% % 8.3 Group recordings according to stimulation and save vars 'recdata_group' and 'opt'
% % stim_types = {'GPIO-1-1s', 'OG-LED-1s', 'OG-LED-5s', 'OG-LED-5s GPIO-1-1s'};
% % stim_types = unique(cellfun(@(x) char(x), recdata_organized(:,3), 'UniformOutput',false));
% group_info = organize_rec_group_info(recdata_organized);
% stim_types = {group_info.name};
% recdata_group.all = recdata_organized;

% for gn = 1:numel(group_info)
% 	fieldName = strrep(group_info(gn).name, '-', '_');
% 	fieldName = strrep(fieldName, ' ', '_');
% 	recdata_group.(fieldName) = recdata_organized(group_info(gn).idx, :);

% end


% % Save organized and calculate data 
% data_fullpath = fullfile(FolderPathVA.ventralApproach, '*.mat');
% [data_filename, FolderPathVA.ventralApproach] = uiputfile(data_fullpath,...
%             'Select a folder to save data');
% if isequal(data_filename, 0)
% 	disp('User selected Cancel')
% else
% 	data_fullpath = fullfile(FolderPathVA.ventralApproach, data_filename);
% 	disp(['User selected ', data_fullpath]);
% 	% save(data_fullpath, 'recdata_organized', 'opt')
% 	save(data_fullpath, 'recdata_group', 'opt')
% end


%% ====================
% 6.7 sort the recordings using date and time
recdata_organized_bk = recdata_organized;
recNames = recdata_organized(:,1);

% Extract date and time portions and convert to datetime format
datesAndTimes = cellfun(@(str) datetime(str(1:15), 'InputFormat', 'yyyyMMdd-HHmmss'), recNames);

% Sort the strings based on date and time
[sortedDatesAndTimes, sortedIndices] = sort(datesAndTimes);

% Sort the original cell array using the sorted indices
recdata_organized = recdata_organized(sortedIndices,:);


%% ====================
% 6.8 Save the modified 'recdata_organized'
uisave('recdata_organized', fullfile(FolderPathVA.ventralApproach, 'recdata_organized'));




%% ====================
% % 9 Clear temp variables to reclaim memory
% clear recordings recdata_backup