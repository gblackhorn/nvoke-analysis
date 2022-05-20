function [filtered_struct_var,varargout] = filter_entries_in_structure(struct_var,fieldName,varargin)
	% Filter the entries in a structure varible.
    % Keep and/or discard certain entries using the inputs of varargin
    % Note: originally coded for filtering var "grouped_event_info" output by func [group_event_info_multi_category]
    % Note: "tags_keep" and "tags_discard". At least one of them should be input to use this function

	% struct_var: structure varible
	% fieldName: one field name in struct_var. This field should only contain char. 

	% Defaults
	% category_names = {};
	% filter_field = {}; % some values, such as "freq", can be used as threshold to filter data
    % filter_par = {};
    clean_ap_entry = false; % true: discard delay and rebound categories from airpuff experiments
    IgnoreCase = true; % ignore case if arrayVar and tag contain strings
    airpuff_tag = {'[ap]'}; % tag used to find airpuff entries
    apDis_tag = {'delay', 'rebound'}; % airpuff group entries containing these tags will be discarded if 'clean_ap_entry' is true

    tags_keep = {''};
    tags_discard = {''};

	% Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('tags_keep', varargin{ii})
            tags_keep = varargin{ii+1}; % cell/char. Keep groups containing these words
        elseif strcmpi('tags_discard', varargin{ii})
            tags_discard = varargin{ii+1}; % cell/char. Discard groups containing these words
        elseif strcmpi('clean_ap_entry', varargin{ii})
            clean_ap_entry = varargin{ii+1}; % true: discard delay and rebound categories from airpuff experiments
        elseif strcmpi('IgnoreCase', varargin{ii})
            IgnoreCase = varargin{ii+1}; 
        end
    end

    %% Main content
    % Convert tags_keep and tags_discard from 'char' type to 'cell'. 
    if isa(tags_keep,'char')
        tags_keep = {tags_keep};
    end
    if isa(tags_discard,'char')
        tags_discard = {tags_discard};
    end

    if isempty([tags_keep{:}]) && isempty([tags_discard{:}]) 
        error('At least one of the varargin (tags_keep, tags_discard) should be inputted');
    end

    % entry_num = numel(struct_var);

    % Find out data type (string, numeric or logical)
    firstContent = struct_var(1).(fieldName);
    if isa(firstContent, 'char')
        fieldContent = {struct_var.(fieldName)};
    else 
        if length(firstContent)>1 
            error('Entry content in the specified field must be char/string, single numeric or single logical value')
        else
            fieldContent = [struct_var.(fieldName)];
        end
    end

    % discard tags containing tags_discard
    if ~isempty([tags_discard{:}])
        [disIDX_td] = judge_array_content(fieldContent,tags_discard,'IgnoreCase',IgnoreCase);
    else
        disIDX_td = [];
    end

    % discard tags without tags_keep
    if ~isempty([tags_keep{:}])
        [keepIDX_tk] = judge_array_content(fieldContent,tags_keep,'IgnoreCase',IgnoreCase);
    else
        keepIDX_tk = [];
    end
    allIDX = [1:numel(struct_var)]';
    disIDX_tk = setdiff(allIDX, keepIDX_tk); % index to be discarded according to keepIDX_tk

    if clean_ap_entry % discard delay and rebound categories from airpuff experiments
        [apIDX] = judge_array_content(fieldContent,airpuff_tag,'IgnoreCase',IgnoreCase);
        fieldContent_ap = fieldContent(apIDX);
        [disIDX_apGroup] = judge_array_content(fieldContent_ap,apDis_tag,'IgnoreCase',IgnoreCase); % return the IDX of apIDX
        disIDX_ap = apIDX(disIDX_apGroup);
    else
        disIDX_ap = [];
    end

    disIDX = unique([disIDX_td;disIDX_tk;disIDX_ap]);
    filtered_struct_var = struct_var;
    filtered_struct_var(disIDX) = [];
    varargout{1} = disIDX; 
end