function [alignedData_eventInfo_filtered,varargout] = filter_event_and_trace_in_alignedData(alignedData_eventInfo,fieldName,varargin)
    % Filter events in eventProp and value (aligned event traces) field
    % This fucn utilize func [filter_entries_in_structure]

    % alignedData_eventInfo: a struct var. usually it is alignedData.trace 
    %       - fields: eventProp, value, mean_val, std_val, roi, etc.
    % fieldName: field name in alignedData.trace.eventInfo
    
    % Defaults
    tags_keep = {''};
    tags_discard = {''};

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('tags_keep', varargin{ii})
            tags_keep = varargin{ii+1};
        elseif strcmpi('tags_discard', varargin{ii})
            tags_discard = varargin{ii+1};
        % elseif strcmpi('keep_colNames', varargin{ii})
        %   keep_colNames = varargin{ii+1};
     %    elseif strcmpi('RowNameField', varargin{ii})
     %        RowNameField = varargin{ii+1};
        end
    end

    %% main contents
    alignedData_eventInfo_filtered = alignedData_eventInfo;
    roi_num = numel(alignedData_eventInfo_filtered);
    for n = 1:roi_num
        event_struct = alignedData_eventInfo_filtered(n).eventProp;
        [~,disIDX] = filter_entries_in_structure(event_struct,fieldName,...
            'tags_keep',tags_keep,'tags_discard',tags_discard); % get the index of events to be discarded
        alignedData_eventInfo_filtered(n).eventProp(disIDX) = []; % discard events in eventProp field
        alignedData_eventInfo_filtered(n).value(:,disIDX) = [];  % discard event aligned trace in value field

        % recalculte the mean and std of the aligned traces
        alignedData_eventInfo_filtered(n).mean_val = mean(alignedData_eventInfo_filtered(n).value, 2, 'omitnan');
        alignedData_eventInfo_filtered(n).std_val = std(alignedData_eventInfo_filtered(n).value, 0, 2, 'omitnan');
    end
end

