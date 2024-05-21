function [varargout] = plot_TemporalRaster(plotWhere, TemporalData, varargin)
    % Create a temporal raster plot
    %
    % Can be used to plot:
    %   1. Calcium event timestamps in ROIs
    %   2. Calcium event timestamps aligned to stimulation
    %
    % Example: plot_TemporalRaster(plotWhere, TemporalData)
    % "plotWhere" specifies the axis where the plot will be created.
    % "TemporalData" contains the timestamps of events.
    % If "TemporalData" is an array of numbers, one row of raster will be plotted.
    % If "TemporalData" is a cell array, data in every cell will be plotted in a single row.

    % Define default values
    defaults.xtickInt = 10; % Interval of x ticks
    defaults.yInterval = 5; % Offset on y axis to separate data from various ROIs
    defaults.sz = 20; % Marker area
    defaults.rowNames = []; % Cell array containing strings used to label y_ticks
    defaults.x_window = []; % [a b] numerical array to set the limitation of x axis

    % Create an input parser object
    p = inputParser;

    % Define optional parameters and their default values
    addParameter(p, 'xtickInt', defaults.xtickInt);
    addParameter(p, 'yInterval', defaults.yInterval);
    addParameter(p, 'sz', defaults.sz);
    addParameter(p, 'rowNames', defaults.rowNames);
    addParameter(p, 'x_window', defaults.x_window);

    % Parse the input arguments
    parse(p, varargin{:});

    % Access the parsed results
    xtickInt = p.Results.xtickInt;
    yInterval = p.Results.yInterval;
    sz = p.Results.sz;
    rowNames = p.Results.rowNames;
    x_window = p.Results.x_window;

    % Main content
    % Find out how many rows of raster will be plotted
    if ~iscell(TemporalData)
        TemporalData = {TemporalData}; % Convert "TemporalData" to a cell if it is a numerical array
    end
    row_num = numel(TemporalData); % Total number of rows

    % Create rowNames if it does not exist or is empty
    if isempty(rowNames)
        rowNames = arrayfun(@num2str, 1:row_num, 'UniformOutput', false); % Create numerical array and convert to cell array of strings
    end

    % Create raster plot
    y_pos = zeros(1, row_num); % Variable for storing the position of row data on y axis
    TemporalData = cellfun(@(x) x(:), TemporalData, 'UniformOutput', false); % Ensure each cell contains vertical array
    axes(plotWhere)
    hold on
    for rn = 1:row_num
        y_pos(rn) = y_pos(rn) - rn * yInterval; % Adjust y value using yInterval
        x_raster = TemporalData{rn}; % Get raster value from TemporalData

        if ~isempty(x_raster)
            y_raster = y_pos(rn) * ones(size(x_raster)); % Create y values for all raster data
            scatter(x_raster, y_raster, sz, 'k|', 'filled', ...
                'MarkerEdgeColor', 'k', 'LineWidth', 1); % Plot one row of raster using data in a single cell of TemporalData
        end
    end

    % Adjust x limits
    if isempty(x_window)
        x_window = xlim; % Get the x-axis limits of the current axis
    else
        xlim(x_window)
    end


    % Adjust y limits
    ymax = y_pos(1); % Get the largest y value
    ymin = y_pos(end); % Get the smallest y value
    newYl = [ymin - abs(yInterval) / 2, ymax + abs(yInterval) / 2];
    ylim(newYl) % Adjust y-axis limits

    TemporalData_all = cell2mat(TemporalData(:)); % Convert all data in "TemporalData" to a vertical numerical array
    yticks(flip(y_pos));
    yticklabels(flip(rowNames));

    x_ticks = x_window(1):xtickInt:x_window(2);
    set(gca, 'TickDir', 'out'); % Set tick direction to 'out'. The only other option is 'in'
    xticks(x_ticks);
    xlabel('time (s)')

    varargout{1} = TemporalData_all;
end
