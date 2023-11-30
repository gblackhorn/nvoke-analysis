function drawChordDiagram(corrMatrix, distMatrix, roiNames, varargin)

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

    % Check the input sizes
    assert(isequal(size(corrMatrix), size(distMatrix)), 'The correlation and distance matrices must be the same size.');
    assert(size(corrMatrix, 1) == length(roiNames), 'The number of ROI names must match the size of the matrices.');

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end
    hold on; % Keep the figure "open" to draw multiple layers
    axis equal;
    axis off;
    colormap hot; % Colormap for representing distance

    % Calculate the positions of the nodes
    numNodes = length(roiNames);
    angleStep = 2 * pi / numNodes;
    angles = (0:numNodes-1) * angleStep;
    positions = [cos(angles)', sin(angles)'];

    % Draw the nodes
    for i = 1:numNodes
        plot(positions(i, 1), positions(i, 2), 'o', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'k');
        textOffset = 1.1;
        text(positions(i, 1) * textOffset, positions(i, 2) * textOffset, roiNames{i}, 'HorizontalAlignment', 'center');
    end

    % Draw the chords
    for i = 1:numNodes
        for j = i+1:numNodes
            if corrMatrix(i, j) > corrThresh % Draw a chord only for positive correlations
                % Determine the Bezier control points
                midPoint = (positions(i, :) + positions(j, :)) / 2;
                controlPoint = [0, 0]; % Control point at the center
                
                % Set the color based on the distance
                distColor = 1 - (distMatrix(i, j) - min(distMatrix(:))) / (max(distMatrix(:)) - min(distMatrix(:)));
                hotMap = hot; % Get the colormap data
                edgeColor = hotMap(ceil(distColor * size(hotMap, 1)), :);
                
                % Set the width based on the correlation
                lineWidth = (corrMatrix(i, j)-corrThresh) * 10;
                
                % Calculate the bezier curve
                bezierPts = bezierCurve([positions(i, :); controlPoint; positions(j, :)]);
                
                % Plot the chord
                plot(bezierPts(:, 1), bezierPts(:, 2), 'LineWidth', lineWidth, 'Color', edgeColor);
            end
        end
    end

    hold off;
end

function bezierPts = bezierCurve(ctrlPts)
    t = linspace(0, 1, 100)';
    bezierPts = (1-t).^2 .* ctrlPts(1, :) + 2*(1-t).*t .* ctrlPts(2, :) + t.^2 .* ctrlPts(3, :);
end
