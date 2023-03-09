function [grouped_event,grouped_event_setting,varargout] = mod_and_group_eventProp(eventProp_all,eventType,adataSetting,varargin)
    % Modify the contents in eventProp_all and group them according to the settings
    % Tags, such as stimulation and peak category, can be modified for readibility and easy group
    % This function also adds some normalized value to events

    % eventProp_all: a structure variable containing event properties 
    % eventType: 'event' or 'roi'. Entry type in event info 
    % mgSetting: setting for modifying eventProp_all
    % adataSetting: settings used to prepare alignedData var

    
    % Defaults
    mgSetting.seperate_spon = false; % true/false. Whether to seperated spon according to stimualtion
    mgSetting.dis_spon = false; % true/false. Discard spontaneous events
    mgSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
    mgSetting.groupField = {'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 

    % rename the stimulation tag if og evokes spike at the onset of stimulation
    mgSetting.mark_EXog = false; % if true, rename the og to EXog if the value of field 'stimTrig' is 1
    mgSetting.og_tag = {'og', 'og-ap'}; % find og events with these strings. 'og' to 'Exog', 'og-ap' to 'EXog-ap'

    % arrange the order of group entries using function [sort_struct_with_str] with settings below. 
    mgSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
    mgSetting.sort_order_plus = {'ap', 'EXopto'};

    mgSetting.sponOnly = false;
    debug_mode = true; % true/false
    % % ref_group = 1;
    % par = {'rise_duration','peak_mag_delta'}; % fields will be normalized in grouped_event_info.event_info
    % norm_par_suffix = 'refNorm'; % added to the end of names of new fields containing the normalized pars

    for ii = 1:2:(nargin-3)
        if strcmpi('mgSetting', varargin{ii})
            mgSetting = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        end
    end

    %% main contents
    % if the eventType is roi, only keep the "spon" entries
    if strcmp(eventType,'roi') && mgSetting.sponOnly
        [eventProp_all] = filter_structData(eventProp_all,...
            'peak_category','spon',1);
    end


    if mgSetting.mark_EXog 
        mgSetting.og_tag = {'og', 'og-ap'}; % 
        idx_check = cell(1, numel(mgSetting.og_tag));
        for n = 1:numel(mgSetting.og_tag)
            [~,idx_check{n}] = filter_structData(eventProp_all,'stim_name',mgSetting.og_tag{n},[]); % accquire the idx of all og-trial events
        end
        idxAll_check = [idx_check{:}];
        eventProp_check = eventProp_all(idxAll_check);
        eventProp_uncheck = eventProp_all;
        eventProp_uncheck(idxAll_check) = [];
        [~,idx_ogEx] = filter_structData(eventProp_check,'stimTrig',1,[]); % accquire the idx of og triggered events
        cat_setting.cat_type = 'stim_name';
        cat_setting.cat_names = {'EXog', 'EXog-ap'};
        cat_setting.cat_merge = {{'og'}, {'og-ap'}};
        [eventProp_check(idx_ogEx)] = mod_cat_name(eventProp_check(idx_ogEx),...
            'cat_setting',cat_setting,'dis_extra', false,'stimType',false);
        eventProp_all = [eventProp_uncheck eventProp_check];
    end

    [eventProp_all_norm] = norm_eventProp_with_spon(eventProp_all,'entry',eventType,'dis_spon',mgSetting.dis_spon);
    % modify the peak category names
    if mgSetting.modify_eventType_name % Note: when style is 'roi', there will be more data number, if noStim and interval are categorized as spon
        [eventProp_all_norm] = mod_cat_name(eventProp_all_norm,'dis_extra', true,'seperate_spon',mgSetting.seperate_spon);
    end

    % mgSetting.groupField = {'peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'
    % [grouped_event_info, grouped_event_setting] = group_event_info_multi_category(eventProp_all,...
    %   'category_names', category_names);
    [grouped_event, grouped_event_setting] = group_event_info_multi_category(eventProp_all_norm,...
        'category_names', mgSetting.groupField);
    if numel(mgSetting.groupField)==1 && strcmpi(mgSetting.groupField, 'peak_category')
        [grouped_event] = merge_event_info(grouped_event); % merge some groups
    end

    for gn = 1:numel(grouped_event)
        group_name = grouped_event(gn).group;
        if debug_mode
            fprintf('[mod_and_group_eventProp] group (%d/%d): %s\n',gn,numel(grouped_event),group_name);
            if gn == 3
                pause
            end
        end
        % [grouped_event(gn).numTrial,grouped_event(gn).numRoi,grouped_event(gn).numRoiVec] = get_num_fieldUniqueContent(grouped_event(gn).event_info,...
        %     'fn_1', 'trialName', 'fn_2', 'roiName');
        [TrialRoiList] = get_roiNum_from_eventProp(grouped_event(gn).event_info);
        grouped_event(gn).numTrial = numel(TrialRoiList);
        grouped_event(gn).numRoi = sum([TrialRoiList.roi_num]);
        grouped_event(gn).TrialRoiList = TrialRoiList;

        if strcmp(eventType,'roi') && ~contains(group_name,'spon') && ~contains(group_name,'varied')
            [grouped_event(gn).eventPb,grouped_event(gn).eventPbList] = analyze_roi_event_possibility(grouped_event(gn).event_info,'debug_mode',debug_mode);
        end
    end

    % Sort group 
    [grouped_event] = sort_struct_with_str(grouped_event,'group',mgSetting.sort_order,'strCells_plus',mgSetting.sort_order_plus);

    grouped_event_setting.event_type = eventType;

    if ~isempty(adataSetting) 
        grouped_event_setting.traceData_type = adataSetting.traceData_type;
        grouped_event_setting.event_data_group = adataSetting.event_data_group;
        grouped_event_setting.event_filter = adataSetting.event_filter;
        grouped_event_setting.event_align_point = adataSetting.event_align_point;
        grouped_event_setting.cat_keywords = adataSetting.cat_keywords;
    end
end

