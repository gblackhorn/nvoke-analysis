function filePairs = findAllTexFilePairs(folderPath, varargin)
    % This function finds all .tex files with the specified inputContentTag (default: 'meanSemTab')
    % and pairs them with corresponding outputContentTag files (default: 'nNumInfo').

    % Define propertyTags
    propertyTags = {'FWHM', 'rise_duration', 'peak_delta_norm_hpstd', 'cv2', 'sponInterval', 'sponfq', 'peak_delay'};
    
    % Default contentTags
    inputContentTag = 'meanSemTab';
    outputContentTag = 'nNumInfo';
    
    % Parse varargin for input and output content tags
    if nargin >= 2
        inputContentTag = varargin{1};  % User-specified inputContentTag
    end
    if nargin >= 3
        outputContentTag = varargin{2};  % User-specified outputContentTag
    end
    
    % Get all .tex files in the folder
    texFiles = dir(fullfile(folderPath, '*.tex'));
    texFileNames = {texFiles.name};  % Create a cell array of file names
    
    % Use cellfun to find files containing the inputContentTag
    containsInputTag = cellfun(@(x) contains(x, inputContentTag), texFileNames);
    inputFileIndices = find(containsInputTag);  % Get indices of files containing the inputContentTag
    numInputFiles = numel(inputFileIndices);  % Number of input files
    
    % Pre-allocate the structure for file pairs
    filePairs(numInputFiles).inputFile = '';
    filePairs(numInputFiles).outputFile = '';
    filePairs(numInputFiles).combinedFilename = '';  % New field for combined filename
    
    % Initialize a counter for filling the struct
    pairIndex = 1;
    
    % Loop through each input file and find corresponding outputContentTag file
    for i = 1:numInputFiles
        currentFile = texFileNames{inputFileIndices(i)};
        currentNameWithoutExt = removeTexExtension(currentFile);  % Remove the extension
        currentNameParts = strsplit(currentNameWithoutExt, ' ');

        % Get the core file name by removing contentTags and propertyTags
        coreNameParts = currentNameParts(~ismember(currentNameParts, {inputContentTag, outputContentTag, propertyTags{:}}));
        coreFileName = strjoin(coreNameParts, ' ');
        
        % Add the inputContentTag file to the structure
        inputFile = fullfile(folderPath, currentFile);
        filePairs(pairIndex).inputFile = inputFile;
        
        % Now look for the corresponding outputContentTag file
        matchedFile = findMatchingContentFile(texFiles, coreFileName, propertyTags, outputContentTag);
        
        if isempty(matchedFile)
            warning('No matching %s file found for: %s', outputContentTag, inputFile);
            filePairs(pairIndex).outputFile = '';  % Add empty if no match found
        else
            filePairs(pairIndex).outputFile = matchedFile;
        end
        
        % Create the combined filename by appending the outputContentTag to the inputFile
        combinedFilename = fullfile(folderPath, [currentNameWithoutExt ' ' outputContentTag '.tex']);
        filePairs(pairIndex).combinedFilename = combinedFilename;  % Save combined filename
        
        % Increment the pair index
        pairIndex = pairIndex + 1;
    end
end

function matchedFile = findMatchingContentFile(texFiles, coreFileName, propertyTags, outputContentTag)
    % This function searches for the corresponding outputContentTag file based on the core file name.
    
    % Initialize matchedFile as empty
    matchedFile = '';
    
    % Loop through all files to find one with outputContentTag in its name
    for i = 1:length(texFiles)
        currentFile = texFiles(i).name;
        currentNameWithoutExt = removeTexExtension(currentFile);  % Manually remove the extension
        currentNameParts = strsplit(currentNameWithoutExt, ' ');
        
        % Check if the file contains the outputContentTag and does NOT contain any propertyTags
        if ismember(outputContentTag, currentNameParts) && ~any(ismember(currentNameParts, propertyTags))
            currentCoreParts = currentNameParts(~ismember(currentNameParts, {outputContentTag}));
            currentCoreName = strjoin(currentCoreParts, ' ');
            
            % If the core names match, return the matched file
            if strcmp(currentCoreName, coreFileName)
                matchedFile = fullfile(texFiles(i).folder, currentFile);
                return;
            end
        end
    end
end

function nameWithoutExt = removeTexExtension(fileName)
    % Remove the .tex extension from a filename
    [~, nameWithoutExt] = fileparts(fileName);  % This works on just filenames too
end
