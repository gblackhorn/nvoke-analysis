function [barInfo, varargout] = barPlotOfStructData(structData, valField, groupField, varargin)
    % barPlotOfStructData Creates a bar plot from structured data.
    %
    % This function generates a bar plot using data from a structure array.
    % The field specified by `valField` contains the data to be plotted,
    % and the field specified by `groupField` contains the tags used to group
    % the data in `valField`. Additional optional parameters can be provided
    % to customize the plot.
    %
    % Syntax:
    % [barInfo, varargout] = barPlotOfStructData(structData, valField, groupField, 'ParameterName', ParameterValue, ...)
    %
    % Inputs:
    %   structData - Structure array containing the data.
    %   valField   - String specifying the field name containing the values to be plotted.
    %   groupField - String specifying the field name containing the grouping tags.
    %
    % Optional Name-Value Pair Arguments:
    %   'TickAngle'   - Angle of the x-axis tick labels (default: 0).
    %   'EdgeColor'   - Color of the edges of the bars (default: 'none').
    %   'FaceColor'   - Color of the faces of the bars (default: '#4D4D4D').
    %   'FontSize'    - Font size of the x-axis tick labels (default: 14).
    %   'FontWeight'  - Font weight of the x-axis tick labels (default: 'bold').
    %
    % Outputs:
    %   barInfo - Bar object containing information about the created bar plot.
    %   varargout - Additional outputs as needed.
    %
    % Example:
    %   structData(1).value = 10;
    %   structData(1).group = 'A';
    %   structData(2).value = 15;
    %   structData(2).group = 'B';
    %   structData(3).value = 20;
    %   structData(3).group = 'A';
    %   structData(4).value = 25;
    %   structData(4).group = 'B';
    %   [barInfo] = barPlotOfStructData(structData, 'value', 'group', 'TickAngle', 45, 'FaceColor', '#FF5733');
    %

    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'structData', @isstruct);
    addRequired(p, 'valField', @ischar);
    addRequired(p, 'groupField', @ischar);

    % Define default values for optional parameters
    defaultPlotWhere = [];
    defaultTitleStr = 'Bar plot';
    defaultTickAngle = 0;
    defaultEdgeColor = 'none';
    defaultFaceColor = '#4D4D4D';
    defaultFontSize = 14;
    defaultFontWeight = 'bold';

    % Add optional parameters to the parser
    addParameter(p, 'plotWhere', defaultPlotWhere);
    addParameter(p, 'titleStr', defaultTitleStr);
    addParameter(p, 'TickAngle', defaultTickAngle);
    addParameter(p, 'EdgeColor', defaultEdgeColor);
    addParameter(p, 'FaceColor', defaultFaceColor);
    addParameter(p, 'FontSize', defaultFontSize);
    addParameter(p, 'FontWeight', defaultFontWeight);

    % Parse the inputs
    parse(p, structData, valField, groupField, varargin{:});

    % Assign parsed values to variables
    structData = p.Results.structData;
    valField = p.Results.valField;
    groupField = p.Results.groupField;
    plotWhere = p.Results.plotWhere;
    dtitleStr = p.Results.TickAngle;
    TickAngle = p.Results.TickAngle;
    EdgeColor = p.Results.EdgeColor;
    FaceColor = p.Results.FaceColor;
    FontSize = p.Results.FontSize;
    FontWeight = p.Results.FontWeight;

    % Extract the values and group data from structData
    valData = [structData.(valField)];
    groupData = {structData.(groupField)};

    % Get unique groups and their indices
    [uniqueGroups, ~, groupIdx] = unique(groupData);
    nGroups = numel(uniqueGroups);

    % Creat barInfo.data and calculate mean, std, and ste for plotting
    barInfoDataFields = {'group', 'groupData', 'meanVal', 'stdVal', 'seVal', 'nNum'};
    barInfo.data = empty_content_struct(barInfoDataFields,nGroups);

    % % Calculate means and standard deviations for each group
    % nGroups = numel(uniqueGroups);
    % means = zeros(1, nGroups);
    % stds = zeros(1, nGroups);
    % ses = zeros(1, nGroups);

    for i = 1:nGroups
    	barInfo.data(i).group = uniqueGroups(i); 
    	barInfo.data(i).groupData = valData(groupIdx == i); 
    	barInfo.data(i).meanVal = mean(groupVals, "omitnan"); 
    	barInfo.data(i).stdVal = std(groupVals, "omitnan");
    	barInfo.data(i).seVal = ste(groupVals, 'omitnan', true);
    	barInfo.data(i).nNum = sum(~isnan(barInfo.data(i).groupData));
    	% barInfo.data(i).nNum = numel(barInfo.data(i).groupData);
        % groupVals = valData(groupIdx == i);
        % means(i) = mean(groupVals, "omitnan");
        % stds(i) = std(groupVals, "omitnan");
        % ses(i) = ste(groupVals, 'omitnan', true);
    end

    % Create bar plot
    if isempty(plotWhere)
        f = figure;
        plotWhere = gca;
    else
        axes(plotWhere)
        f = gcf;
    end

    % x = [1:1:group_num];
    x = [barInfo.data.group]
    y = [barInfo.data.meanVal];
    yError = [barInfo.data.seVal];

    groupNames = arrayfun(@num2str, x, 'UniformOutput', false);


    % Plot bars
    [barPlotInfo] = barplot_with_errBar(y(:)','barX',x,'plotWhere',plotWhere,...
        'errBarVal',yError(:)','barNames',groupNames,'dataNumVal',[barInfo.data.n],...
        'TickAngle', TickAngle, 'FontSize', FontSize, 'FontWeight', FontWeight);
    ylabel(ylabelStr);
    titleStr = replace(titleStr, '_', '-');
    titleStr = replace(titleStr, ':', '-');
    title(titleStr);
end
