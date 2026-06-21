function [recdata, varargout] = ROI_matinfo2matlab(varargin)
	%ROIinfo2matlab 
	% read all ROI.csv in a folder and get info into matlab
	%   Detailed explanation goes here

	if ispc
		input_dir = 'G:\Workspace\Inscopix_Seagate\Projects\';
		output_dir = 'D:\guoda\Documents\Workspace\Analysis\nVoke\Ventral_approach\processed mat files\';
	elseif isunix
		input_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/ventral_exported_decon_demix_rawdata/';
		output_dir = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
	end
	debug_mode = false;
	default_frame_rate = 20; % Hz. Used when no matching ROI CSV is available.

	% Optionals for inputs
	for ii = 1:2:(nargin)
		if strcmpi('input_dir', varargin{ii})
			input_dir = varargin{ii+1};
		elseif strcmpi('output_dir', varargin{ii})
			output_dir = varargin{ii+1};
		elseif strcmpi('debug_mode', varargin{ii})
			debug_mode = varargin{ii+1};
		elseif strcmpi('default_frame_rate', varargin{ii})
			default_frame_rate = varargin{ii+1};
		end
	end

	roi_readout_file_folder = uigetdir(input_dir, 'Select a folder containing CNMF-E processed results');

	% roi_readout_file_info = dir([roi_readout_file_folder, '\', '*-ROI.csv']);
	% if ispc
	% 	roi_readout_file_info = dir([roi_readout_file_folder, '\*ROI*.csv']); % file containing raw ROI data with time info
	% 	roi_readout_file_info_processed = dir([roi_readout_file_folder, '\*results*.mat']); % file containing CNMF-E processed data
	% elseif isunix
	% 	roi_readout_file_info = dir([roi_readout_file_folder, '/*ROI*.csv']); % file containing raw ROI data with time info
	% 	roi_readout_file_info_processed = dir([roi_readout_file_folder, '/*results*.mat']); % file containing CNMF-E processed data
	% end

	roi_readout_file_info = dir(fullfile(roi_readout_file_folder, '*ROI*.csv')); % file containing raw ROI data with time info
	roi_readout_file_info_processed = dir(fullfile(roi_readout_file_folder, '*results*.mat')); % file containing CNMF-E processed data


	cell_num = 0;

	for n = 1:numel(roi_readout_file_info_processed)
		if debug_mode
			fprintf('%d/%d: %s\n',n,numel(roi_readout_file_info_processed),roi_readout_file_info_processed(n).name)
			if n == 7
				pause
			end
		end
		roi_readout_file_processed = fullfile(roi_readout_file_info_processed(n).folder, roi_readout_file_info_processed(n).name);
		load(roi_readout_file_processed, 'results'); % load CNMF-E processed results
		% roiSpatialComponents = results.A; % spatial components of neurons
		CalSig_decon = results.C; % temporal components of neurons. results.C has deconvoluted and demixed data. Each row is a neuron
		CalSig_raw = results.C_raw; % raw data
		CalSig_decon = CalSig_decon'; % transpose matrix to have neurons arranged in columns
		CalSig_raw = CalSig_raw';

		% prepare neuron name for table
		neuron_name = {};
		for nn = 1:size(CalSig_decon, 2) % from 1 to number of columns (neurons)
			neuron_name{nn} = ['neuron', num2str(nn)];
		end
	    
		CalSig_decon = array2table(CalSig_decon, 'VariableNames', neuron_name); % convert CalSig_decon to table. Use neuron name as column names
		CalSig_raw = array2table(CalSig_raw, 'VariableNames', neuron_name); 

		result_file_name = roi_readout_file_info_processed(n).name;
		recording_key = result_file_name(1:min(25, length(result_file_name)));
		matching_roi_idx = find(startsWith({roi_readout_file_info.name}, recording_key, 'IgnoreCase', true));

		if numel(matching_roi_idx) > 1
			error('Multiple ROI CSV files match CNMF-E result file "%s".', result_file_name);
		elseif numel(matching_roi_idx) == 1
			roi_file_info = roi_readout_file_info(matching_roi_idx);
			roi_readout_file = fullfile(roi_file_info.folder, roi_file_info.name);
			opts = detectImportOptions(roi_readout_file); % create import options based on file content
			opts.DataLine = 3; % set data line from the third row of csv file. First 2 rows are 'char'
			opts.VariableDescriptionsLine = 2; % set 2nd row as variable description
			ROI_table = readtable(roi_readout_file, opts); % import file using modified opts, so data will be number arrays

			trim_frames = find(isnan(ROI_table{:, :}(:, 2))); % find frames trimmed off. Look for nan rows in 1st ROI (table from .csv file)
			ROI_table(trim_frames, :) = []; % delete trimmed frames

			[ROI_table, recording_time, ROI_num] = ROI_calc_plot(ROI_table);
			recording_name = roi_file_info.name;
			time_info_table = ROI_table(:, 'Time'); % time info in table form
		else
			frame_num = height(CalSig_decon);
			Time = (0:(frame_num-1))' / default_frame_rate;
			time_info_table = table(Time);
			recording_name = result_file_name;
			warning('No ROI CSV matched "%s". Generated timestamps at %.g Hz.', ...
				result_file_name, default_frame_rate);
		end
		% cell_num = cell_num + size(ROI_table, 2);
		recdata{n, 1} = recording_name;
		% recdata_raw{n, 1} = roi_readout_file_info(n).name;

		CalSig_decon = [time_info_table CalSig_decon]; % concatanate time and roi info into the same table
		CalSig_raw = [time_info_table CalSig_raw];

		recdata{n, 2}.decon = CalSig_decon;
		recdata{n, 2}.raw = CalSig_raw;
		recdata{n, 2}.cnmfe_results = organize_extract_CNMFspacialInfo(results);

		% decide whether there is a gpio file for this roi file. If yes, get GPIO info
		filename_stem = recording_name(1:min(25, length(recording_name))); % filename like recording_20190910_130653 (25 letters+numbers) or 2020-04-16-15-37-11_video (from nvoke2)
		if ispc
			gpio_file_info = dir([roi_readout_file_folder, '\', filename_stem, '*gpio*.csv']); % looking for accompnied gpio file
			if isempty(gpio_file_info)
				gpio_file_info = dir([roi_readout_file_folder, '\', filename_stem, '*GPIO*.csv']); % looking for accompnied gpio file
			end
		elseif isunix
			gpio_file_info = dir([roi_readout_file_folder, '/', filename_stem, '*gpio*.csv']); % looking for accompnied gpio file
			if isempty(gpio_file_info)
				gpio_file_info = dir([roi_readout_file_folder, '/', filename_stem, '*GPIO*.csv']); % looking for accompnied gpio file
			end
		end 
		if ~isempty(gpio_file_info)
	        % n
	        % gpio_file_info.name
	        % if n == 9
	        %     pause
	        % end
			gpio_file = fullfile(gpio_file_info.folder, gpio_file_info.name);
			GPIO_table = readtable(gpio_file);
			[channel, EX_LED_power, GPIO_duration, stimulation ] = GPIO_data_extract(GPIO_table);
			recdata{n, 3} = stimulation;
			recdata{n, 4} = channel;
		else
		end
	end
	varargout{1} = numel(roi_readout_file_info_processed); % recording numbers
	varargout{2} = cell_num; % total cell numbers
	[recdata_file, recdata_path] = uiputfile([output_dir, '/*.mat'], 'Save recdata into a .matfile');
	if isequal(recdata_file,0) || isequal(recdata_path,0)
	   disp('User clicked Cancel.')
	else
	   disp(['User selected ',fullfile(recdata_path,recdata_file),...
	         ' and then clicked Save.'])
	   save(fullfile(recdata_path,recdata_file),'recdata');
	end
end

