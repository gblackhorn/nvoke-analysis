function [alignedDataStructNew, varargout] = validateAlignedDataStructForEventAnalysis(alignedDataStruct, requiredEventProp)
    % Discard the recordings without 'requiredEventProp'

    % Initialize input parser
    p = inputParser;

    % Add required inputs with validation functions
    addRequired(p, 'alignedDataStruct', @isstruct);
    addRequired(p, 'requiredEventProp', @(x) ischar(x));

    % Parse inputs
    parse(p, alignedDataStruct, requiredEventProp);    

    % Loop through Recordings and discard those without sync tag in the eventProp (Due to single neuron)
    recNum = numel(alignedDataStruct);
    dixIDX = [];
    for rn = 1:recNum
        if ~isempty(alignedDataStruct(rn).traces)
            % Get the field names in the first ROI 
            eventPropFields = fieldnames(alignedDataStruct(rn).traces(1).eventProp); 

            % Look for 'requiredEventProp' in the 'eventPropFields'
            tf = strcmpi(eventPropFields, requiredEventProp);

            % If there is no 'requiredEventProp', add this recording to discard list
            if isempty(find(tf))
                dixIDX = [dixIDX rn];
            end
        else
            dixIDX = [dixIDX rn];
        end
    end

    alignedDataStructNew = alignedDataStruct;
    alignedDataStructNew(dixIDX) = [];
    varargout{1} = dixIDX;
end





