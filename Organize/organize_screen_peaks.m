function [peak_properties_table_screened, varargout] = organize_screen_peaks(peak_properties_table,highpass_data_std, varargin)
    % Use criterias to screen peaks
    %   peak_properties_table: table variable with VariableNames listed in
    %   function "transient_properties_variable_names". It's the main output of
    %   function "organize_transient_properties". Need to specify only one roi
    %   for this function to work
    
    %	highpass_data_std: output of function "organize_transient_properties" using 'highpass' filter

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

    peak_properties_table_screened = peak_properties_table;
    peak_noise_ratio = peak_properties_table.peak_mag_delta/highpass_data_std;

	idx_fail_rise_time = find(peak_properties_table.rise_duration>=criteria_rise_time(2) & peak_properties_table.rise_duration<=criteria_rise_time(1));
	idx_fail_slope = find(peak_properties_table.peak_slope>=criteria_slope(2) & peak_properties_table.peak_slope<=criteria_slope(1));
	idx_fail_pnr = find(peak_noise_ratio>=criteria_pnr & peak_noise_ratio<=criteria_pnr);

	idx_combine = [idx_fail_rise_time; idx_fail_slope; idx_fail_pnr];
	idx_discard = unique(idx_combine);
    if ~isempty(idx_discard)
        peak_properties_table_screened(idx_discard, :) = [];
    end

	if nargout >= 2 % return the processed traces data with time info and processing method
	    varargout{1}.criteria_rise_time = criteria_rise_time;
	    varargout{1}.criteria_slope = criteria_slope;
	    varargout{1}.criteria_pnr = criteria_pnr;
	end 
end

