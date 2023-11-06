function [varargout] = stylishPieChart(pieData,varargin)
    % Create a stylish pie chart by using explode and, heatmap, customized font

    % pieData: vector

    % sliceNames: strings 

    % default
    explodeEffect = true;
    sliceNamePrefix = 'Category';

    % figure parameters
    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column
    labelFontSize = 12;
    titleFontSize = 14; 
    titleFontWeight = 'bold'; 
    sliceColors = [
        0.9020    0.3922    0.0980
        0.0980    0.3922    0.9020
        0.5020    0.7529    0.9020
        0.9020    0.7529    0.5020
    ];


    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('explodeEffect', varargin{ii})
            explodeEffect = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('sliceNames', varargin{ii})
            sliceNames = varargin{ii+1};
        elseif strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1};
        % elseif strcmpi('save_dir', varargin{ii})
        %     save_dir = varargin{ii+1};
        % elseif strcmpi('gui_save', varargin{ii})
        %     gui_save = varargin{ii+1};
        end
    end 

    sliceNum = numel(pieData);

    % slice name for each slice
    if ~exist('sliceNames','var')
        sliceSN = num2cell([1:sliceNum]); % serial numbers of slices
        sliceNames = cellfun(@(x) sprintf('%s %d',sliceNamePrefix,x),sliceSN,'UniformOutput',false);
    end

    % Calculate the total sum of pieData
    total = sum(pieData);

    % Create custom labels with category name, pieData value, and percentage
    labels = cell(size(pieData));
    for i = 1:length(pieData)
        percentage = (pieData(i) / total) * 100;
        labels{i} = sprintf('%s \n%d (%.1f%%)', sliceNames{i}, pieData(i), percentage);
    end

    % Explode the 1st and 4th slice (move them slightly outwards)
    explode = mod(0:(sliceNum-1),2);

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end

    % Create a pie chart with custom labels and explode
    h = pie(gca,pieData,explode,labels);

    % Apply custom colors and remove border lines
    for k = 1:2:length(h)
        set(h(k), 'FaceColor', sliceColors(mod((k+1)/2, size(sliceColors, 1)) + 1, :), 'EdgeColor', 'none');
    end

    % Apply customized font size
    for i = 2:2:length(h)
        set(h(i),'FontSize',labelFontSize);
    end

    % Set the title with a custom font size and font weight
    if ~exist('titleStr','var')
        titleStr = 'Stylish Pie Chart';
    end
    title(titleStr, 'FontSize', titleFontSize, 'FontWeight', titleFontWeight);


    varargout{1} = h;
end
