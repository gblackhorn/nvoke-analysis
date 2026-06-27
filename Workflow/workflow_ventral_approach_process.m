% This script is used to process nVoke recordings. Compatible with windows 10/11
%	- Files should be on a local drive for proper reading and writing speed
%	- Inscopix Data Processing Software (IDPS) must be installed on the PC to use the APIs
%	- CNMFe process should be run on deigo cluster


%% ====================
% 0. clear varibles
clearvars -except recdata_organized alignedData_allTrials seriesData_sync

%% ====================
% 1. Setup folders 
% This section is necessary for most sections in this workflow script. 
% Even if you don't want to save the plots, folderPath should exist to avoid bug

GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
folderPath = initProjFigPathVIIO(GUI_chooseFolder);


%% ==================== 
% Step 2.1.1 Crop isxd files in a chosen folder and saved to another folder
% Description:
%   This script crops Inscopix .isxd files found in a user-chosen folder, and saves
%   the cropped videos to another specified folder. The cropping rectangle and other
%   parameters are predefined. Cropped file metadata is saved along with the video.
overwrite = false; % true/false. If true, overwrite existing cropped files

% Keyword used to identify the video file to crop. This helps target the correct .isxd file(s).
% Example: '2021-03-29-13-48-34_video_sched_0.isxd'
movieKeyword = '*2021-03-29-13-48-34_video_sched_0.isxd';

% Define cropping rectangle (in pixels)
% Top-left corner: (Left, Top), Width and Height define the region
% These values should be chosen based on visual inspection of the video
Left = 352;
Top = 186;
Width = 647;
Height = 425;
Bottom = Top + Height;
Right = Left + Width;

% [top, left, bottom, right] format required by Inscopix cropping function
cropRectangle = [Top, Left, Bottom, Right];

% Select input and output folders with GUI
[inputFolder,projectFolder,chosenStatus] = getInputOutputFolders('inputFolder',folderPath.recording,...
	'outputFolder',folderPath.project,'inputMSG','Chose a recording folder');

% Crop videos and save them to projectFolder if folders were properly selected
if chosenStatus
	crop_nVokeRec(inputFolder,projectFolder,cropRectangle,...
		'keyword',movieKeyword,'overwrite',overwrite);
end

%% ==================== 
% Step 2.1.2 Downsampling the movies
% Description:
%   This section performs spatial and/or temporal downsampling on previously cropped ISXD/TIFF movie files.
%   The user selects the folder containing the input movies and the destination for the downsampled files.
%   Downsampling helps reduce data size and accelerates processing in later steps.
overwrite = false; % true/false. If true, overwrite existing downsampled files
temporal_factor = 1; % int ≥1  (default 1 = no temporal DS)
spatial_factor = 2; % int ≥1  (default 1 = no spatial DS)
movieKeyword = '*.isxd'; % Code will search for files with names like this and motion-correct them

% Select input and output folders with GUI
[inputFolder,projectFolder,chosenStatus] = getInputOutputFolders('inputFolder',folderPath.recording,...
	'outputFolder',folderPath.project,'inputMSG','Chose a folder containing cropped files');

% Downsample the movies if folders were properly selected
if chosenStatus
	downsample_nVokeRec(inputFolder,projectFolder,'keyword',movieKeyword,...
		'temporal_factor',temporal_factor,'spatial_factor',spatial_factor, 'overwrite', overwrite);
end

%% ==================== 
% Step 2.1.3 Spatial filter and motion correct the movies
% Description:
%   This section applies spatial bandpass filtering and motion correction to ISXD movie files.
%   The user selects the input folder containing cropped ISXD files and an output folder for saving results.
%   Motion correction stabilizes the movie based on a reference frame, and optionally removes the intermediate filtered file.

overwrite = false;         % true/false. If true, overwrite existing motion corrected files
movieKeyword = '*-PP.isxd';% Pattern to match input ISXD files for motion correction
rmBPfile = true;           % true/false. If true, delete the intermediate bandpass filtered file after correction

% Select input and output folders with GUI
[inputFolder, projectFolder, chosenStatus] = getInputOutputFolders( ...
    'inputFolder', folderPath.recording, ...
    'outputFolder', folderPath.project, ...
    'inputMSG', 'Chose a folder containing cropped files');

% Motion correct the movies if folders were properly selected
if chosenStatus
    motionCorrect_nVokeRec(inputFolder, projectFolder, ...
        'keyword', movieKeyword, ...
        'overwrite', overwrite, ...
        'rmBPfile', rmBPfile);
end

%% ==================== 
% Step 2.2 (Optional) Create DFF files from motion corrected files
% Description:
%   This step generates ΔF/F (DFF) files from motion-corrected ISXD movies.
%   These DFF files can be loaded and examined in the Inscopix Data Processing Software (IDPS).
%   The user selects a folder containing motion-corrected files, filtered using a keyword.

movieKeyword = '*-MC.isxd';  % Pattern to identify motion corrected files
overwrite = false;           % true/false. If true, overwrite existing DFF files

