% path to data location
% data_dir = 'D:\guoda\Documents\Workspace_Analysis\OIST\Inscopix\Demo\S1prism_AAV1_demo_with_LR\S1prism_AAV1_demo_v2_data'; % folder for testing
data_dir = 'F:\Workspace\inscopix\IO recording mobile HDD'; % Folder of IO recroding in mobile HDD
output_dir = 'D:/guoda/Documents/Inscopix_Projects/IO_GCaMP/IO_GCaMP_data/'; % processed files will be saved here
data_dir_chosen = uigetdir(data_dir, 'Choose a folder including recordings collected in 1 single day'); % choos 1 day data for processing
dirinfo_data_dir_chosen = dir(data_dir_chosen); % get info of this folder
dirinfo_data_dir_chosen = dirinfo_data_dir_chosen(3:end,:); % get rid of '.' and '..' from list


% series names from day_1 and day_2
series_rec_names = {{'recording_20160613_105808',
            'recording_20160613_110507',
            'recording_20160613_111207',
            'recording_20160613_111907'}
            {'recording_20160616_102500',
            'recording_20160616_103200',
            'recording_20160616_103900',
            'recording_20160616_104600'}};

% % set output dir
% output_dir = fullfile(data_dir, 'processed');
% if ~exist(output_dir) 
% 	mkdir(output_dir);
% else
% end

% process data file one by one. Start from pre-processed cells
% series_rec_names_number = 0;
for n = 1:length(series_rec_names)
	for m = 1:length(series_rec_names{n})
	% series_rec_names_number = series_rec_names_number + numel(series_rec_names{n});
	pp_files = fullfile(data_dir, [series_rec_names{n}{m}, '-PP-PP.isxd']); % location of pre-processed files
	% rec_files = fullfile(data_dir, [series_rec_names{n}{m}, '.isxd'])

	% process files with bandpass filter
	bp_files = fullfile(output_dir, [series_rec_names{n}{m}, '-BP-PP.isxd']); % location of bandpass-filtered files
	isx.spatial_filter(pp_files, bp_files, 'low_cutoff', 0.005, 'high_cutoff', 0.500); % use the default cutoff number

	% Motion correct the movies using the mean projection as a reference frame
	mean_proj_file = fullfile(output_dir, [series_rec_names{n}{m}, '-mean_image.isxd']); % Location of mean image used for motion correction
	isx.project_movie(bp_files, mean_proj_file, 'stat_type', 'mean'); % generate mean image
	mc_files = isx.make_output_file_path(bp_files, output_dir, 'MC'); % location of motion corrected files
	translation_files = isx.make_output_file_path(mc_files, output_dir, 'translation','ext', 'csv'); % location of translation files
	crop_rect_file  = fullfile(output_dir, [series_rec_names{n}{m}, '-crop_rect.csv']); % location of files containing crop rectangle info
	isx.motion_correct(bp_files, mc_files, 'max_translation', 20, 'reference_file_name', mean_proj_file_file, 'low_bandpass_cutoff', 'None', 'high_bandpass_cutoff', 'None', 'output_translation_files', 'translation_files', 'output_crop_rect_file', 'crop_rect_file');

	% Run dF/F on the motion corrected movies.
	dff_files = isx.make_output_file_pathF(mc_files, output_dir, 'DFF');
	isx.dff(mc_files, dff_files, 'f0_type', 'mean');
	end
end
