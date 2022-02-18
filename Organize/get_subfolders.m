function [subfolders, varargout] = get_subfolders(folder, varargin)
	% Get subfolders without '.', and '..''
	% 'folder' can be a path with wildcard "*"

	% % Defaults
	% keyword = [];


	% % Optionals for inputs
	% for n = 1:2:(nargin+1)
	% 	if strcmpi('keyword', varargin{n})
	% 		keyword = varargin{ii+1};
	% 	end
	% end


	% Main content
	folder_content = dir(folder);
	dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
	subfolders = folder_content(dirflag); % Extract only those that are directories
	subfolders = subfolders(~startsWith({subfolders.name}, '.')); % remove content starts with "."

	subfolders_num = numel(subfolders); 

	varargout{1} = subfolders_num;
end