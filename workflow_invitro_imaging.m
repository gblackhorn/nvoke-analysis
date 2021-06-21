% workflow_invitro_imaging

% organized files in subfolders
% organized subfolders. date/sliceCell/recording
if ~exist('date_folder', 'var') 
	date_folder = 'G:\Workspace\Kevin_data\';
else
	if ~isstr(date_folder)
		date_folder = 'G:\Workspace\Kevin_data\';
	end
end

date_folder = uigetdir(date_folder, 'Select a folder to make it organized for CNMFe process');
date_folder_info = dir(date_folder);
date_folder_info = date_folder_info(3:end);

for dn = 1:size(date_folder_info, 1) % number of content
	if date_folder_info(dn).isdir == 1
		subfolder = fullfile(date_folder, date_folder_info(dn).name);
		organize_invitro_data(subfolder);
	end
end

%% ====================
% make a list of sampling frequency of recordings in sub-subfolders
% date/sliceCell/recording. 3 layers. invitro_rec_frequency can deal with recording folder when sliceCell is chosen
if ~exist('date_folder', 'var') 
	date_folder = 'G:\Workspace\Kevin_data\';
else
	if ~ischar(date_folder)
		date_folder = 'G:\Workspace\Kevin_data\';
	end
end

date_folder = uigetdir(date_folder, 'Select a date folder to read tif and csv files in its sub-subfolders');
cell_folder_info = dir(date_folder);
cell_folder_info = cell_folder_info(3:end);

rec_num = 0;
for dn = 1:size(cell_folder_info, 1) % number of SxCx folders
	if cell_folder_info(dn).isdir == 1
		cell_folder_path = fullfile(date_folder, cell_folder_info(dn).name);
		[recInfoTable_single] = invitro_rec_frequency(cell_folder_path);
		rec_num = rec_num+1;
	end
	if rec_num == 1
		recInfoTable = recInfoTable_single;
	else
		recInfoTable = [recInfoTable; recInfoTable_single];
	end
end

prompt_save_recInfoTable = 'Do you want to save recording information into a csv file? y/n [y]: ';
input_str = input(prompt_save_recInfoTable, 's');
if isempty(input_str)
	input_str = 'y';
end
if input_str == 'y'
	rec_folder_parts = regexp(date_folder, '\', 'split');
	recInfoTable_filename = [rec_folder_parts{end}, '_recordingInfo.csv'];
	recInfoTable_path = fullfile(date_folder, recInfoTable_filename);
	writetable(recInfoTable, recInfoTable_path);
end



