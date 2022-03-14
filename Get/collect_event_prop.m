function [eventProp_all,varargout] = collect_event_prop(alignedData,varargin)
	% Return the event properties from all ROIs and all trials stored in alignedData
	% alignedData is the output from get_event_trace_allTrials or get_event_trace_trial


	% Defaults
	style = 'roi'; % options: 'roi' or 'event'
                    % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
                    % 'event': events are seperated (struct length = events_num). mean values were not calculated
    debug_mode = false; % true/false

    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('style', varargin{ii})
            style = varargin{ii+1}; % options: 'roi' or 'event'
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1}; 
        end
    end


    % ====================
    % Main contents
    trial_num = numel(alignedData);
    event_type = alignedData(1).event_type;
    data_type = alignedData(1).data_type;

    eventProp_all_cell = cell(trial_num, 1);
    for tn = 1:trial_num
    	alignedData_trial = alignedData(tn);
    	trialName = alignedData_trial.trialName;
        fovID = alignedData_trial.fovID;

        if debug_mode
            fprintf('trial %d: %s\n', tn, trialName)
            if tn == 36
                pause
            end
        end

    	if ~isempty(alignedData_trial.time)
    		stim_name = alignedData_trial.stim_name;
    		space_in_stim_name = strfind(stim_name, ' '); % "space" between various stimulation names, such as 'OG-LED-5s GPIO-1-1s'
    		if  ~isempty(space_in_stim_name)
    			combine_stim = true;
    		else
    			combine_stim = false;
    		end

    		if strcmpi(stim_name, 'no-stim')
    			stim_repeats = NaN;
    		else
    			stim_repeats = alignedData_trial.stimInfo.repeats;
    		end

    		roi_num = numel(alignedData_trial.traces);
    		eventProp_trial = cell(roi_num, 1);

    		for rn = 1:roi_num
    			roiData = alignedData_trial.traces(rn);
    			roiName = roiData.roi; 
                eventProp_roi = roiData.eventProp;
                roi_coor = roiData.roi_coor;
    			event_num = numel(eventProp_roi);

                % fprintf(' -roi %d: %s\n', rn, roiName)

                if ~isempty(eventProp_roi)
        			switch style
        				case 'roi'
                            [C,ia,ic] = unique({eventProp_roi.peak_category}, 'stable'); % get unique peak categories
                            peakCat_num = numel(C);
                            eventProp_trial_roi = cell(peakCat_num, 1); 
                            for pcn = 1:peakCat_num
                                pc_idx = find(ic==pcn); % index of event prop belongs to peak category (pcn)
                                eventProp_roi_peakCat = eventProp_roi(pc_idx);
                                peakCat_name = C{pcn};
                                event_num_peakCat = numel(pc_idx);

                                eventProp_trial_roi{pcn}.trialName = trialName;
                                eventProp_trial_roi{pcn}.roiName = roiName;
                                eventProp_trial_roi{pcn}.fovID = fovID;
                                eventProp_trial_roi{pcn}.stim_name = stim_name;
                                eventProp_trial_roi{pcn}.combine_stim = combine_stim; % multiple stimuli combined in single recordings
                                eventProp_trial_roi{pcn}.stim_repeats = stim_repeats;
                                eventProp_trial_roi{pcn}.roi_coor = roi_coor;
                                eventProp_trial_roi{pcn}.event_num = event_num_peakCat;
                                eventProp_trial_roi{pcn}.peak_category = peakCat_name;
                                eventProp_trial_roi{pcn}.entryStyle = style;

                                eventProp_trial_roi{pcn}.eventPropData = eventProp_roi_peakCat;
                                eventProp_trial_roi{pcn}.rise_duration = mean([eventProp_roi_peakCat.rise_duration]);
                                eventProp_trial_roi{pcn}.peak_mag_delta = mean([eventProp_roi_peakCat.peak_mag_delta]);
                                eventProp_trial_roi{pcn}.peak_delta_norm_hpstd = mean([eventProp_roi_peakCat.peak_delta_norm_hpstd]);
                                eventProp_trial_roi{pcn}.peak_slope = mean([eventProp_roi_peakCat.peak_slope]);
                                eventProp_trial_roi{pcn}.peak_slope_norm_hpstd = mean([eventProp_roi_peakCat.peak_slope_norm_hpstd]);
                            end

                            eventProp_trial{rn} = [eventProp_trial_roi{:}];

        				case 'event'
        					prop_trialName = cell(1, event_num);
        					prop_roiName = cell(1, event_num);
                            prop_fovID = cell(1, event_num);
        					prop_stim_name = cell(1, event_num);
                            prop_roi_coor = cell(1, event_num);

        					prop_trialName(:) = {trialName};
        					prop_roiName(:) = {roiName};
                            prop_fovID(:) = {fovID};
        					prop_stim_name(:) = {stim_name};
                            prop_roi_coor(:) = {roi_coor};

                            [eventProp_roi.trialName] = prop_trialName{:};
                            [eventProp_roi.roiName] = prop_roiName{:};
                            [eventProp_roi.fovID] = prop_fovID{:};
                            [eventProp_roi.stim_name] = prop_stim_name{:};
                            [eventProp_roi.roi_coor] = prop_roi_coor{:};
                            [eventProp_roi.combine_stim] = deal(combine_stim);
                            [eventProp_roi.stim_repeats] = deal(stim_repeats);
                            [eventProp_roi.entryStyle] = deal(style);

                            eventProp_trial{rn} = eventProp_roi;

        			end
                    eventProp_trial{rn} = orderfields(eventProp_trial{rn});
                else
                    eventProp_trial{rn} = [];
                end
    		end
            eventProp_all_cell{tn} = [eventProp_trial{:}];
    	end
    end
    eventProp_all = [eventProp_all_cell{:}];
end