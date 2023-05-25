function [] = rm_subdir_files(varargin)
% Remove subdir files and folders specified by keywords
%   keywords are stored in a cell array


    % Defaults
    dir_path = 'S:\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\guoda\Inscopix\Projects\Exported_tiff';


    % Options
    for ii = 1:2:(nargin)
    	if strcmpi('keywords_file', varargin{ii})
    		keywords_file = varargin{ii+1};
    	elseif strcmpi('keywords_dir', varargin{ii})
    		keywords_dir = varargin{ii+1};
    	elseif strcmpi('dir_path', varargin{ii})
    		dir_path = varargin{ii+1};
        % elseif strcmpi('show_progress', varargin{ii})
        %     show_progress = varargin{ii+1};
        end
    end

    % Main contents
    if dir_path==0 
    	fprintf('directory was not specified')
    	return
    else
    	if ~exist('keywords_file', 'var') && ~exist('keywords_dir', 'var')
    		fprintf('no keywords specified for file/foler')
    		return
    	else
	    	folder_content = dir(dir_path);
	    	dirflag = [folder_content.isdir];
	    	subfolders = folder_content(dirflag); % Extract only those that are directories
	    	subfolders = subfolders(~startsWith({subfolders.name}, '.')); % remove content starts with "."
	    	subfolders_num = numel(subfolders); 

	    	for i = 1:subfolders_num % Ignore "." and ".." 
	    		subfolder = fullfile(dir_path, subfolders(i).name);

		    	if exist('keywords_file', 'var')
		    		kf_num = length(keywords_file); % keywords_file number
		    		for kfn = 1:kf_num
		    			file_list = dir(fullfile(subfolder, keywords_file{kfn}));
		    			if ~isempty(file_list)
		    				for fn = 1:numel(file_list)
		    					file_path = fullfile(subfolder, file_list(fn).name);
		    					delete(file_path)
		    				end
		    			end
		    		end
		    	end

		    	if exist('keywords_dir', 'var')
		    		kd_num = length(keywords_dir); % keywords_file number
		    		for kdn = 1:kd_num
		    			subfolder_content = dir(fullfile(subfolder, keywords_dir{kdn}));
		    			subdirflag = [subfolder_content.isdir];
		    			sub_subfolders = subfolder_content(subdirflag); % Extract only those that are directories
		    			sub_subfolders = sub_subfolders(~startsWith({sub_subfolders.name}, '.')); % remove content starts with "."

		    			if ~isempty(sub_subfolders)
		    				for dn = 1:numel(sub_subfolders)
		    					rmdir(fullfile(subfolder, sub_subfolders(dn).name), 's');
		    				end
		    			end
		    		end
		    	end
		    end
	    end
    end
end