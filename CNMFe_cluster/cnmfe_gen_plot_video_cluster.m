function [varargout] = cnmfe_gen_plot_video_cluster(varargin)
	% Select a folder containing recording folders. Use saved neuron workspace to plot and make video
	% After being copied to bucket, these info should be updated for future analysis
	% This function should also be used when data folder containing result being moved to another location
	% NOTE: Each subfolder in the selected folder contains the data from a single recording

	% Defaults
% 	folder = ['G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff'];
    folder = ['R:\UusisaariU\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\guoda\Inscopix\Projects\Exported_tiff\IO_ventral_approach'];
	select_with_UI = false;
	plot_contour = true;
	plot_roi_traces = true;
	creat_video = true;
	save_demixed = true;
	% cnmfe_script_path = fullfile('D:\guoda\Documents\MATLAB\Codes\nvoke-analysis\Process',...
	% 	'cnmfe_large_data_script'); % script used to process tif/tiff file with cnmfe 

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('select_with_UI', varargin{ii})
			select_with_UI = varargin{ii+1}; % recording frequency
		elseif strcmpi('plot_contour', varargin{ii})
			plot_contour = varargin{ii+1}; % recording frequency
		elseif strcmpi('plot_roi_traces', varargin{ii})
			plot_roi_traces = varargin{ii+1}; % recording frequency
		elseif strcmpi('creat_video', varargin{ii})
			creat_video = varargin{ii+1}; % recording frequency
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
		cnmfe_result_file = dir(fullfile(recfolder, '*results.mat'));
		if ~isempty(cnmfe_result_file)
			disp(sprintf('Creating figures and videos for %s', recfolders(i).name))
			tic

			[cnmfe_workspace_path, cnmfe_workspace_folder] = get_cnmfe_workspace_path(recfolder,...
				'subfolder_lv', 3, 'sort_direction', 'ascend');
			load(cnmfe_workspace_path, 'neuron');

			[~, rec_file_name_stem, ~] = fileparts(neuron.file);

			%% show neuron contours
			Coor = neuron.show_contours(0.6);
			contours_fullpath = fullfile(recfolder, [rec_file_name_stem, '_contours']);
			% saveas(gcf, contours_fullpath, 'jpeg');
			print(contours_fullpath, '-dpng');
			

			%% create a video for displaying the
            kt = 3;
			amp_ac = 140;
			range_ac = 5+[0, amp_ac];
			multi_factor = 10;
			range_Y = 1300+[0, amp_ac*multi_factor];

			avi_filename = neuron.show_demixed_video(save_demixed, kt, [], amp_ac, range_ac, range_Y, multi_factor);


			%% save neurons shapes
			neuron.save_neurons();

			toc
		end
	end
end