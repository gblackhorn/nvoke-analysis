function drawEdgeBundling(corrMatrix, distMatrix, roiNames, varargin)

    % default
    corrThresh = -1; % Only correlations higher then the threshold will be shown as edges
    edgeScale = 20; % scaling factor applied to the correlation values when setting the edge width
    colorBarStr = 'Distance (pixel)';
    lineAlpha = 0.5;
    labelFontSize = 10;
    labelFontWeight = 'normal'; % 'normal' / 'bold'

    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('plotWhere', varargin{ii}) 
            plotWhere = varargin{ii+1}; 
        elseif strcmpi('corrThresh', varargin{ii})
            corrThresh = varargin{ii+1};
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1};
        elseif strcmpi('colorBarStr', varargin{ii})
            colorBarStr = varargin{ii+1};
        elseif strcmpi('showEdgelabel', varargin{ii})
            showEdgelabel = varargin{ii+1};
        end
    end


    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end
    hold on; % Keep the figure "open" to draw multiple layers

    % Define the number of nodes
    numNodes = numel(roiNames);
    
    % Define the positions of the nodes in a circular layout
    theta = linspace(0, 2*pi, numNodes+1)';
    theta(end) = []; % remove the duplicate end point
    positions = [cos(theta), sin(theta)];

    % % Define colors for nodes and text
    % nodeColors = lines(numNodes); % Get a colormap array

    % Plot the nodes
    for i = 1:numNodes
        % scatter(positions(i,1), positions(i,2), 'filled', 'MarkerFaceColor', nodeColors(i,:));
        % scatter(positions(i,1), positions(i,2), 'filled');
        scatter(positions(i,1), positions(i,2), 'filled', 'MarkerFaceColor', 'k');
    end

    % Label the nodes with adjusted alignment
    padding = 0.1; % Adjust padding if necessary
    for i = 1:numNodes
        x = positions(i,1);
        y = positions(i,2);
        textPos = positions(i,:) * (1 + padding); % Move text away from the node
        
        % Adjust the text alignment based on the node's position
        if x < -0.1  % Node is to the left, align text to the right
            horzAlign = 'right';
        elseif x > 0.1  % Node is to the right, align text to the left
            horzAlign = 'left';
        else  % Node is at the top or bottom, align text to the center
            horzAlign = 'center';
        end
        
        text(textPos(1), textPos(2), roiNames{i}, ...
             'HorizontalAlignment', horzAlign, ...
             'VerticalAlignment', 'middle', ...
             'Color', 'k', ... % black color for better visibility
             'FontSize', labelFontSize, ...
             'FontWeight', labelFontWeight, ...
             'BackgroundColor', 'w', ... % white background to avoid overlapping with edges
             'Margin', 1); % a small margin around the text for better legibility
    end


    % Draw the chords with improved color distinction
     % Get the range of distances
     minDist = min(distMatrix(:));
     maxDist = max(distMatrix(:));
     
     % Create a colormap that covers the full spectrum (e.g., jet or hsv)
     fullColorMap = jet(numNodes); % Use a colormap with a full spectrum
     colormap(fullColorMap); % Apply the colormap to the current figure

     % Draw the edges
     for i = 1:numNodes
         for j = i+1:numNodes % Only upper triangular part
             if corrMatrix(i, j) > corrThresh % Threshold for visibility
                 % Map the correlation to line width
                 lineWidth = 1 + edgeScale * (corrMatrix(i, j) - corrThresh);
                 
                 % Map the distance to a color index in the colormap
                 distColorIndex = round(1 + (distMatrix(i, j) - minDist) / (maxDist - minDist) * (numNodes - 1));
                 edgeColor = fullColorMap(distColorIndex, :);
                 
                 % Define control points for Bezier curves
                 midPoint = (positions(i,:) + positions(j,:)) / 2;
                 controlPoint = midPoint / norm(midPoint) * corrThresh; % Adjust for 'bundling' effect
                 
                 % Draw the Bezier curve
                 bezierLine(positions(i,:), controlPoint, positions(j,:), lineWidth, edgeColor, lineAlpha);
             end
         end
     end

    % Set the axes to be equal and turn off the axis
    axis equal off;
    
    % Set the figure background to be white
    set(gcf, 'Color', 'w');

    % Add a color bar to the right of the figure
    c = colorbar;
    c.Label.String = colorBarStr;
    c.Label.FontSize = labelFontSize;
    
    % Set color limits based on min and max distances
    caxis([minDist maxDist]);
    
    % Adjust color bar ticks to span the range of distances
    c.Ticks = linspace(minDist, maxDist, length(c.Ticks));


    hold off; % Release the figure hold

    if ~exist('titleStr','var')
        titleStr = 'Edge bundling for correlation (thickness)';
    end
    titleStr = sprintf('%s\ncorrThresh: %g',titleStr,corrThresh);
    title(titleStr)

    % Get the current axes
    ax = gca;

    % Increase y-axis limits
    yl = ylim(ax); % Get the current y-axis limits
    upBorder = 0.1*(yl(2)-yl(1));
    ylim(ax, [yl(1), yl(2) + upBorder]); % Increase the upper limit
end

function bezierLine(p0, p1, p2, lineWidth, edgeColor, lineAlpha)
    % Generate points for the Bezier curve
    t = linspace(0, 1, 100);
    Bx = (1-t).^2 .* p0(1) + 2 .* (1-t) .* t .* p1(1) + t.^2 .* p2(1);
    By = (1-t).^2 .* p0(2) + 2 .* (1-t) .* t .* p1(2) + t.^2 .* p2(2);
    
    % Draw the line on the current figure
    lineHandle = line(Bx, By, 'Color', [edgeColor lineAlpha], 'LineWidth', lineWidth);
end
