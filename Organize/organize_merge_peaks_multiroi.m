function [peak_properties_tables_updated,varargout] = organize_merge_peaks_multiroi(peak_properties_tables,rec_data,varargin)
    % return data, in which close events are merged
    
    %
    
    % Defaults
    merge_time_interval = 0.5; % default: 0.5s. peak to peak interval.
    slope_per_low  = 0.1; % percentage of peak value (low) to calculate slope
    slope_per_high = 0.9; % percentage of peak value (high) to calculate slope

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('merge_time_interval', varargin{ii})
    		merge_time_interval = varargin{ii+1};
        elseif strcmpi('slope_per_low', varargin{ii})
            slope_per_low = varargin{ii+1};
        elseif strcmpi('slope_per_high', varargin{ii})
            slope_per_high = varargin{ii+1};
        end
    end

    % Main contents
    peak_properties_tables_updated = peak_properties_tables;
    time_info = rec_data.Time;
    roi_num = size(peak_properties_tables_updated, 2);
    for rn = 1:roi_num
        if size(peak_properties_tables_updated{1, rn}, 2) ~= 1
            peak_properties_table_single = peak_properties_tables_updated{1, rn};
        else
            peak_properties_table_single = peak_properties_tables_updated{1, rn}{:};
        end
        
        % Debugging
        % disp(['roi_num: ', num2str(rn)])
        % if rn == 3
        %     disp('pause for debugging')
        %     pause
        % end

        if ~isempty(peak_properties_table_single)
            discard_nan_idx = isnan(peak_properties_table_single{:, 1});
            peak_properties_table_single(discard_nan_idx, :) = [];
        end

        if ~isempty(peak_properties_table_single)
            roi_name = peak_properties_tables_updated.Properties.VariableNames{rn};
            roi_trace = rec_data{:, roi_name};
            [peak_properties_table_single] = organize_merge_peaks_roi(peak_properties_table_single,...
                time_info,roi_trace,'merge_time_interval',merge_time_interval,...
                'slope_per_low',slope_per_low,'slope_per_high',slope_per_high);

            if size(peak_properties_tables_updated{1, rn}, 2) ~= 1
                peak_properties_tables_updated{1, rn} = peak_properties_table_single;
            else
                peak_properties_tables_updated{1, rn}{:} = peak_properties_table_single;
            end
        end
    end
end

