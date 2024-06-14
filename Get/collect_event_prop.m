function [eventProp_all, varargout] = collect_event_prop(alignedData, varargin)
    % COLLECT_EVENT_PROP Return the event properties from all ROIs and all trials stored in alignedData
    %   alignedData is the output from get_event_trace_allTrials or get_event_trace_trial
    %   [eventProp_all, varargout] = collect_event_prop(alignedData, 'style', 'roi', 'debug_mode', true)

    % Initialize input parser
    p = inputParser;

    % Required inputs
    addRequired(p, 'alignedData', @isstruct);

    % Optional parameters with default values
    addParameter(p, 'style', 'roi', @(x) ismember(x, {'roi', 'event'}));
    addParameter(p, 'debug_mode', false, @islogical);

    % Parse inputs
    parse(p, alignedData, varargin{:});

    % Extract values from the parsed inputs
    alignedData = p.Results.alignedData;
    style = p.Results.style;
    debug_mode = p.Results.debug_mode;

    % Main contents
    trial_num = numel(alignedData);  % Number of trials
    event_type = alignedData(1).event_type;  % Type of event
    data_type = alignedData(1).data_type;  % Type of data

    % Initialize cell array to store event properties for each trial
    eventProp_all_cell = cell(trial_num, 1);
    
    % Loop through each trial
    for tn = 1:trial_num
        alignedData_trial = alignedData(tn);  % Data for the current trial
        trialName = alignedData_trial.trialName;  % Name of the current trial
        fovID = alignedData_trial.fovID;  % Field of view ID

        % Debugging information
        if debug_mode
            fprintf('trial %d: %s\n', tn, trialName);
            if tn == 36
                pause;
            end
        end

        % Check if time field is not empty
        if ~isempty(alignedData_trial.time)
            stim_name = alignedData_trial.stim_name;  % Name of the stimulation
            combine_stim = contains(stim_name, ' ');  % Check if stimulation names are combined

            % Determine the number of stimulus repeats
            if strcmpi(stim_name, 'no-stim')
                stim_repeats = NaN;
            else
                stim_repeats = alignedData_trial.stimInfo.UnifiedStimDuration.repeats;
            end

            roi_num = numel(alignedData_trial.traces);  % Number of ROIs in the current trial
            eventProp_trial = cell(roi_num, 1);  % Initialize cell array for event properties of each ROI

            % Loop through each ROI
            for rn = 1:roi_num
                roiData = alignedData_trial.traces(rn);  % Data for the current ROI
                % Process the ROI data based on the specified style
                eventProp_trial{rn} = process_roi_data(roiData, trialName, fovID, stim_name, combine_stim, stim_repeats, style);
            end
            % Combine event properties from all ROIs in the current trial
            eventProp_all_cell{tn} = [eventProp_trial{:}];
        end
    end
    % Combine event properties from all trials
    eventProp_all = [eventProp_all_cell{:}];
end

function eventProp_trial_roi = process_roi_data(roiData, trialName, fovID, stim_name, combine_stim, stim_repeats, style)
    % PROCESS_ROI_DATA Process data for a single ROI based on the specified style
    %   This function processes the data for a single ROI and returns the event properties
    roiName = roiData.roi;
    subNuclei = roiData.subNuclei;
    eventProp_roi = roiData.eventProp;
    roi_coor = roiData.roi_coor;
    event_num = numel(eventProp_roi);

    eventProp_trial_roi = [];

    if ~isempty(eventProp_roi)
        % Process data based on the specified style (either 'roi' or 'event')
        switch style
            case 'roi'
                eventProp_trial_roi = process_roi_style(roiData, eventProp_roi, trialName, roiName, subNuclei, fovID, stim_name, combine_stim, stim_repeats, roi_coor);
            case 'event'
                eventProp_trial_roi = process_event_style(roiData, eventProp_roi, trialName, roiName, subNuclei, fovID, stim_name, combine_stim, stim_repeats, roi_coor, event_num);
        end
    end
end

