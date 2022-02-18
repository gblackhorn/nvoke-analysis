function [varargout] = cnmfe_series_delete_rois(varargin)
	% manually delete false ROIs in saved workspace in subfolders (recfolders)
	% This will only affect the ROIs in the concatenated matrix, but not the matrix for single recordings composing the series
	% [NOTE]: 
	%		- Run "cnmfe_series_delete_rois_update" after this code to apply the new roi set to single recordings in the series
	%		- This code needs display. Don't run it background
	%		- Run this code on cluster. Because following process with "cnmfe_series_delete_rois_update" is needed to be run on cluster
	%
	% varargout{1} = folder;

	% Defaults
	% opt = [];
	folder = ['/flash/UusisaariU/GD/'];
	use_gui = true;
	rm_prev_workspace = false;
	% stim_keyword = {'og5s', 'ap1s', 'mix'};

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('use_gui', varargin{ii})
			use_gui = varargin{ii+1}; % recording frequency
		elseif strcmpi('rm_prev_workspace', varargin{ii})
			rm_prev_workspace = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	if use_gui
		folder = uigetdir(folder,...
			'Select a folder containing saved workspace in subfolders');
		if folder == 0
			return
		else
			varargout{1} = folder;
		end
	end

	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders

	% folder_content = dir(folder);
	% dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
	% recfolders = folder_content(dirflag); % Extract only those that are directories
	% recfolders = recfolders(~startsWith({recfolders.name}, '.')); % remove content starts with "."

	% recfolders_num = numel(recfolders); 

	[recfolders, recfolders_num] = get_subfolders(folder);

	for i = 1:recfolders_num % Ignore "." and ".." 
		recfolder = fullfile(folder, recfolders(i).name);
		cnmfe_workspace = dir(fullfile(recfolder, '*workspace*.mat'));
		if ~isempty(cnmfe_workspace)

			if numel(cnmfe_workspace) > 1 % if more than one workspace found, use the latest one
				warning('%d workspace mat files found in the recording folder. Using the latest one', numel(cnmfe_workspace))
				[~, idx] = sort ([cnmfe_workspace.datenum], 'ascend');
				sorted_idx = idx(end);
				cnmfe_workspace = cnmfe_workspace(sorted_idx);
			end

			cnmfe_workspace_path = fullfile(recfolder, cnmfe_workspace.name);
			cnmfe_mono_series_delete_rois('workspace_file', cnmfe_workspace_path,...
				'use_gui', use_gui, 'rm_prev_workspace', rm_prev_workspace);
			
		end
	end
	varargout{2} = recfolders;
end
