function [patchCoor,stimName,varargout] = get_gpio_from_csv(path_gpio,varargin)
	% Read a gpio csv file directly exported from ISPS  



	% Defaults
	useGUI = true; % use GUI to load csv file

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('useGUI', varargin{ii})
	        useGUI = varargin{ii+1};
	    % elseif strcmpi('savePlot', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	    %     savePlot = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    end
	end


	% Read a gpio csv file 
	if useGUI
		[file_gpioCSV,folder_gpioCSV] = uigetfile('*.csv', 'Select a gpio CSV file',path_gpio);
		path_gpio = fullfile(folder_gpioCSV,file_gpioCSV);
	else
		[folder_gpioCSV, file_gpioCSV, ext] = fileparts(path_gpio);
	end
	GPIO_table = readtable(path_gpio);


	% extract gpio information from the table
	[channel, EX_LED_power, GPIO_duration, stimulation ] = GPIO_data_extract(GPIO_table);
	[gpio_Info, gpio_info_table] = organize_gpio_info(channel,...
	    			'modify_ch_name', true, 'round_digit_sig', 2); 
	[StimDuration,UnifiedStimDuration,ExtraInfo] = get_stimInfo(gpio_Info);
	patchCoor = {StimDuration.patch_coor};
	stimName = UnifiedStimDuration.type; 

	varargout{1} = folder_gpioCSV;
	varargout{2} = StimDuration;
	varargout{3} = UnifiedStimDuration;

end