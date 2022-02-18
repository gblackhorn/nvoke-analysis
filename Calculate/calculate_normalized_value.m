function [peak_properties_table_screened, varargout] = calculate_normalized_value(peak_properties_table,highpass_data_std, varargin)
    % calculate normalized peak_mag_delta, peak_mag_10percent, peak_slope, etc.
    %   peak_properties_table: table variable with VariableNames listed in
    %   function "transient_properties_variable_names". It's the main output of
    %   function "organize_transient_properties". Need to specify only one roi
    %   for this function to work
    
    %	highpass_data_std: output of function "organize_transient_properties" using 'highpass' filter

    % % Defaults
    % str_idx_peak_delta_norm_hpstd = 18; % index of specific string in transient_properties_variable_names
    % str_idx_peak_mag_10per_norm_hpstd = 19; % index of specific string in transient_properties_variable_names
    % str_idx_peak_mag_90per_norm_hpstd = 20; % index of specific string in transient_properties_variable_names
    % str_idx_peak_slope_norm_hpstd = 21; % index of specific string in transient_properties_variable_names

    % % Optionals for inputs
    % for ii = 1:2:(nargin-2)
    % 	if strcmpi('rise_time', varargin{ii})
    % 		criteria_rise_time = varargin{ii+1};
    % 	elseif strcmpi('slope', varargin{ii})
    % 		criteria_slope = varargin{ii+1};
    % 	elseif strcmpi('pnr', varargin{ii})
    % 		criteria_pnr = varargin{ii+1};
    %     end
    % end

    peak_properties_table_screened = peak_properties_table; % allocate ram for output
    peak_delta = peak_properties_table.peak_mag_delta;

    % Calculation
    peak_delta_norm_hpstd = peak_delta/highpass_data_std;
    peak_mag_10percent_norm_hpstd = peak_properties_table.peak_mag_10percent/highpass_data_std;
    peak_mag_90percent_norm_hpstd = peak_properties_table.peak_mag_90percent/highpass_data_std;
    peak_slope_norm_hpstd = peak_properties_table.peak_slope/highpass_data_std;

    % Add the calculated normalized value to peak_properties_table 
    peak_properties_table_screened = addvars(peak_properties_table_screened,...
        peak_delta_norm_hpstd,peak_mag_10percent_norm_hpstd,peak_mag_90percent_norm_hpstd,...
        peak_slope_norm_hpstd);
    
%     peak_properties_table_screened = [peak_properties_table_screened,...
%         peak_delta_norm_hpstd,...
%         peak_mag_10percent_norm_hpstd, peak_mag_90percent_norm_hpstd,...
%         peak_slope_norm_hpstd];
end

