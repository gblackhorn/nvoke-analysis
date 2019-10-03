function [ROIdata, varargout] = ROIinfo2matlab(inputArg)
%ROIinfo2matlab 
% read all ROI.csv in a folder and get info into matlab
%   Detailed explanation goes here

input_dir = 'G:\Workspace\Inscopix_Seagate\Projects';
output_dir = 'G:\Workspace\Inscopix_Seagate\Analysis';

roi_readout_file_folder = uigetdir(input_dir, 'Select a folder containing ROI readout files');

% roi_readout_file_info = dir([roi_readout_file_folder, '\', '*-ROI.csv']);
roi_readout_file_info = dir([roi_readout_file_folder, '\*ROI.csv']);



cell_num = 0;

for n = 1:numel(roi_readout_file_info)
	roi_readout_file = fullfile(roi_readout_file_info(n).folder, roi_readout_file_info(n).name);
	opts = detectImportOptions(roi_readout_file); % creat import options based on file content
	opts.DataLine = 3; % set data line from the third row of csv file. First 2 rows are 'char'
	opts.VariableDescriptionsLine = 2; % set 2nd row as variable description
	ROI_table = readtable(roi_readout_file, opts); % import file using modified opts, so data will be number arrays
    [ROI_table, recording_time, ROI_num] = ROI_calc_plot(ROI_table);
	cell_num = cell_num + size(ROI_table, 2);
	ROIdata{n, 1} = roi_readout_file_info(n).name;
	ROIdata{n, 2} = ROI_table;

	% decide whether there is a gpio file for this roi file. If yes, get GPIO info
	filename_stem = roi_readout_file_info(n).name(1:25); % filename like recording_20190910_130653 (25 letters+numbers)
	gpio_file_info = dir([roi_readout_file_folder, '\', filename_stem, '*gpio*.csv']); % looking for accompnied gpio file
	if ~isempty(gpio_file_info)
		gpio_file = fullfile(gpio_file_info.folder, gpio_file_info.name);
		GPIO_table = readtable(gpio_file);
		[ channel, EX_LED_power, GPIO_duration, stimulation ] = GPIO_data_extract(GPIO_table);
		ROIdata{n, 3} = stimulation;
		ROIdata{n, 4} = channel;
	else
	end
end
varargout{1} = numel(roi_readout_file_info); % recording numbers
varargout{2} = cell_num; % total cell numbers
[ROIdata_file, ROIdata_path] = uiputfile([output_dir, '/*.mat'], 'Save ROIdata into a .matfile');
if isequal(ROIdata_file,0) || isequal(ROIdata_path,0)
   disp('User clicked Cancel.')
else
   disp(['User selected ',fullfile(ROIdata_path,ROIdata_file),...
         ' and then clicked Save.'])
   save(fullfile(ROIdata_path,ROIdata_file),'ROIdata');
end


