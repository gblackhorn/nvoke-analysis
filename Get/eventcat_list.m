function [event_list,varargout] = eventcat_list(alignedData,varargin)
    % Creat lists for every ROIs. The list includes the number of every kind of events


    % debug_mode = false; % true/false

    % for ii = 1:2:(nargin-2)
    %     if strcmpi('debug_mode', varargin{ii})
    %         debug_mode = varargin{ii+1};
    %     % elseif strcmpi('norm_par_suffix', varargin{ii})
    %     %     norm_par_suffix = varargin{ii+1};
    %     end
    % end

    %% main contents
    [cat_setting] = set_CatNames_for_mod_cat_name('event');
    event_names = cat_setting.cat_names;
    event_names_num = numel(event_names);
    trial_num = numel(alignedData);
    event_list_fields = {'trial','stim','fovID','roi_num','roi_info'};
    event_list = empty_content_struct(event_list_fields,trial_num);

    [event_list.trial] = alignedData.trialName;
    [event_list.stim] = alignedData.stim_name;
    [event_list.fovID] = alignedData.fovID;
    for tn = 1:trial_num
        roi_data = alignedData(tn).traces;
        roi_num = numel(roi_data);
        event_list(tn).roi_num = roi_num;

        event_field_names = strrep(event_names,'-','_');
        event_list(tn).roi_info = empty_content_struct(['roi',event_field_names],roi_num);
        [event_list(tn).roi_info.roi] = roi_data.roi;

        for rn = 1:roi_num
            roi_events = {roi_data(rn).eventProp.peak_category};
            for en = 1:event_names_num
                event = event_names{en};
                event_pos = find(strcmp(event,roi_events));
                event_num = numel(event_pos);
                event_field = strrep(event,'-','_');
                event_list(tn).roi_info(rn).(event_field) = event_num;
            end
        end
    end
end

