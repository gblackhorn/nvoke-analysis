function [peak_properties_tables_add_norm,varargout] = calculate_normalized_value_multirois(peak_properties_tables,highpass_data_stds,varargin)
    % use function "calculate_normalized_value" to calculate normalized value for multiple rois
    % from the same recording.
    %   Detailed explanation goes here
    
    % Defaults

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

    % main contents
    peak_properties_tables_add_norm = cell(size(peak_properties_tables));
    roi_num = size(peak_properties_tables, 2);
    for rn = 1:roi_num
        if size(peak_properties_tables{1, rn}, 2) ~= 1
            peak_properties_table_single = peak_properties_tables{1, rn};
        else
            peak_properties_table_single = peak_properties_tables{1, rn}{:};
        end
        
        if ~isempty(peak_properties_table_single)
        	highpass_data_std_single = highpass_data_stds{1, rn};
        	[peak_properties_table_single] = calculate_normalized_value(peak_properties_table_single,...
        		highpass_data_std_single);
        end
        
        peak_properties_tables_add_norm{1, rn} = peak_properties_table_single;
        
%         if size(peak_properties_tables_add_norm{1, rn}, 2) ~= 1
%             peak_properties_tables_add_norm{1, rn} = peak_properties_table_single;
%         else
%             peak_properties_tables_add_norm{1, rn}{:} = peak_properties_table_single;
%         end
    end
    peak_properties_tables_add_norm = cell2table(peak_properties_tables_add_norm,...
        'VariableNames', peak_properties_tables.Properties.VariableNames);
end

