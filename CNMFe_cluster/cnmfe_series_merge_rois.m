function [obj,varargout] = cnmfe_series_merge_rois(obj,show_merge,merge_thr_spatial,min_corr_res,min_pnr_res,seed_method_res,varargin)
	% Merge ROIs in a series-workspace containing multiple recordings. Update the spatial and temporal components
	% The first recording, as default, will be used as a template (mergeing will be applied on it and sptial components will be passed to other recordings and series afterwards)
	% However, a specific recording can be used as a template by giving a keyword in the tif file name


	% Defaults
	% addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	% opt = [];


	keyword = [];
	save_initialization = false;
	use_parallel = true;


	% Optionals for inputs
	for ii = 1:2:(nargin-6)
		if strcmpi('keyword', varargin{ii}) % specify the template recording by giving a keyword in it tif file
			keyword = varargin{ii+1};
		elseif strcmpi('save_initialization', varargin{ii})
			save_initialization = varargin{ii+1}; % recording frequency
		elseif strcmpi('use_parallel', varargin{ii})
			use_parallel = varargin{ii+1}; % recording frequency
		end
	end

	% Main content

	%% Merge ROIs in a single recording, and spead the spatial components to others
	batches_num = numel(obj.batches);
	if isempty(keyword)
		batch_idx = 1;
	else
		keyword = lower(keyword);
		for i = 1:batches_num
			rec_name = lower(obj.file{i});
			keyword_loc = strfind(rec_name, keyword);
			if ~isempty(keyword_loc)
				batch_idx = i;
				batch_tif_fullpath = rec_name;
				[~, batch_tif_name, ~] = fileparts(batch_tif_fullpath);
				break
			end
		end
	end

	neuron_bat = obj.batches{batch_idx}.neuron; % This is the Sources2D "neuron" of a single recording will be used as a template for merging ROIs
	fprintf('ROIs in "%s" will be merged and the spatial components will be spread to other recordings and also the series\n', batch_tif_name);

	neuron_bat_merged = cnmfe_merge_rois(neuron_bat,show_merge,merge_thr_spatial,...
		min_corr_res,min_pnr_res,seed_method_res,...
		'save_initialization', save_initialization, 'use_parallel', use_parallel);

	ROI_num_new = size(neuron_bat_merged.A, 2);

	fprintf('Spread the new spatial components to all single recordings in the series\n')
	for n = 1:batches_num
		fprintf('\nprocessing batch %d/%d\n', n, batches_num)
		if n ~= batch_idx
			neuron_bat_k = obj.batches{n}.neuron;
			neuron_bat_k.A = neuron_bat_merged.A;
			neuron_bat_k.P.k_ids = neuron_bat_merged.P.k_ids;
			neuron_bat_k.tags = neuron_bat_merged.tags;
			
			[tmp_K, T] = size(neuron_bat_k.C);
			if ROI_num_new > tmp_K
			    neuron_bat_k.C = [neuron_bat_k.C; zeros(ROI_num_new-tmp_K, T)];
			elseif ROI_num_new < tmp_K
				neuron_bat_k.C((ROI_num_new+1):end, :) = [];
			end
			% update temporal components
			neuron_bat_k.update_temporal_parallel(use_parallel);
			
			% collect results
			obj.batches{n}.neuron = neuron_bat_k;
		else
			obj.batches{n}.neuron = neuron_bat_merged;
		end
	end

	% collect results
	obj.A = neuron_bat_merged.A;
	obj.W = neuron_bat_merged.W;
	obj.b = neuron_bat_merged.b;
	obj.f = neuron_bat_merged.f;
	obj.b0 = neuron_bat_merged.b0;
	obj.ids = neuron_bat_merged.ids;
	obj.tags = neuron_bat_merged.tags;
	obj.P.k_ids = neuron_bat_merged.P.k_ids; 

	%% get the correlation image and PNR image for all neurons 
	obj.correlation_pnr_batch(); 

	%% concatenate temporal components 
	obj.concatenate_temporal_batch(); 

	%% Save the updated workspace
	log_folder = obj.P.log_folder;
	obj.save_workspace_batch(log_folder); 
	fprintf('series workspace saved to %s\n', log_folder);
end
