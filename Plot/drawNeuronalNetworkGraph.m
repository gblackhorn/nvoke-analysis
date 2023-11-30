function [h] = drawNeuronalNetworkGraph(corrMatrix, distMatrix, roiNames, varargin)
    % Create the graph object from the correlation matrix


    % Defaults
    showEdgelabel = false; % true/false. Show the weight as edge label
    nodeFontsize = 10;
    corrThresh = 0; % Only correlations higher then the threshold will be shown as edges

    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    % Optionals
    for ii = 1:2:(nargin-3)
        if strcmpi('plotWhere', varargin{ii}) 
            plotWhere = varargin{ii+1}; 
        elseif strcmpi('showEdgelabel', varargin{ii})
            showEdgelabel = varargin{ii+1};
        elseif strcmpi('corrThresh', varargin{ii})
            corrThresh = varargin{ii+1};
        end
    end

    % Get the upper triangle without the diagnol line
    G = graph(corrMatrix, roiNames, 'upper', 'omitselfloops');


    if corrThresh > 0
        % Remove edges smaller than corrThresh
        G = rmedge(G, find(G.Edges.Weight < corrThresh));
    else
        warning('variable corrThresh is equal or smaller than 0')
        % Remove edges with non-positive correlation
        % G = rmedge(G, 1:numedges(G), find(G.Edges.Weight <= 0));
        G = rmedge(G, find(G.Edges.Weight <= 0));
    end
    

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end
    hold on; % Keep the figure "open" to draw multiple layers


    % Create a layout for the graph
    h = plot(gca, G, 'Layout', 'force');
    h.NodeFontSize = nodeFontsize;
    title(sprintf('Neuronal Network Graph\ncorrThresh: %g',corrThresh));

    % Customize the node colors
    numNodes = numnodes(G);
    nodeColorMap = lines(numNodes); % Using 'lines' colormap for different colors
    h.NodeColor = nodeColorMap;

    if isempty(find(degree(G) == 0))
        % Customize node sizes based on degree
        % nodeSizes = 5 * degree(G);
        nodeSizes = 1 * degree(G);
        h.MarkerSize = nodeSizes;

        % Normalize the weights for correlation
        weights = G.Edges.Weight / max(G.Edges.Weight); 
        h.LineWidth = 5 * weights;
    end

    % % Normalize distances for color mapping
    % maxDist = max(distMatrix(:));
    % minDist = min(distMatrix(:));
    % distColors = (distMatrix - minDist) / (maxDist - minDist); % Normalize between 0 and 1
    % distColors = 1 - distColors; % Invert so that small distances are "warmer" (red) and large are "cooler" (blue)

    % % Draw the edges with colors based on distances
    % for i = 1:numedges(G)
    %     % Get the nodes connected by the edge
    %     edgeNodes = G.Edges.EndNodes(i,:);
    %     nodeIndices = findnode(G, edgeNodes);

    %     % Get the color corresponding to the distance
    %     edgeColor = [distColors(nodeIndices(1), nodeIndices(2)), 0, 0]; % Red channel only for simplicity

    %     % Draw the edge
    %     h = plot(G, 'XData', h.XData, 'YData', h.YData, 'Edges', edgeNodes, 'EdgeColor', edgeColor, 'LineWidth', 5 * weights(i));
    % end

    % % Edge colors based on distances
    % % Get the unique edges from the upper triangular part of the distance matrix
    % [I, J] = find(triu(distMatrix, 1));
    % for k = 1:length(I)
    %     % Find the edge in the graph
    %     edgeIdx = findedge(G, roiNames{I(k)}, roiNames{J(k)});
    %     % Normalize the distance to use it for the color
    %     normalizedDist = (distMatrix(I(k), J(k)) - minDist) / (maxDist - minDist);
    %     % Set the color for the edge
    %     h.EdgeColor(edgeIdx, :) = [1-normalizedDist, 0, normalizedDist]; % From red to blue
    % end

    % Add labels to the edges representing the weights
    if showEdgelabel
        labeledge(h, G.Edges.EndNodes(:,1), G.Edges.EndNodes(:,2), round(G.Edges.Weight,2));
    end

    % Adjust the figure
    set(gcf, 'Color', 'w'); % Set background color to white
    axis off;  % Turn off the axis
    box off;   % Turn off the box surrounding the plot

    % Display the graph
    drawnow;

    hold off; % Release the figure
end
