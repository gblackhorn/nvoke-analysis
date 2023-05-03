% Workflow for Moscope project


% 1. Copy and rename nVoke2 raw data files using the paired Mocap (qtm) names. Renamed raw data
% files and a csv file containing original and new names will be saved to a specified folder

% Requirement:
%	- a folder of mat files containing the metadata of qtm measurements 
%	- a folder of nVoke2 raw data files
% Instruction: the code below will use GUI to locate 
%	- the qtm metadata file folder
%	- nVoke2 raw data file folder
%	- A folder to save the renamed copies of nVoke2 raw data files (Do not use the raw data folder above!)

% Default folder paths. GUI will use the following folder to start.
% Modify them if necessary
QTMmatFolderPath = 'S:\PROCESSED_DATA_BACKUPS\Moscope\MoScope_name_corrected_qtm_files\MATFILES';
nVokeRawDataFolder = 'S:\RAW_BACKUPS\INSCOPIX\MoScope';
nVokeRenameDataFolder = 'S:\PROCESSED_DATA_BACKUPS\Moscope\INSCOPIX_renamed';

% Rename and save nVoke2 data files
% nVoke_oldNew_filenames: a structure containing the original and new file names
% debriefing: containing the selected folder paths
[nVoke_oldNew_filenames,debriefing] = batchMod_nVoke2_filenames('QTMmatFolderPath',QTMmatFolderPath,...
	'nVokeRawDataFolder',nVokeRawDataFolder,'nVokeRenameDataFolder',nVokeRenameDataFolder);

% Add how many files were renamed and copied and how many of them not to
% the debriefing output