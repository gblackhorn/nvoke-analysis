function [varargout] = cnmfe_mono_series_delete_rois_update(varargin)
	% Updating the spactial (A) and temporal (C) matrices of single recordings in a series workspace
	% [NOTE]: Use function "cnmfe_series_delete_rois" to modify the series ROIs and subsequently the A and C
	% 		before using this function.
	%

	% Defaults
	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	% opt = [];
	folder = ['/flash/UusisaariU/GD/'];
	workspace_file = [];
	use_gui = true;
	force_update = false;
	rm_prev_workspace = false;
	use_parallel = true;
	% stim_keyword = {'og5s', 'ap1s', 'mix'};

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1};
		elseif strcmpi('workspace_file', varargin{ii})
			workspace_file = varargin{ii+1}; % recording frequency
		elseif strcmpi('use_gui', varargin{ii})
			use_gui = varargin{ii+1}; % recording frequency
		elseif strcmpi('force_update', varargin{ii})
			force_update = varargin{ii+1}; % recording frequency
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

	neuron = Sources2D();
	load(workspace_file, 'neuron');

	series_roi_num = size(neuron.A, 2); % number of ROIs in series
	fprintf('\nseries %s: %d ROIs\n', recfolder, series_roi_num);

	single_roi_num = size(neuron.batches{1}.neuron.A, 2); % number of ROIs in the first recording of series
	if series_roi_num < single_roi_num || force_update
		batches_num = numel(neuron.batches); % number of recordings in the series

		% Spread the new spatial components from series to single recordings
		fprintf('Spread the new spatial components from series to single recordings\n')
		for ii = 1:batches_num
			batch_k = neuron.batches{ii};
			neuron_k = batch_k.neuron;
			neuron_k.A = neuron.A; % pass spatial compoents of neurons from series to single recording
			% neuron_k.W = neuron.W; 
			neuron_k.P.k_ids = neuron.P.k_ids; 
			% neuron_k.b = neuron.b; 
			neuron_k.ids = neuron.ids; 
			neuron_k.tags = neuron.tags; 
			
			fprintf('\nprocessing batch %d/%d\n', ii, batches_num)
			[tmp_K, T] = size(neuron_k.C);
			if series_roi_num > tmp_K
			    neuron_k.C = [neuron_k.C; zeros(series_roi_num-tmp_K, T)];
			elseif series_roi_num < tmp_K
				neuron_k.C((series_roi_num+1):end, :) = [];
			end
			% update temporal components
			neuron_k.update_temporal_parallel(use_parallel);
			
			% collect results
			batch_k.neuron = neuron_k;
			neuron.batches{ii} = batch_k;
		end	

		% Update the spatial and temporal components
		%% udpate spatial components for all batches
		neuron.update_spatial_batch(use_parallel); 

		%% udpate temporal components for all bataches
		neuron.update_temporal_batch(use_parallel); 

		%% update background 
		neuron.update_background_batch(use_parallel); 

		%% get the correlation image and PNR image for all neurons 
		neuron.correlation_pnr_batch(); 

		%% concatenate temporal components 
		neuron.concatenate_temporal_batch(); 


		%% Save the updated workspace
		log_folder = neuron.P.log_folder;
		neuron.save_workspace_batch(log_folder); 
		fprintf('series workspace saved to %s\n', log_folder);

		if rm_prev_workspace
			delete cnmfe_workspace_path;
		end
	elseif series_roi_num == single_roi_num
		fprintf('Nothing updated. series and single recordings already share the same ROIs\n');
	end
	varargout{2} = recfolder;
end
