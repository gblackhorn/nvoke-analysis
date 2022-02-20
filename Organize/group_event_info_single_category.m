function [grouped_event_info, varargout] = group_event_info_single_category(event_info, category_name, varargin)


	% Defaults
	filter_field = {}; % some values, such as "freq", can be used as threshold to filter data
    filter_par = {};
	groupname_prefix = '';

	% Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('filter_field', varargin{ii})
            filter_field = varargin{ii+1}; % {thresh1, thresh2,...}
        elseif strcmpi('filter_par', varargin{ii})
            filter_par = varargin{ii+1}; % {[min1, max1], [min2, max2],...} use NaN for inf value
        elseif strcmpi('groupname_prefix', varargin{ii})
        	groupname_prefix = varargin{ii+1};
        end
    end

    %% Main content
    if ~isempty(filter_field)
    	[event_info] = filter_struct(event_info, filter_field, filter_par);
    end

    category_content = {event_info.(category_name)};
    category_content_unique = unique(category_content);
    category_content_unique_num = numel(category_content_unique);

    idx = cell(category_content_unique_num, 1);

    for n = category_content_unique_num:-1:1
    	keyword = category_content_unique{n};
        if isempty(groupname_prefix)
           groupname = keyword;
        else 
    	   groupname = [groupname_prefix, '-', keyword];
        end
        % groupname = replace(groupname, '-', '_');

    	idx_logic = [cellfun(@(x) strcmpi(x, keyword), category_content,  'UniformOutput',false)];
    	idx{n} = find([idx_logic{:}]);
        grouped_event_info(n).group = groupname;
    	grouped_event_info(n).event_info = event_info(idx{n});
        grouped_event_info(n).tag = keyword;
    end

    varargout{1} = idx;
    varargout{2} = category_content_unique;
end