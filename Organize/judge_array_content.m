function [trueIDX, varargout] = judge_array_content(arrayVar, tag, varargin)
    % Judge if the entries in arrayVar contain elements in tag or exactly match it. 
    % Return the index of "true" entries.

    % arrayVar: cell array (string), numeric array, or logical array
    % tag: string(s) in cell array, numeric array, logical array
    % trueIDX: index of arrayVar entries containing or exactly matching tag element

    % Defaults
    IgnoreCase = true;  % ignore case if arrayVar and tag contain strings
    ExactMatch = false; % match exactly if set to true

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('IgnoreCase', varargin{ii})
            IgnoreCase = varargin{ii+1}; % cell array containing strings. Keep groups containing these words
        elseif strcmpi('ExactMatch', varargin{ii})
            ExactMatch = varargin{ii+1}; % If true, match only exact entries
        end
    end

    %% Main content
    trueIDX = [];
    
    if isa(arrayVar, 'cell')
        tagNum = numel(tag);
        for tn = 1:tagNum
            if ExactMatch
                % If exact match is enabled, we check for exact matches in arrayVar
                if IgnoreCase
                    TFarray = strcmpi(arrayVar, tag{tn});
                else
                    TFarray = strcmp(arrayVar, tag{tn});
                end
            else
                % Otherwise, check if arrayVar contains the tag
                TFarray = contains(arrayVar, tag{tn}, 'IgnoreCase', IgnoreCase);
            end
            trueIDX_part = find(TFarray);
            trueIDX_part = trueIDX_part(:);
            trueIDX = [trueIDX; trueIDX_part];
        end
    elseif isa(arrayVar, 'numeric')
        % For numeric arrays, ismember inherently handles exact matching
        TFarray = ismember(arrayVar, tag);
        trueIDX = find(TFarray);
        trueIDX = trueIDX(:);
    elseif isa(arrayVar, 'logical')
        trueIDX = find(arrayVar == tag);
        trueIDX = trueIDX(:);
    end
    
    trueIDX = unique(trueIDX);  % Remove duplicates
    
end
