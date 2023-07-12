function [varargout] = cnmfe_process_series_cluster(varargin)
	% Process tif/tiff files in subfolders of selected directory with CNMFe  
	% multiple files in the same subfolder will be considered as a series of recordings
	% add key words, such as stimulation type, in the file names for the order in the series

	% Defaults
	opt.Fs = 20;
	opt.keyword = 'air'; % use the file name containing this as template for the series
	folder = '/flash/UusisaariU/GD/';
	stim_keyword = {'air','opto', 'mix'};
	use_gui = false;

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('Fs', varargin{ii})
			opt.Fs = varargin{ii+1}; % recording frequency
		elseif strcmpi('keyword', varargin{ii})
			opt.keyword = varargin{ii+1}; % keyword to specify a single recording for mergeing ROIs
		elseif strcmpi('stim_keyword', varargin{ii})
			stim_keyword = varargin{ii+1}; 
		elseif strcmpi('use_gui', varargin{ii})
			use_gui = varargin{ii+1}; 
		end
	end


	% Main content
	if use_gui
		folder = uigetdir(folder,...
			'Select a folder containing to-be processed files in subfolders');
		if folder == 0
			return
		end
	end

	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders

	% folder_content = dir(folder);
	% dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
	% subfolders = folder_content(dirflag); % Extract only those that are directories
	% subfolders = subfolders(~startsWith({subfolders.name}, '.')); % remove content starts with "."

	% subfolders_num = numel(subfolders); 

	[subfolders, subfolders_num] = get_subfolders(folder);
	
	file_names = cell(subfolders_num, 1);
	file_num = 0;

	for i = 1:subfolders_num % Ignore "." and ".." 
		subfolder = fullfile(folder, subfolders(i).name);
		cnmfe_result_file = dir(fullfile(subfolder, '*results.mat'));
		if isempty(cnmfe_result_file)
			for n = 1:numel(stim_keyword)
				stim_keyword_wild = ['*', stim_keyword{n}, '*.tif*'];
				tiff_file = dir(fullfile(subfolder, stim_keyword_wild)); % find the file with stimulation keyword in its name
				if ~isempty(tiff_file)
					if isempty(strfind(stim_keyword{n}, 'mix')) % not looking for file with 'mix' in its name
						tiff_file = tiff_file(~contains({tiff_file.name}, 'mix', 'IgnoreCase', true)); 
					end
					file_names{i}{n} = fullfile(subfolder, tiff_file.name);
				end
			end
			non_empty_idx_sub = find(~cellfun(@isempty, file_names{i}));
			file_names{i} = file_names{i}(non_empty_idx_sub);
			file_num = file_num+numel(file_names{i});
		end
	end
	non_empty_idx = find(~cellfun(@isempty, file_names)); % index of cells not empty
	file_names = file_names(non_empty_idx); % discard empty cells from "file_names"
	% file_num = numel(file_names);
	disp([num2str(file_num), ' files will be processed:'])
	% disp(file_names)
	varargout{1} = file_names;

	for ii = 1:numel(file_names)
		% tic
		nams = file_names{ii};
		% cd folder;
		cnmfe_series_large_data_script_cluster
		% toc
	end

end
