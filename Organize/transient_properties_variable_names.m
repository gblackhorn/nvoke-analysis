function [transient_properties_variable_names] = transient_properties_variable_names(output_type, varargin)
    % return transient_properties_variable_names
    %   output_type: 
    %		- 'peaks'
    %		- 'std': for highpass filtered data
    %	varargin{1}: specify the strings in transient_properties_variable_names

    % Defaults
    transient_properties_variable_names = {'peak_loc', 'peak_mag', 'rise_loc', 'decay_loc','peak_time',...
	'rise_time', 'decay_time', 'rise_duration', 'decay_duration', 'peak_mag_delta',...
	'peak_loc_10percent', 'peak_mag_10percent', 'peak_time_10percent', 'peak_loc_90percent', 'peak_mag_90percent',...
	'peak_time_90percent', 'peak_slope', 'peak_delta_norm_hpstd', 'peak_mag_10percent_norm_hpstd', 'peak_mag_90percent_norm_hpstd',...
    'peak_slope_norm_hpstd', 'stim_info', 'peak_category'};

    if nargin == 2
        str_select = varargin{1};
    end

	str_select = [1:length(transient_properties_variable_names)];
   
    
    if strcmpi('peak', output_type)
    	transient_properties_variable_names = transient_properties_variable_names(str_select);
    elseif strcmpi('std', output_type)
        transient_properties_variable_names = {'std'};
end

