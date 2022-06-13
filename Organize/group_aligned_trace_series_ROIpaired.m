function [grouped_data,varargout] = group_aligned_trace_series_ROIpaired(alignedData_series,varargin)
    % group aligned event traces. Series data (same FOV, same ROI set) is required.
    % Traces from the same neuron but different trials will be plot in the same row
    % Each neuron has its own row

    % alignedData_series: a struct var. contain only one series 
    
    % Defaults
    ref_stim = ''; % reference stimulation
    ref_SpikeCat = ''; % reference spike/peak/event category 
    other_SpikeCat = ''; % spike/peak/event category in other trial will be plot
    % plot_spon = true;
    debug_mode = false;

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        if strcmpi('ref_stim', varargin{ii})
            ref_stim = varargin{ii+1};
        elseif strcmpi('ref_SpikeCat', varargin{ii})
            ref_SpikeCat = varargin{ii+1};
        elseif strcmpi('other_SpikeCat', varargin{ii})
            other_SpikeCat = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
          debug_mode = varargin{ii+1};
     %    elseif strcmpi('RowNameField', varargin{ii})
     %        RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    trial_num = numel(alignedData_series);
    if ~isempty(ref_stim)
        % Sort the order of trials. Neurons in reference stim trial will be plotted first
        ref_stim_tf = strcmpi(ref_stim,{alignedData_series.stim_name});
        ref_trial_idx = find(ref_stim_tf);
        other_trial_idx = find(ref_stim_tf==false);
        trial_order = [ref_trial_idx other_trial_idx];

        refName = sprintf('%s[%s]', ref_SpikeCat, ref_stim); % name of the reference containing both spikeCat and stim info
        use_ref = true;
    else
        trial_order = [1:trial_num];
        use_ref = false;
    end

    % Creat an empty structure to store trace data and event properties. Group them using ROI
    roi_num = numel(alignedData_series(trial_order(1)).traces); % roi number in reference/1st trial
    StructAllo1 = cell(1,roi_num); % allocate empty cell for structure
    grouped_data = struct('roi',StructAllo1,'ref',StructAllo1,'plot_trace_data',StructAllo1,...
        'eventPropData',StructAllo1);

    % Creat an empty structure to store ROI trace data from multiple trials with differectn stimulations 
    StructAllo2 = cell(1,trial_num); % allocate empty cell for structure
    plot_trace_data_field = struct('spike_stim',StructAllo2,'ref_amp_mean',StructAllo2,'timeinfo',StructAllo2,...
        'raw_trace',StructAllo2,'trace_mean',StructAllo2,'trace_std',StructAllo2,...
        'norm_trace',StructAllo2,'norm_trace_mean',StructAllo2,'norm_trace_std',StructAllo2);
    % Creat an empty structure to store the event properties. Grouped to trials with different stimulations
    eventProp_field = struct('group',StructAllo2,'event_info',StructAllo2);

    % Go through ROIs. Data will be grouped according to ROI
    for rn = 1:roi_num % rn is the index of roi in ref or the first trial
        grouped_data(rn).roi = alignedData_series(trial_order(1)).traces(rn).roi;
        grouped_data(rn).ref = refName;
        grouped_data(rn).plot_trace_data = plot_trace_data_field;
        grouped_data(rn).eventPropData = eventProp_field;

        if debug_mode
            fprintf('roi %d/%d: %s\n', rn, roi_num, grouped_data(rn).roi)
            if rn == 2
                pause
            end
        end

        % Go through trials. Collect data if a trial has the ROI in the ref/first trial
        for tn = 1:trial_num
            trial_name = alignedData_series(trial_order(tn)).trialName;
            trial_roi = {alignedData_series(trial_order(tn)).traces.roi};
            roi_idx = find(strcmp(grouped_data(rn).roi, trial_roi));
            if ~isempty(roi_idx) % if roi is present in this trial
                tag_stim = alignedData_series(trial_order(tn)).stim_name;
                if use_ref && tn == 1
                    tag_SpikeCat = ref_SpikeCat;
                    ref_trial = true; % 
                else
                    tag_SpikeCat = other_SpikeCat;
                    ref_trial = false;
                end

                if debug_mode
                    fprintf(' - trial %d/%d: %s\n', tn, trial_num, tag_stim)
                end

                trialData = alignedData_series(trial_order(tn)).traces(roi_idx); % specific trial, specific roi
                if ~isempty(trialData.eventProp) % if events found in this ROI of this trial
                    [~,disIDX] = filter_entries_in_structure(trialData.eventProp,'peak_category',...
                        'tags_keep',tag_SpikeCat);
                    
                    trialData.value(:, disIDX) = [];
                    trialData.eventProp(disIDX) = [];

                    grouped_data(rn).plot_trace_data(tn).spike_stim = sprintf('%s[%s]', tag_SpikeCat, tag_stim);
                    grouped_data(rn).eventPropData(tn).group = sprintf('%s[%s]', tag_SpikeCat, tag_stim);;

                    if ref_trial
                        ref_amp_mean = mean([trialData.eventProp.peak_mag_delta]);
                    end

                    grouped_data(rn).plot_trace_data(tn).timeinfo = alignedData_series(trial_order(tn)).time;
                    grouped_data(rn).plot_trace_data(tn).raw_trace = trialData.value;
                    grouped_data(rn).plot_trace_data(tn).trace_mean = mean(trialData.value, 2, 'omitnan');
                    grouped_data(rn).plot_trace_data(tn).trace_std = std(trialData.value, 0, 2, 'omitnan');
                    grouped_data(rn).eventPropData(tn).event_info = trialData.eventProp;
                    [grouped_data(rn).eventPropData(tn).event_info.trial] = deal(trial_name(1:8));
                    [grouped_data(rn).eventPropData(tn).event_info.roi] = deal(grouped_data(rn).roi);

                    if use_ref 
                        grouped_data(rn).plot_trace_data(tn).ref_amp_mean = ref_amp_mean;
                        if tn ~= 1 && ~isnan(ref_amp_mean)
                            grouped_data(rn).plot_trace_data(tn).norm_trace = grouped_data(rn).plot_trace_data(tn).raw_trace/ref_amp_mean;
                            grouped_data(rn).plot_trace_data(tn).norm_trace_mean = mean(grouped_data(rn).plot_trace_data(tn).norm_trace, 2, 'omitnan');
                            grouped_data(rn).plot_trace_data(tn).norm_trace_std = std(grouped_data(rn).plot_trace_data(tn).norm_trace, 0, 2, 'omitnan');
                        end
                    end
                end
            end
        end

        if use_ref
            [grouped_data(rn).eventPropData] = norm_grouped_event_info(grouped_data(rn).eventPropData,1,...
                'norm_par_suffix','refNorm');
        end
    end

end

