function [varargout] = draw_WindowShade(plotWhere,shadeData,varargin)
    % Draw shade with given x data on an existing axis

    % draw_WindowShade(gca,shadeData) Plot window shades on the current axis. "shadeData" is a nx2 numeric
    % array. 1st column of shadeData contains the timestamps, and 2nd column contains 0 or 1. [... 0 1 1 0 ...]
    % will draw a shade window

    % Defaults
    shadeColor = '#4DBEEE'; % default color
    shadeAlpha = 0.3; % default trasparency
    yRange = [];

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('shadeColor', varargin{ii})
            shadeColor = varargin{ii+1};
        elseif strcmpi('shadeAlpha', varargin{ii})
            shadeAlpha = varargin{ii+1};
        elseif strcmpi('yRange', varargin{ii})
            yRange = varargin{ii+1}; % input a 1x2 number array for yMin and yMax to draw shade in this range
        end
    end

    axes(plotWhere) % Creat a Cartesian axes in case it doesn't exist
    if isempty(yRange)
        axProp = get(gca); % Get the properties of axis
        yRange = axProp.YLim; % Use the y limits of current axis for shade plotting
    end

    % Locate the min and max value in patch_data, and replace them with yLims
    shade_yMin_idx = find(shadeData(:,2)==0);
    shade_yMax_idx = find(shadeData(:,2)==1);
    shadeData(shade_yMin_idx,2) = yRange(1);
    shadeData(shade_yMax_idx,2) = yRange(2);

    patch('XData',shadeData(:, 1), 'YData', shadeData(:, 2),...
                'FaceColor', shadeColor, 'FaceAlpha', shadeAlpha, 'EdgeColor', 'none');
end
