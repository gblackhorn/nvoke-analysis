function [filtered_struct_var,varargout] = filter_groups_in_structure(struct_var,fieldName,varargin)
	% Filter the groups in a structure varible.
    % Note: originally coded for filtering var "grouped_event_info" output by func [group_event_info_multi_category]

	% struct_var: structure varible
	% fieldName: one field name in struct_var. This field should only contain char. 

	% Defaults
	% category_names = {};
	% filter_field = {}; % some values, such as "freq", can be used as threshold to filter data
    % filter_par = {};
    clean_ap_group = true; % true: discard delay and rebound categories from airpuff experiments

	% Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('words_keep', varargin{ii})
            words_keep = varargin{ii+1}; % cell array containing strings. Keep groups containing these words
        elseif strcmpi('words_discard', varargin{ii})
            words_discard = varargin{ii+1}; % cell array containing strings. Discard groups containing these words
        elseif strcmpi('clean_ap_group', varargin{ii})
            clean_ap_group = varargin{ii+1}; % true: discard delay and rebound categories from airpuff experiments
        end
    end

    %% Main content
    if ~exist('words_keep','var') && ~exist('words_discard','var') 
        error('At least one of the varargin (words_keep, words_discard) should be inputted');
    end

    group_num = numel(struct_var);

    % discard groups containing words_discard
    if exist('words_discard','var')
        disIDX_wd = [];
        wd_num = numel(words_discard);
        for n = 1:group_num
            group = struct_var(n).(fieldName);
            for wdn = 1:wd_num
                if ~isempty(strfind(group, words_discard{wdn}))
                    dis_tf = true;
                    break
                else
                    dis_tf = false;
                end
            end
            if dis_tf
                disIDX_wd = [disIDX_wd; n];
            end
        end
        
    else
        disIDX_wd = [];
    end

    % discard groups without words_keep
    if exist('words_keep','var')
        disIDX_wk = [];
        wk_num = numel(words_keep);
        for n = 1:group_num
            group = struct_var(n).(fieldName);
            for wkn = 1:wk_num
                if clean_ap_group % discard delay and rebound categories from airpuff experiments
                    if ~isempty(strfind(group, 'ap'))
                        if ~isempty(strfind(group, 'delay')) || ~isempty(strfind(group, 'rebound'))
                            dis_tf = true;
                            break
                        end
                    end
                end

                if ~isempty(strfind(group, words_keep{wkn}))
                    dis_tf = false;
                    break
                else
                    dis_tf = true;
                end
            end
            if dis_tf
                disIDX_wk = [disIDX_wk; n];
            end
        end
    else
        disIDX_wk = [];
    end

    % combine disIDX_wd and disIDX_wk, and filter groups
    disIDX = unique([disIDX_wd;disIDX_wk]);
    filtered_struct_var = struct_var;
    filtered_struct_var(disIDX) = [];
end