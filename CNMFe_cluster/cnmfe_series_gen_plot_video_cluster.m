function [varargout] = cnmfe_series_gen_plot_video_cluster(varargin)
	% Select a folder containing recording folders. Use saved neuron workspace to plot and make video, save results
	% Saved workspace maps the original data in the path where CNMFe process was taken. It is usually on flash for Deigo cluster
	% Read the neuron.P.mat_data.Properties to find the path info

	% Defaults
% 	folder = ['G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff'];
    folder = ['R:\UusisaariU\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\guoda\Inscopix\Projects\Exported_tiff\IO_ventral_approach'];
	select_with_UI = false;
	save_results = true;
	plot_contour = true;
	plot_roi_traces = true;
	creat_video = true;
	save_demixed = true;
	kt = 3; % scalar, the number of frames to be skipped
	% cnmfe_script_path = fullfile('D:\guoda\Documents\MATLAB\Codes\nvoke-analysis\Process',...
	% 	'cnmfe_large_data_script'); % script used to process tif/tiff file with cnmfe 

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('select_with_UI', varargin{ii})
			select_with_UI = varargin{ii+1}; % recording frequency
		elseif strcmpi('save_results', varargin{ii})
			save_results = varargin{ii+1}; % recording frequency
		elseif strcmpi('plot_contour', varargin{ii})
			plot_contour = varargin{ii+1}; % recording frequency
		elseif strcmpi('plot_roi_traces', varargin{ii})
			plot_roi_traces = varargin{ii+1}; % recording frequency
		elseif strcmpi('creat_video', varargin{ii})
			creat_video = varargin{ii+1}; % recording frequency
		elseif strcmpi('kt', varargin{ii})
			kt = varargin{ii+1}; % recording frequency
		end
	end

	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders

	% Main content
	if select_with_UI
		folder = uigetdir(folder,...
			'Select a folder containing processed recordings in subfolders');
		if folder == 0
			return
		end
	end

	folder_content = dir(folder);
	dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
	recfolders = folder_content(dirflag); % Extract only those that are directories
	recfolders = recfolders(~startsWith({recfolders.name}, '.')); % remove content starts with "."

	recfolders_num = numel(recfolders); 

	for i = 1:recfolders_num % Ignore "." and ".." 
		recfolder = fullfile(folder, recfolders(i).name);
		cnmfe_workspace = dir(fullfile(recfolder, '*workspace*.mat')); % the series workspace containing several recordings

		if ~isempty(cnmfe_workspace)
			if numel(cnmfe_workspace) > 1 % if more than one workspace found, use the latest one
				warning('%d workspace mat files found in the recording folder. Using the latest one', numel(cnmfe_workspace))
				[~, idx] = sort ([cnmfe_workspace.datenum], 'ascend');
				sorted_idx = idx(end);
				cnmfe_workspace = cnmfe_workspace(sorted_idx);
			end
			disp(sprintf('Creating figures and videos for %s', recfolders(i).name))
			
			cnmfe_workspace_path = fullfile(recfolder, cnmfe_workspace.name);

			cnmfe_mono_series_gen_plot_video_cluster(cnmfe_workspace_path,...
				'save_results', save_results, 'plot_contour', plot_contour,...
				'plot_roi_traces', plot_roi_traces, 'creat_video', creat_video,...
				'kt', kt);
		end
	end
end