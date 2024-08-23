function [grouped_event_info,varargout] = group_event_info_single_category(event_info,category_name,varargin)


	% Defaults
	filter_field = {}; % some values, such as "freq", can be used as threshold to filter data
    filter_par = {};
	groupname_prefix = '';
    f_groupname = 'group'; % fieldname for group names
    f_event_info = 'event_info'; % fieldname for group names

	% Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('filter_field', varargin{ii})
            filter_field = varargin{ii+1}; % {thresh1, thresh2,...}
        elseif strcmpi('filter_par', varargin{ii})
            filter_par = varargin{ii+1}; % {[min1, max1], [min2, max2],...} use NaN for inf value
        elseif strcmpi('groupname_prefix', varargin{ii})
        	groupname_prefix = varargin{ii+1};
        elseif strcmpi('f_groupname', varargin{ii})
            f_groupname = varargin{ii+1}; % {[min1, max1], [min2, max2],...} use NaN for inf value
        elseif strcmpi('f_event_info', varargin{ii})
            f_event_info = varargin{ii+1};
        end
    end

    %% Main content
    if ~isempty(filter_field)
    	[event_info] = filter_struct(event_info, filter_field, filter_par);
    end

    [catContent, catContentUnique, catContentUniqueNum, catContentUniqueTag] = extractCatContentInfo(event_info, category_name);

    % catContent = {event_info.(category_name)};

    % % Convert the catContent from cell to numeric array if possible
    % isNumOrLogical = isCellArrayNumericOrLogical(catContent);
    % if isNumOrLogical
    %     catContent = cellfun(@(x) num2str(x), catContent, 'UniformOutput', false);
    % end

    % catContentUnique = unique(catContent);
    % catContentUniqueNum = numel(catContentUnique);

    idx = cell(catContentUniqueNum, 1);

    for n = catContentUniqueNum:-1:1
    	groupChar = catContentUnique{n};
        tagName = catContentUniqueTag{n};
        if isempty(groupname_prefix)
           groupname = tagName;
        else 
    	   groupname = [groupname_prefix, '-', tagName];
        end
        % groupname = replace(groupname, '-', '_');

    	idx_logic = [cellfun(@(x) strcmpi(x, groupChar), catContent,  'UniformOutput',false)];
    	idx{n} = find([idx_logic{:}]);
        grouped_event_info(n).(f_groupname) = groupname;
    	grouped_event_info(n).(f_event_info) = event_info(idx{n});
        grouped_event_info(n).tag = tagName;
    end

    varargout{1} = idx;
    varargout{2} = catContentUnique;
end


function [catContent, catContentUnique, catContentUniqueNum, catContentUniqueTag] = extractCatContentInfo(event_info, category_name)

    % Get the values in the filed of 'category_name'
    catContent = {event_info.(category_name)};

    % Convert the catContent from cell to numeric array if possible
    isNumOrLogical = isCellArrayNumericOrLogical(catContent);
    if isNumOrLogical
        catContent = cellfun(@(x) num2str(x), catContent, 'UniformOutput', false);
    end

    catContentUnique = unique(catContent);
    catContentUniqueTag = catContentUnique;
    catContentUniqueNum = numel(catContentUnique);


    % Treat 'type' (0 for asyn, 1 for sync) differently
    switch category_name
        case 'type'
            % Replace '0' with 'async' and '1' with 'sync'
            catContentUniqueTag = strrep(catContentUniqueTag, '0', 'asynch');
            catContentUniqueTag = strrep(catContentUniqueTag, '1', 'synch');
        otherwise
    end
end