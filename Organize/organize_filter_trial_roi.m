function [recdata_selected,varargout] = organize_filter_trial_roi(recdata,event_info_table,varargin)
    % Return recdata using unique trials and rois listed in event_info_table
    %   event_info_table: output of func "freq_analysis_histogram" 

    recdata_trial_names = recdata(:, 1);

    unique_trial_rois = unique(event_info_table(:, {'recording_name', 'roi_name'}));
    unique_trials = unique(unique_trial_rois.recording_name);
    unique_trials_num = length(unique_trials);

    trial_keep_idx = ones(unique_trials_num, 1);

    % Discard trials
    for tn = 1:unique_trials_num
        trial_keep_idx(tn) = find(strcmp(unique_trials{tn}, recdata_trial_names));
    end
    recdata_selected = recdata(trial_keep_idx, :);
    recdata_selected_trial_names = recdata_selected(:, 1);



    % Discard ROIs
    trials_num = size(recdata_selected, 1);
    for tn = 1:trials_num
        unique_rois_idx = find(strcmp(recdata_selected_trial_names{tn}, unique_trial_rois.recording_name));
        roi_keep_names = unique_trial_rois{unique_rois_idx, 'roi_name'};
        recdata_selected{tn, 2}.lowpass = recdata_selected{tn, 2}.lowpass(:, ['Time', roi_keep_names']);
        recdata_selected{tn, 2}.smoothed = recdata_selected{tn, 2}.smoothed(:, ['Time', roi_keep_names']);
        recdata_selected{tn, 2}.highpass = recdata_selected{tn, 2}.highpass(:, ['Time', roi_keep_names']);

        recdata_selected{tn, 5} = recdata_selected{tn, 5}(:, roi_keep_names);
    end
end