function [group, varargout] = organize_rec_group_info(recdata, varargin)
    % Return the group information of recordings according to stimulation method
    % 

    % Defaults
    stim_str_col = 3; % column number of stimulation names



    % key_string = 'video'; % Key_string is used to locate the end of string used for nameing subfolder
    % num_idx_correct = -2; % key_string idx + num_idx_correct = idx of the end of string for subfolder name

    % for ii = 1:2:(nargin-1)
    % 	if strcmpi('key_string', varargin{ii})
    % 		key_string = varargin{ii+1};
    % 	elseif strcmpi('num_idx_correct', varargin{ii})
    % 		num_idx_correct = varargin{ii+1};
    % 	end
    % end

    % Main content
    stim_str = recdata(:, stim_str_col);
    stim_str = cellfun(@(x) char(x), stim_str, 'UniformOutput', false); 

    stim_str_unique = unique(stim_str);
    stim_num = numel(stim_str_unique);

    for n = 1:stim_num
        group(n).name = stim_str_unique{n};
        group(n).idx = find(strcmp(stim_str, stim_str_unique{n}));
    end
end

