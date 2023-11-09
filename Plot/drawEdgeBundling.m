function drawEdgeBundling(corrMatrix, distMatrix, roiNames, varargin)

    % default
    corrThresh = 0.2;

    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('plotWhere', varargin{ii}) 
            plotWhere = varargin{ii+1}; 
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

    % Define colors for nodes and text
    nodeColors = lines(numNodes); % Get a colormap array

    % Plot the nodes
    for i = 1:numNodes
        scatter(positions(i,1), positions(i,2), 'filled', 'MarkerFaceColor', nodeColors(i,:));
    end

    % Label the nodes with some padding
    padding = 0.1; % Adjust padding if necessary
    for i = 1:numNodes
        textPos = positions(i,:) * (1 + padding); % Move text away from the node
        text(textPos(1), textPos(2), roiNames{i}, 'HorizontalAlignment', 'center', ...
             'VerticalAlignment', 'middle', 'Color', nodeColors(i,:), 'FontSize', 10, 'FontWeight', 'bold');
    end

    % Draw the edges
    for i = 1:numNodes
        for j = i+1:numNodes % Only upper triangular part
            if corrMatrix(i, j) > corrThresh % Threshold for visibility
                % Map the correlation to line width
                lineWidth = 1 + 5 * (corrMatrix(i, j) - corrThresh);
                
                % Map the distance to a color
                normalizedDist = (distMatrix(i, j) - min(distMatrix(:))) / (max(distMatrix(:)) - min(distMatrix(:)));
                edgeColor = [1-normalizedDist, normalizedDist, 0]; % From red to green

                % Define control points for Bezier curves
                midPoint = (positions(i,:) + positions(j,:)) / 2;
                controlPoint = midPoint / norm(midPoint) * corrThresh; % Adjust for 'bundling' effect
                
                % Draw the Bezier curve
                bezierLine(positions(i,:), controlPoint, positions(j,:), lineWidth, edgeColor);
            end
        end
    end

    % Set the axes to be equal and turn off the axis
    axis equal off;
    
    % Set the figure background to be white
    set(gcf, 'Color', 'w');

    hold off; % Release the figure hold
end

function bezierLine(p0, p1, p2, lineWidth, edgeColor)
    % Generate points for the Bezier curve
    t = linspace(0, 1, 100);
    Bx = (1-t).^2 .* p0(1) + 2 .* (1-t) .* t .* p1(1) + t.^2 .* p2(1);
    By = (1-t).^2 .* p0(2) + 2 .* (1-t) .* t .* p1(2) + t.^2 .* p2(2);
    
    % Draw the line on the current figure
    line(Bx, By, 'Color', edgeColor, 'LineWidth', lineWidth);
end
