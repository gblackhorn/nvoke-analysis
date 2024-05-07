function [timeFluorTab,varargout] = readInscopixTraceCsv(varargin)
    % Read the csv file containing the recording time info and fluorescence info exported by the
    % Inscopix Data Processing software (IDPS), and convert the csv file to a table variable

    % csvFilePath: Full path of a csv file. If empty, the function will ask you to locate the file
    % using a GUI


    % Default
    locateFileWithGui = false; % If true, use GUI to locate the csvFilePath



    % Optionals
    % for ii = 1:2:(nargin-1)
    %     if strcmpi('plotWhere', varargin{ii})
    %         plotWhere = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
    %     elseif strcmpi('XTick', varargin{ii})
    %         XTick = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
    %     end
    % end 

    % Check if the csvFilePath var exists
    switch nargin
    case 0
        [file, fileFolder] = uigetfile('*.csv', 'Select a CSV file');
        csvFilePath = fullfile(fileFolder,file);
    otherwise
        csvFilePath = varargin{1};
    end

    % Check if the csvFilePath is a csv file
    csvFilePath = ensureCSVFile(csvFilePath);

    % Extract the folder path
    [fileFolder, fileNameStem, fileExt] = fileparts(csvFilePath);

    % Set the opt for reading the csv file
    opts = detectImportOptions(csvFilePath); % create import options based on file content
    opts.DataLine = 3; % set data line from the third row of csv file. First 2 rows are 'char'

    % Read the csv file
    timeFluorTab = readtable(csvFilePath, opts); % import file using modified opts, so data will be number arrays

    % Remove the rows containing NaN
    trimFrames = find(isnan(timeFluorTab{:, :}(:, 2))); % find frames trimmed off. Look for nan rows in 1st ROI (table from .csv file)
    timeFluorTab(trimFrames, :) = []; % delete trimmed frames

    % Rename columns
    timeColumnName = {'Time'};  % Name for the first column
    numCells = size(timeFluorTab, 2) - 1;  % Determine number of cells from columns
    cellColumnNames = arrayfun(@(i) sprintf('Cell%d', i), 1:numCells, 'UniformOutput', false);

    % Assign new names to the table
    timeFluorTab.Properties.VariableNames = [timeColumnName, cellColumnNames];

    % Assign some vars to varargouts
    varargout{1} = fileFolder;
    varargout{2} = fileNameStem;
end
