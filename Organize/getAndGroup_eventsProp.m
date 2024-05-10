function [grouped_event,varargout] = getAndGroup_eventsProp(alignedData,varargin)
    % Get eventProp from every ROI and every trials in alignedData, and group them accroding to settings


    % Defaults
    entry = 'event'; % options: 'roi' or 'event'
    modify_stim_name = true; % true/false. Change the stimulation name, 
                            % such as GPIOxxx and OG-LEDxxx (output from nVoke), to simpler ones (ap, og, etc.)
    ggSetting.sponOnly = false; % true/false. If eventType is 'roi', and ggSetting.sponOnly is true. Only keep spon entries
    ggSetting.seperate_spon = true; % true/false. Whether to seperated spon according to stimualtion
    ggSetting.dis_spon = false; % true/false. Discard spontaneous events
    ggSetting.modify_eventType_name = true; % Modify event type using function [mod_cat_name]
    ggSetting.groupField = {'stim_name','peak_category'}; % options: 'fovID', 'stim_name', 'peak_category'; Field of eventProp_all used to group events 

    % if strcmp('stim_name',ggSetting.groupField) && strcmp('roi',eprop.entry)
    %   keep_eventcat = 'spon'; % only keep spon events to avoid duplicated values when eprop.entry is "roi"
    %   eventProp_all = filter_structData(eventProp_all,'peak_category','spon',1);
    % end

    % rename the stimulation tag if og evokes spike at the onset of stimulation
    ggSetting.mark_EXog = false; % true/false. if true, rename the og to EXog if the value of field 'stimTrig' is 1
    ggSetting.og_tag = {'og', 'og&ap'}; % find og events with these strings. 'og' to 'Exog', 'og&ap' to 'EXog&ap'

    % arrange the order of group entries using function [sort_struct_with_str] with settings below. 
    ggSetting.sort_order = {'spon', 'trig', 'rebound', 'delay'}; % 'spon', 'trig', 'rebound', 'delay'
    ggSetting.sort_order_plus = {'ap', 'EXopto'};

    adata = [];

    debug_mode = false; % true/false


    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        if strcmpi('entry', varargin{ii}) 
            entry = varargin{ii+1}; % excitation filter.  
        elseif strcmpi('modify_stim_name', varargin{ii}) 
            modify_stim_name = varargin{ii+1}; % inhibition filter.
        elseif strcmpi('ggSetting', varargin{ii}) 
            ggSetting = varargin{ii+1}; % rebound filter. 
        elseif strcmpi('adata', varargin{ii}) 
            adata = varargin{ii+1}; % rebound filter. 
        elseif strcmpi('debug_mode', varargin{ii}) 
            debug_mode = varargin{ii+1}; % rebound filter. 
        end
    end


    % Collect eventProp
    [eventProp_all]=collect_events_from_alignedData(alignedData,...
        'entry',entry,'modify_stim_name',modify_stim_name);


    % Group eventProp according to the 'mgSetting.groupField' and add more information
    [grouped_event,grouped_event_setting] = mod_and_group_eventProp(eventProp_all,entry,adata,...
        'mgSetting',ggSetting,'debug_mode',debug_mode);
    [grouped_event_setting.TrialRoiList] = get_roiNum_from_eventProp_fieldgroup(eventProp_all,'stim_name'); % calculate all roi number
    if strcmpi(entry,'roi')
        GroupNum = numel(grouped_event);
        % GroupName = {grouped_event.group};
        for gn = 1:GroupNum
            EventInfo = grouped_event(gn).event_info;
            fovIDs = {EventInfo.fovID};
            roi_num = numel(fovIDs);
            fovIDs_unique = unique(fovIDs);
            fovIDs_unique_num = numel(fovIDs_unique);
            fovID_count_struct = empty_content_struct({'fovID','numROI','perc'},fovIDs_unique_num);
            [fovID_count_struct.fovID] = fovIDs_unique{:};
            for fn = 1:fovIDs_unique_num
                fovID_count_struct(fn).numROI = numel(find(contains(fovIDs,fovID_count_struct(fn).fovID)));
                fovID_count_struct(fn).perc = fovID_count_struct(fn).numROI/roi_num;
            end
            grouped_event(gn).fovCount = fovID_count_struct;
        end
    end


    varargout{1} = eventProp_all;
end

