function [varargout] = plot_TemporalData_Trace(plotWhere, xData, yData, varargin)
    % Create a plot for temporal related data

    % Can be used to plot: 
    %   1. Calcium fluorescence traces in ROIs
    %   2. Calcium fluorescence level aligned to stimulation 

    % Example: 
    % plot_TemporalData_Trace(plotWhere, xData, yData) "PlotWhere" is used to specify the axis where
    % the plot will be created. "xData" is the time information. "yData" is a matrix containing the
    % temporal related values. Each column of "yData" contains a single set of temporal related
    % data.

    % Define default values
    defaults.yData2 = [];
    defaults.plotInterval = 10;
    defaults.xtickInt = 10;
    defaults.showYtickRight = false;
    defaults.plot_marker = false;
    defaults.marker1_xData = {};
    defaults.marker2_xData = {};
    defaults.LineWidth = 1;
    defaults.line_color = '#616887';
    defaults.line_color2 = '#ADADAD';
    defaults.marker1Size = 40;
    defaults.marker2Size = 15;
    defaults.marker1_style = '.'; % Updated to dot
    defaults.marker2_style = '>';
    defaults.marker1_color = '#8D73BA';
    defaults.marker2_color = '#BA9973';
    defaults.shadeData = {};
    defaults.shadeColor = {'#F05BBD', '#4DBEEE', '#ED8564'};
    defaults.titleStr = '';
    defaults.ylabels = [];

    % Create an input parser object
    p = inputParser;

    % Define optional parameters and their default values
    addParameter(p, 'yData2', defaults.yData2);
    addParameter(p, 'plotInterval', defaults.plotInterval);
    addParameter(p, 'xtickInt', defaults.xtickInt);
    addParameter(p, 'showYtickRight', defaults.showYtickRight);
    addParameter(p, 'plot_marker', defaults.plot_marker);
    addParameter(p, 'marker1_xData', defaults.marker1_xData);
    addParameter(p, 'marker2_xData', defaults.marker2_xData);
    addParameter(p, 'LineWidth', defaults.LineWidth);
    addParameter(p, 'line_color', defaults.line_color);
    addParameter(p, 'line_color2', defaults.line_color2);
    addParameter(p, 'marker1Size', defaults.marker1Size);
    addParameter(p, 'marker2Size', defaults.marker2Size);
    addParameter(p, 'marker1_style', defaults.marker1_style);
    addParameter(p, 'marker2_style', defaults.marker2_style);
    addParameter(p, 'marker1_color', defaults.marker1_color);
    addParameter(p, 'marker2_color', defaults.marker2_color);
    addParameter(p, 'shadeData', defaults.shadeData);
    addParameter(p, 'shadeColor', defaults.shadeColor);
    addParameter(p, 'titleStr', defaults.titleStr);
    addParameter(p, 'ylabels', defaults.ylabels);

    % Parse the input arguments
    parse(p, varargin{:});

    % Access the parsed results
    yData2 = p.Results.yData2;
    plotInterval = p.Results.plotInterval;
    xtickInt = p.Results.xtickInt;
    showYtickRight = p.Results.showYtickRight;
    plot_marker = p.Results.plot_marker;
    marker1_xData = p.Results.marker1_xData;
    marker2_xData = p.Results.marker2_xData;
    LineWidth = p.Results.LineWidth;
    line_color = p.Results.line_color;
    line_color2 = p.Results.line_color2;
    marker1Size = p.Results.marker1Size;
    marker2Size = p.Results.marker2Size;
    marker1_style = p.Results.marker1_style;
    marker2_style = p.Results.marker2_style;
    marker1_color = p.Results.marker1_color;
    marker2_color = p.Results.marker2_color;
    shadeData = p.Results.shadeData;
    shadeColor = p.Results.shadeColor;
    titleStr = p.Results.titleStr;
    ylabels = p.Results.ylabels;

    if isempty(ylabels)
        ylabels = NumArray2StringCell(size(yData, 2));
    end

    if isempty(plotWhere)
        fig_canvas(1, 'unit_width', 0.9, 'unit_height', 0.9);
        plotWhere = gca;
    end

    trace_num = size(yData, 2); % number of traces = number of yData columns
    trace_length = size(yData, 1); % data point number of yData
    trace_y_tick = ylabels;

    % Adjust the y intervals to increase the readability and avoid overlapping
    offsets = zeros(1, trace_num);  % Initialize offsets for each trace
    yData_shift = yData;  % Initialize adjusted data matrix
    yData2_shift = yData2;  % Initialize adjusted data matrix

    for i = 1:trace_num  % Iterate through each trace
        if i > 1
            % Calculate the offset based on the previous trace's min and the current trace's max
            offsets(i) = offsets(i-1) - (max(yData(:,i)) - min(yData(:,i-1))) - abs(min(yData(:,i-1)) - max(yData(:,i)));
        end
        
        % Adjust the trace by the calculated offset
        yData_shift(:,i) = yData(:,i) + offsets(i);

        if ~isempty(yData2)
            yData2_shift(:,i) = yData2(:,i) + offsets(i);
        end
    end

    % Use offsets to calculate the plotInterval, which will be used to set the yLim and the raised
    % value of marker1 (event peak)
    if numel(offsets) == 1 % When there is only one ROI
        plotInterval = (max(yData) - min(yData))/2;
    else
        plotInterval = max(diff(offsets));
    end
    marker1_raiseVal = abs(plotInterval)/4;

    % Plot the data traces
    plot(xData, yData_shift, 'LineWidth', LineWidth, 'Color', line_color);
    hold on

    % Plot the data traces using yData2 if it is not empty
    if ~isempty(yData2)
        plot(xData, yData2_shift, 'LineWidth', LineWidth, 'Color', line_color2);
    end

    xlim([xData(1) xData(end)]); % set the x-axis limit to the beginning and the end of xData
    ymax = max(yData_shift(:,1)); % Get the largest y value
    ymin = min(yData_shift(:,end)); % Get the smallest y value
    newYl = [ymin-abs(plotInterval)/2 ymax+abs(plotInterval)/2];
    ylim(newYl) % add plotInterval to ymax and ymin and use them for ylim
    hold on

    if isempty(marker1_xData)
        marker1_xData = cell(1, trace_num);
    end
    if isempty(marker2_xData)
        marker2_xData = cell(1, trace_num); 
    end

    if plot_marker
        for tn = 1:trace_num
            marker1_xData_trace = marker1_xData{tn};
            [~,~,marker1_xData_idx] = intersect(marker1_xData_trace, xData); % Get the locations of the time points in xData
            marker1_yData_trace = yData_shift(marker1_xData_idx, tn); % y values of trace at the marker1_xData
            scatter(marker1_xData_trace, marker1_yData_trace + marker1_raiseVal, marker1Size, marker1_style, ...
                'MarkerEdgeColor', marker1_color, 'MarkerFaceColor', marker1_color, 'LineWidth', 1); % Adjusted to dot above the peak

            marker2_xData_trace = marker2_xData{tn};
            [~,~,marker2_xData_idx] = intersect(marker2_xData_trace, xData); % Get the locations of the time points in xData
            marker2_yData_trace = yData_shift(marker2_xData_idx, tn); % y values of trace at the marker2_xData
            scatter(marker2_xData_trace, marker2_yData_trace, marker2Size, marker2_style, ...
                'MarkerEdgeColor', marker2_color, 'LineWidth', 1);
        end
    end

    set(gca, 'box', 'off')
    set(gca, 'TickDir', 'out'); % Make tick direction to be out. The only other option is 'in'
    yticks(flip(offsets));
    yticklabels(flip(trace_y_tick));
    set(gca, 'Xtick', [xData(1):xtickInt:xData(end)]);

    % Display the value of y on the right side of the axis
    if showYtickRight
        yyaxis right
        ylim(newYl)
        ylabel('y-value')
    end

    if ~isempty(shadeData)
        shade_type_num = numel(shadeData);
        for stn = 1:shade_type_num
            draw_WindowShade(plotWhere, shadeData{stn}, 'shadeColor', shadeColor{stn});
        end
    end

    set(gca, 'children', flipud(get(gca, 'children')))

    title(titleStr);
    xlabel('Time (s)');
    hold off
end

function strCell = NumArray2StringCell(numArray)
    % Helper function to convert a numeric array to a cell array of strings
    strCell = arrayfun(@num2str, numArray, 'UniformOutput', false);
end
