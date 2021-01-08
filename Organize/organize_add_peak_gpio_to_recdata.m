function [recdata_organized,varargout] = organize_add_peak_gpio_to_recdata(recdata,varargin)
    % add organized gpio information and peak information to recdata, which
    % includes recording names, decon and raw data, gpio raw data from nVoke 
    %   Detailed explanation goes here
    
    % Defaults
    lowpass_fpass = 1;
    highpass_fpass = 4;   
    smooth_method = 'loess';
    smooth_span = 0.1;
    prominence_factor = 4; % prominence_factor doesn't influence peak finding in decon data
    existing_peak_duration_extension_time_pre  = 0.3; % duration in second, before existing peak rise 
    existing_peak_duration_extension_time_post = 0; % duration in second, after decay
    criteria_rise_time = [0 0.8]; % unit: second. filter to keep peaks with rise time in the range of [min max]
    criteria_slope = [3 80]; % default: slice-[50 2000]
    							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
    							% ventral approach default: [3 80]
    							% slice default: [50 2000]
    % criteria_mag = 3; % default: 3. peak_mag_normhp
    criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
    criteria_excitated = 2; % If a peak starts to rise in 2 sec since stimuli, it's a excitated peak
    criteria_rebound = 1; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end
    stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    % use_criteria = true; % true or false. choose to use criteria or not for picking peaks
    stim_pre_time = 10; % time (s) before stimuli start
    stim_post_time = 10; % time (s) after stimuli end
    plot_traces = 0; % 0: do not plot. 1: plot. 2: plot with pause
    save_traces = 0; % 0: do not save. 1: save
    [peak_properties_variable_names] = peak_properties_variable_names('peak', [1:17]);

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('lowpass_fpass', varargin{ii})
    		lowpass_fpass = varargin{ii+1};
		if strcmpi('highpass_fpass', varargin{ii})
    		highpass_fpass = varargin{ii+1};
		if strcmpi('smooth_method', varargin{ii})
    		smooth_method = varargin{ii+1};
		if strcmpi('smooth_span', varargin{ii})
    		smooth_span = varargin{ii+1};
    	elseif strcmpi('prominence_factor', varargin{ii})
    		prominence_factor = varargin{ii+1};
		elseif strcmpi('extension_time_pre', varargin{ii}) 
			existing_peak_duration_extension_time_pre = varargin{ii+1};
		elseif strcmpi('extension_time_post', varargin{ii}) 
			existing_peak_duration_extension_time_post = varargin{ii+1};
		elseif strcmpi('criteria_rise_time', varargin{ii})
    		criteria_rise_time = varargin{ii+1};
		elseif strcmpi('criteria_slope', varargin{ii})
			criteria_slope = varargin{ii+1};
		elseif strcmpi('criteria_pnr', varargin{ii})
			criteria_pnr = varargin{ii+1};
		elseif strcmpi('criteria_excitated', varargin{ii}) % needed for smooth process
			criteria_excitated = varargin{ii+1};
		elseif strcmpi('criteria_rebound', varargin{ii}) % needed for smooth process
			criteria_rebound = varargin{ii+1};
		elseif strcmpi('stim_time_error', varargin{ii}) % needed for smooth process
			stim_time_error = varargin{ii+1};
		% elseif strcmpi('use_criteria', varargin{ii}) % needed for smooth process
		% 	use_criteria = varargin{ii+1};
		elseif strcmpi('stim_pre_time', varargin{ii}) % needed for smooth process
			stim_pre_time = varargin{ii+1};
		elseif strcmpi('stim_post_time', varargin{ii}) % needed for smooth process
			stim_post_time = varargin{ii+1};
		elseif strcmpi('plot_traces', varargin{ii}) % needed for smooth process
			plot_traces = varargin{ii+1};
		elseif strcmpi('save_traces', varargin{ii}) % needed for smooth process
			save_traces = varargin{ii+1};
    	end
    end

    % column numbers and contents of recdata
    col_name = 1;
    col_trace = 2;
    col_gpioname = 3;
    col_gpioinfo = 4;
    col_peak = 5;

    % Main contents
    recdata_organized = recdata; % allocate ram
    recording_num = size(recdata_organized, 1);
    for rn = 1:recording_num
    	recording_name = recdata_organized{rn, col_name};
    	rec_data_decon = recdata_organized{rn, col_trace}.decon; % deconvoluted data processed by CNMFe
    	rec_data_raw = recdata_organized{rn, col_trace}.raw; % data after removing background, neuropil, and demixing 
    	roi_num = size(rec_data_decon, 2)-1;

    	% Organize stimulation channel properties: name, duration, train window, etc.
    	if ischar(recdata_organized{rn, col_gpioname})
    		stim_name = recdata_organized{rn, col_gpioname};
    	elseif iscell(recdata_organized{rn, col_gpioname})
    		stim_name = recdata_organized{rn, col_gpioname}{:};
    	end
    	if isempty(stim_name)
    		stim_str = 'no-stim';
    	elseif strfind(stim_name, 'noStim')
    		stim_str = 'no-stim';
    	else
    		[recdata_organized{rn, col_gpioinfo}, gpio_info_table] = organize_gpio_info(gpio_info,...
    			'stim_idx_start', 3, 'round_digit', 0);
    		stim_str = join(gpio_info_table.stim_ch_str);
    	end 
    	recdata_organized{rn, col_gpioname} = stim_str;


    	% Process data, find peaks and extract their properties
    	[rec_data_decon] = ROI_calc_plot(rec_data_decon); % make sure table variable name for timeinfo is correct
    	[rec_data_raw] = ROI_calc_plot(rec_data_raw); % make sure table variable name for timeinfo is correct
    	% Get peak properties from decon data
    	[peak_properties_decon, data_table_processed_decon] = organize_transient_properties(rec_data_decon,...
			'decon', 1, 'prom_par', prominence_factor,...
			'peakProperties_names', peak_properties_variable_names);
		% lowpass
		[peak_properties_lowpass, rec_data_lowpass] = organize_transient_properties(rec_data_raw,...
			'decon', 0, 'filter', 'lowpass', 'filter_par', lowpass_fpass,...
			'prom_par', prominence_factor, 'existing_peakInfo', peak_properties_decon,...
			'peakProperties_names', peak_properties_variable_names); 
		% smooth
		[peak_properties_smooth, rec_data_smooth] = organize_transient_properties(rec_data_raw,...
			'decon', 0, 'filter', 'smooth', 'filter_par', smooth_span, 'smooth_method', smooth_method,...
			'prom_par', prominence_factor, 'existing_peakInfo', peak_properties_decon,...
			'peakProperties_names', peak_properties_variable_names);
		% Get std of highpassed data. std is used to normalized peak amplitude
		[peak_properties_highpass, rec_data_highpass] = organize_transient_properties(rec_data_raw,...
			'decon', 0, 'filter', 'highpass', 'filter_par', highpass_fpass,...
			'peakProperties_names', 'highpass_std'); 

		% screen peaks with criteria
		[peak_properties_lowpass] = organize_screen_peaks_multirois(peak_properties_lowpass,...
			peak_properties_highpass, 'rise_time', criteria_rise_time,...
			'slope', criteria_slope, 'pnr', criteria_pnr);
		[peak_properties_smooth] = organize_screen_peaks_multirois(peak_properties_smooth,...
			peak_properties_highpass, 'rise_time', criteria_rise_time,...
			'slope', criteria_slope, 'pnr', criteria_pnr);

		% category peaks
		% [peak_category] = organize_category_peaks(peak_properties_table,gpio_info_table,varargin)
		[peak_properties_lowpass] = organize_category_peaks_multirois(peak_properties_lowpass,...
			gpio_info_table, 'stim_time_error', stim_time_error);
		[peak_properties_smooth] = organize_category_peaks_multirois(peak_properties_smooth,...
			gpio_info_table, 'stim_time_error', stim_time_error);
    end


end