function eventProp_trial_roi = process_roi_style(roiData, eventProp_roi, trialName, roiName, subNuclei, fovID, stim_name, combine_stim, stim_repeats, roi_coor)
    % PROCESS_ROI_STYLE Process ROI data in 'roi' style
    %   This function processes the data for a single ROI in 'roi' style and returns the event properties

    % Get unique peak categories
    [C, ~, ic] = unique({eventProp_roi.peak_category}, 'stable');
    peakCat_num = numel(C);  % Number of unique peak categories
    eventProp_trial_roi = cell(peakCat_num, 1);

    % Loop through each peak category
    for pcn = 1:peakCat_num
        pc_idx = find(ic == pcn);  % Index of events belonging to the current peak category
        eventProp_roi_peakCat = eventProp_roi(pc_idx);  % Events in the current peak category
        peakCat_name = C{pcn};  % Name of the current peak category
        event_num_peakCat = numel(pc_idx);  % Number of events in the current peak category

        % Create a struct for the current peak category
        eventProp_trial_roi{pcn} = struct( ...
            'trialName', trialName, ...
            'roiName', roiName, ...
            'subNuclei', subNuclei, ...
            'fovID', fovID, ...
            'stim_name', stim_name, ...
            'combine_stim', combine_stim, ...
            'stim_repeats', stim_repeats, ...
            'roi_coor', roi_coor, ...
            'event_num', event_num_peakCat, ...
            'peak_category', peakCat_name, ...
            'entryStyle', 'roi', ...
            'eventPropData', eventProp_roi_peakCat, ...
            'stimEvent_possi_info', [], ...
            'stimEvent_possi', [], ...
            'stimTrig', roiData.stimTrig, ...
            'sponfq', roiData.sponfq, ...
            'sponInterval', roiData.sponInterval, ...
            'cv2', roiData.cv2, ...
            'stimfq', roiData.stimfq, ...
            'stimfqNorm', roiData.stimfqNorm, ...
            'stimfqDeltaNorm', roiData.stimfqDeltaNorm, ...
            'rise_duration', mean([eventProp_roi_peakCat.rise_duration]), ...
            'peak_mag_delta', mean([eventProp_roi_peakCat.peak_mag_delta]), ...
            'peak_delta_norm_hpstd', mean([eventProp_roi_peakCat.peak_delta_norm_hpstd]), ...
            'peak_slope', mean([eventProp_roi_peakCat.peak_slope]), ...
            'peak_slope_norm_hpstd', mean([eventProp_roi_peakCat.peak_slope_norm_hpstd]), ...
            'CaLevelDeltaData', roiData.CaLevelDeltaData, ...
            'CaLevelDelta', roiData.CaLevelDelta, ...
            'CaLevelmeanBase', roiData.CaLevelmeanBase, ...
            'CaLevelmeanStim', roiData.CaLevelmeanStim, ...
            'CaLevelMinDelta', roiData.CaLevelMinDelta, ...
            'StimCurveFit', roiData.StimCurveFit, ...
            'StimCurveFit_TauMean', roiData.StimCurveFit_TauMean, ...
            'StimCurveFit_TauNum', roiData.StimCurveFit_TauNum ...
        );

        % Check for the presence of stimulation event possibility info
        stim_possi_pc_idx = find(strcmp({roiData.stimEvent_possi.cat_name}, peakCat_name));
        if ~isempty(stim_possi_pc_idx)
            eventProp_trial_roi{pcn}.stimEvent_possi_info = roiData.stimEvent_possi(stim_possi_pc_idx);
            eventProp_trial_roi{pcn}.stimEvent_possi = roiData.stimEvent_possi(stim_possi_pc_idx).cat_possibility;
        end
    end

    % Combine event properties for all peak categories in the current ROI
    eventProp_trial_roi = [eventProp_trial_roi{:}];
end

function eventProp_trial_roi = process_event_style(roiData, eventProp_roi, trialName, roiName, subNuclei, fovID, stim_name, combine_stim, stim_repeats, roi_coor, event_num)
    % PROCESS_EVENT_STYLE Process ROI data in 'event' style
    %   This function processes the data for a single ROI in 'event' style and returns the event properties

    % Create arrays of repeated trial and ROI information
    prop_trialName = repmat({trialName}, 1, event_num);
    prop_roiName = repmat({roiName}, 1, event_num);
    prop_subNuclei = repmat({subNuclei}, 1, event_num);
    prop_fovID = repmat({fovID}, 1, event_num);
    prop_stim_name = repmat({stim_name}, 1, event_num);
    prop_roi_coor = repmat({roi_coor}, 1, event_num);

    % Assign repeated information to event properties
    [eventProp_roi.trialName] = prop_trialName{:};
    [eventProp_roi.roiName] = prop_roiName{:};
    [eventProp_roi.subNuclei] = prop_subNuclei{:};
    [eventProp_roi.fovID] = prop_fovID{:};
    [eventProp_roi.stim_name] = prop_stim_name{:};
    [eventProp_roi.roi_coor] = prop_roi_coor{:};
    [eventProp_roi.combine_stim] = deal(combine_stim);
    [eventProp_roi.stim_repeats] = deal(stim_repeats);
    [eventProp_roi.entryStyle] = deal('event');

    % Return the processed event properties for the current ROI
    eventProp_trial_roi = eventProp_roi;
end



% function [eventProp_all,varargout] = collect_event_prop(alignedData,varargin)
% 	% Return the event properties from all ROIs and all trials stored in alignedData
% 	% alignedData is the output from get_event_trace_allTrials or get_event_trace_trial


