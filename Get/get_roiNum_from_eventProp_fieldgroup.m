function [TrialRoiList,varargout] = get_roiNum_from_eventProp_fieldgroup(eventProp,field_name,varargin)
    % Creat lists that involve trial, roi names, number of roi from the information in eventProp
    % The number of lists is the number of unique contents in a specific field, such as "stim_name" 
    % The TrialRoiList will be used to count ROI numbers

    % eventProp: a structure variable containing event properties 
    % field_name: a char var

    debug_mode = false; % true/false

    for ii = 1:2:(nargin-2)
        if strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        % elseif strcmpi('norm_par_suffix', varargin{ii})
        %     norm_par_suffix = varargin{ii+1};
        end
    end

    %% main contents
    field_contents = {eventProp.(field_name)};
    unique_fc = unique(field_contents);
    unique_fc_num = numel(unique_fc);
    TrialRoiList_fields = {field_name,'list','recNum','roiNum'};
    TrialRoiList = empty_content_struct(TrialRoiList_fields,unique_fc_num);

    for n = 1:unique_fc_num
    	fc = unique_fc{n};
    	idx = find(strcmp(fc,field_contents));
    	eventProp_sub = eventProp(idx);

    	TrialRoiList(n).(field_name) = fc;
    	TrialRoiList(n).list = get_roiNum_from_eventProp(eventProp_sub);
    	TrialRoiList(n).recNum = numel(TrialRoiList(n).list);
    	TrialRoiList(n).recNum = sum([TrialRoiList(n).list.roi_num]);
    end
end

