function [fieldData_all,varargout] = collect_StructFieldData(StructVar,data_field,varargin)
    % Collect data in StructVar.data_field and concatenate them 

    % StructVar: struct var
    % data_field: name of a field in StructVar
    
    % Defaults
    tag_field = ''; % name of a field in StructVar other than "data_field". The concatenated data can be tagged with info from this field

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('tag_field', varargin{ii})
            tag_field = varargin{ii+1};
        % elseif strcmpi('other_trial_event_type', varargin{ii})
        %     other_trial_event_type = varargin{ii+1};
        % elseif strcmpi('keep_colNames', varargin{ii})
        %   keep_colNames = varargin{ii+1};
     %    elseif strcmpi('RowNameField', varargin{ii})
     %        RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    if ~isempty(tag_field) && isfield(StructVar, tag_field)
        tag_data = true; % tag every entry in fieldData_all with the info from StructVar.tag_field
    else
        tag_data = false;
    end

    for sn = 1:numel(StructVar)
        fieldData = StructVar(sn).(data_field);
        tag = StructVar(sn).(tag_field);
        [fieldData.(tag_field)] = deal(tag);

        if sn == 1
            fieldData_all = fieldData;
        else
            fieldData_all = [fieldData_all, fieldData];
        end
    end
end