% 	% Defaults
% 	style = 'roi'; % options: 'roi' or 'event'
%                     % 'roi': events from a ROI are stored in a length-1 struct. mean values were calculated. 
%                     % 'event': events are seperated (struct length = events_num). mean values were not calculated
%     debug_mode = false; % true/false

%     % Optionals
%     for ii = 1:2:(nargin-1)
%         if strcmpi('style', varargin{ii})
%             style = varargin{ii+1}; % options: 'roi' or 'event'
%         elseif strcmpi('debug_mode', varargin{ii})
%             debug_mode = varargin{ii+1}; 
%         end
%     end


%     % ====================
%     % Main contents
%     trial_num = numel(alignedData);
%     event_type = alignedData(1).event_type;
%     data_type = alignedData(1).data_type;

%     eventProp_all_cell = cell(trial_num, 1);
%     for tn = 1:trial_num
%     	alignedData_trial = alignedData(tn);
%     	trialName = alignedData_trial.trialName;
%         fovID = alignedData_trial.fovID;

%         if debug_mode
%             fprintf('trial %d: %s\n', tn, trialName)
%             if tn == 36
%                 pause
%             end
%         end

%     	if ~isempty(alignedData_trial.time)
%     		stim_name = alignedData_trial.stim_name;
%     		space_in_stim_name = strfind(stim_name, ' '); % "space" between various stimulation names, such as 'OG-LED-5s GPIO-1-1s'
%     		if  ~isempty(space_in_stim_name)
%     			combine_stim = true;
%     		else
%     			combine_stim = false;
%     		end

%     		if strcmpi(stim_name, 'no-stim')
%     			stim_repeats = NaN;
%     		else
%     			stim_repeats = alignedData_trial.stimInfo.UnifiedStimDuration.repeats;
%     		end

%     		roi_num = numel(alignedData_trial.traces);
%     		eventProp_trial = cell(roi_num, 1);

%     		for rn = 1:roi_num
%     			roiData = alignedData_trial.traces(rn);
%     			roiName = roiData.roi; 
%                 subNuclei = roiData.subNuclei;
%                 eventProp_roi = roiData.eventProp;
%                 roi_coor = roiData.roi_coor;
%     			event_num = numel(eventProp_roi);

%                 % fprintf(' -roi %d: %s\n', rn, roiName)

%                 if ~isempty(eventProp_roi)
%         			switch style
%         				case 'roi'
%                             [C,ia,ic] = unique({eventProp_roi.peak_category}, 'stable'); % get unique peak categories
%                             peakCat_num = numel(C);
%                             eventProp_trial_roi = cell(peakCat_num, 1); 
%                             for pcn = 1:peakCat_num
%                                 pc_idx = find(ic==pcn); % index of event prop belongs to peak category (pcn)
%                                 eventProp_roi_peakCat = eventProp_roi(pc_idx);
%                                 peakCat_name = C{pcn};
%                                 event_num_peakCat = numel(pc_idx);

%                                 eventProp_trial_roi{pcn}.trialName = trialName;
%                                 eventProp_trial_roi{pcn}.roiName = roiName;
%                                 eventProp_trial_roi{pcn}.subNuclei = subNuclei;
%                                 eventProp_trial_roi{pcn}.fovID = fovID;
%                                 eventProp_trial_roi{pcn}.stim_name = stim_name;
%                                 eventProp_trial_roi{pcn}.combine_stim = combine_stim; % multiple stimuli combined in single recordings
%                                 eventProp_trial_roi{pcn}.stim_repeats = stim_repeats;
%                                 eventProp_trial_roi{pcn}.roi_coor = roi_coor;
%                                 eventProp_trial_roi{pcn}.event_num = event_num_peakCat;
%                                 eventProp_trial_roi{pcn}.peak_category = peakCat_name;
%                                 eventProp_trial_roi{pcn}.entryStyle = style;

%                                 eventProp_trial_roi{pcn}.eventPropData = eventProp_roi_peakCat;

%                                 stim_possi_pc_idx = find(strcmp({roiData.stimEvent_possi.cat_name},peakCat_name)); % get the position of peakCat_name in stimEvent_possi
%                                 if ~isempty(stim_possi_pc_idx) % if stimEvent_possi contains the peakCat_name
%                                     eventProp_trial_roi{pcn}.stimEvent_possi_info = roiData.stimEvent_possi(stim_possi_pc_idx); % assign the possibility info of a specific peak cat to eventProp_trial_roi{pcn}
%                                     eventProp_trial_roi{pcn}.stimEvent_possi = roiData.stimEvent_possi(stim_possi_pc_idx).cat_possibility; % assign the possibility info of a specific peak cat to eventProp_trial_roi{pcn}
%                                 else % most likely the peakCat_name is "spon"
%                                     eventProp_trial_roi{pcn}.stimEvent_possi_info = [];
%                                     eventProp_trial_roi{pcn}.stimEvent_possi = [];
%                                 end

