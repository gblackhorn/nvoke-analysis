function [varargout] = stylishScatter(xData,yData,varargin)
    % Create a stylish scatter plot with grid

    % xData and yData: vectors


    % default
    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    xlabelStr = 'x label';
    ylabelStr = 'y label';
    titleStr = 'Stylish Scatter';

    MarkerSize = 10;
    MarkerEdgeColor = 'k';
    MarkerFaceColor = 'r';

    FontSize = 12;
    LineWidth = 1.5;

    gridON = true; % true/false. If on, plot grids
    GridLineStyle = ':';
    GridColor = 'k';
    GridAlpha = 0.2;

    showCorrCoef = false; % Calculate the correlation coefficient and the linear regression parameters. Show them in the plot
    lineColor = '#585858';

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('xlabelStr', varargin{ii})
            xlabelStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('ylabelStr', varargin{ii})
            ylabelStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1};
        elseif strcmpi('MarkerSize', varargin{ii})
            MarkerSize = varargin{ii+1};
        elseif strcmpi('MarkerEdgeColor', varargin{ii})
            MarkerEdgeColor = varargin{ii+1};
        elseif strcmpi('MarkerFaceColor', varargin{ii})
            MarkerFaceColor = varargin{ii+1};
        elseif strcmpi('FontSize', varargin{ii})
            FontSize = varargin{ii+1};
        elseif strcmpi('LineWidth', varargin{ii})
            LineWidth = varargin{ii+1};
        elseif strcmpi('gridON', varargin{ii})
            gridON = varargin{ii+1};
        elseif strcmpi('GridLineStyle', varargin{ii})
            GridLineStyle = varargin{ii+1};
        elseif strcmpi('GridColor', varargin{ii})
            GridColor = varargin{ii+1};
        elseif strcmpi('GridAlpha', varargin{ii})
            GridAlpha = varargin{ii+1};
        elseif strcmpi('showCorrCoef', varargin{ii})
            showCorrCoef = varargin{ii+1};
        elseif strcmpi('lineColor', varargin{ii})
            lineColor = varargin{ii+1};
        end
    end 

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end

    h = scatter(gca,xData,yData,...
        MarkerSize,'MarkerEdgeColor',MarkerEdgeColor,'MarkerFaceColor',MarkerFaceColor);
    xlabel(xlabelStr);
    ylabel(ylabelStr);
    title(titleStr);
    box off;
    set(gca,'FontSize',FontSize,'LineWidth',LineWidth);
    set(gcf,'Color','w');

    if gridON
        grid on;    
        set(gca, 'GridLineStyle',GridLineStyle,'GridColor',GridColor,'GridAlpha',GridAlpha);
    end

    hold on

    % Calculate the correlation coefficient and the linear regression parameters.
    if showCorrCoef
        % Calculate linear regression parameters
        p = polyfit(xData,yData, 1); % p(1) is the slope, p(2) is the intercept

        % Calculate the correlation coefficient for annotation
        [R,pValue] = corrcoef(xData,yData);
        correlationCoefficient = R(1,2);
        corrCoefPval = pValue(1,2);

        % Generate xData values for the line
        xLine = linspace(min(xData), max(xData), 100); % 100 points for a smooth line

        % Calculate corresponding y values using the regression parameters
        yLine = polyval(p, xLine);

        % Plot the regression line
        plot(xLine,yLine,'Color',lineColor,'LineStyle','-','LineWidth', 2);

        % Determine the limits of the current axes
        xlims = xlim; % Get the x-axis limits
        ylims = ylim; % Get the y-axis limits

        % Position for the annotation in the top right corner
        xPos = xlims(2); % The rightmost limit of the x-axis
        yPos = ylims(2); % The topmost limit of the y-axis

        % Annotate the plot with the correlation coefficient
        str = sprintf('R = %.2f, p-value = %.3f',correlationCoefficient,corrCoefPval);
        text(xPos-range(xlims)*0.1,yPos-range(ylims)*0.05,str,'FontWeight','bold',...
            'VerticalAlignment','top','HorizontalAlignment','right');
        % text(max(xData),min(yData),str,'FontWeight','bold',...
        %     'VerticalAlignment','top','HorizontalAlignment','right');

        varargout{2} = correlationCoefficient;
        varargout{3} = corrCoefPval;
    end

    hold off

    varargout{1} = h;
end
