% Note: go to the folder containing recordings in its subfolders
%% ====================
% Run this section only once
addpath(genpath('/flash/UusisaariU/GD')); % add this folder to matlab path to use function in it and its subfolders
opt.Fs = 20;
opt.video = false;
folder = pwd; 

folder_content = dir(folder);
dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
subfolders = folder_content(dirflag); % Extract only those that are directories
subfolders = subfolders(~startsWith({subfolders.name}, '.')); % remove content starts with "."

subfolders_num = numel(subfolders); 
file_names = cell(subfolders_num, 1);

for i = 1:subfolders_num % Ignore "." and ".." 
	subfolder = fullfile(folder, subfolders(i).name);
	cnmfe_result_file = dir(fullfile(subfolder, '*results.mat'));
	if isempty(cnmfe_result_file)
		tiff_file = dir(fullfile(subfolder, '*-MC*.tif*')); % list .tif and .tiff files
		tiff_file = tiff_file(~contains({tiff_file.name}, '-dff', 'IgnoreCase', true)); % discard deltaF/F file
		if length(tiff_file) > 1
			[~, idx] = sort([tiff_file.bytes], 'descend'); % sort files according to date
			[~, latest_file_idx] = max(idx);
			tiff_file = tiff_file(latest_file_idx); % use the latest modified file
        end
        file_names{i} = fullfile(subfolder, tiff_file.name);
	end
end
non_empty_idx = find(~cellfun(@isempty, file_names)); % index of cells not empty
file_names = file_names(non_empty_idx); % discard empty cells from "file_names"
file_num = numel(file_names);
disp([num2str(file_num), ' files will be processed:'])
disp(file_names)

ii = 1;
%% ====================
% run this section for each recordings.

nam = file_names{ii};
ii = ii+1;
% Run "cnmfe_large_data_script_cluster.m"
% Temprol solution: pause at line 111 in "viewNeurons.m" make sure the ROI and traces will be plotted


%% ====================
cnmfe_process_batch_cluster('folder', folder,...
	'Fs', opt.Fs, 'video', opt.video);