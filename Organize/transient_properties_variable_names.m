function [transient_properties_variable_names] = transient_properties_variable_names(output_type, varargin)
    % return transient_properties_variable_names
    %   output_type: 
    %		- 'peaks'
    %		- 'std': for highpass filtered data
    %	varargin{1}: specify the strings in transient_properties_variable_names

    % Defaults
    transient_properties_variable_names = {'peak_loc', 'peak_mag', 'rise_loc', 'decay_loc','peak_time',...
	'rise_time', 'decay_time', 'rise_duration', 'decay_duration', 'peak_mag_relative',...
	'peak_loc_25percent', 'peak_mag_25percent', 'peak_time_25percent', 'peak_loc_75percent', 'peak_mag_75percent',...
	'peak_time_75percent', 'peak_slope', 'peak_norm_hpstd'};
	str_select = [1:length(transient_properties_variable_names)];

    if nargin == 2
    	str_select = varargin{1};
    end
    
    if strcmpi('peak', output_type)
    	transient_properties_variable_names = transient_properties_variable_names(str_select);
    elseif strcmpi('std', output_type)
        transient_properties_variable_names = {'std'};
end

