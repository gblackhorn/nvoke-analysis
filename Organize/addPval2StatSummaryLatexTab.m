function addPval2StatSummaryLatexTab(folderPath, file1Keyword, file2Keyword, varargin)
    % addPval2StatSummaryLatexTab Updates the meanSemTab nNumInfo table with pValue and hValue columns
    % using information from the corresponding modelCompTab.
    %
    % This function finds pairs of LaTeX tables based on the specified keywords,
    % extracts relevant data, and updates the meanSemTab nNumInfo table with
    % statistical information from the modelCompTab table.
    %
    % Inputs:
    %   folderPath - The path to the folder containing the LaTeX files.
    %   file1Keyword - The keyword to identify the meanSemTab nNumInfo files.
    %   file2Keyword - The keyword to identify the modelCompTab files.
    %   optionalKeyword - An optional keyword that both files must contain.
    %   varargin - Optional suffix to add to the updated file name.

    % Example:
    %   folderPath = 'D:\guoda\Documents\Workspace\Analysis\nVoke_ventral_approach\VIIO_paper_figure\VIIO_eventProp\test';
    %   file1Keyword = 'meanSemTab nNumInfo';
    %   file2Keyword = 'modelCompTab';
    %   addPval2StatSummaryLatexTab(FolderPathVA.fig, file1Keyword, file2Keyword,...
    %       'optionalKeyword', propName, 'suffix', fileSuffix);

    % Create an input parser object
    p = inputParser;

    % Add required arguments
    addRequired(p, 'folderPath', @ischar);
    addRequired(p, 'file1Keyword', @ischar);
    addRequired(p, 'file2Keyword', @ischar);

    % Add optional suffix argument with a default value of empty string
    addParameter(p, 'optionalKeyword', '', @ischar);
    addParameter(p, 'suffix', '', @ischar);

    % Parse the inputs
    parse(p, folderPath, file1Keyword, file2Keyword, varargin{:});
    
    % Extract parsed input values
    optionalKeyword = p.Results.optionalKeyword;
    suffix = p.Results.suffix;

    % Find pairs of relevant files
    pairedFiles = findFilePairs(folderPath, file1Keyword, file2Keyword, 'optionalKeyword', optionalKeyword);
    
    % Loop through each pair and update the meanSemTab nNumInfo table
    for i = 1:length(pairedFiles)
        meanSemTabFile = pairedFiles{i}{1};
        modelCompTabFile = pairedFiles{i}{2};
        
        % Read the content of each file
        meanSemContent = fileread(fullfile(folderPath, meanSemTabFile));
        modelCompContent = fileread(fullfile(folderPath, modelCompTabFile));
        
        % Extract table contents from both files
        [header, tabRows, preTabContent, postTabContent] = extractLatexTabContent(meanSemContent);
        [modelHeader, modelRows, ~, ~] = extractLatexTabContent(modelCompContent);
        
        % Check if the header already contains pValue and hValue
        if contains(header, 'pValue') && contains(header, 'hValue')
            % Inform the user and skip updating
            fprintf('File %s already contains pValue and hValue columns. No update is performed.\n', meanSemTabFile);
            continue; % Skip to the next file
        end
        
        % Split the header to find the position of 'pValue'
        modelHeaderCells = strsplit(modelHeader, '&');
        pValueIndex = find(contains(modelHeaderCells, 'pValue'), 1); % Locate the pValue column index
        
        % Initialize pValue and hValue with default values
        pValue = 'n.s.';
        hValue = 0;
        
        % Check if pValueIndex exists and extract pValue from the fullModel row
        if ~isempty(pValueIndex)
            % Find the fullModel row and remove the trailing \\ before splitting
            fullModelRow = modelRows{contains(modelRows, '\texttt{fullModel}')};
            fullModelRow = strrep(fullModelRow, '\\', ''); % Remove trailing \\
            fullModelCells = strsplit(fullModelRow, '&');  % Split fullModel row into columns
            
            if length(fullModelCells) >= pValueIndex
                pValue = strtrim(fullModelCells{pValueIndex}); % Extract and trim pValue
                % Check if pValue is numeric and update hValue based on its value
                numericPValue = str2double(pValue);
                if ~isnan(numericPValue) && numericPValue < 0.05
                    hValue = 1;
                end
            end
        end
        
        % Fix the header to include pValue and hValue columns correctly
        headerCells = strsplit(header, '&');
        header = strjoin(strtrim(headerCells), ' & '); % Reconstruct header without extra spaces
        header = strrep(header, '\\', ''); % Remove any trailing '\\'
        header = [header, ' & pValue & hValue \\']; % Append new headers
        
        % Calculate the number of columns needed based on the new header
        numColumns = length(strsplit(header, '&'));
        
        % Update the tabularx line (add two 'X' columns for pValue and hValue)
        tabularxLine = ['\begin{tabularx}{\linewidth}{', repmat('|X', 1, numColumns), '|}'];

        % Initialize new table content
        newTableContent = {tabularxLine};  % Add the updated \begin{tabularx}
        newTableContent{end+1} = '\hline';  % Add \hline before the header
        newTableContent{end+1} = header;
        newTableContent{end+1} = '\hline';  % Add \hline after the header
        
        % Process each row and ensure proper formatting
        for j = 1:length(tabRows)
            % Remove trailing \\ from each row for consistent formatting
            row = strrep(strtrim(tabRows{j}), '\\', '');
            rowCells = strsplit(row, '&');
            
            % Calculate how many columns are missing
            numMissingCols = numColumns - length(rowCells);
            
            if j == length(tabRows)
                % For the last row, directly add pValue and hValue, no extra &
                row = sprintf('%s & %s & %d', row, pValue, hValue);
            else
                % For non-last rows, append the necessary number of '&'
                if numMissingCols > 0
                    rowCells = [rowCells, repmat({' '}, 1, numMissingCols)];
                end
                row = strjoin(rowCells, ' & ');
            end
            
            % Append the formatted row with trailing \\
            newTableContent{end+1} = [row, ' \\'];
        end

        % Add final \hline after the last row
        newTableContent{end+1} = '\hline';
        
        % Add the final \end{tabularx}
        newTableContent{end+1} = '\end{tabularx}';
        
        % Generate the updated file name with optional suffix
        [~, name, ext] = fileparts(meanSemTabFile);
        updatedFileName = fullfile(folderPath, [name suffix ext]);

        % Write the modified content back to the file
        fid = fopen(updatedFileName, 'w');
        % Write pre-table content
        fprintf(fid, '%s\n', preTabContent);
        % Write the tabularx environment and new table content
        fprintf(fid, '%s\n', newTableContent{:});
        % Write post-table content
        fprintf(fid, '%s\n', postTabContent);
        fclose(fid);        
        % Display the update status
        fprintf('Updated file saved as: %s\n', updatedFileName);
    end
end
