function [recInfoTable] = invitro_rec_frequency(rec_folder)
    % Read tif files and csv file (time info) in subfolders to calculate recording frequency, and output a list
    %   Only use this in folders organized by function -  'organize_invitro_data'
    % outputArg1 = inputArg1;
    % outputArg2 = inputArg2;

    % default_folder = 'G:\Workspace\Kevin_data\';
    % rec_folder = uigetdir(default_folder, 'Select a folder to read tif and csv files in its subfolders');
    folderInfo = dir(rec_folder);
    folderInfo = folderInfo(3:end); % get rid of . and .. from folderInfo

    % recInfoTable: recording name, frame number, recording duration, recording frequency
    recT_varTypes = {'string', 'double', 'double', 'double'};
    recT_varNames = {'recName', 'frameNum', 'recDuration', 'recFrequency'};
    recInfoTable = table('Size', [size(folderInfo, 1) 4], 'VariableTypes', recT_varTypes, 'VariableNames', recT_varNames);
    rec_num = 0;
    for fn = 1:(size(folderInfo, 1)) % number of subfolders
    	if folderInfo(fn).isdir == 1
    		rec_num = rec_num+1;
	    	% fn
	    	rec_name = folderInfo(fn).name;

	    	% if fn == 23
	    	% 	pause
	    	% end

	    	subfolder = [rec_folder, '\', folderInfo(fn).name];
	    	tifDir = dir(fullfile(subfolder, '*.tif*')); 
	    	csvDir = dir(fullfile(subfolder, '*waveforms.csv'));
	    	tifFile = fullfile(tifDir(1).folder, tifDir(1).name);
	    	csvFile = fullfile(csvDir(1).folder, csvDir(1).name);

	    	tifInfo = imfinfo(tifFile);
	    	stackNum = size(tifInfo, 1); % number of stacks in tif file

	    	csvTable = readtable(csvFile);
	    	rec_duration = csvTable.Time_s_(end) - csvTable.Time_s_(1);
	    	rec_frequency = stackNum/rec_duration; % Hz

	    	recInfoTable.recName(rec_num) = rec_name;
	    	recInfoTable.frameNum(rec_num) = stackNum;
	    	recInfoTable.recDuration(rec_num) = rec_duration;
	    	recInfoTable.recFrequency(rec_num) = rec_frequency;
	    end
    end

    % prompt_save_recInfoTable = 'Do you want to save recording information into a csv file? y/n [y]: ';
    % input_str = input(prompt_save_recInfoTable, 's');
    % if isempty(input_str)
    % 	input_str = 'y';
    % end
    % if input_str == 'y'
    % 	rec_folder_parts = regexp(rec_folder, '\', 'split');
    % 	recInfoTable_filename = [rec_folder_parts{end}, '_recordingInfo.csv'];
    % 	recInfoTable_path = fullfile(rec_folder, recInfoTable_filename);
    % 	writetable(recInfoTable, recInfoTable_path);
    % end
end

