function [varargout] = cnmfe_series_delete_rois_update(varargin)
	% Updating the spactial (A) and temporal (C) matrices of single recordings in series workspaces in subfolders
	% [NOTE]: Use function "cnmfe_series_delete_rois" to modify the series ROIs and subsequently the A and C
	% 		before using this function.
	%

	% Defaults
	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	% opt = [];
	folder = ['/flash/UusisaariU/GD/'];
	force_update = false;
	rm_prev_workspace = false;
	% use_gui = false;
	% stim_keyword = {'og5s', 'ap1s', 'mix'};

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('force_update', varargin{ii})
			force_update = varargin{ii+1}; % recording frequency
		elseif strcmpi('rm_prev_workspace', varargin{ii})
			rm_prev_workspace = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
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
			cnmfe_mono_series_delete_rois_update('workspace_file', cnmfe_workspace_path,...
				'force_update', force_update, 'rm_prev_workspace', rm_prev_workspace);
		end
	end
end
