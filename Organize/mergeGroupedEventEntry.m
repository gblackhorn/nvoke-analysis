function [newGroupedEvent,varargout] = mergeGroupedEventEntry(groupedEvent,tagsForMerge,varargin)
	% Merger entries in groupedEvent (struct var)

	% groupedEvent: output of function 'getAndGroup_eventsProp'
	% tagsForMerge: cell var containing the tags in groupedEvent.tag

	% Defaults
	NewGroupName = 'newGroup';
	NewtagName = strjoin(tagsForMerge,' & ');
	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('NewGroupName', varargin{ii})
	        NewGroupName = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('NewtagName', varargin{ii})
	        NewtagName = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('debugMode', varargin{ii})
	        debugMode = varargin{ii+1}; 
	    end
	end

	% number of tags in tagsForMerge. Create a cell var to store the 
	tagsNum = numel(tagsForMerge);
	tagsIDX = cell(1,tagsNum);

	groupedEventFieldNames = fieldnames(groupedEvent);
	newEntry = empty_content_struct(groupedEventFieldNames,1);
	groupedEventTags = {groupedEvent.tag};

	% get the IDX of to be merged entries from groupedEvent
	for n = 1:tagsNum
		entryTagIDX = find(cellfun(@(x) strcmpi(tagsForMerge{n},x),groupedEventTags));
		tagsIDX{n} = reshape(entryTagIDX,1,[]);
	end
	tagsIDXall = horzcat(tagsIDX{:});

	% Create a new entry using the data from groupedEvent
	newEntry.group = NewGroupName;
	newEntry.tag = NewtagName;
	newEntry.event_info = horzcat(groupedEvent(tagsIDXall).event_info);
	newEntry.TrialRoiList = horzcat(groupedEvent(tagsIDXall).TrialRoiList);

	[~,recNum,recDateNum,roiNum] = get_roiNum_from_eventProp(newEntry.event_info);
	newEntry.numTrial = recNum;
	newEntry.animalNum = recDateNum;
	newEntry.numRoi = roiNum;

	groupedEvent(tagsIDXall) = [];
	newGroupedEvent = horzcat(groupedEvent,newEntry);
end
