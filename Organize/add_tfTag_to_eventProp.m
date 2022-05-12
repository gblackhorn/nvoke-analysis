function [eventProp_new,varargout] = add_tfTag_to_eventProp(eventProp,fieldName,targetContent,varargin)
	% Return a new eventProp including a new tag field

	% eventProp: a structure containing event properties for a single ROI
	% fieldName: search if the specified field has certain content
	% targetContent: All events in eventProp will be marked as 'true' if field [fieldName] has targetContent

	% Defaults
	newFieldName = 'tag'; % default 2s. 

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('newFieldName', varargin{ii})
	        newFieldName = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('timeInfo', varargin{ii})
	       %  timeInfo = varargin{ii+1};
	    end
	end	

	%% Content
	eventProp_new = eventProp;
	fieldContent = {eventProp(:).(fieldName)};
	structSize = size(fieldContent);
	tf_content = strcmpi(targetContent, fieldContent);
	if ~isempty(find(tf_content))
		tagField = num2cell(logical(ones(structSize)));
	else
		tagField = num2cell(logical(zeros(structSize)));
	end

	if isfield(eventProp_new, newFieldName)
		error('Error in func [add_tfTag_to_eventProp]. \n - field %s exists. Use another one for newFieldName', newFieldName);
	else
		[eventProp_new.(newFieldName)] = tagField{:};
	end

	varargout{1} = newFieldName;
	varargout{2} = tagField{1};
end