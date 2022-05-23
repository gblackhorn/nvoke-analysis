function [new_structVar,varargout] = add_norm_fields(structVar,par_fields,varargin)
    % Calculate the mean values of data in "par_fields" and normalized the data with mean values.
    % Add new fields to store the norm_data
    % Note: structVar.par_fields must only contain numeric

    % structVar: a structure field
    % par_fields: char var or cell containing characters
    
    % Defaults
    ref_idx = 'all';

    % new field will be connected to prefix and suffix with "_"
    newF_prefix = ''; % characters placed before "par_fields" to name the new fields
    newF_suffix = ''; % characters placed after "par_fields" to name the new fields

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('ref_idx', varargin{ii})
    		ref_idx = varargin{ii+1}; % input should be an numeric array
    	elseif strcmpi('newF_prefix', varargin{ii})
    		newF_prefix = varargin{ii+1};
    	elseif strcmpi('newF_suffix', varargin{ii})
    		newF_suffix = varargin{ii+1};
        % elseif strcmpi('RowNameField', varargin{ii})
        %     RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    new_structVar = structVar;
    if isempty(newF_prefix) && isempty(newF_suffix) 
        newF_prefix = 'norm'; % at lease one of the -fix should be ~empty to creat a new field
    end

    % Get the structVar_ref used to calculate the reference mean values
    if isa(ref_idx,'char')
        structVar_ref = structVar;
    else
        structVar_ref = structVar(ref_idx);
    end

    if isa(par_fields, 'char')
        par_num = 1;
        par_fields = {par_fields};
    elseif isa(par_fields, 'cell')
        par_num = numel(par_fields);
    end

    for n = 1:par_num
        par_name = par_fields{n};
        par_meanVal = CollectAndAverage_fielddata(structVar_ref,par_name);
        par_normVal = [structVar.(par_name)]/par_meanVal;
        par_normVal_cell = num2cell(par_normVal);

        par_name_norm = par_name;
        if ~isempty(newF_prefix)
            par_name_norm = sprintf('%s_%s',newF_prefix,par_name_norm);
        end
        if ~isempty(newF_suffix)
            par_name_norm = sprintf('%s_%s',par_name_norm,newF_suffix);
        end
        [new_structVar.(par_name_norm)] = par_normVal_cell{:};
    end
end

