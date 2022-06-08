function [structVar_new,varargout] = mod_struct_str(structVar,field_name,old_str,new_str,varargin)
	% Replace the old string in every entry of a specified with a new one
	% various old_str can be input in a cell array. They will all be replaced by the new_str

	% structVar: structure var
	% field_name: name of a field containing 'char' in each entry
	% old_str: one 'char' var or a cell array containing multiple 'char' 
	% new_str: one 'char' var

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
	str_cell = {structVar.(field_name)}; % collect all strings in the field "field_name" in a cell

	if isa(old_str,'char')
		old_str = {old_str};
	end

	os_num = numel(old_str); % number of the old strings
	for osn = 1:os_num
		str_cell = strrep(str_cell,old_str{osn},new_str);
	end

	structVar_new = structVar;
	[structVar_new.(field_name)] = str_cell{:};
end
