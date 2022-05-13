function [structData_sorted,varargout] = sort_struct_with_str(structData,fieldName,strCells,varargin)
	% Sort structure data with a string field. 

	% structData: structure
	% fieldName: Name of the field used to filterdata
	% strCells: structData will be sorted according to the order of strings in strCells. Example {'spon', 'trig', 'rebound'}
	% varargin(strCells_plus) can be used to sort structData on the second level

	% Defaults
	% val_relation = 'equal'; % equal/larger/smaller. only valie when value is 'numeric'. larger and smaller includ the specific val

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('strCells_plus', varargin{ii})
	        strCells_plus = varargin{ii+1}; % used to sort entries in a single sort_group
        % elseif strcmpi('timeInfo', varargin{ii})
	       %  timeInfo = varargin{ii+1};
	    end
	end	

	%% Content
	% structData_sorted = structData;
	contents = {structData.(fieldName)}; % assign the field contents to a cell array

	sort_group_num = numel(strCells);
	sort_group = cell(1, sort_group_num);
	unsorted_idx = [1:length(structData)];
	for n = 1:sort_group_num
		pattern = strCells{n};
		tf = contains(contents, pattern);
		idx = find(tf);
		sort_group{n} = structData(idx);
		unsorted_idx(idx) = NaN;

		if exist('strCells_plus', 'var')
			sort_subgroup_num = numel(strCells_plus);
			sort_subgroup = cell(1, sort_subgroup_num);
			contents_subgroup = {structData(idx).(fieldName)};
			% unsorted_sub_idx = [1:sort_subgroup_num];
			unsorted_sub_idx = [1:length(contents_subgroup)];
			for sn = 1:sort_subgroup_num
				pattern_sub = strCells_plus{sn};
				tf_sub = contains(contents_subgroup, pattern_sub);
				idx_sub = find(tf_sub);
				sort_subgroup{sn} = sort_group{n}(idx_sub);
				unsorted_sub_idx(idx_sub) = NaN;
			end
			unsorted_sub_idx = (unsorted_sub_idx(~isnan(unsorted_sub_idx)));
			sort_group{n} = [sort_subgroup{:} sort_group{n}(unsorted_sub_idx)];
		end
	end
	unsorted_idx = (unsorted_idx(~isnan(unsorted_idx)));
	structData_sorted = [sort_group{:} structData(unsorted_idx)];

	% Delete duplicated entries in case loop-hole
	sorted_contents = {structData_sorted.(fieldName)};
	[unique_sc, ia, ic] = unique(sorted_contents, 'stable');
	structData_sorted = structData_sorted(ia);
end