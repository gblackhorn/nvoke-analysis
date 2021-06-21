function [ROIdata,varargout] = ROI_matinfo2matlab_invitro(sample_frequency, varargin)
    % Read CNMFe exported *results.mat for calcium info, and waveforms.csv for precise recording
    % start time all recordings should have the same sampling frequency, stimulation start time
    % (stim_start), and stimulation duration (stim_duration)
    % number of input: 1 (no stimulation) or 3 (sample_frequency, stim_start, stim_duration)
    stim_frequency = 20; % Hz. Ask Kevin about it
    stim_pulse_time = 0.01; % time duration of a single pulse

    if nargin ~= 1 &&  nargin ~= 3
    	disp('Either input 1 var (sampling frequency) or 3 var (sampling frequency, stim start time, and stim duration)');
    	return
    end
    switch  nargin
    case 1
    	stim_exist = 0;
    	stim = { };
    case 3
    	stim_exist = 1;
    	input_prompt_stim = 'Input stimulation name: ';
    	input_str_stim =  input(input_prompt_stim, 's');
    	if isempty(input_str_stim)
    		input_str_stim = 'no input';
    		stim = input_str_stim;
    		stim_start = varargin(2); % time in s
    		stim_duration = varargin(3); % time in s
    		stimT = 0:1/1e3:(stim_start+stim_duration+1); % time frequency for stimulation
    		stimD = [(stim_start+stim_pulse_time/2):1/stim_frequency:(stim_start+stim_duration)];
    		stim_pulse = 5*pulstran(stimT, stimD, @rectpuls, stim_pulse_time);
    		stimT = stimT';
    		stim_pulse = stim_pulse';
    		stim_info = [stimT stim_pulse];
    	end
    end

    if ispc
    	input_dir = 'G:\Workspace\Inscopix_Seagate\Projects\';
    	output_dir = 'G:\Workspace\Inscopix_Seagate\Analysis\';
    elseif isunix
    	input_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/ventral_exported_decon_demix_rawdata/';
    	output_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
    end

    roi_readout_file_folder = uigetdir(input_dir, 'Select a folder containing CNMF-E processed results');

    % roi_readout_file_info = dir([roi_readout_file_folder, '\', '*-ROI.csv']);
    if ispc
    	time_readout_file_info = dir([roi_readout_file_folder, '\*waveforms*.csv']); % file containing raw ROI data with time info
    	roi_readout_file_info_processed = dir([roi_readout_file_folder, '\*results*.mat']); % file containing CNMF-E processed data
    elseif isunix
    	time_readout_file_info = dir([roi_readout_file_folder, '/*waveforms*.csv']); % file containing raw ROI data with time info
    	roi_readout_file_info_processed = dir([roi_readout_file_folder, '/*results*.mat']); % file containing CNMF-E processed data
    end

    cell_num = 0;
    for n = 1:numel(roi_readout_file_info_processed)
    	roi_readout_file_processed = fullfile(roi_readout_file_info_processed(n).folder, roi_readout_file_info_processed(n).name);
    	load(roi_readout_file_processed, 'results'); % load CNMF-E processed results
    	CalSig_decon = results.C; % results.C has deconvoluted and demixed data. Each row is a neuron
    	CalSig_raw = results.C_raw; % raw data
    	CalSig_decon = CalSig_decon'; % transpose matrix to have neurons arranged in columns
    	CalSig_raw = CalSig_raw';
    	image_num = size(CalSig_decon, 1); % number of images in the stack

    	% prepare neuron name for table
    	neuron_name = {};
    	for nn = 1:size(CalSig_decon, 2) % from 1 to number of columns (neurons)
    		neuron_name{nn} = ['neuron', num2str(nn)];
    	end

    	CalSig_decon = array2table(CalSig_decon, 'VariableNames', neuron_name); % convert CalSig_decon to table. Use neuron name as column names
    	CalSig_raw = array2table(CalSig_raw, 'VariableNames', neuron_name); 

    	time_readout_file  = fullfile(time_readout_file_info(n).folder, time_readout_file_info(n).name);
    	opts = detectImportOptions(time_readout_file); % creat import options based on file content
    	opts.DataLine = 2; % set data line from the third row of csv file. First 2 rows are 'char'
    	opts.VariableDescriptionsLine = 1; % set 2nd row as variable description
    	time_table = readtable(time_readout_file, opts); % import file using modified opts, so data will be number arrays
    	time_table.Properties.VariableNames{1} = 'Time'; % set first column varible name as Time
    	rec_start_time = table2array(time_table(1,1)); % time when first image was taken
    	rec_duration = table2array(time_table(end,1)); % use the last time point as the recording duration. This might be wrong if recording is trimmed

    	ROIdata{n, 1} = roi_readout_file_info_processed(n).name; % name of recording
    	time_info = [1:image_num]'; 
    	time_info = time_info*(1/sample_frequency);
    	time_info_start_error = rec_start_time-time_info(1);
    	time_info = time_info+time_info_start_error;
    	time_info_table = array2table(time_info, 'VariableNames', {'Time'});

    	CalSig_decon = [time_info_table CalSig_decon]; % concatanate time and roi info into the same table
    	CalSig_raw = [time_info_table CalSig_raw];

    	ROIdata{n, 2}.decon = CalSig_decon;
    	ROIdata{n, 2}.raw = CalSig_raw;

    	ROIdata{n, 3} = stim;
    	ROIdata{n, 4}(1).name{:} = 'placeholder to make in vitro data compatible to in vivo format'; % in vitro data placeholder
    	ROIdata{n, 4}(1).time_value{:} = []; % in vitro data placeholder
    	ROIdata{n, 4}(2).name{:} = 'placeholder to make in vitro data compatible to in vivo format'; % in vitro data placeholder
    	ROIdata{n, 4}(2).time_value{:} = []; % in vitro data placeholder
    	if stim_exist == 1
    		ROIdata{n, 4}(3).name{:} = stim;
    		ROIdata{n, 4}(3).time_value = stim_info;
    	end
    end

    [ROIdata_file, ROIdata_path] = uiputfile([output_dir, '/*.mat'], 'Save ROIdata into a .matfile');
    if isequal(ROIdata_file,0) || isequal(ROIdata_path,0)
       disp('User clicked Cancel.')
    else
       disp(['User selected ',fullfile(ROIdata_path,ROIdata_file),...
             ' and then clicked Save.'])
       save(fullfile(ROIdata_path,ROIdata_file),'ROIdata');
    end

end

