function [CharCellArray_kw,idx,varargout] = filter_CharCells(CharCellArray,keywords,varargin)
    % Filter the CharCellArray using keywords.  
    % Elements without keywords will be discarded.
    % if the number of keywords is bigger than one. Char must contain all keyword to be kept

    % CharCellArray: {}. cell array only contains characters
    % keywords: {}. cell array contains 0-n keywords. 
    % varargin{1}: true/false. Choose if ignore case
    % idx: index of kept elements in CharCellArray

    CC_size = size(CharCellArray); % size of the elements in the CharCellArray
    TF = logical(ones(CC_size));
    IgnoreCase = false;

    if nargin == 3
        IgnoreCase = varargin{1};
    end

    if ~isempty(keywords)
        if isa(keywords,'char')
            keywords = {keywords};
        end

        kw_num = length(keywords); % number of keywords
        for kn = 1:kw_num
            kw = keywords{kn};
            tf_kw = contains(CharCellArray,kw,'IgnoreCase',IgnoreCase);
            TF = TF & tf_kw;
        end
    end

    idx = find(TF);
    CharCellArray_kw = CharCellArray(idx);
    varargout{1} = TF;
end

