function eventStructNew = mergeGroupedEventData(eventStruct, group1, group2, varargin)
    % Merge two groups of events in eventStruct

    % Use the name and tag of group1 for the merged group by default 
    % Use the 'peak_category' of group1 events for group2 events

    % Merge the n numbers and TrialRoiList as well
    % Watch out: 

    % eventStruct: Output by the function 'getAndGroup_eventsProp'   

    % Input parser
    p = inputParser;

    % Required input
    addRequired(p, 'eventStruct', @isstruct);
    addRequired(p, 'group1', @ischar); 
    addRequired(p, 'group2', @ischar); 

    % Optional inputs
    addParameter(p, 'newPeakCat', '', @ischar);  % Option to save the LaTeX text to a file
    addParameter(p, 'newGroupName', '', @ischar);  % Option to save the LaTeX text to a file
    addParameter(p, 'newTag', '', @ischar);  % Filename for the output .tex file

    % Parse inputs
    parse(p, eventStruct, group1, group2, varargin{:});
    
    % Assign parsed values to variables
    eventStruct = p.Results.eventStruct;
    group1 = p.Results.group1;
    group2 = p.Results.group2;
    newPeakCat = p.Results.newPeakCat;
    newGroupName = p.Results.newGroupName;
    newTag = p.Results.newTag;

    % Locate the group1 and group2
    groupNames = {eventStruct.group};
    group1IDX = find(strcmpi(groupNames, group1));
    group2IDX = find(strcmpi(groupNames, group2));

    % Get the 'peak_category' of group1 events
    if isempty(newPeakCat)
        newPeakCat = unique({eventStruct(group1IDX).event_info.peak_category});
        if numel(newPeakCat) > 1
            error('Only 1 kind of peak category is allowed')
        else
            newPeakCat = newPeakCat{1};
        end
    else
        % Modify the 'peak_category' of the group1 events
        [eventStruct(group1IDX).event_info.peak_category] = deal(newPeakCat);
    end

    % Modify the 'peak_category' of group2 events
    [eventStruct(group2IDX).event_info.peak_category] = deal(newPeakCat);

    % Update the group name
    if ~isempty(newGroupName)
        eventStruct(group1IDX).group = newGroupName;
    end

    % Change the group tag
    if ~isempty(newTag)
        eventStruct(group1IDX).tag = newTag;
    end

    % Add the events in group2 to group1
    eventStruct(group1IDX).event_info = [eventStruct(group1IDX).event_info, eventStruct(group2IDX).event_info];

    % Update the n number and recording list
    [TrialRoiList,recNum,animalNum,roiNum] = get_roiNum_from_eventProp(eventStruct(group1IDX).event_info);
    eventStruct(group1IDX).recNum = recNum;
    eventStruct(group1IDX).animalNum = animalNum;
    eventStruct(group1IDX).roiNum = roiNum;
    eventStruct(group1IDX).TrialRoiList = TrialRoiList;


    % Delete the group2
    eventStruct(group2IDX) = [];
    eventStructNew = eventStruct;
end