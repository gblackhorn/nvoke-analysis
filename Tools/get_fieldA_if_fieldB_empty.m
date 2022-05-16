function [fieldA_array,varargout] = get_fieldA_if_fieldB_empty(structVar,fieldA_name,fieldB_name,varargin)
    % Get the fieldA contents if the fieldB of the same entry is empty

    % structVar: a structure variable
    % fieldA_name: name of fieldA
    % fieldB_name: name of fieldB
    
    
    fieldA = {structVar.(fieldA_name)};
    fieldB = {structVar.(fieldB_name)};

    IDX_empty_fieldB = find(cellfun(@isempty, fieldB));
    fieldA_array = fieldA(IDX_empty_fieldB);

    varargout{1} = IDX_empty_fieldB; % index of empty fieldB in structVar
end

