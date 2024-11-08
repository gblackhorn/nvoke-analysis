function [grouped_event,varargout] = getAndGroup_eventsProp(alignedData,varargin)
    % Get eventProp from every ROI and every trials in alignedData, and group them accroding to settings

    % Create an instance of the inputParser
    p = inputParser;

    % Required input
    addRequired(p, 'alignedData', @isstruct);

    % Defaults
    defaultEntry = 'event';
    defaultModifyStimName = true;
    defaultGgSetting = struct('sponOnly', false, ...
                              'seperate_spon', true, ...
                              'dis_spon', false, ...
                              'modify_eventType_name', true, ...
                              'groupField', {{'stim_name','peak_category'}}, ... % Note the double curly braces
                              'mark_EXog', false, ...
                              'og_tag', {{'og', 'og&ap'}}, ... % Note the double curly braces
                              'sort_order', {{'spon', 'trig', 'rebound', 'delay'}}, ...
                              'sort_order_plus', {{'ap', 'EXopto'}});    defaultAdata = [];

    % Add optional parameters to the input parser
    addParameter(p, 'entry', defaultEntry, @ischar);
    addParameter(p, 'modify_stim_name', defaultModifyStimName, @islogical);
    addParameter(p, 'ggSetting', defaultGgSetting, @isstruct);
    addParameter(p, 'adata', defaultAdata);
    addParameter(p, 'filterROIs', false, @islogical);
    addParameter(p, 'filterROIsStimTags', {}, @iscell);
    addParameter(p, 'filterROIsStimEffects', {}, @iscell);
    addParameter(p, 'debug_mode', false, @islogical);

    % Parse inputs
    parse(p, alignedData, varargin{:});

    % Retrieve parsed values
    entry = p.Results.entry;
    modify_stim_name = p.Results.modify_stim_name;
    ggSetting = p.Results.ggSetting;
    adata = p.Results.adata;
    filterROIs = p.Results.filterROIs;
    filterROIsStimTags = p.Results.filterROIsStimTags;
    filterROIsStimEffects = p.Results.filterROIsStimEffects;
    debug_mode = p.Results.debug_mode;


    if filterROIs
        [alignedData,tfIdxWithSubNucleiInfo,roiNumAll,roiNumKep,roiNumDis] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
            'stim_names',filterROIsStimTags,'filters',filterROIsStimEffects);
    end


    % Collect eventProp
    eventProp_all = collect_event_prop(alignedData, 'style', entry, 'modifyStimName',modify_stim_name); % only use 'event' for 'style'
    % [eventProp_all]=collect_events_from_alignedData(alignedData,...
    %     'entry',entry,'modify_stim_name',modify_stim_name);


    % Group eventProp according to the 'mgSetting.groupField' and add more information
    [grouped_event, grouped_event_setting] = mod_and_group_eventProp(eventProp_all, entry, adata, ...
        'separateSpon', ggSetting.separateSpon, ...
        'discardSpon', ggSetting.dis_spon, ...
        'modifyEventTypeName', ggSetting.modify_eventType_name, ...
        'groupField', ggSetting.groupField, ...
        'markEXog', ggSetting.mark_EXog, ...
        'ogTags', ggSetting.og_tag, ...
        'sortOrder', ggSetting.sort_order, ...
        'sortOrderPlus', ggSetting.sort_order_plus, ...
        'debugMode', debug_mode);

    % [grouped_event,grouped_event_setting] = mod_and_group_eventProp(eventProp_all,entry,adata,...
    %     'mgSetting',ggSetting,'debug_mode',debug_mode);
    
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

