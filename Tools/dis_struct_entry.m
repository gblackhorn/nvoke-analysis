function [structVar_new,varargout] = dis_struct_entry(structVar,field_name,keywords,keywords_type,varargin)
	% Delete entries in structVar according to keywords
	% Find the entries containing keywords. 'discard' or 'keep' the entries according to the keywords_type

	% structVar: structure var
	% field_name: name of a field containing 'char' in each entry
	% keywords: one 'char' or a cell array containing multiple 'char' 
	% keywords_type: 'discard'/'keep'

	% Defaults


	% % Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('stim_name', varargin{ii})
	%         stim_name = varargin{ii+1}; % if not empty, cat_name will become cat_name[stim_name]
	%     elseif strcmpi('cat_exclude', varargin{ii})
	%         cat_exclude = varargin{ii+1}; 
	%     elseif strcmpi('debug_mode', varargin{ii})
	%         debug_mode = varargin{ii+1}; 
	%     end
	% end

	% ====================
	% Main contents
	field_content = {structVar.(field_name)};
	if isa(keywords,'char')
		keywords = {keywords};
	end

	idx = [];
	key_num = numel(keywords);
	for kn = 1:key_num
		pattern = keywords{kn};
		pattern_tf = contains(field_content, pattern);
		idx = [idx, find(pattern_tf)];
	end

	switch keywords_type
		case 'discard'
			structVar_new = structVar;
			structVar_new(idx) = [];
		case 'keep'
			structVar_new = structVar(idx);
		otherwise
			error('Error in [dis_struct_entry]: input %s or %s for keywords_type',...
				'discard', 'keep')
	end
end
