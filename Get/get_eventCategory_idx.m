function [category_idx,varargout] = get_eventCategory_idx(peakCategories,varargin)
	% Get the index of events belongs to different categories

	% peakCategories: cell array containing strings of peak category names. Usually arranged chronologically
	% category_idx： structure var containing field 'name' and 'idx'

	% Defaults

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('pc_norm', varargin{ii})
	%         pc_norm = varargin{ii+1}; 
	%     elseif strcmpi('amp_data', varargin{ii})
	%         amp_data = varargin{ii+1};
	%     end
	% end	

	%% Content
	pc_unique = unique(peakCategories);
	groupNum = numel(pc_unique);

	category_idx = struct('name', cell(1, groupNum), 'idx', cell(1, groupNum));

	for n = 1:groupNum
		category_idx(n).name = pc_unique{n};
		tf_pc = strcmpi(category_idx(n).name, peakCategories);
		category_idx(n).idx = find(tf_pc);
	end

	varargout{1} = groupNum;
	varargout{2} = pc_unique;
end