function [varargout] = plotCalciumTracesFromIDPScsv(varargin)
    % PLOT_CALCIUM_TRACES_FROM_CSV Plots calcium traces by reading the csv file
    % exported by the Inscopix Data Processing software (IDPS).
    %
    % Note: Y value of traces is (DF/D) %
    %
    % Usage:
    %   plotCalciumTracesFromCsv(showYtickRight, 'filePath', filePath)
    %   plotCalciumTracesFromCsv(showYtickRight)
    %
    % Inputs:
    %   showYtickRight - Boolean flag to show the ROI signal value on the right Y axis.
    %   Optional parameters (specified as name-value pairs):
    %     'filePath' - Full path to the CSV file to be loaded.

    % Create an inputParser object
    p = inputParser;

    % Add required and optional parameters
    addParameter(p, 'showYtickRight', true,@islogical);
    addParameter(p, 'AxesHandle', []);
    addParameter(p, 'filePath', '', @ischar);
    addParameter(p, 'folderPath', '', @ischar);
    addParameter(p, 'Title', 'ROI traces of rec exported from IDPS', @ischar);

    % Parse the input arguments
    parse(p, varargin{:});

    % Access the parsed results
    axesHandle = p.Results.AxesHandle;
    showYtickRight = p.Results.showYtickRight;
    filePath = p.Results.filePath;
    folderPath = p.Results.folderPath;
    Title = p.Results.Title;

    % Ensure the required function readInscopixTraceCsv is available
    if ~exist('readInscopixTraceCsv', 'file')
        error('The function readInscopixTraceCsv is not available in the path.');
    end

    % Read the CSV file
    if isempty(filePath)
        % Use the GUI to choose the file
        [file, path] = uigetfile(fullfile(folderPath,'*.csv'), 'Select the CSV file');
        if isequal(file, 0)
            disp('User canceled file selection.');
            return;
        end
        filePath = fullfile(path, file);
    end
    
    % Read the CSV file and convert it to a table variable
    [timeFluorTab, csvFolder, csvName] = readInscopixTraceCsv(filePath); % csvName does not contain the file extension

    shortRecName = extractDateTimeFromFileName(csvName); % Get he yyyyddmm-hhmmss from recording file name
    % plotTitle = ['ROI traces of rec-',shortRecName];
    roiNames = timeFluorTab.Properties.VariableNames; % Get the ROI names
    shortRoiNames = cellfun(@(x) x(5:end),roiNames,'UniformOutput',false); % Remove 'cell' from the roi names


    % Get the time data and trace data
    timeData = timeFluorTab{:, 1};
    traceData = timeFluorTab{:, 2:end};

    % Convert the deltaF/F to deltaF/F %
    traceData = traceData .* 100;

    % Display the image matrix in the specified axes or create a new figure
    if isempty(axesHandle)
        fig_canvas(1,'unit_width',0.5,'unit_height',0.5,'fig_name',Title);
        % figure;
        axesHandle = gca;
    end
    axes(axesHandle);

    % Plot the temporal data trace
    plot_TemporalData_Trace(axesHandle, timeData, traceData, ...
        'ylabels', shortRoiNames, 'showYtickRight', showYtickRight, 'titleStr', Title);

    % Display a message
    % disp('Calcium traces have been plotted successfully.');

    varargout{1} = Title;
    varargout{2} = csvFolder;
    varargout{3} = timeData;
    varargout{4} = traceData;
    varargout{5} = shortRoiNames;
end
