function [field_meanVal,varargout] = CollectAndAverage_fielddata(structVar,field,varargin)
    % Collect the data in a specific "field" of structure varible and calculate the mean value 
    % Note: structVar.field must only contain numeric
    
    % Defaults
    % trans = true; % true/false. Transpose the table
    % keep_rowNames = true; % true/false. Add row names into a new field or use them as field names if transposed
    % keep_colNames = true; % true/false. Use them as field names or add row names into a new field if transposed

    % RowNameField = 'RowNames'; % default field name for the RowNames from tableVar

    % % Optionals for inputs
    % for ii = 1:2:(nargin-1)
    % 	if strcmpi('trans', varargin{ii})
    % 		trans = varargin{ii+1};
    % 	elseif strcmpi('keep_rowNames', varargin{ii})
    % 		keep_rowNames = varargin{ii+1};
    % 	elseif strcmpi('keep_colNames', varargin{ii})
    % 		keep_colNames = varargin{ii+1};
    %     elseif strcmpi('RowNameField', varargin{ii})
    %         RowNameField = varargin{ii+1};
    %     end
    % end

    %% main contents
    field_data = [structVar.(field)];
    field_meanVal = mean(field_data);
    varargout{1} = field_data;
end

