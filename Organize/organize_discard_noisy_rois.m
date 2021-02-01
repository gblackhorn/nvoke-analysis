function [peak_properties_tables_screened,trace_data_screened,varargout] = organize_discard_noisy_rois(peak_properties_tables,highpass_data_stds,trace_data,varargin)
    % use function "organize_screen_noisey_roi" to screen peak from multiple rois
    % in the same recording.
    %   Detailed explanation goes here
    
    % Defaults
    std_fold = 10; % default: 10. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.

    % Optionals for inputs
    for ii = 1:2:(nargin-3)
    	if strcmpi('std_fold', varargin{ii})
    		std_fold = varargin{ii+1};
        end
    end

    % main contents
    peak_properties_tables_screened = peak_properties_tables;
    trace_data_screened = trace_data;
    roi_num = size(peak_properties_tables, 2);
    noisey_roi_code = zeros(1, roi_num);
    for rn = 1:roi_num
        if size(peak_properties_tables{1, rn}, 2) ~= 1
            peak_properties_table_single = peak_properties_tables{1, rn};
        else
            peak_properties_table_single = peak_properties_tables{1, rn}{:};
        end
        
    	% peak_properties_table_single = peak_properties_tables{1, rn}{:};
    	highpass_data_std_single = highpass_data_stds{1, rn};
    	[noisey_roi_code(rn)] = organize_screen_noisy_roi(peak_properties_table_single,...
    		highpass_data_std_single, 'std_fold', std_fold);

    end
    noisey_roi_idx = find(noisey_roi_code);
    if ~isempty(noisey_roi_idx)
        noisey_roi_names = peak_properties_tables.Properties.VariableNames(noisey_roi_idx); % get table variable names
        peak_properties_tables_screened = removevars(peak_properties_tables_screened, noisey_roi_names);
        trace_data_screened.decon = removevars(trace_data_screened.decon, noisey_roi_names);
        trace_data_screened.raw = removevars(trace_data_screened.raw, noisey_roi_names);
        trace_data_screened.lowpass = removevars(trace_data_screened.lowpass, noisey_roi_names);
        trace_data_screened.smooth = removevars(trace_data_screened.smooth, noisey_roi_names);
        trace_data_screened.highpass = removevars(trace_data_screened.highpass, noisey_roi_names);
    end
end

