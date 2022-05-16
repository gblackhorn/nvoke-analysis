function [structVar,varargout] = convert_table2struct(tableVar,varargin)
    % Convert a table variable to a structure variable 
    % Originally wrote to convert recdata{n, 5}, which stores peak properties, to structure
    
    %   Detailed explanation goes here
    
    % Defaults
    trans = true; % true/false. Transpose the table
    keep_rowNames = true; % true/false. Add row names into a new field or use them as field names if transposed
    keep_colNames = true; % true/false. Use them as field names or add row names into a new field if transposed

    RowNameField = 'RowNames'; % default field name for the RowNames from tableVar

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('trans', varargin{ii})
    		trans = varargin{ii+1};
    	elseif strcmpi('keep_rowNames', varargin{ii})
    		keep_rowNames = varargin{ii+1};
    	elseif strcmpi('keep_colNames', varargin{ii})
    		keep_colNames = varargin{ii+1};
        elseif strcmpi('RowNameField', varargin{ii})
            RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    % T_varNames = tableVar.Properties.VariableNames;
    % T_rowNames = tableVar.Properties.RowNames;
    % A = table2array(tableVar); % convert the table var to an array var.

    if trans
        [tableVar] = transpose_table(tableVar);
    end

    T_rowNames = tableVar.Properties.RowNames;
    structVar = table2struct(tableVar);
    [structVar.(RowNameField)] = T_rowNames{:};
end

