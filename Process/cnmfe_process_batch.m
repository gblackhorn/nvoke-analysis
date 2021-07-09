function [varargout] = cnmfe_process_batch(varargin)
	% Process tif/tiff files in subfolders of selected directory with CNMFe  

	% Defaults
	opt = [];
	folder = ['G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff'];
	cnmfe_large_data_script_path = fullfile('D:\guoda\Documents\MATLAB\Codes\nvoke-analysis\Process',...
		'cnmfe_large_data_script'); % script used to process tif/tiff file with cnmfe 

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('Fs', varargin{ii})
			opt.Fs = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	clc;
	folder = uigetdir(folder,...
		'Select a folder containing to-be processed files in subfolders');
	if folder == 0
		return
	end

	folder_content = dir(folder);
	dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
	subfolders = folder_content(dirflag); % Extract only those that are directories
	subfolders = subfolders(~startsWith({subfolders.name}, '.')); % remove content starts with "."

	subfolders_num = numel(subfolders); 
	file_names = cell(subfolders_num, 1);

	for i = 1:subfolders_num % Ignore "." and ".." 
		subfolder = fullfile(folder, subfolders(i).name);
		cnmfe_result_file = dir(fullfile(subfolder, '*results.mat'));
		if isempty(cnmfe_result_file)
			tiff_file = dir(fullfile(subfolder, '*-mc*.tif*')); % list .tif and .tiff files
			tiff_file = tiff_file(~contains({tiff_file.name}, '-dff', 'IgnoreCase', true)); % discard deltaF/F file
			if length(tiff_file) > 1
				[~, idx] = sort([tiff_file.datenum]); % sort files according to date
				[~, latest_file_idx] = max(idx);
				tiff_file = tiff_file(latest_file_idx); % use the latest modified file
            end
            file_names{i} = fullfile(subfolder, tiff_file.name);
		end
	end
	non_empty_idx = find(~cellfun(@isempty, file_names)); % index of cells not empty
	file_names = file_names(non_empty_idx); % discard empty cells from "file_names"


	for ii = 1:numel(file_names)
		tic
		nam = file_names{ii};
% 		run(cnmfe_large_data_script_path);
        cnmfe_large_data_script
		toc
	end

end