function plotCalciumImagingWithROIs(imageMatrix, roiBoundaries, roiNames, varargin)
    % PLOTCALCIUMIMAGINGWITHROIS Plots an image of calcium imaging with ROI boundaries and labels.
    %
    %   plotCalciumImagingWithROIs(imageMatrix, roiBoundaries, roiNames, ...)
    %   plots the calcium imaging matrix and overlays the ROI boundaries with labels.
    %   Each ROI is distinguished by a different color.
    %
    %   Optional parameters (specified as name-value pairs):
    %   - 'AxesHandle': Handle to the axes where the image should be plotted.
    %   - 'Title': A title for the plot.
    %   - Additional properties to be passed to the plot and text functions.
    %
    %   Input arguments:
    %   - imageMatrix: The calcium imaging matrix (2D array).
    %   - roiBoundaries: A cell array where each cell contains the boundary of a single ROI.
    %       - recdata_organized{n, 2}.roi_edge
    %       - alignedData_allTrials(n).traces.roiEdge     
    %   - roiNames: A cell array of strings containing the names of the ROIs.

    % Defaults
    LineWidth = 1;
    FontSize = 10;
    FontWeight = 'normal';

    % Create an inputParser object
    p = inputParser;
    
    % Define optional parameters
    addParameter(p, 'AxesHandle', []); % Optional parameter 'AxesHandle' with default value []
    addParameter(p, 'Title', 'Calcium Imaging with ROI Boundaries and Labels'); % Optional parameter 'Title' with default value
    
    % Parse the input arguments
    parse(p, varargin{:});
    
    % Access the parsed results
    axesHandle = p.Results.AxesHandle;
    plotTitle = p.Results.Title;

    % Define a list of colors for different ROIs
    colors = lines(length(roiBoundaries)); % Generate a colormap with distinct colors

    % Display the image matrix in the specified axes or create a new figure
    if isempty(axesHandle)
        fig_canvas(1,'unit_width',0.5,'unit_height',0.5,'fig_name',plotTitle);
        % figure;
        axesHandle = gca;
    end
    axes(axesHandle);
    imshow(imageMatrix, [], 'InitialMagnification', 'fit');
    hold on;
    
    % Loop through each ROI and plot the boundaries with labels
    centroids = zeros(length(roiBoundaries), 2);
    textHandles = gobjects(length(roiBoundaries), 1);
    for k = 1:length(roiBoundaries)
        boundary = roiBoundaries{k};
        roiName = roiNames{k};
        color = colors(k, :); % Get the color for this ROI
        
        % Plot the ROI boundary
        plot(boundary(:,2), boundary(:,1), 'Color', color, 'LineWidth', LineWidth);
        
        % Calculate the centroid of the ROI for labeling
        centroids(k, :) = mean(boundary, 1);
        
        % Add the ROI label initially at the centroid
        textHandles(k) = text(centroids(k, 2), centroids(k, 1), roiName, 'Color', color, 'FontSize', FontSize, 'FontWeight', FontWeight);
    end
    
    % Adjust text positions to avoid overlap
    adjustTextPositions(textHandles, centroids);
    
    % Add a title if specified
    title(plotTitle);
    hold off;
end

function adjustTextPositions(textHandles, centroids)
    % ADJUSTTEXTPOSITIONS Adjusts the positions of text handles to avoid overlap
    % 
    %   adjustTextPositions(textHandles, centroids) moves the text labels to
    %   prevent them from overlapping, based on their initial positions and centroids.
    
    numTexts = length(textHandles);
    minDistance = 20; % Minimum distance between text labels
    
    for i = 1:numTexts
        for j = i+1:numTexts
            % Calculate the distance between two text labels
            dx = centroids(j, 2) - centroids(i, 2);
            dy = centroids(j, 1) - centroids(i, 1);
            distance = sqrt(dx^2 + dy^2);
            
            % If the labels are too close, adjust their positions
            if distance < minDistance
                % Calculate new positions to avoid overlap
                angle = atan2(dy, dx);
                shiftX = minDistance * cos(angle);
                shiftY = minDistance * sin(angle);
                
                % Adjust positions
                centroids(j, 2) = centroids(i, 2) + shiftX;
                centroids(j, 1) = centroids(i, 1) + shiftY;
                
                % Update text positions
                textHandles(j).Position = [centroids(j, 2), centroids(j, 1), 0];
            end
        end
    end
end
