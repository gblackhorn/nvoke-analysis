function [all_series_eventProp,varargout] = collect_AllEventProp_from_seriesData(seriesData_sync,varargin)
    % Collect all eventProp from seriesData_sync variable. Tag and concatenate them

    % seriesData_sync: struct var
    %           - fields: seriesName, SeriesData, ca_events, ref_stim, ROIs, ROIs_num, NeuronGroup_data
    % 
    % 1. Gather data from seriesData_sync.NeuronGroup_data.eventPropData
    % 2. 
    
    % Defaults
    % tag_field = ''; % name of a field in StructVar other than "data_field". The concatenated data can be tagged with info from this field

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
        % if strcmpi('tag_field', varargin{ii})
        %     tag_field = varargin{ii+1};
        % elseif strcmpi('other_trial_event_type', varargin{ii})
        %     other_trial_event_type = varargin{ii+1};
        % elseif strcmpi('keep_colNames', varargin{ii})
        %   keep_colNames = varargin{ii+1};
     %    elseif strcmpi('RowNameField', varargin{ii})
     %        RowNameField = varargin{ii+1};
        % end
    end

    %% main contents
    series_num = numel(seriesData_sync);
    for sn = 1:series_num
        roi_num = numel(seriesData_sync(sn).NeuronGroup_data);
        for rn = 1:roi_num
            eventPropData = seriesData_sync(sn).NeuronGroup_data(rn).eventPropData;
            tf_empty = cellfun(@isempty, {eventPropData.event_info});
            idx_empty = find(tf_empty);
            eventPropData(idx_empty) = [];
            
            eventProp = collect_StructFieldData(eventPropData,...
                'event_info','tag_field','group');
            if sn == 1 && rn == 1
                all_series_eventProp = eventProp;
            else
                all_series_eventProp = [all_series_eventProp, eventProp];
            end
        end
    end
end

