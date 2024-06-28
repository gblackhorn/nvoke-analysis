function [newAlignedData] = filterNeuronsInAlignedDataVar(alignedData, neuronPropName, propCriteria, propCriteriaLogic, varargin)
    % Filter the ROIs in the data structure, alignedData, using criteria on a certain neuron
    % property 

    % Example:

    % Input parser
    p = inputParser;

    % Required input
    addRequired(p, 'alignedData', @isstruct);
    addRequired(p, 'neuronPropName', @ischar); % Name of a field in alignedData(n).traces
    addRequired(p, 'propCriteria', @(x) ischar(x) || isnumeric(x));
    addRequired(p, 'propCriteriaLogic', @ischar); % 'is'/'isnot'/'bigger'/'smaller' than the propCriteria
                                                % 'bigger' and 'smaller' include the 'propCriteria' value

    % Optional parameters with default values
    addParameter(p, 'keep', true, @islogical); % If true, when the prop meets the criteria, keep the neuron
                                               % If false, discard the neurons meet the criteria

    % Parse inputs
    parse(p, alignedData, neuronPropName, propCriteria, propCriteriaLogic, varargin{:});

    % Assign parsed values to variables
    alignedData = p.Results.alignedData;
    neuronPropName = p.Results.neuronPropName;
    propCriteria = p.Results.propCriteria;
    propCriteriaLogic = p.Results.propCriteriaLogic;
    keep = p.Results.keep;


    
    % Validate inputs

    % Check if the neuronProp exists 
    neuronPropTF = isfield(alignedData(1).traces, neuronPropName); 
    if ~neuronPropTF
        error('Struct data does not include the neuron property indicated by the input neuronPropname')
    end

    % Check the property data type (Use the property of the first neuron in the first recording as
    % the example)
    egProp = alignedData(1).traces(1).(neuronPropName);
    egPropVarType = class(egProp);

    % Validate the 'propCriteria' using the 'egPropVarType'. They must be the same kind of var type
    if ~isa(propCriteria, egPropVarType)
        error('The type of input var propCriteria must be %s', egPropVarType)
    end

    % Validate the 'propCriteriaLogic'
    if isa(propCriteria, 'char')
        % When char is the type of the 'propCriteria', the 'propCriteriaLogic' can only be 'is'
        % or 'isnot'
        if ~strcmpi(propCriteriaLogic, 'is') && ~strcmpi(propCriteriaLogic, 'isnot') 
            error('Input propCriteria is a char var, propCriteriaLogic must be either is or isnot')
        end
    end



    % Loop through the recordings in alignedData
    newAlignedData = alignedData;
    recNum = numel(newAlignedData);
    disRecIDX = []; % Used to store the index of recordings to be discarded from newAlignedData
    for rn = 1:recNum
        if ~isempty(newAlignedData(rn).traces)
            % Get the properties of all the neurons in the current recording
            neuronsProp = {newAlignedData(rn).traces.(neuronPropName)};

            % Examine the prop using the 'propCriteria' and the 'propCriteriaLogic'
            if isa(newAlignedData(rn).traces(1).(neuronPropName), 'char') 
                meetCriteriaTF = cellfun(@(x) strcmpi(x, propCriteria), neuronsProp);

                % Invert the binary array if the 'propCriteriaLogic' is 'isnot'
                if strcmpi(propCriteriaLogic, 'isnot')
                    meetCriteriaTF = ~meetCriteriaTF;
                end
            else
                switch propCriteriaLogic
                    case 'is'
                        meetCriteriaTF = cellfun(@(x) x == propCriteria, neuronsProp);
                    case 'isnot'
                        meetCriteriaTF = cellfun(@(x) x ~= propCriteria, neuronsProp);
                    case 'bigger'
                        meetCriteriaTF = cellfun(@(x) x >= propCriteria, neuronsProp);
                    case 'smaller'
                        meetCriteriaTF = cellfun(@(x) x <= propCriteria, neuronsProp);
                end
            end

            if keep
                % Using the binary array 'meetCriteriaTF' to discard the neurons fail to meet the criteria
                newAlignedData(rn).traces = newAlignedData(rn).traces(meetCriteriaTF);
            else
                meetCriteriaTF = ~meetCriteriaTF;

            end

            % Mark the recording as to be discarded if all neurons are discarded
            if isempty(newAlignedData(rn).traces)
                disRecIDX = [disRecIDX, rn];
            end
        else
            % Mark the recording as to be discarded if it is empty
            disRecIDX = [disRecIDX, rn];
        end
    end

    % Discard the empty recordings 
    newAlignedData(disRecIDX) = [];
end



