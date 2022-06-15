function [structGroup,varargout] = group_struct_entries(structVar,condition_field,varargin)
    % Group entries in structVar according to the contents of condition_field
    % Entries sharing the same numeric/char in the specified field will be grouped together

    % structVar: a structure variable with multiple entries.
    % condition_field: name of a field in structVar
    % structGroup: a structure. Each entry contains a group. 

    
    % % Defaults
    % FieldN = fieldnames(ca_events);

    % % Optionals for inputs
    % for ii = 1:2:(nargin-1)
    %     if ~isempty(find(strcmpi(varargin{ii}, FieldN)))
    %         condition.(varargin{ii}) = varargin{ii+1};
    %     end
    % end

    %% main contents
    con_f_contents = {structVar.(condition_field)};
    groups = unique(con_f_contents); 
    g_num = numel(groups); % number of groups

    for n = 1:g_num
        g = groups{n}; % group value: numeric/char
        if isa(g, 'char')
            idx = find(strcmp(g, con_f_contents)); % index of entris belong to "g" group
            f_name = g;
        elseif isa(g, 'numeric')
            idx = find(cellfun(@(x) x==g, con_f_contents,'UniformOutput',false));
            f_name = num2str(g);
        else
            error('func [group_struct_entries]:\n condition_filed data class should be either char or numeric')
        end

        structGroup.(f_name) = structVar(idx);
    end
end

