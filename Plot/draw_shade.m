function [varargout] = draw_shade(shadeRange,plotWhere,varargin)
    % draw square shade on an axes. Usually used to mark stimulation period
    %   shadeRange: 2-column matrix contains the x-start and x-end of the shade
    %   plotwhere: the axes where the shade would be plotted on
    %   varargin: 

    % Defaults
    shadeColor = '#4DBEEE';
    shadeAlpha = 0.3; % transparency
    shadeEdgeColor = 'none'; 

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('shadeColor', varargin{ii})
            shadeColor = varargin{ii+1}; % shade color can be specified
        % elseif strcmpi('ylim', varargin{ii})
        %     ylim_min = varargin{ii+1}(1);
        %     ylim_max = varargin{ii+1}(2);
        end
    end

    % Main contents
    axes(plotWhere);
    axp = get(gca);
    ymin = axp.YLim(1); % shade will cover from Ymin to Ymax
    ymax = axp.YLim(2);
    y_set = [ymin ymax ymax ymin];

    shadeRepeat = size(shadeRange, 1);
    shade_x = [];
    shade_y = [];
    for n = 1:shadeRepeat
    	shade_x = [shade_x, repelem(shadeRange(n, :), 2)];
    	shade_y = [shade_y, y_set];
    end

    sh = patch('XData',shade_x, 'YData', shade_y,...
		'FaceColor', shadeColor, 'FaceAlpha', shadeAlpha, 'EdgeColor', shadeEdgeColor);
end

