function [dataArray,dataGroupArray,varargout] = createDataAndGroupNameArray(dataCell,groupNames,varargin)
    % Input cell array of data (dataCell), and strings in cell (groupNames) whose number equals the
    % number of dataCell. Return a numeric array (dataArray) and a cell array
    % (dataGroupArray). dataArray and dataGroupArray have the same length

    % The outputs dataArray and dataGroupArray can be used for other functions, such as anova1

    % Input data, a vector, and dataGroup, a cell array containing strings to mark every number in data

    % Defaults

    % % Optionals
    % for ii = 1:2:(nargin-2)
    %     if strcmpi('displayopt', varargin{ii})
    %         displayopt = varargin{ii+1}; 
    %     elseif strcmpi('overwrite', varargin{ii})
    %         overwrite = varargin{ii+1};
    %     % elseif strcmpi('stimStart_err', varargin{ii})
    %     %     stimStart_err = varargin{ii+1};
    %     % elseif strcmpi('nonstimMean_pos', varargin{ii})
    %     %     nonstimMean_pos = varargin{ii+1};
    %     end
    % end 


    % validate the input
    if iscell(dataCell) && iscell(groupNames)
        sizeDataCell = size(dataCell);
        sizeGroupNames = size(groupNames);
        if ~isequal(sizeDataCell,sizeGroupNames)
            error('the size of input_1 (a data cell array) and input_2 (a string cell array) must be the same');
        end
        groupNames_allStr = all(cellfun(@ischar,groupNames));
        if ~groupNames_allStr
            error('All cells in input_2 must only contain strings')
        end
    else
        error('Input_1 and input_2 must be cell arrays')
    end

    % loop through cells and make group names for every data point
    groupNum = numel(dataCell);
    dataGroupCell = cell(size(dataCell));
    for n = 1:groupNum
        groupName = groupNames{n};

        dataGroupCell{n} = cell(size(dataCell{n}));
        [dataGroupCell{n}{:}] = deal(groupName);
    end
    dataArray = [dataCell{:}];
    dataGroupArray = [dataGroupCell{:}];
end