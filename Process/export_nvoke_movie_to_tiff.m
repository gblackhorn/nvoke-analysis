function [] = export_nvoke_movie_to_tiff(input_folder, output_folder, varargin)
	% export nvoke .isxd movie files to tiff
	% key words used to filter files can be specified with "keyword" as varargin
	% default keyword is '-MC.isxd'. Used to find all motion corrected movies

	% Defaults
	% input_folder = 0;
	% output_folder = 0;
	keyword = '-MC.isxd';
	overwrite = false;

	look_for_input_folder = 'G:\Workspace\Inscopix_Seagate\Projects\'; % modify this path to make the navigation easier
	look_for_output_folder = 'G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff\'; % modify this path to make the navigation easier

	% Options
	for ii = 1:2:(nargin-2)
		if strcmpi('keyword', varargin{ii})
			keyword = varargin{ii+1};
		elseif strcmpi('overwrite', varargin{ii})
			overwrite = varargin{ii+1};
		end
	end

	% Main content
	% if input_folder ~= 0
	% 	input_folder = uigetdir(look_for_input_folder, 'Select a folder containing .isdx movie files');
	% 	if input_folder == 0
	% 		disp('Input folder not selected')
	% 		return
	% 	end
	% end

	% if output_folder ~= 0
	% 	output_folder = uigetdir(look_for_output_folder, 'Select a folder containing .isdx movie files');
	% 	if output_folder == 0
	% 		disp('Output folder not selected')
	% 		return
	% 	end
	% end

	input_fileinfo = dir(fullfile(input_folder, ['*',keyword]));
	movie_num = numel(input_fileinfo);
	exported_num = 0;
	for mn = 1:movie_num
		input_file_fullpath = fullfile(input_folder, input_fileinfo(mn).name);

		[~, file_name_stem, ~] = fileparts(input_file_fullpath);
		output_file_fullpath = fullfile(output_folder, [file_name_stem, '.tiff']);

		tiff_exist = dir(output_file_fullpath);

		if isempty(tiff_exist) || overwrite
			isx.export_movie_to_tiff(input_file_fullpath, output_file_fullpath);
			exported_num = exported_num+1;
		end
	end
	fprintf('\n%d movies were exported to\n  %s\n', exported_num, output_folder);
end