function [varargout] = delete_cnmfe_results(folder,varargin)
	% delete cnmfe results in subfolders for re-analysis

	% Defaults
	folder = ['S:\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\guoda\Inscopix\Projects\Exported_tiff'];
	rec_idx = 0; % look for first level subfolder and its content

	% Optionals for inputs
	for ii = 1:2:(nargin-1)
		if strcmpi('rec_idx', varargin{ii})
			rec_idx = varargin{ii+1};
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
	if rec_idx ~= 0
		recfolders = recfolders(rec_idx);
	end

	recfolders_num = numel(recfolders); 

	for i = 1:recfolders_num % Ignore "." and ".." 
		subfolder = fullfile(folder, recfolders(i).name);
		cnmfe_result_file = dir(fullfile(subfolder, '*results.mat'));
		source_extraction_folder = dir(fullfile(subfolder, '*source_extraction'));
		if ~isempty(cnmfe_result_file)
			delete(fullfile(cnmfe_result_file.folder, cnmfe_result_file.name));
		end
		if ~isempty(source_extraction_folder)
			rmdir(fullfile(source_extraction_folder.folder, source_extraction_folder.name), 's');
		end
	end
end