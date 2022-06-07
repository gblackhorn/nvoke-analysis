function [subfolder_path, varargout] = get_subfolder_content(folder,varargin)
	% Return the selected-level subfolder (oldest or newest) and its content 
	% folder can be sorted using date, "ascend" (default) or "descend"

	% Defaults
	subfolder_lv = 1; % look for first level subfolder and its content
	sort_direction = 'ascend';

	% Optionals for inputs
	for ii = 1:2:(nargin-1)
		if strcmpi('subfolder_lv', varargin{ii})
			subfolder_lv = varargin{ii+1};
		elseif strcmpi('sort_direction', varargin{ii})
			sort_direction = varargin{ii+1}; % recording frequency
		end
	end

	% Main content
	% subfolder_content = cell(subfolder_lv, 1);
	for i = 1:subfolder_lv
		% folder_content = dir(folder);
		% dirflag = [folder_content.isdir]; % Get a logical vector that tells which is a directory
		% subfolders = folder_content(dirflag); % Extract only those that are directories
		% subfolders = subfolders(~startsWith({subfolders.name}, '.')); % remove content starts with "."

		[subfolders, subfolders_num] = get_subfolders(folder);

		if length(subfolders) >= 1
			[~, idx] = sort([subfolders.datenum], sort_direction); 
			sorted_idx = idx(end);
			% [~, sorted_idx] = max(idx);
			subfolder = subfolders(sorted_idx); % pick the sorted subfolders, latest (default) or oldest
		elseif isempty(subfolders)
			error_msg = sprintf('level %d subfolder not found in "%s"', subfolder_lv, folder);
			disp(error_msg)
			return
		end
		folder = fullfile(subfolder.folder, subfolder.name);
		% subfolder_content{i} = dir(fullfile(subfolder.folder, subfolder.name));
	end
	subfolder_path = folder;
	subfolder_content = dir(subfolder_path); % content of target subfolder
	varargout{1} = subfolder_content; 
end