function [varargout] = cnmfe_mono_series_gen_plot_video_cluster(workspace_file,varargin)
	% Input a path of workspace mat file for a multi-recording series, 
	% and save cnmfe results, plots and videos

	% Defaults
	addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	% select_with_UI = false;
	save_results = true;
	plot_contour = true;
	plot_roi_traces = true;
	creat_video = true;
	save_demixed = true;
	kt = 3; % scalar, the number of frames to be skipped

	% Optionals for inputs
	for ii = 1:2:(nargin-1)
		if strcmpi('save_results', varargin{ii})
			save_results = varargin{ii+1}; % recording frequency
		% elseif strcmpi('select_with_UI', varargin{ii})
		% 	select_with_UI = varargin{ii+1}; % recording frequency
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
	

	% Main contents
	[recfolder, workspace_file_name, ~] = fileparts(workspace_file);
	fprintf('\nsave CNMFe results and creating figures and videos for %s\n', workspace_file_name);
	
	load(workspace_file, 'neuron');
	
	for ii = 1:numel(neuron.batches) % number of recordings
		neuron_single = neuron.batches{ii}.neuron;


		[~, rec_file_name_stem, ~] = fileparts(neuron_single.file);
		fprintf('\n%s\n', rec_file_name_stem)
		tic
		%% Save *_results.mat
		if save_results
			results = neuron_single.obj2struct();
			results_filename = sprintf('%s%s%s_results.mat', recfolder, filesep, rec_file_name_stem);
			save(results_filename, 'results');
			fprintf(' - results saved\n');
		end


		%% show neuron contours
		if plot_contour
			Coor = neuron_single.show_contours(0.6);
			contours_fullpath = fullfile(recfolder, [rec_file_name_stem, '_contours']);
			% saveas(gcf, contours_fullpath, 'jpeg');
			print(contours_fullpath, '-dpng');

			%% save neurons shapes
			neuron_single.save_neurons();
			fprintf(' - spatial and temporal components figurs saved');
		end
		

		%% create a video for displaying the
        if creat_video    
			avi_filename = neuron_single.show_demixed_video(save_demixed, kt, []);
			fprintf(' - video saved');
		end
		toc
	end 
end