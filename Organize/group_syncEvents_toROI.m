function [grouped_ca_events,varargout] = group_syncEvents_toROI(seriesData_sync,varargin)
    % Events in the same same series are grouped according to their ROIs

    % seriesData_sync: struct var containing 1 series data. 
    %       - fields: seriesName, SeriesData, ca_events, ref_stim, ROIs, ROIs_num
    % grouped_syncEvents: 
    %       - fields: ROI names
    %       - entries: trials with different stimulations

    
    % Defaults
    ref_event_type = ''; % Calcium event/spike type: trig/rebound/spon... 
    other_trial_event_type = '';

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        if strcmpi('ref_event_type', varargin{ii})
            ref_event_type = varargin{ii+1};
        elseif strcmpi('other_trial_event_type', varargin{ii})
            other_trial_event_type = varargin{ii+1};
        % elseif strcmpi('keep_colNames', varargin{ii})
        %   keep_colNames = varargin{ii+1};
     %    elseif strcmpi('RowNameField', varargin{ii})
     %        RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    ca_events = seriesData_sync.ca_events;
    stims = unique({ca_events.stim_name});
    ref_stim = seriesData_sync.ref_stim;
    other_stims_idx = find(strcmp(stims, ref_stim)==0); % index of other stimulations in 'stims'
    other_stims = stims(other_stims_idx);
    other_stims_num = numel(other_stims);

    if ~isempty(ref_stim)
        [ref_ca_events_conditioned] = collect_events_with_conditions(ca_events,...
        'stim_name', ref_stim, 'peak_category', ref_event_type);

        [grouped_ca_events] = group_event_info_single_category(ref_ca_events_conditioned,'roiName',...
            'f_event_info', [ref_stim,'_ref']);
        grouped_ca_events = rmfield(grouped_ca_events, 'tag');

        ref_rois = {grouped_ca_events.group};


        % [grouped_ca_events] = group_struct_entries(ca_events_conditioned,'roiName');

        for n = 1:other_stims_num
            other_stim = other_stims{n};
            % % Creat an empty structure using the field names from "grouped_ca_events"
            % f = fieldnames(grouped_ca_events)';
            % f{2,1} = {};
            % other_grouped_ca_events = struct(f{:}); 

            [other_ca_events_conditioned] = collect_events_with_conditions(ca_events,...
            'stim_name', other_stim, 'peak_category', other_trial_event_type);

            other_stim_fname = strrep(other_stim,'-','_');
            [other_grouped_ca_events] = group_event_info_single_category(other_ca_events_conditioned,'roiName',...
            'f_event_info', other_stim_fname);

            roi_num = numel(other_grouped_ca_events);
            for rn = 1:roi_num
                roi_name = other_grouped_ca_events(rn).group;
                entry_idx = find(strcmpi(roi_name, ref_rois));
                grouped_ca_events(entry_idx).(other_stim_fname) = other_grouped_ca_events(rn).(other_stim_fname);
            end
        end
    end
end

