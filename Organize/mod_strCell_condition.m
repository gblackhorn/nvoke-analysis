function [CatCellNew,varargout] = mod_strCell_condition(CatCells,targetStr,varargin)
	% Modify strings in a cell array using conditions
	% targetStr in CatCells will be modified if conditions are met

	% CatCells: a cell array only containing strings
	% targetStr: Strings to be modified
	% newStr: if newStr is not empty, ignore conditions and change the targetStr to newStr


	% Defaults
	newStr = ''; % 
	containStr = ''; % targetStr will be modified to containStr_mod if CatCells contains containStr
	containStr_mod = ''; % new string for targetStr
	lackStr = ''; % targetStr will be modified to lackStr_mod if CatCells lacks lackStr
	lackStr_mod = ''; % % new string for targetStr
	% containStr_keep = {}; % targetStr will not be modified if CatCells contains containStr_keep
	% group_mod = {}; % targetStr will be modified if CatCells contains containStr

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('containStr', varargin{ii})
	        containStr = varargin{ii+1}; 
        elseif strcmpi('containStr_mod', varargin{ii})
	        containStr_mod = varargin{ii+1};
		elseif strcmpi('lackStr', varargin{ii})
	        lackStr = varargin{ii+1};
		elseif strcmpi('lackStr_mod', varargin{ii})
	        lackStr_mod = varargin{ii+1};
		elseif strcmpi('newStr', varargin{ii})
	        newStr = varargin{ii+1};
	    % elseif strcmpi('group_mod', varargin{ii})
	    %     group_mod = varargin{ii+1};
	    % elseif strcmpi('group_keep', varargin{ii})
	    %     group_keep = varargin{ii+1};
	    end
	end	

	%% Content
	CatCellNew = CatCells;
	tf_targetStr = strcmpi(targetStr, CatCellNew);
	idx_targetStr = find(tf_targetStr);
	if ~isempty(idx_targetStr)
		if ~isempty(newStr)
			% ignore all conditions and change targetStr to newStr
			for nt = 1:numel(idx_targetStr)
				CatCellNew{nt} = newStr;
			end
		else
			if ~isempty(containStr)
				tf_containStr = strcmpi(containStr, CatCellNew);
				idx_containStr = find(tf_containStr);
				if ~isempty(idx_containStr) && ~isempty(containStr_mod)
					for nt = 1:numel(idx_targetStr)
						CatCellNew{nt} = containStr_mod;
					end
				end
			end

			if ~isempty(lackStr)
				tf_lackStr = strcmpi(lackStr, CatCellNew);
				idx_lackStr = find(tf_lackStr);
				if ~isempty(idx_lackStr) && ~isempty(lackStr_mod)
					for nt = 1:numel(idx_targetStr)
						CatCellNew{nt} = lackStr_mod;
					end
				end
			end
		end
	end
end