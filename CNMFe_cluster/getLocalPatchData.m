function patchDataPath = getLocalPatchData(folderPath)
    % Read the CNMFe patch data in the subfoler
    % Original CNMFe code locate the patch data using obj.P.mat_file, which contains the path when CNMFe processing took place. 
    % This is an alternative function of 'load_patch_data' in Sources2D
    % It finds the patch data in the subfolder of the recording folder

    % Step 1: Find the folder that ends with "source_extraction"
    filesAndDirs = dir(folderPath);

    % Filter only directories and exclude '.' and '..'
    dirsOnly = filesAndDirs([filesAndDirs.isdir]);
    dirNames = {dirsOnly.name};

    % Exclude '.' and '..'
    validDirs = ~ismember(dirNames, {'.', '..'});

    % Apply this filter to dirNames and dirsOnly
    dirNames = dirNames(validDirs);
    dirsOnly = dirsOnly(validDirs);

    % Find the directories that end with "source_extraction"
    matches = endsWith(dirNames, 'source_extraction');

    % Get the matched directory paths
    matchedDirs = fullfile({dirsOnly(matches).folder}, {dirsOnly(matches).name});

    % Check how many matches were found
    if isempty(matchedDirs)
        error('No folder ending with "source_extraction" was found.');
    else
        % Use the unique matching folder
        sourceExtractionFolder = matchedDirs{1};
    end

    % Step 2: In this subfolder, look for '.mat' files starting with 'data'
    matFiles = dir(fullfile(sourceExtractionFolder, 'data*.mat'));

    % Check how many .mat files were found
    if isempty(matFiles)
        error('No .mat file starting with "data" was found in the folder: %s', sourceExtractionFolder);
    elseif length(matFiles) > 1
        warning('Multiple .mat files starting with "data" were found. Returning the first one.');
        selectedMatFile = matFiles(1).name;  % Return the first file
    else
        selectedMatFile = matFiles(1).name;  % Return the only matching file
    end

    % Full path to the selected .mat file
    patchDataPath = fullfile(sourceExtractionFolder, selectedMatFile);
end