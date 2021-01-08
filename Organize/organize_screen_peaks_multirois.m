function [peak_properties_tables_screened,varargout] = organize_screen_peaks_multirois(peak_properties_tables,highpass_data_stds, varargin)
    % use function "organize_screen_peaks" to screen peak from multiple rois
    % from the same recording.
    %   Detailed explanation goes here
    
    % Defaults
    criteria_rise_time = [0 0.8]; % unit: second. filter to keep peaks with rise time in the range of [min max]
    criteria_slope = [3 80]; % default: slice-[50 2000]
    							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
    							% ventral approach default: [3 80]
    							% slice default: [50 2000]
    % criteria_mag = 3; % default: 3. peak_mag_normhp
    criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('rise_time', varargin{ii})
    		criteria_rise_time = varargin{ii+1};
    	elseif strcmpi('slope', varargin{ii})
    		criteria_slope = varargin{ii+1};
    	elseif strcmpi('pnr', varargin{ii})
    		criteria_pnr = varargin{ii+1};
        end
    end

    % main contents
    peak_properties_tables_screened = peak_properties_tables;
    roi_num = size(peak_properties_tables, 2);
    for rn = 1:roi_num
    	peak_properties_table_single = peak_properties_tables{1, rn}{:};
    	highpass_data_std_single = highpass_data_stds{1, rn};
    	[peak_properties_table_single] = organize_screen_peaks(peak_properties_table_single,...
    		highpass_data_std_single, 'rise_time', criteria_rise_time,...
    		'slope', criteria_slope, 'pnr', criteria_pnr)
    	peak_properties_tables_screened{1, rn}{:} = peak_properties_table_single;
    end
    if nargout >= 2 % return the processed traces data with time info and processing method
	    varargout{1}.criteria_rise_time = criteria_rise_time;
	    varargout{1}.criteria_slope = criteria_slope;
	    varargout{1}.criteria_pnr = criteria_pnr;
	end 
end

