function [transient_properties,varargout] = organize_transient_properties(RecInfoTable,varargin)
    % Read a table (RecInfoTable) containing time and traces information. Find peaks in traces
    % and output properties of peaks/transients, such as locations of rises and
    % their durations
    %   RecInfoTable: a table variable
    %		- 1st col: time infomation
    %		- 2nd-end col: traces

    % Defaults
    filter_chosen = 'none';
    prominence_factor = 4;
    filter_par = 1; % default Hz for lowpass filter
    rec_fq = 10; % recording frequency in Hz
    decon = 0;
    smooth_method = 'loess';
    use_existing_peakInfo = false;
    existing_peakInfo = cell2table(cell(1, (size(RecInfoTable, 2)-1)));
    existing_peak_duration_extension_time_pre  = 0; % duration in second, before existing peak rise 
    existing_peak_duration_extension_time_post = 1; % duration in second, after decay
    merge_peaks = false;
    merge_time_interval = 0.5; % default: 0.5s. peak to peak interval.

    % pack_singlerow_table_in_cell = 0;
    [transient_prop_var_names] = transient_properties_variable_names('peak', [1:18]);
	% transient_properties_col_names_highpass = {'std'};
    debug_mode = false; % true/false

	% Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('filter', varargin{ii})
    		filter_chosen = varargin{ii+1};
    	elseif strcmpi('prom_par', varargin{ii})
    		prominence_factor = varargin{ii+1};
    	elseif strcmpi('filter_par', varargin{ii})
    		filter_par = varargin{ii+1};
		elseif strcmpi('recording_fq', varargin{ii})
			rec_fq = varargin{ii+1};
		elseif strcmpi('use_existing_peakInfo', varargin{ii})
			use_existing_peakInfo = varargin{ii+1};
		elseif strcmpi('existing_peakInfo', varargin{ii})
            existing_peakInfo = varargin{ii+1};
        elseif strcmpi('decon', varargin{ii})
			decon = varargin{ii+1};
		elseif strcmpi('transient_properties_names', varargin{ii})
			transient_prop_var_names = varargin{ii+1};
		elseif strcmpi('extension_time_pre', varargin{ii}) 
			existing_peak_duration_extension_time_pre = varargin{ii+1};
		elseif strcmpi('extension_time_post', varargin{ii}) 
			existing_peak_duration_extension_time_post = varargin{ii+1};
        elseif strcmpi('merge_peaks', varargin{ii}) % needed for smooth process
            merge_peaks = varargin{ii+1};
        elseif strcmpi('merge_time_interval', varargin{ii})
            merge_time_interval = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        end
    end

   	look_for_peaks = 1; % default: find peaks and calculate properties. When 'highpass' filter is applied, this will be changed to 0 automatically
   	roi_names = RecInfoTable.Properties.VariableNames(2:end);
    time_info = RecInfoTable{:, 1}; % RecInfoTable.Time
    roi_num = size(RecInfoTable, 2)-1; % number of rois/traces
    rec_fq = 1/(time_info(10)-time_info(9));
    transient_properties = cell(1, roi_num);
    transient_prop_var_names = transient_prop_var_names(1:20);

    % process traces and extract transient properties
   	RecInfoTable_processed = RecInfoTable; % allocate ram for RecInfoTable_processed
    for n = 1:roi_num % go through every roi

        % Debugging
        % disp(['roi_num: ', num2str(n)])
        if debug_mode
            fprintf('  roi_num: %d/%d\n', n, roi_num);
            if n == 29
                disp('pause for debugging')
                pause
            end
        end


    	roi_trace = RecInfoTable{:, (n+1)};
        if strcmpi('highpass', filter_chosen)
            [peak_par,processed_data_and_info] = findpeaks_after_filter(roi_trace,...
                'filter', filter_chosen, 'filter_par', filter_par, 'recording_fq', rec_fq);
            transient_properties{n} = peak_par.std;
            [transient_prop_var_names] = transient_properties_variable_names('std');
        else
            if use_existing_peakInfo % look for peaks/transients with a set of peak data
                if size(existing_peakInfo{1, n}, 2) ~= 1
                    peakInfo = existing_peakInfo{1, n};
                else
                    peakInfo = existing_peakInfo{1, n}{:,:};
                end
                if ~isempty(peakInfo)
                    [peak_par, processed_data_and_info] = find_peaks_with_existing_peakinfo(roi_trace,...
                        peakInfo, 'filter', filter_chosen, 'filter_par', filter_par,...
                        'recording_fq', rec_fq, 'decon', decon, 'time_info', time_info,...
                        'extension_time_pre', existing_peak_duration_extension_time_pre,...
                        'extension_time_post', existing_peak_duration_extension_time_post,...
                        'merge_peaks', merge_peaks, 'merge_time_interval', merge_time_interval);
                    transient_properties{n} = calculate_transient_properties(processed_data_and_info.processed_trace,...
                        time_info, peak_par.peakMag, peak_par.peakLoc,...
                        'slope_per_low', 0.1, 'slope_per_high', 0.9, 'existing_peakInfo', peakInfo,...
                        'extension_time_pre', existing_peak_duration_extension_time_pre,...
                        'extension_time_post', existing_peak_duration_extension_time_post);
                else
                    transient_properties{n} = peakInfo;
                end
            else
                [peak_par,processed_data_and_info] = findpeaks_after_filter(roi_trace,...
                    'decon', decon, 'filter', filter_chosen, 'filter_par', filter_par,...
                    'recording_fq', rec_fq, 'prom_par', prominence_factor, 'time_info', time_info);
                transient_properties{n} = calculate_transient_properties(processed_data_and_info.processed_trace,...
                    time_info, peak_par.peakMag, peak_par.peakLoc,...
                    'slope_per_low', 0.1, 'slope_per_high', 0.9);
            end
            % transient_properties{n} = calculate_transient_properties(processed_data_and_info.processed_trace,...
            %     time_info, peak_par.peakMag, peak_par.peakLoc,...
            %     'slope_per_low', 0.1, 'slope_per_high', 0.9);
            transient_properties{n} = array2table(transient_properties{n},...
                    'VariableNames', transient_prop_var_names);
        end
        RecInfoTable_processed{:, (n+1)} = processed_data_and_info.processed_trace;
        
    end
    transient_properties = cell2table(transient_properties, 'VariableNames', roi_names);
    if nargout >= 2 % return the processed traces data with time info and processing method
        varargout{1}.processed_data = RecInfoTable_processed;
        varargout{1}.method = processed_data_and_info.method;
        varargout{1}.parameter = filter_par;
    end
end

