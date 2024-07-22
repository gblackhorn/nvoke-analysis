function foundRecord = getRecordByID(evenDataStructure, recordID)
    % returns a single record from the evenDataStructure that matches the recordID
    % evenDataStructure is a structure with cell arrays
    % recordID is the ID of the record to return

    foundRecord = [];

    % check if the input is a structure
    if ~isstruct(evenDataStructure)
        warning('Input must be a structure');
        return;
    end

    % check if the recordID is a string, char array or array of strings
    if ~ischar(recordID) && ~isstring(recordID) && ~iscellstr(recordID)
        warning('Record ID must be a string, char array or cell array of strings');
        return;
    end

    if ischar(recordID)
        recordID = {recordID};
    end
    

    % how many records are we looking for?
    numRecords = numel(recordID);


    % check if the structure has the field 'trialName'
    if ~isfield(evenDataStructure, 'trialName')
        error('Input structure must have the field ''trialName''');
    end

% find all records that match the recordIDs
    index = [];
    for i = 1:numRecords
        dateTimeStr = extractDateTime(evenDataStructure.trialName)
        % find the index of the record with the given ID
        index = [index; find(strcmp(recordID{i}, dateTimeStr))];
    end


    % check if a matching record was found
    if isempty(index)
        error('No record found with the given ID');
    end

    % if we found more than one record, return the first one with a warning
    if numel(index) > 1
        warning('Multiple records found with the given ID, returning the first one');
    end
    % get the single record
    foundRecord = evenDataStructure(index(1));
end

function dateTimeStr = extractDateTime(inputStr)
    % Ensure the input is a character array (string)
    inputStr = char(inputStr);
    
    % Find the index of the first underscore
    underscoreIndex = find(inputStr == '_', 1);
    
    % Extract the date-time string up to the first underscore
    if ~isempty(underscoreIndex)
        dateTimeStr = inputStr(1:underscoreIndex-1);
    else
        error('No underscore found in the input string.');
    end
end