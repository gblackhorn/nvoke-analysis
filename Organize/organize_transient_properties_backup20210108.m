function [TransientProperties,varargout] = organize_transient_properties(RecInfoTable,varargin)
    % Read a table (RecInfoTable) containing time and traces information. Find peaks in traces
    % and output properties of peaks/transients, such as locations of rises and
    % their durations
    %   RecInfoTable: a table variable
    %		- 1st col: time infomation
    %		- 2nd-end col: traces

    % Defaults
    filter_chosen = 'none';
    prominence_factor = 4;
    filter_parameter = 1; % default Hz for lowpass filter
    rec_fq = 10; % recording frequency in Hz
    decon = 0;
    smooth_method = 'loess';
    existing_peakInfo = [];
    existing_peak_duration_extension_time_pre  = 0.3 % duration in second, before existing peak rise 
    existing_peak_duration_extension_time_post = 0 % duration in second, after decay

    % pack_singlerow_table_in_cell = 0;
    [transient_properties_variable_names] = transient_properties_variable_names('peak');
	% TransientProperties_col_names_highpass = {'std'};

	% Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('filter', varargin{ii})
    		filter_chosen = varargin{ii+1};
    	elseif strcmpi('prom_par', varargin{ii})
    		prominence_factor = varargin{ii+1};
    	elseif strcmpi('filter_par', varargin{ii})
    		filter_parameter = varargin{ii+1};
		elseif strcmpi('recording_fq', varargin{ii})
			rec_fq = varargin{ii+1};
		elseif strcmpi('existing_peakInfo', varargin{ii})
			existing_peakInfo = varargin{ii+1};
		elseif strcmpi('decon', varargin{ii})
			decon = varargin{ii+1};
		elseif strcmpi('TransientProperties_names', varargin{ii})
			transient_properties_variable_names = varargin{ii+1};
		elseif strcmpi('extension_time_pre', varargin{ii}) 
			existing_peak_duration_extension_time_pre = varargin{ii+1};
		elseif strcmpi('extension_time_post', varargin{ii}) 
			existing_peak_duration_extension_time_post = varargin{ii+1};
    end

   	look_for_peaks = 1; % default: find peaks and calculate properties. When 'highpass' filter is applied, this will be changed to 0 automatically
   	roi_names = RecInfoTable.Properties.VariableNames(2:end);
    time_info = RecInfoTable{:, 1}; % RecInfoTable.Time
    roi_num = size(RecInfoTable, 2)-1; % number of rois/traces
    rec_fq = 1/(time_info(10)-time_info(9));
    TransientProperties = cell(1, roi_num);

    % process traces and extract transient properties
   	RecInfoTable_processed = RecInfoTable; % allocate ram for RecInfoTable_processed
    for n = 1:roi_num % go through every roi
    	roi_trace = RecInfoTable{:, (n+1)};
    	if decon == 1
    		[peak_par,processed_data_and_info] = findpeaks_after_filter(roi_trace,'decon',1);

    	elseif decon == 0
    		if strcmpi('highpass', filter_chosen)
    			[peak_par,processed_data_and_info] = findpeaks_after_filter(roi_trace,...
    				'decon',0, 'filter', filter_chosen, 'filter_par', filter_parameter,...
    				'recording_fq', rec_fq);
    			roi_trace_std = peak_par.std;
    			look_for_peaks = 0; % Don't look for peak if traces are highpass filtered
    			[transient_properties_variable_names] = transient_properties_variable_names('std');
    		else
    			[peak_par,processed_data_and_info] = findpeaks_after_filter(roi_trace,...
    				'decon',0, 'filter', filter_chosen, 'filter_par', filter_parameter,...
    				'recording_fq', rec_fq, 'prom_par', prominence_factor, 'time_info', time_info);
    		end
    	end
    	RecInfoTable_processed{:, (n+1)} = processed_data_and_info.processed_trace;

    	if look_for_peaks == 1
    		peakMag = peak_par.peakMag;
    		peakLoc = peak_par.peakLoc;
    		TransientProperties{n} = calculate_transient_properties(roi_trace,time_info,...
    			peakMag,peakLoc,'slope_per_low', 0.1, 'slope_per_high', 0.9);

			TransientProperties{n} = array2table(TransientProperties{n},...
				'VariableNames', transient_properties_variable_names(1:17));
		elseif look_for_peaks == 0
			TransientProperties{n} = [roi_trace_std];
			TransientProperties{n} = array2table(TransientProperties(n),...
    				'VariableNames', transient_properties_variable_names);
    	end
    end
	TransientProperties = cell2table(TransientProperties, 'VariableNames', roi_names);
    if nargout >= 2 % return the processed traces data with time info and processing method
    	varargout{1}.processed_data = RecInfoTable_processed;
    	varargout{1}.method = filter_name;
    	varargout{1}.parameter = filter_parameter;
    end
end

