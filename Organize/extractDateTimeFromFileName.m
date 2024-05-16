function dateTimePart = extractDateTimeFromFileName(fileNameString)
    % EXTRACTDATETIME Extracts and formats the date and time part from a given title string.

    %   dateTimePart = extractDateTimeFromFileName(titleString) extracts and formats the date
    %   and time part from the input title string. The function handles two formats:
    %   1. 'YYYYMMDD-HHMMSS_description'
    %   2. 'YYYY-MM-DD-HH-MM-SS_description' and converts it to 'YYYYMMDD-HHMMSS'.
    
    % Find the position of the first underscore
    underscorePos = strfind(fileNameString, '_');
    
    if isempty(underscorePos)
        error('Unexpected title format. The title must contain an underscore.');
    end
    
    % Extract the date and time part
    dateTimePart = fileNameString(1:underscorePos(1)-1);
    
    % Check if the dateTimePart contains hyphens
    if contains(dateTimePart, '-')
        % Remove the hyphens from the date part and from the time part
        parts = strsplit(dateTimePart, '-');
        if numel(parts) == 6
            dateTimePart = [parts{1}, parts{2}, parts{3}, '-', parts{4}, parts{5}, parts{6}];
        elseif numel(parts) == 2
            dateTimePart = fileNameString(1:underscorePos(1)-1);
        else
            error('Unexpected date format. The date and time should be in the format "YYYY-MM-DD-HH-MM-SS".');
        end
    end
end