%                                 eventProp_trial_roi{pcn}.stimTrig = roiData.stimTrig;
%                                 eventProp_trial_roi{pcn}.sponfq = roiData.sponfq;
%                                 eventProp_trial_roi{pcn}.sponInterval = roiData.sponInterval;
%                                 eventProp_trial_roi{pcn}.cv2 = roiData.cv2;
%                                 eventProp_trial_roi{pcn}.stimfq = roiData.stimfq;
%                                 eventProp_trial_roi{pcn}.stimfqNorm = roiData.stimfqNorm;
%                                 eventProp_trial_roi{pcn}.stimfqDeltaNorm = roiData.stimfqDeltaNorm;
%                                 eventProp_trial_roi{pcn}.rise_duration = mean([eventProp_roi_peakCat.rise_duration]);
%                                 eventProp_trial_roi{pcn}.peak_mag_delta = mean([eventProp_roi_peakCat.peak_mag_delta]);
%                                 eventProp_trial_roi{pcn}.peak_delta_norm_hpstd = mean([eventProp_roi_peakCat.peak_delta_norm_hpstd]);
%                                 eventProp_trial_roi{pcn}.peak_slope = mean([eventProp_roi_peakCat.peak_slope]);
%                                 eventProp_trial_roi{pcn}.peak_slope_norm_hpstd = mean([eventProp_roi_peakCat.peak_slope_norm_hpstd]);
%                                 % eventProp_trial_roi{pcn}.baseChangeNorm = roiData.baseChangeNorm;
%                                 eventProp_trial_roi{pcn}.CaLevelDeltaData = roiData.CaLevelDeltaData;
%                                 eventProp_trial_roi{pcn}.CaLevelDelta = roiData.CaLevelDelta;
%                                 eventProp_trial_roi{pcn}.CaLevelmeanBase = roiData.CaLevelmeanBase;
%                                 eventProp_trial_roi{pcn}.CaLevelmeanStim = roiData.CaLevelmeanStim;
%                                 % eventProp_trial_roi{pcn}.baseChangeMinNorm = roiData.baseChangeMinNorm;
%                                 eventProp_trial_roi{pcn}.CaLevelMinDelta = roiData.CaLevelMinDelta;
                                
%                                 eventProp_trial_roi{pcn}.StimCurveFit = roiData.StimCurveFit;
%                                 eventProp_trial_roi{pcn}.StimCurveFit_TauMean = roiData.StimCurveFit_TauMean;
%                                 eventProp_trial_roi{pcn}.StimCurveFit_TauMean = roiData.StimCurveFit_TauMean;
%                                 eventProp_trial_roi{pcn}.StimCurveFit_TauNum = roiData.StimCurveFit_TauNum;
%                             end

%                             eventProp_trial{rn} = [eventProp_trial_roi{:}];

%         				case 'event'
%         					prop_trialName = cell(1, event_num);
%         					prop_roiName = cell(1, event_num);
%                             prop_subNuclei = cell(1, event_num);
%                             prop_fovID = cell(1, event_num);
%         					prop_stim_name = cell(1, event_num);
%                             prop_roi_coor = cell(1, event_num);

%         					prop_trialName(:) = {trialName};
%         					prop_roiName(:) = {roiName};
%                             prop_subNuclei(:) = {subNuclei};
%                             prop_fovID(:) = {fovID};
%         					prop_stim_name(:) = {stim_name};
%                             prop_roi_coor(:) = {roi_coor};

%                             [eventProp_roi.trialName] = prop_trialName{:};
%                             [eventProp_roi.roiName] = prop_roiName{:};
%                             [eventProp_roi.subNuclei] = prop_subNuclei{:};
%                             [eventProp_roi.fovID] = prop_fovID{:};
%                             [eventProp_roi.stim_name] = prop_stim_name{:};
%                             [eventProp_roi.roi_coor] = prop_roi_coor{:};
%                             [eventProp_roi.combine_stim] = deal(combine_stim);
%                             [eventProp_roi.stim_repeats] = deal(stim_repeats);
%                             [eventProp_roi.entryStyle] = deal(style);

%                             eventProp_trial{rn} = eventProp_roi;

%         			end
%                     % eventProp_trial{rn} = orderfields(eventProp_trial{rn});
%                 else
%                     eventProp_trial{rn} = [];
%                 end
%     		end
%             eventProp_all_cell{tn} = [eventProp_trial{:}];
%     	end
%     end
%     eventProp_all = [eventProp_all_cell{:}];
% end