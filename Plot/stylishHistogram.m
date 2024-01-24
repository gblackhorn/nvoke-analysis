function [varargout] = stylishHistogram(data,varargin)
    % Create a stylish scatter plot with grid

    % xData and yData: vectors


    % default
    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    XTick = [];
    YTick = [];

    xlabelStr = 'x label';
    ylabelStr = 'y label';
    titleStr = 'Stylish Histogram';

    FaceColor = '#8F8F8F';
    bgColor = [1 1 1];
    Orientation = 'vertical'; % vertical/horizontal

    FontSize = 12;


    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('XTick', varargin{ii})
            XTick = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('YTick', varargin{ii})
            YTick = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('xlabelStr', varargin{ii})
            xlabelStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('ylabelStr', varargin{ii})
            ylabelStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('Orientation', varargin{ii})
            Orientation = varargin{ii+1};
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1};
        elseif strcmpi('FontSize', varargin{ii})
            FontSize = varargin{ii+1};
        end
    end 

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end

    % h = histogram(gca, data, 'FaceColor', FaceColor, 'EdgeColor', 'none',...
    %     'Orientation', Orientation); % Set colors and remove edge line
    switch Orientation
        case 'vertical'
            h = bar(gca, data, 'FaceColor', FaceColor, 'EdgeColor', 'none'); % Set colors and remove edge line
        case 'horizontal'
            h = barh(gca, data, 'FaceColor', FaceColor, 'EdgeColor', 'none'); % Set colors and remove edge line
            set(gca, 'YDir', 'reverse')
    end
    

    % Styling
    set(gca, 'box', 'off'); % Turn off the box surrounding the plot
    set(gca, 'color', 'none'); % Set background color to none
    axis tight; % Fit the axis tightly to the data
    xlabel(xlabelStr);
    ylabel(ylabelStr);
    title(titleStr);

    % Removing grid lines
    grid off;

    % Optional: set the figure background color
    set(gcf, 'Color', bgColor); % White background for the figure

    % Optional: remove axis ticks if desired
    set(gca, 'XTick', XTick);
    set(gca, 'YTick', YTick);

    % Optional: use a custom font
    set(gca, 'FontName', 'Arial', 'FontSize', FontSize);

    varargout{1} = h;
end
