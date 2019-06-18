function [ output_args ] = nvoke_file_process( input_args )
% Process raw data file recorded by nVoke system and save output files in a
% new location. Copy GPIO files to the same location.
% IMPORTANT: Change "data_dir" (parent directory of data folders) and "output_dir" 
% 			to make it easier to use on your computer.
%   suffix: 
%       - PP: preprocess
%       - PP-BP: spatial bandpass
%       - PP-BP-MC: motion correction 
%       - PP-BP-DFF: dF/F
% !!! This code only reads the files in subfolders (1 level) of chosen folder !!!
% When asked to chose data dir, chose something like "recording_yyyymmdd (which contains recordings in subfolders)"

% path to data location
% data_dir = 'D:\guoda\Documents\Workspace_Analysis\OIST\Inscopix\Demo\S1prism_AAV1_demo_with_LR\S1prism_AAV1_demo_v2_data'; % folder for testing
data_dir = 'G:\Workspace\Inscopix_Seagate\recordings'; % default folder of nVoke recordings.

% % output_dir local PC
% output_dir = 'D:\guoda\Documents\Inscopix_Projects\IO_GCaMP\IO_GCaMP_data'; % processed files will be saved here
 
% % output_dir ventral approach
% output_dir = 'F:\Workspace\inscopix\Projects\Ventral _IO_GCaMP_CN_Chrimson\Ventral_IO_GCaMP_CN_Chrimson_data';
% output_dir dorsal implant
output_dir = 'G:\Workspace\Inscopix_Seagate\Projects'; % default folder of processed files

data_dir_chosen = uigetdir(data_dir, 'Choose a folder including recordings collected in 1 single day'); % choos the project folder
dirinfo_data_dir_chosen = dir(data_dir_chosen); % get info of this folder
dirinfo_data_dir_chosen = dirinfo_data_dir_chosen(3:end,:); % get rid of '.' and '..' from list

output_dir_chosen = uigetdir(output_dir, 'Choose a folder to save processed recording files'); % in subfolders of "projects"
dirinfo_output_dir_chosen = dir(output_dir_chosen); % get info of this folder
dirinfo_output_dir_chosen = dirinfo_output_dir_chosen(3:end,:); % get rid of '.' and '..' from list

disp(['Data dir: ', data_dir_chosen])
disp(['Output dir: ', output_dir_chosen])


% process data file one by one. Start from pre-processed cells
for n = 1:length(dirinfo_data_dir_chosen)
	data_dir_raw_files = fullfile(data_dir_chosen, dirinfo_data_dir_chosen(n).name); % subfolder containing raw data file
	raw_file_info_isxd = dir([data_dir_raw_files, '\*.isxd']); % info of raw data file. If raw recording is saved as isxd file (nVoke 2.0)
	raw_file_info_hdf5 = dir([data_dir_raw_files, '\*.hdf5']); % info of raw data file. If raw recording is saved as hdf5 file (nVoke 1.0)
	if length(raw_file_info_isxd) ~= 0
		raw_file_info = raw_file_info_isxd;
	elseif length(raw_file_info_hdf5) ~= 0
		raw_file_info = raw_file_info_hdf5;
	else
		return
	end
	for m = 1:length(raw_file_info)
		raw_file_no_ext = raw_file_info(m).name(1:end-5); % file name without extension '.hdf5'
		raw_file = fullfile(raw_file_info(m).folder, raw_file_info(m).name); % raw_file whole path
		disp(['Processing raw data (', num2str(n), '/', num2str(length(dirinfo_data_dir_chosen)), '): ', raw_file_info(m).name])

		% process files with preprocess
		pp_file = fullfile(output_dir_chosen, [raw_file_no_ext, '-PP.isxd']); % location and name of pre-processed files
		if ~exist(pp_file, 'file')
			isx.preprocess(raw_file, pp_file, 'spatial_downsample_factor', 2);
			disp([' - Output: ', raw_file_no_ext, '-PP.isxd'])
		end

		% process files with bandpass filter
		bp_file = fullfile(output_dir_chosen, [raw_file_no_ext, '-PP-BP.isxd']); % location of bandpass-filtered files
		if ~exist(bp_file, 'file')
			isx.spatial_filter(pp_file, bp_file, 'low_cutoff', 0.005, 'high_cutoff', 0.500); % use the default cutoff number
			disp([' - Output: ', raw_file_no_ext, '-PP-BP.isxd'])
		end

		% Motion correct the movies using the mean projection as a reference frame
		mean_proj_file = fullfile(output_dir_chosen, [raw_file_no_ext, '-mean_image.isxd']); % Location of mean image used for motion correction
		if ~exist(mean_proj_file, 'file')
			isx.project_movie(bp_file, mean_proj_file, 'stat_type', 'mean'); % generate mean image
			disp([' - Output: ', raw_file_no_ext, '-mean_image.isxd'])
		end
		mc_file = isx.make_output_file_path(bp_file, output_dir_chosen, 'MC'); % location of motion corrected files
		translation_files = isx.make_output_file_path(mc_file, output_dir_chosen, 'translations','ext', 'csv'); % location of translation files
		crop_rect_file  = fullfile(output_dir_chosen, [raw_file_no_ext, '-crop_rect.csv']); % location of files containing crop rectangle info
		if ~exist(mc_file, 'file')
			isx.motion_correct(bp_file, mc_file, 'max_translation', 20, 'reference_file_name', mean_proj_file, 'low_bandpass_cutoff', 0.004, 'high_bandpass_cutoff', 0.016, 'output_translation_files', 'translation_files', 'output_crop_rect_file', 'crop_rect_file');
			disp([' - Output: ', raw_file_no_ext, '-PP-BP-MC.isxd'])
		end

		% Run dF/F on the motion corrected movies.
		dff_file = isx.make_output_file_path(mc_file, output_dir_chosen, 'DFF');
		if ~exist(dff_file, 'file')
			isx.dff(mc_file, dff_file, 'f0_type', 'mean');
			disp([' - Output: ', raw_file_no_ext, '-PP-BP-MC-DFF.isxd'])
		end

		% copy and rename the GPIO file to output folder if it exists
		gpio_file_info = dir([data_dir_raw_files, '\gpio*']);
		if length(gpio_file_info) ~= 0
			gpio_file = fullfile(gpio_file_info.folder, gpio_file_info.name);
			gpio_file_rename = fullfile(output_dir_chosen, [raw_file_no_ext, '-GPIO.raw']);
			copyfile(gpio_file, gpio_file_rename);
			disp([' - Output: ', raw_file_no_ext, '-GPIO.raw'])
		end
	end
end
end

