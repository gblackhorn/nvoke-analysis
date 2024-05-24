function [varargout] = plot_TemporalRaster(TemporalData, varargin)
    % Create a temporal raster plot
    %
    % Can be used to plot:
    %   1. Calcium event timestamps in ROIs
    %   2. Calcium event timestamps aligned to stimulation
    %
    % Example: plot_TemporalRaster(TemporalData, 'colorData', colorData)
    % "TemporalData" contains the timestamps of events.
    % If "TemporalData" is an array of numbers, one row of raster will be plotted.
    % If "TemporalData" is a cell array, data in every cell will be plotted in a single row.
    % "colorData" is an optional cell array of the same size as "TemporalData" for specifying colors of scatter points.
    % "plotWhere" is an optional axis handle where the plot will be created. If not provided, a new figure will be created.

    % Define default values for optional parameters
    defaults.colorData = [];       % Cell array for specifying colors of scatter points
    defaults.norm2roi = false;    % true: Normalize the color range in every ROI. false: normalize to all the peaks in all ROIs
    defaults.colorMapType = 'jet';% Type of color map
    defaults.plotWhere = [];      % Axis handle for plotting
    defaults.xtickInt = 10;       % Interval of x ticks
    defaults.yInterval = 5;       % Offset on y axis to separate data from various ROIs
    defaults.sz = 40;             % Marker area (size of scatter points)
    defaults.rowNames = [];       % Cell array containing strings used to label y_ticks
    defaults.x_window = [];       % [a b] numerical array to set the limitation of x axis

    % Create an input parser object
    p = inputParser;

    % Define optional parameters and their default values
    addParameter(p, 'colorData', defaults.colorData);
    addParameter(p, 'norm2roi', defaults.norm2roi);
    addParameter(p, 'colorMapType', defaults.colorMapType);
    addParameter(p, 'plotWhere', defaults.plotWhere);
    addParameter(p, 'xtickInt', defaults.xtickInt);
    addParameter(p, 'yInterval', defaults.yInterval);
    addParameter(p, 'sz', defaults.sz);
    addParameter(p, 'rowNames', defaults.rowNames);
    addParameter(p, 'x_window', defaults.x_window);

    % Parse the input arguments
    parse(p, varargin{:});

    % Access the parsed results
    colorData = p.Results.colorData;
    norm2roi = p.Results.norm2roi;
    colorMapType = p.Results.colorMapType;
    plotWhere = p.Results.plotWhere;
    xtickInt = p.Results.xtickInt;
    yInterval = p.Results.yInterval;
    sz = p.Results.sz;
    rowNames = p.Results.rowNames;
    x_window = p.Results.x_window;

    % Validate colorData if provided
    if ~isempty(colorData)
        if ~iscell(colorData) || numel(colorData) ~= numel(TemporalData)
            error('colorData must be a cell array with the same size as TemporalData');
        else
            colorful = true;
            if ~norm2roi
                % Concatenate the colorData and find the min and max for rescaling the colorData
                colorData = cellfun(@ensureHorizontal,colorData,'UniformOutput',false);
                colorDataAll = horzcat(colorData{:});
                colorValMin = min(colorDataAll);
                colorValMax = max(colorDataAll);
            end
        end
    else
        colorful = false; 
    end

    % Find out how many rows of raster will be plotted
    if ~iscell(TemporalData)
        TemporalData = {TemporalData}; % Convert "TemporalData" to a cell if it is a numerical array
    end
    row_num = numel(TemporalData); % Total number of rows

    % Create rowNames if it does not exist or is empty
    if isempty(rowNames)
        rowNames = arrayfun(@num2str, 1:row_num, 'UniformOutput', false); % Create numerical array and convert to cell array of strings
    end

    % Create a new figure if plotWhere is not provided
    if isempty(plotWhere)
        figure;
        plotWhere = gca;
    end

    % Create raster plot
    y_pos = zeros(1, row_num); % Variable for storing the position of row data on y axis
    TemporalData = cellfun(@(x) x(:), TemporalData, 'UniformOutput', false); % Ensure each cell contains vertical array
    axes(plotWhere) % Set the specified axis for plotting
    hold on

    for rn = 1:row_num
        y_pos(rn) = y_pos(rn) - rn * yInterval; % Adjust y value using yInterval
        xRaster = TemporalData{rn}; % Get raster value from TemporalData

        if ~isempty(xRaster)
            yRaster = y_pos(rn) * ones(size(xRaster)); % Create y values for all raster data
            if isempty(colorData)
                scatter(xRaster, yRaster, sz, 'k|', 'filled', ...
                    'MarkerEdgeColor', 'k', 'LineWidth', 1); % Plot one row of raster using data in a single cell of TemporalData
            else
                % Use provided colorData to determine the colors
                colorRaster = colorData{rn}; % Get color data for the current row

                % rescale the colorRaster 
                if norm2roi
                    colorValMin = min(colorRaster);
                    colorValMax = max(colorRaster);
                end
                colorRaster = normalizeArrayWithLimits(colorRaster,colorValMin,colorValMax);


                scatter(xRaster, yRaster, sz, colorRaster,"square",'filled', ...
                    'LineWidth', 1); % Plot with specified colors
            end
        end
    end

    if colorful
        colormap(gca,colorMapType);
        clim([0 1])
        cbar = colorbar('eastoutside')
        set(cbar, 'TickDirection', 'out');
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
    yticks(flip(y_pos)); % Set y ticks based on the positions of the rows
    yticklabels(flip(rowNames)); % Label y ticks with row names

    x_ticks = x_window(1):xtickInt:x_window(2); % Set x ticks based on x_window and xtickInt
    set(gca, 'TickDir', 'out'); % Set tick direction to 'out'. The only other option is 'in'
    xticks(x_ticks); % Apply x ticks to the axis
    xlabel('time (s)') % Label the x axis

    varargout{1} = TemporalData_all; % Return the combined TemporalData as output
end
