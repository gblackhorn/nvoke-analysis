function [grouped_event_info, varargout] = group_event_info_multi_category(event_info, varargin)
	% Group event info with given category_names.
	% For example: fovID, mouseID, stim, etc.
	% Note: when multiple category_names were given, event_info will be sorted in a nested way according to
	%	the order of category_names.

	% Defaults
	category_names = {};
	filter_field = {}; % some values, such as "freq", can be used as threshold to filter data
    filter_par = {};

	% Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('category_names', varargin{ii})
            category_names = varargin{ii+1};
        elseif strcmpi('filter_field', varargin{ii})
            filter_field = varargin{ii+1}; % {thresh1, thresh2,...}
        elseif strcmpi('filter_par', varargin{ii})
            filter_par = varargin{ii+1}; % {[min1, max1], [min2, max2],...} use NaN for inf value
        end
    end



    %% Main content
    % filter data

    event_info_fieldnames = fieldnames(event_info);

    
    if ~isempty(category_names)
        category_num = numel(category_names);
    	% group_cat_info = struct('g_name', cell(category_num, 1), 'g_content_unique', cell(category_num, 1);

        grouped_event_info_temp = cell(category_num, 1); % each cell contains grouped info using "cn" categories  
        group_tags = cell(category_num, 1);
    	for cn = 1:category_num 
    		if cn == 1 % first level group
    			[grouped_event_info_temp{cn},~,group_tags{cn}] = group_event_info_single_category(event_info, category_names{cn},...
    				'filter_field', filter_field, 'filter_par', filter_par);
            else % for the 2nd and more levels of group. Visit parent group and creat new groups from there
                % group_names_prev = fieldnames(grouped_event_info_temp{cn-1});
                group_num_prev = numel(grouped_event_info_temp{cn-1});

                new_group_cell = cell(group_num_prev, 1);
                for np = 1:group_num_prev
                    group = grouped_event_info_temp{cn-1};
                    name_prefix = group(np).group;
                    event_info = group(np).event_info;
                    % group_event_info = grouped_event_info_temp{cn-1}.(group_names_prev{np});
                    [new_group_cell{np},~,tags] = group_event_info_single_category(event_info, category_names{cn},...
                        'groupname_prefix', name_prefix);
                end
                grouped_event_info_temp{cn} = [new_group_cell{:}];
                group_tags{cn} = tags;
            end
    	end
        grouped_event_info = grouped_event_info_temp{category_num};
        grouped_event_info_option.category_names = category_names;
        grouped_event_info_option.filter_field = filter_field;
        grouped_event_info_option.filter_par = filter_par;

        varargout{1} = grouped_event_info_option;
    end
end