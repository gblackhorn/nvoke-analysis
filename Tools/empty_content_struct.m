function [new_struct] = empty_content_struct(field_names,entry_num)
    % Creat a structure var with empty content

    % field_names: 'Char' or 'cell'. Name(s) of fields.
    % entry_num: Number of entries

    if isa(field_names,'char')
        field_names = {field_names};
    end
    field_names = field_names(:).';

    if nargin == 1
        cellVar = field_names;
        cellVar{2,1} = {};
        new_struct = struct(cellVar{:});
    elseif nargin == 2
        if isempty(entry_num) || entry_num == 0
            cellVar = field_names;
            cellVar{2,1} = {};
            new_struct = struct(cellVar{:});
        else
            fn_num = numel(field_names);
            cellarray = cell(fn_num,entry_num);
            new_struct = cell2struct(cellarray,field_names);
        end
    end
end

