function [varargout] = cnmfe_mono_series_delete_rois(varargin)
	% manually delete false ROIs in a saved workspace 
	% This will only affect the ROIs in the concatenated matrix, but not the matrix for single recordings composing the series
	% [NOTE]: 
	%		- Run "cnmfe_series_delete_rois_update" after this code to apply the new roi set to single recordings in the series
	%		- This code needs display. Don't run it background
	%		- Run this code on cluster. Because following process with "cnmfe_series_delete_rois_update" is needed to be run on cluster
	%

	% Defaults
	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	% opt = [];
	folder = '/flash/UusisaariU/GD/';
	workspace_file = [];
	use_gui = true;
	rm_prev_workspace = false;
	% stim_keyword = {'og5s', 'ap1s', 'mix'};

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('workspace_file', varargin{ii})
			workspace_file = varargin{ii+1}; % recording frequency
		elseif strcmpi('use_gui', varargin{ii})
			use_gui = varargin{ii+1}; % recording frequency
		elseif strcmpi('rm_prev_workspace', varargin{ii})
			rm_prev_workspace = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	if isempty(workspace_file) && use_gui
		workspace_file = uigetfile(folder,...
			'Select a workspace matfile to modify the ROIs');
		if workspace_file == 0
			return
		else
			varargout{1} = workspace_file;
		end
	end


	[recfolder, workspace_file_name, ~] = fileparts(workspace_file);
	fprintf('====================\n')
	fprintf('updating workspace for series %s\n', workspace_file_name);

	load(workspace_file, 'neuron');

	series_roi_num = size(neuron.A, 2); % number of ROIs in series
	fprintf('\nseries %s: %d ROIs\n', recfolder, series_roi_num);

	batches_num = numel(neuron.batches); % number of recordings in the series
	for ii = 1:batches_num
		neuron_single = neuron.batches{ii}.neuron; % Source2D struct of a single recording
		single_roi_num = size(neuron_single.A, 2);
		[~, rec_name, ~] = fileparts(neuron_single.file);

		fprintf(' - %s: %d ROIs\n', rec_name, single_roi_num); 
	end	

	prompt_manual_deletion = 'Do you want to modify ROIs in series manually? y/n [y]: ';
	str_manual_deletion = input(prompt_manual_deletion, 's');
	if isempty(str_manual_deletion)
		str_manual_deletion = 'y';
	end

	switch str_manual_deletion
		case 'y'
			neuron.viewNeurons([],neuron.C_raw); 
			series_roi_num = size(neuron.A, 2); % number of ROIs in series
			fprintf('series %s: current ROIs number is %d\n', recfolder, series_roi_num);

			save_workspace_path = neuron.save_workspace;
			fprintf('series workspace saved to %s\n', save_workspace_path);

			if rm_prev_workspace
				delete cnmfe_workspace_path;
			end
		otherwise
			fprintf('\nseries %s: ROIs not changed', recfolder);
	end

	varargout{2} = recfolder;
end
