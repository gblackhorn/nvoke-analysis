function [transient_properties_variable_names] = transient_properties_variable_names(output_type)
    %UNTITLED9 Summary of this function goes here
    %   Detailed explanation goes here
    
    if strcmpi('peak', output_type)
        transient_properties_variable_names = {'peak_loc', 'peak_mag', 'rise_loc', 'decay_loc','peak_time',...
	'rise_time', 'decay_time', 'rise_duration', 'decay_duration', 'peak_mag_relative',...
	'peak_loc_25percent', 'peak_mag_25percent', 'peak_time_25percent', 'peak_loc_75percent', 'peak_mag_75percent',...
	'peak_time_75percent', 'peak_slope', 'peak_zscore'};;
    elseif strcmpi('std', output_type)
        transient_properties_variable_names = {'std'};
end

