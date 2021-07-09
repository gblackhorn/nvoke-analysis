function [varargout] = organize_processed_files(input_folder, output_folder)
	% Collect *results.mat, *gpio.csv, and *ROI.csv files in each subfolder from 'input_folder' and
	% copy them to the 'output_folder'
	% varargout{1}: names of recordings of which information was not copied to the new folder. Because 
	% some information files are missing


	% Main content
	input_folder_content = dir(input_folder);
	dirflag = [input_folder_content.isdir]; % Get a logical vector that tells which is a directory
	input_subfolders = input_folder_content(dirflag); % Extract only those that are directories
	input_subfolders = input_subfolders(~startsWith({input_subfolders.name}, '.')); % remove content starts with "."

	input_subfolders_num = numel(input_subfolders); 
	file_names = cell(input_subfolders_num, 1);

	organized_rec_num = 0;
	not_organized_rec_num = 0;
	partially_organized_rec_num = 0;
	for i = 1:input_subfolders_num % Ignore "." and ".." 
		input_subfolder = fullfile(input_folder, input_subfolders(i).name);
		cnmfe_result_file = dir(fullfile(input_subfolder, '*results.mat'));
		roi_readout_file_info = dir(fullfile(input_subfolder, '*ROI.csv'));
		gpio_file = dir(fullfile(input_subfolder, '*gpio.csv'));
		% if isempty(cnmfe_result_file) || isempty(roi_readout_file_info) || isempty(gpio_file) 

		% 	not_organized_rec_num = not_organized_rec_num+1;
		% 	not_organized_rec_name{not_organized_rec_num, 1} = input_subfolders(i).name;
		% else
		% 	organized_rec_num = organized_rec_num+1;
		% 	copyfile(fullfile(cnmfe_result_file.folder, cnmfe_result_file.name), output_folder);
		% 	copyfile(fullfile(roi_readout_file_info.folder, roi_readout_file_info.name), output_folder);
		% 	copyfile(fullfile(gpio_file.folder, gpio_file.name), output_folder);
		% end


		partially_org_state = false;
		if isempty(cnmfe_result_file) % nothing will be copied to the output folder
			not_organized_rec_num = not_organized_rec_num+1; % data in this subfolder considered to be not organized
			not_organized_rec_name{not_organized_rec_num, 1} = input_subfolders(i).name;
		else
			for ii = 1:numel(cnmfe_result_file)
				copyfile(fullfile(cnmfe_result_file(ii).folder, cnmfe_result_file(ii).name), output_folder);
			end

			% if *ROI.csv and/or *gpio.csv not found, subfolder is considered to be partially organized.
			% warning information will be displayed 
			if isempty(roi_readout_file_info) 
				partially_org_state = true;
				warning(sprintf('time info (*ROI.csv) not found in %s', input_subfolders(i).name))
			else
				for ii = 1:numel(roi_readout_file_info)
					copyfile(fullfile(roi_readout_file_info(ii).folder, roi_readout_file_info(ii).name), output_folder);
				end
			end

			if isempty(gpio_file)
				partially_org_state = true;
				warning(sprintf('stimulation info (*gpio.csv) not found in %s', input_subfolders(i).name))
			else
				for ii = 1:numel(gpio_file)
					copyfile(fullfile(gpio_file(ii).folder, gpio_file(ii).name), output_folder);
				end
			end

			if partially_org_state
				partially_organized_rec_num = partially_organized_rec_num+1;
				partially_organized_rec_name{partially_organized_rec_num, 1} = input_subfolders(i).name;
			else
				organized_rec_num = organized_rec_num+1;
			end
		end


	end
	summary_text = sprintf('\ninformation from %d out of %d recordings was completely copied to the output folder.\n %d out of %d was partially copied to the output folder',...
		organized_rec_num, input_subfolders_num, partially_organized_rec_num, input_subfolders_num);
	disp(summary_text);

	if not_organized_rec_num > 0
		disp('Information of following recordings was not copied:')
		disp(not_organized_rec_name)
	else
		not_organized_rec_name = 'none';
	end

	if partially_organized_rec_num > 0
		disp('Information of following recordings was not enought for further analysis:')
		disp(partially_organized_rec_name)
	else
		partially_organized_rec_name = 'none';
	end

	varargout{1} = not_organized_rec_name;
	varargout{2} = partially_organized_rec_name;
end