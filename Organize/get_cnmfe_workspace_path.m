function [cnmfe_workspace_path, varargout] = get_cnmfe_workspace_path(rec_folder_path,varargin)
	% Return the selected-level subfolder (oldest or newest) and its content 
	% folder can be sorted using date, "ascend" (default) or "descend"

	% Defaults
	subfolder_lv = 3; % look for first level subfolder and its content
	sort_direction = 'ascend';

	% Optionals for inputs
	for ii = 1:2:(nargin-1)
		if strcmpi('subfolder_lv', varargin{ii})
			subfolder_lv = varargin{ii+1};
		elseif strcmpi('sort_direction', varargin{ii})
			sort_direction = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	[output_folder_path, output_folder_contents] = get_subfolder_content(rec_folder_path,...
				'subfolder_lv', subfolder_lv, 'sort_direction', sort_direction); % saved workspace, and log files are in 3rd level subfolder

	% There are 2 mat files in the 'output_folder', one contains intermediate_results, the other one contains
	% the final result. The latter one can be used to generate contours, roi traces and videos
	% The latter one will be used
	matfiles = output_folder_contents(contains({output_folder_contents.name}, '.mat'));
	cnmfe_workspace = matfiles(~contains({matfiles.name}, 'intermediate_results', 'IgnoreCase', true)); 
	cnmfe_workspace_path = fullfile(cnmfe_workspace.folder, cnmfe_workspace.name);

	varargout{1} = cnmfe_workspace.folder;
end