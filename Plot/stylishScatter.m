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

    MarkerEdgeColor = 'k';
    MarkerFaceColor = 'r';

    FontSize = 12;
    LineWidth = 1.5;

    gridON = true; % true/false. If on, plot grids
    GridLineStyle = ':';
    GridColor = 'k';
    GridAlpha = 0.5;

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
        end
    end 

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end

    h = scatter(gca,xData,yData,'MarkerEdgeColor',MarkerEdgeColor, 'MarkerFaceColor',MarkerFaceColor);
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

    varargout{1} = h;
end
