function [peak_properties_tables_add_stim_str,varargout] = organize_add_stim_str_to_table_multirois(peak_properties_tables,gpio_info_table,varargin)
    % Add stimulation strings to peak property table
    % Caution (2021.01.10): only works with up to 2 stimulation channels so far 
    %   peak_properties_tables: multiple roi table
    %   gpio_info_table: output of function "organize_gpio_info". multiple stim_ch can be used
    
    % Defaults
    stim_str_full = 'no-stim';

    % main contents
    peak_properties_tables_add_stim_str = cell(size(peak_properties_tables));
    roi_num = size(peak_properties_tables, 2);
    for rn = 1:roi_num
        if size(peak_properties_tables{1, rn}, 2) ~= 1
            peak_properties_table_single = peak_properties_tables{1, rn};
        else
            peak_properties_table_single = peak_properties_tables{1, rn}{:};
        end

    	stim_ch_num = size(gpio_info_table, 1);
        stim = cell(size(peak_properties_table_single.rise_time));
    	if ~isempty(gpio_info_table)
            stim_str_full = join(gpio_info_table.stim_ch_str);
     %        stim = cellfun(@(x) stim_str_full, stim, 'UniformOutput', false);
	    % else
	    % 	stim = cellfun(@(x) stim_str_full, stim, 'UniformOutput', false);
	    end
        stim = cellfun(@(x) stim_str_full, stim, 'UniformOutput', false);

        peak_properties_table_single = addvars(peak_properties_table_single,stim);
        peak_properties_tables_add_stim_str{1, rn} = peak_properties_table_single;
	    % peak_properties_tables_add_stim_str{1, rn}{:} = [peak_properties_table_single, peak_category];
    end
    peak_properties_tables_add_stim_str = cell2table(peak_properties_tables_add_stim_str,...
        'VariableNames', peak_properties_tables.Properties.VariableNames);
end

