function [trueIDX,varargout] = judge_array_content(arrayVar,tag,varargin)
	% Judge if the entries in arrayVar contain elements in tag. Return the index of "true" entries

	% arrayVar: cell array (string), numeric array, or logical array
	% tag: string(s) in cell array, numeric array, logical array
    % trueIDX: index of arrayVar entries containing tag element

	% Defaults
    IgnoreCase = true; % ignore case if arrayVar and tag contain strings

	% Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('IgnoreCase', varargin{ii})
            IgnoreCase = varargin{ii+1}; % cell array containing strings. Keep groups containing these words
        % elseif strcmpi('tags_discard', varargin{ii})
        %     tags_discard = varargin{ii+1}; % cell array containing strings. Discard groups containing these words
        % elseif strcmpi('clean_ap_entry', varargin{ii})
        %     clean_ap_entry = varargin{ii+1}; % true: discard delay and rebound categories from airpuff experiments
        end
    end

    %% Main content
    arrayVarType = class(arrayVar);
    if ~isa(tag, arrayVarType)
        error('The 1st input (arrayVar) and the 2nd input (tag) should be the same class:\n cell, numeric or logical');
    end

    trueIDX = [];
    if isa(arrayVar, 'cell')
        tagNum = numel(tag);
        for tn = 1:tagNum
            TFarray = contains(arrayVar, tag{tn}, 'IgnoreCase', IgnoreCase);
            trueIDX_part = find(TFarray);
            trueIDX_part = trueIDX_part(:);
            trueIDX = [trueIDX;trueIDX_part];
        end
    elseif isa(arrayVar, 'numeric')
        TFarray = ismember(arrayVar, tag);
        trueIDX = find(TFarray);
        trueIDX = trueIDX(:);
    elseif isa(arrayVar, 'logical')
        trueIDX = find(arrayVar==tag);
        trueIDX = trueIDX(:);
    end 
    trueIDX = unique(trueIDX);   
end