% This script is used to process nVoke recordings. Compatible with windows 10/11
%	- Files should be on a local drive for proper reading and writing speed
%	- Inscopix Data Processing Software (IDPS) must be installed on the PC to use the APIs
%	- CNMFe process should be run on deigo cluster


%% ====================
% 0. clear varibles
clearvars -except recdata_organized alignedData_allTrials seriesData_sync

%% ==================== 
% Step 1.1 Setup input/output folders for the project
% Description:
%   This step initializes the folder paths used in the workflow. The user is prompted via GUI
%   to select a folder containing the raw recording data (input) and a separate folder for the
%   project (output) where processed files and results will be stored.

% Prompt user to select raw recording data folder and project folder
[inputFolder, outputFolder, chosenStatus] = getInputOutputFolders(...
    'inputMSG', 'Select the folder containing raw recording data');

% Initialize folderPath structure if selection was successful
if chosenStatus
    folderPath.recording = inputFolder;  % Raw input data
    folderPath.project   = outputFolder; % Project output path
else
    error('Folder selection canceled. Workflow cannot proceed without setting folderPath.');
end

%% ==================== 
% Step 2.1 Copy raw recording files to project folder
% Description:
%   This step copies selected files (e.g., raw recordings) from the recording folder to the project folder.
%   It uses a keyword to filter which files to copy and supports optional overwriting of existing files.

overwrite = false;             % true/false. If true, overwrite existing files in the destination
movieKeyword = '*.isxd';       % Pattern to match files for copying (e.g., raw recordings)

% Select input (source) and output (destination) folders with GUI
[inputFolder, outputFolder, chosenStatus] = getInputOutputFolders( ...
    'inputFolder', folderPath.recording, ...
    'outputFolder', folderPath.project, ...
    'inputMSG', 'Select the folder containing raw recording files');

% Proceed with copying if folders were selected
if chosenStatus
    folderPath.recording = inputFolder;
    folderPath.project = outputFolder;

    % List files to copy
    fileList = dir(fullfile(inputFolder, movieKeyword));
    for i = 1:numel(fileList)
        srcPath = fullfile(inputFolder, fileList(i).name);
        destPath = fullfile(outputFolder, fileList(i).name);

        if ~exist(destPath, 'file') || overwrite
            copyfile(srcPath, destPath);
            fprintf('Copied: %s\n', fileList(i).name);
        else
            fprintf('Skipped (exists): %s\n', fileList(i).name);
        end
    end
end

%% ==================== 
% Step 2.2.1 (optional) Crop isxd files in a chosen folder and saved to another folder
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
[inputFolder,projectFolder,chosenStatus] = getInputOutputFolders('inputFolder',folderPath.project,...
	'outputFolder',folderPath.project,'inputMSG','Chose a recording folder');

% Crop videos and save them to projectFolder if folders were properly selected
if chosenStatus
	crop_nVokeRec(inputFolder,projectFolder,cropRectangle,...
		'keyword',movieKeyword,'overwrite',overwrite);
end

%% ==================== 
% Step 2.2.2 (optional) Downsampling the movies
% Description:
%   This section performs spatial and/or temporal downsampling on previously cropped ISXD/TIFF movie files.
%   The user selects the folder containing the input movies and the destination for the downsampled files.
%   Downsampling helps reduce data size and accelerates processing in later steps.
overwrite = false; % true/false. If true, overwrite existing downsampled files
temporal_factor = 1; % int ≥1  (default 1 = no temporal DS)
spatial_factor = 2; % int ≥1  (default 1 = no spatial DS)
movieKeyword = '*.isxd'; % Code will search for files with names like this and motion-correct them

% Select input and output folders with GUI
[inputFolder,projectFolder,chosenStatus] = getInputOutputFolders('inputFolder',folderPath.project,...
	'outputFolder',folderPath.project,'inputMSG','Chose a folder containing cropped files');

% Downsample the movies if folders were properly selected
if chosenStatus
	downsample_nVokeRec(inputFolder,projectFolder,'keyword',movieKeyword,...
		'temporal_factor',temporal_factor,'spatial_factor',spatial_factor, 'overwrite', overwrite);
end

%% ==================== 
% Step 2.3 Spatial filter and motion correct the movies
% Description:
%   This section applies spatial bandpass filtering and motion correction to ISXD movie files.
%   The user selects the input folder containing cropped ISXD files and an output folder for saving results.
%   Motion correction stabilizes the movie based on a reference frame, and optionally removes the intermediate filtered file.

overwrite = false;         % true/false. If true, overwrite existing motion corrected files
movieKeyword = '*-PP.isxd';% Pattern to match input ISXD files for motion correction
rmBPfile = true;           % true/false. If true, delete the intermediate bandpass filtered file after correction

% Select input and output folders with GUI
[inputFolder, projectFolder, chosenStatus] = getInputOutputFolders( ...
    'inputFolder', folderPath.project, ...
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
% Step 2.4 (Optional) Create DFF files from motion corrected files
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
% Step 3.1 Export nVoke movies to TIFF files
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
% Step 3.2 (optional) Batch rename TIFF files to retain only date and time info
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
% Step 3.3 (optional) Delete intermediate .isxd files to free disk space
% Description:
%   This optional step removes specified .isxd files (e.g., bandpass-filtered files) from the project folder
%   to reclaim storage space. Users can preview the list of files before deletion by enabling the display flag.

movieKeyword = '*BP.isxd';   % Pattern to match files for deletion (e.g., bandpass-filtered files)
showFileList = true;         % true/false. If true, display a list of files to be deleted

% Call function to delete matched files from the project folder
folderPath.project = rmFilesWithKeywords(folderPath.project, movieKeyword, ...
    'showFileList', showFileList);


%% ==================== 
% Step 3.4 (Optional) Organize exported TIFF files into subfolders
% Description:
%   This optional step organizes exported TIFF files by creating a subfolder for each TIFF file
%   using the date and time information extracted from the filename. This structure is required
%   for downstream CNMF-E processing.
%   The user specifies a key string to identify the naming point in the filename, and an index offset
%   to determine the cutoff for subfolder naming.

key_string = 'video';         % Key string used to locate filename segment for subfolder naming
num_idx_correct = -2;         % Offset from key_string index to define end of subfolder name

% Prompt user to select folder containing exported TIFF files
organize_folder = uigetdir(folderPath.ExportTiff, ...
    'Select a folder containing exported tiff files');

% Proceed with organizing if a folder was selected
if organize_folder ~= 0
    folderPath.ExportTiff = organize_folder;

    % Organize TIFF files into subfolders based on naming rule
    organize_exported_tiff_files(organize_folder, ...
        'key_string', key_string, 'num_idx_correct', num_idx_correct);
else
    disp('Folder not selected')
    return
end

