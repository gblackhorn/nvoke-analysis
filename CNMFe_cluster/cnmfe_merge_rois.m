function [neuron,varargout] = cnmfe_merge_rois(neuron,show_merge,merge_thr_spatial,min_corr_res,min_pnr_res,seed_method_res,varargin)
	% Merge ROIs in a workspace containing a single recording.


	% Defaults
	% addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	% opt = [];


	save_initialization = false;
	use_parallel = true;

	% Optionals for inputs
	for ii = 1:2:(nargin-6)
		if strcmpi('save_initialization', varargin{ii})
			save_initialization = varargin{ii+1}; % recording frequency
		elseif strcmpi('use_parallel', varargin{ii})
			use_parallel = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	%%  merge neurons and update spatial/temporal components
	neuron.merge_neurons_dist_corr(show_merge);
	neuron.merge_high_corr(show_merge, merge_thr_spatial);

	%% update spatial components

	%% pick neurons from the residual
	[center_res, Cn_res, PNR_res] =neuron.initComponents_residual_parallel([], save_initialization, use_parallel, min_corr_res, min_pnr_res, seed_method_res);
	% if show_init
	%     axes(ax_init);
	%     plot(center_res(:, 2), center_res(:, 1), '.g', 'markersize', 10);
	% end
	neuron_init_res = neuron.copy();

	%% udpate spatial&temporal components, delete false positives and merge neurons
	% update spatial
	neuron.update_spatial_parallel(use_parallel);
	% merge neurons based on correlations 
	neuron.merge_high_corr(show_merge, merge_thr_spatial);

	for m=1:2
	    % update temporal
	    neuron.update_temporal_parallel(use_parallel);
	    
	    % delete bad neurons
	    neuron.remove_false_positives();
	    
	    % merge neurons based on temporal correlation + distances 
	    if ~isempty(neuron.ids)
	        neuron.merge_neurons_dist_corr(show_merge);
	    end
	end

	%% run more iterations
	neuron.update_background_parallel(use_parallel);
	neuron.update_spatial_parallel(use_parallel);
	neuron.update_temporal_parallel(use_parallel);

	K = size(neuron.A,2);
	tags = neuron.tag_neurons_parallel();  % find neurons with fewer nonzero pixels than min_pixel and silent calcium transients
	neuron.remove_false_positives();
	neuron.merge_neurons_dist_corr(show_merge);
	neuron.merge_high_corr(show_merge, merge_thr_spatial);

	if K~=size(neuron.A,2)
	    neuron.update_spatial_parallel(use_parallel);
	    neuron.update_temporal_parallel(use_parallel);
	    neuron.remove_false_positives();
	end
end
