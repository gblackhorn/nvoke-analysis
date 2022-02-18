function [varargout] = cnmfe_modify_dir_data(varargin)
	% CNMFe processed data by cluster or VDI will save the directory info in neuron.P. 
	% After being copied to bucket, these info should be updated for future analysis
	% This function should also be used when data folder containing result being moved to another location
	% NOTE: Each subfolder in the selected folder contains the data from a single recording

	% Defaults
% 	folder = ['G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff'];
    folder = ['R:\UusisaariU\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\guoda\Inscopix\Projects\Exported_tiff\IO_ventral_approach'];
	select_with_UI = true;
	% cnmfe_script_path = fullfile('D:\guoda\Documents\MATLAB\Codes\nvoke-analysis\Process',...
	% 	'cnmfe_large_data_script'); % script used to process tif/tiff file with cnmfe 

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('select_with_UI', varargin{ii})
			select_with_UI = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	folder = uigetdir(folder,...
		'Select a folder containing processed files in subfolders');
	if folder == 0
		return
	end

	folder_content = dir(folder);
	dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
	recfolders = folder_content(dirflag); % Extract only those that are directories
	recfolders = recfolders(~startsWith({recfolders.name}, '.')); % remove content starts with "."

	recfolders_num = numel(recfolders); 

	for i = 1:recfolders_num % Ignore "." and ".." 
		recfolder = fullfile(folder, recfolders(i).name);
		cnmfe_result_file = dir(fullfile(recfolder, '*results.mat'));
		if ~isempty(cnmfe_result_file)
			[cnmfe_workspace_path, cnmfe_workspace_folder] = get_cnmfe_workspace_path(recfolder,...
				'subfolder_lv', 3, 'sort_direction', 'ascend');
			load(cnmfe_workspace_path, 'neuron');

			% Modify folder and file paths
			neuron_file_rec_folder_idx = strfind(neuron.file, recfolders(i).name);
            neuron_file_rec_folder_idx = neuron_file_rec_folder_idx(1); % use the first idx
			neuron.file = fullfile(folder, neuron.file(neuron_file_rec_folder_idx:end));
			neuron.P.mat_file = fullfile(folder, neuron.P.mat_file(neuron_file_rec_folder_idx:end));
			neuron.P.folder_analysis = fullfile(folder, neuron.P.folder_analysis(neuron_file_rec_folder_idx:end));
			neuron.P.log_folder = fullfile(folder, neuron.P.log_folder(neuron_file_rec_folder_idx:end));
			neuron.P.log_file = fullfile(folder, neuron.P.log_file(neuron_file_rec_folder_idx:end));
			neuron.P.log_data = fullfile(folder, neuron.P.log_data(neuron_file_rec_folder_idx:end));
% 			neuron.P.mat_data.Properties.Source = fullfile(folder, neuron.P.mat_data.Properties.Source(neuron_file_rec_folder_idx:end));

			save(cnmfe_workspace_path, 'neuron', '-append', '-nocompression');
		end
	end
end