% Prompt user to select a folder containing motion corrected files
MC_fileFolder = uigetdir(folderPath.project, ...
    'Select a folder containing motion corrected files');

% Proceed if a folder was selected
if MC_fileFolder ~= 0
    folderPath.project = MC_fileFolder;

    % Generate DFF files from MC ISXD files
    batchProcess_MC2DFF_nvokeFiles(folderPath.project, ...
        'keyword', movieKeyword, 'overwrite', overwrite);
end

%% ==================== 
% Step 3.1.1 Export nVoke movies to TIFF files
% Description:
%   This section exports processed nVoke ISXD movie files to TIFF format for use in ImageJ, MATLAB,
%   or other analysis tools that require standard image stacks. The user selects the input folder
%   containing .isxd files and an output folder to save the exported TIFFs.

movieKeyword = '*-PP.isxd';  % Pattern to match ISXD files for export
overwrite = false;           % true/false. If true, overwrite existing TIFF exports

% Select input folder containing ISXD files
inputFolder = uigetdir(projectFolder, ...
    'Select a folder (project folder) containing processed recording files (.isxd)');

% Proceed if user selected a valid input folder
if inputFolder ~= 0
    folderPath.project = inputFolder;

    % Select output folder to save TIFF files
    tiffFolder = uigetdir(folderPath.ExportTiff, ...
        'Select a folder to save the exported tiff files');

    % Proceed if user selected a valid output folder
    if tiffFolder ~= 0
        folderPath.ExportTiff = tiffFolder;

        % Export matched ISXD files to TIFF
        export_nvoke_movie_to_tiff(inputFolder, tiffFolder, ...
            'keyword', movieKeyword, 'overwrite', overwrite);
    end
end

%% ==================== 
% Step 3.1.2 (optional) Batch rename TIFF files to retain only date and time info
% Description:
%   This section renames TIFF files exported from IDPS by keeping only the date and time information.
%   A user-defined prefix can be added to the renamed files. This helps standardize file names for downstream analysis.
%   A dry run option is available to preview the renaming actions before committing changes.

movieKeyword = '*.tiff';        % Pattern to match TIFF files for renaming
prefixStr = 'VIIO_caImg_';      % Prefix to prepend to each renamed file
dryRun = true;                  % true/false. If true, only display planned renaming without executing

% Select folder containing TIFF files to rename
[tiffFolder, ~, chosenStatus] = getInputOutputFolders(...
    'inputFolder', folderPath.ExportTiff, ...
    'outputFolder', folderPath.ExportTiff, ...
    'inputMSG', 'Chose a folder containing cropped files');

% Proceed with renaming if folder selection was successful
if chosenStatus
    if dryRun
        disp('Dry run mode: Only showing planned renaming actions');
        renameBatch(tiffFolder, ...
            'keyword', movieKeyword, ...
            'prefix',  prefixStr, ...
            'dryRun',  true);
    else
        renameBatch(tiffFolder, ...
            'keyword', movieKeyword, ...
            'prefix',  prefixStr, ...
            'dryRun',  false);
    end
end


%% ==================== 
% Step 3.1.3 Delete intermediate .isxd files to free disk space
% Description:
%   This optional step removes specified .isxd files (e.g., bandpass-filtered files) from the project folder
%   to reclaim storage space. Users can preview the list of files before deletion by enabling the display flag.

movieKeyword = '*BP.isxd';   % Pattern to match files for deletion (e.g., bandpass-filtered files)
showFileList = true;         % true/false. If true, display a list of files to be deleted

% Call function to delete matched files from the project folder
folderPath.project = rmFilesWithKeywords(folderPath.project, movieKeyword, ...
    'showFileList', showFileList);


%% ==================== 
% 3.2 Create subfolders for each tiff file with their date and time information for following CNMFe process
key_string = 'video'; % Key_string is used to locate the end of string used for nameing subfolder
num_idx_correct = -2; % key_string idx + num_idx_correct = idx of the end of string for subfolder name

organize_folder = uigetdir(folderPath.ExportTiff,...
	'Select a folder containing exported tiff files');
if organize_folder ~= 0
	folderPath.ExportTiff = organize_folder;
	organize_exported_tiff_files(organize_folder,...
		'key_string', key_string, 'num_idx_correct', num_idx_correct);
else
	disp('Folder not selected')
	return
end


%% ==================== 
% 3.3 Remove cnmfe generated files for a new process
% Caution: This code will delete the files output be CNMFe! Backup data!
dir_path_clear = folderPath.ExportTiff;
keywords_file = {'*contours*', '*results.mat'};
keywords_dir = {'*source_extraction*'};

dir_path_clear = uigetdir(folderPath.ExportTiff,...
	'Warning: about to delete objects in the subfolders!');
if dir_path_clear ~= 0
	folderPath.ExportTiff = dir_path_clear;

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

[csvTraceTitle,csvFolder] = plotCalciumTracesFromIDPScsv('showYtickRight',showYtickRight);

