function [noisey_roi_code, varargout] = organize_screen_noisy_roi_code(peak_properties_table,highpass_data_std, varargin)
    % Evaluate the peak_mag_delta and highpass_std, and decide whether the roi is noisey
    
    %	highpass_data_std: output of function "organize_transient_properties" using 'highpass' filter

    % Defaults
    std_fold = 10; % default: 10. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('std_fold', varargin{ii})
    		std_fold = varargin{ii+1};
        end
    end

    peak_properties_table_screened = peak_properties_table;

    if ~isempty(peak_properties_table.peak_mag_delta)
        peak_noise_ratio = mean(peak_properties_table.peak_mag_delta)/highpass_data_std;

        if peak_noise_ratio < std_fold
            noisey_roi_code = 1;
        else
            noisey_roi_code = 0;
        end
    else
        noisey_roi_code = 1; % no peak in ROI, discard the roi as if it's noisey
    end
end

