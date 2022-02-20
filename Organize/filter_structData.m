function [structData_filtered,varargout] = filter_structData(structData,fieldName,value,DOA,varargin)
	% Discard entries in a structure based on the values of specified field

	% structData: structure
	% fieldName: Name of the field used to filterdata
	% value: value in the specified field
	% DOA: dead or alive. 0: discard entries if "value" is found. 1: keep entries if "value" is found. Do nothing if it's empty

	% Defaults
	val_relation = 'equal'; % equal/larger/smaller. only valie when value is 'numeric'. larger and smaller includ the specific val

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('val_relation', varargin{ii})
	        val_relation = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('timeInfo', varargin{ii})
	       %  timeInfo = varargin{ii+1};
	    end
	end	

	%% Content
	structData_filtered = structData;
	if isa(value, 'numeric') || isa(value, 'logical')
		fieldContent = [structData_filtered(:).(fieldName)];
		if isa(value, 'numeric')
			switch val_relation
				case 'equal'
					idx = find(fieldContent==value);
				case 'larger'
					idx = find(fieldContent>=value);
				case 'smaller'
					idx = find(fieldContent<=value);
				otherwise
			end
		else
			idx = find(fieldContent==value);
		end
	elseif isa(value, 'char')
		fieldContent = {structData_filtered(:).(fieldName)};
		tf_array = strcmpi(value, fieldContent);
		idx = find(tf_array);
	end

	if DOA == 0
		structData_filtered(idx) = [];
	elseif DOA == 1
		structData_filtered = structData_filtered(idx);
	elseif isempty(DOA)
	end

	varargout{1} = idx;
end