if saveFig
	msg = 'Save the ROI traces';
	savePlot(gcf,'save_dir',csvFolder,'guiSave',true,...
		'guiInfo',msg,'fname',csvTraceTitle);
end


%% ==================== 
% Better use deigo cluster for this step. Prepare files in the bucket for tranfering them to deigo
% Check file 'command_for_cluster.sh' for useful lines to run CNMFe on cluster

% % 4. Process recordings with CNMFe to extract ROI traces
% % NOTE: This step can be done with VDI, but it is way slower than deigo cluster
% organized_tiff_folder = folderPath.ExportTiff; % This is a parent folder. Each recording has its own subfolder
% Fs = 20; % Hz. recording frequency
% cnmfe_process_batch('folder',  organized_tiff_folder, 'Fs', Fs);


%% ==================== 
% 5.1 Copy *results.mat, *gpio.csv, and *ROI.csv files in each subfolders to another folder
% So recording information in each subfolder can be integrated into a single mat file later
% Manually Export *gpio.csv and *ROI.csv from Inscopix Data processing
% (ISDP) software (Write code with inscopix matlab API to simplify this step)
[folderPath.ExportTiff,folderPath.cnmfe] = getInputOutputFolders('inputFolder',folderPath.ExportTiff,...
	'outputFolder',folderPath.cnmfe,...
	'inputMSG','Select a folder containing CNMFe results in its subfolders',...
	'outputMSG','Select a folder to save mat files and its related csv files for further analysis');

[not_organized_recordings] = organize_processed_files(folderPath.ExportTiff, folderPath.cnmfe);





%% ====================
% 5.2 Convert ROI info to matlab file (.m). 
% Place results.m from CNMFe, ROI info (csv files) and GPIO info (csv) from IDPS to the same folder,
% and run this function
% [ROIdata, recording_num, cell_num] = ROIinfo2matlab; % for data without CNMFe process
input_dir = folderPath.cnmfe;
output_dir = folderPath.ventralApproach;
debug_mode = false; % true/false.

[recdata, recording_num, cell_num] = ROI_matinfo2matlab('input_dir', input_dir,...
	'output_dir', output_dir,'debug_mode',debug_mode); % for CNMFe processed data


%% ====================
% 5.3 If trials are from nvoke2, expecially when they are mixed with nvoke1 data. rename the nvoke 2 trials
recdata_backup = recdata; %recdata
[recdata] = renameFileNamesInROI(recdata);

%% ====================
% 5.4 Save recdata before applying further processes
uisave('recdata', fullfile(folderPath.ventralApproach, 'recdata')); 


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
opt.peakErrTime = 0.4; % unit: second. Preserves the historical effective default used by downstream peak matching
opt.criteria_excitated = 1; % If an event found in this time range after the onset of stimulation, it will be categorized as an exitated/trig event
opt.criteria_rebound = 1; % If an event found in this time range after the end of stimualtion, it will be categorized as an rebound/off-stim event
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
uisave('recdata_organized', fullfile(folderPath.ventralApproach, 'recdata_organized'));


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
overwrite = true; %options: true/false
[recdata_organized] = auto_gen_mouseID_fovID(recdata_organized,'overwrite',overwrite);
% [recdata_organized,mouseIDs,fovIDs] = auto_gen_mouseID_fovID(recdata_organized,'overwrite',overwrite);


%% ====================
% This section requires old recdata_organized containing FOV ID information
% Assign the new 'recdata_organized' to 'recdata_target': The data receiving FOV info
% Load old 'recdata_organized' from a saved file

% 6.5 Copy the FOV_loc struct-field from a sourceData, if exists, to a newly formed recdata_organized
% recdata_target = recdata_organized; % The data receiving FOV info
recdata_source = recdata_organized_all; % The data giving FOV info

[recdata_target_with_fov,trial_list_wo_fov] = copy_fovInfo(recdata_source,recdata_organized);
recdata_organized = recdata_target_with_fov;

clear recdata_target recdata_source recdata_target_with_fov


%% ====================
% 6.6 Add the location tag (subnuclei information) to ROIs
overwrite = true; %options: true/false
recdata_organized = addRoiLocTag2recdata(recdata_organized,'overwrite',overwrite);

%% ====================
% 6.6.1 Copy location tag (subnuclei information) from another recdata_organized
sourceData = recdata_organized_old;
targetData = recdata_organized;
recdata_organized = copylocTag(sourceData, targetData);


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
% data_fullpath = fullfile(folderPath.ventralApproach, '*.mat');
% [data_filename, folderPath.ventralApproach] = uiputfile(data_fullpath,...
%             'Select a folder to save data');
% if isequal(data_filename, 0)
% 	disp('User selected Cancel')
% else
% 	data_fullpath = fullfile(folderPath.ventralApproach, data_filename);
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
uisave('recdata_organized', fullfile(folderPath.ventralApproach, 'recdata_organized'));




%% ====================
% % 9 Clear temp variables to reclaim memory
% clear recordings recdata_backup
