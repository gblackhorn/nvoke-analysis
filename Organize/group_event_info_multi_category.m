function [grouped_event_info, varargout] = group_event_info_multi_category(event_info, varargin)
    % Group event info with given category_names.
    % For example: fovID, mouseID, stim, etc.
    % Note: when multiple category_names are given, event_info will be sorted in a nested way according to
    % the order of category_names.

    % Create an input parser object
    p = inputParser;

    % Required input validation
    addRequired(p, 'event_info', @(x) isstruct(x));

    % Add optional parameters with default values and validation
    addParameter(p, 'category_names', {}, @iscell);  % Default: empty cell array
    addParameter(p, 'filter_field', {}, @iscell);    % Default: empty cell array
    addParameter(p, 'filter_par', {}, @iscell);                   % Default: empty cell array
    addParameter(p, 'debugMode', false, @(x) islogical(x) || isnumeric(x)); % Default: false

    % Parse the inputs
    parse(p, event_info, varargin{:});

    % Assign the parsed inputs to variables
    event_info = p.Results.event_info;
    category_names = p.Results.category_names;
    filter_field = p.Results.filter_field;
    filter_par = p.Results.filter_par;
    debugMode = p.Results.debugMode;



    %% Main content
    % filter data

    event_info_fieldnames = fieldnames(event_info);

    
    if ~isempty(category_names)
        category_num = numel(category_names);
    	% group_cat_info = struct('g_name', cell(category_num, 1), 'g_content_unique', cell(category_num, 1);

        grouped_event_info_temp = cell(category_num, 1); % each cell contains grouped info using "cn" categories  
        group_tags = cell(category_num, 1);
    	for cn = 1:category_num 
            if debugMode
                fprintf('Category %d/%d\n', cn, category_num)
                if cn == 3
                    pause
                end
            end
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