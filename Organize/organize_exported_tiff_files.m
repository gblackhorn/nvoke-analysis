function [varargout] = organize_exported_tiff_files(tiff_folder, varargin)
    % Make subfolders in the input 'tiff_folder' with the date and time information in tiff file
    % names. Move tiff files in their related folder 
    % 

    % Defaults
    key_string = 'video'; % Key_string is used to locate the end of string used for nameing subfolder
    num_idx_correct = -2; % key_string idx + num_idx_correct = idx of the end of string for subfolder name

    for ii = 1:2:(nargin-1)
    	if strcmpi('key_string', varargin{ii})
    		key_string = varargin{ii+1};
    	elseif strcmpi('num_idx_correct', varargin{ii})
    		num_idx_correct = varargin{ii+1};
    	end
    end

    % Main content
	tiff_folder_content = dir(fullfile(tiff_folder, '*.tiff'));
	tiff_num = numel(tiff_folder_content);

	for i = 1:tiff_num
		key_string_idx = strfind(tiff_folder_content(i).name, key_string);
		subfolder_str_idx_end = key_string_idx+num_idx_correct;
		subfolder_str = tiff_folder_content(i).name(1:subfolder_str_idx_end);

		tiff_current_fullpath = fullfile(tiff_folder, tiff_folder_content(i).name);
		subfolder_path = fullfile(tiff_folder, subfolder_str);

		status_mkdir = mkdir(subfolder_path);
		status_mvfile = movefile(tiff_current_fullpath, subfolder_path);
	end
end

