function cnmfe_save_results(neuron,varargin)
	% Save Sources2D variable "neuron" as results. 
	% This code can also return contours of ROIs


	% Defaults
	% addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
	[folder, name_stem, ~] = fileparts(neuron.file);
	save_workspace = true;
	save_contours = true; % plot and save contours

	% Optionals for inputs
	for ii = 1:2:(nargin-1)
		if strcmpi('folder', varargin{ii})
			folder = varargin{ii+1}; % recording frequency
		elseif strcmpi('save_workspace', varargin{ii})
			save_workspace = varargin{ii+1}; % recording frequency
		elseif strcmpi('save_contours', varargin{ii})
			save_contours = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	if save_workspace
		results = neuron.obj2struct();
	    results_filename = sprintf('%s%s%s_results.mat', folder, filesep, name_stem);
	    save(results_filename, 'results');

	    neuron.save_neurons(); % Save shapes and traces of neuorn
	    fprintf('%s results saved to %s\n', name_stem, folder);
	end

	if save_contours
	    Coor = neuron.show_contours(0.6);
	    contours_fullpath = fullfile(folder, [name_stem, '_contours']);
	    % saveas(gcf, contours_fullpath, 'jpeg');
	    print(contours_fullpath, '-dpng');
	    fprintf('%s contours saved to %s\n', name_stem, folder);
	end
end
