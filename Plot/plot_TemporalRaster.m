function [varargout] = plot_TemporalRaster(plotWhere,TemporalData,varargin)
    % Creat temporal raster plot

    % Can be used to plot: 
    %   1. Calcium event timestamps in ROIs
    %   2. Calcium event timestamps aligned to stimulation 

    % Example: plot_TemporalRaster(plotWhere,TemporalData) "PlotWhere" is used to specify the axis
    % where the plot will be created."TemporalData" contains the timestamps of events.
    % If "TemporalData" is a array of numbers, one row of raster will be ploted. If "TemporalData"
    % is a cell array, data in every cell will be plotted in a single row
    
    % Defaults
    xtickInt = 10; % interval of x ticks
    yInterval = 5; % offset on y axis to seperate data from various ROIs
    sz = 20; % marker area

    save_fig = false;
    save_dir = '';

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
    	if strcmpi('rowNames', varargin{ii})
    		rowNames = varargin{ii+1}; % cell array containing strings used to label y_ticks
        elseif strcmpi('x_window', varargin{ii})
            x_window = varargin{ii+1}; % [a b] numerical array. Used to set the limitation of x axis
        elseif strcmpi('xtickInt', varargin{ii})
            xtickInt = varargin{ii+1}; % [a b] numerical array. Used to set the limitation of x axis
        elseif strcmpi('yInterval', varargin{ii})
            yInterval = varargin{ii+1}; % interval between rows in the plot
        elseif strcmpi('sz', varargin{ii})
            sz = varargin{ii+1}; % size of the markers in the raster plot
        % elseif strcmpi('plotTitle', varargin{ii})
        %     plotTitle = varargin{ii+1}; % string var 
    	% elseif strcmpi('save_fig', varargin{ii})
    	% 	save_fig = varargin{ii+1};
        % elseif strcmpi('save_dir', varargin{ii})
        %     save_dir = varargin{ii+1};
        end
    end

    %% main contents
    % Find out how many rows of raster will be plotted
    if ~iscell(TemporalData)
        TemporalData = {TemporalData}; % convert "TemporalData"  to a cell if it is a numerical array
    end
    row_num = numel(TemporalData); % total number of rows

    % Create rowNames if it does not exist or is empty
    if exist('rowNames')==0 || isempty(rowNames)
        rowNames = [1:row_num]; % Create a numerical array 
        rowNames = arrayfun(@num2str,rowNames,'UniformOutput',0); % The NUM2STR function converts a number 
        % to the string representation of that number. This function is applied to each cell in the A array/matrix 
        % using ARRAYFUN. The 'UniformOutput' parameter is set to 0 to instruct CELLFUN to encapsulate the outputs into a cell array.
    end

    % Create raster plot 
    y_pos = zeros(1,row_num); % variable for storing the position of row data on y axis
    TemporalData = cellfun(@(x) x(:),TemporalData,'UniformOutput',false); % make sure each cell contains vertical array
    axes(plotWhere)
    hold on
    for rn = 1:row_num
        y_pos(rn) = y_pos(rn)-rn*yInterval; % adjust y value using yInterval
        x_raster = TemporalData{rn}; % get raster value from TemporalData
        % x_raster = x_raster(:); % make sure raster value is a vertical array
        % TemporalData{rn} = x_raster; % store the vertical array in TemporalData

        if ~isempty(x_raster)
            y_raster = y_pos(rn)*ones(size(x_raster)); % create y values, using y_pos(rn), for all raster data 
            raster_handle = scatter(x_raster,y_raster,sz,'k|','filled',...
                'MarkerEdgeColor', 'k','LineWidth', 1); % Plot one row of raster using data in a single cell of TemporalData
        end
    end
    TemporalData_all = cell2mat(TemporalData(:)); % Get all data in "TemporalData" and store them in a vertial numerical array
    yticks(flip(y_pos));
    yticklabels(flip(rowNames));
    if exist('x_window')==0 || isempty(x_window)
        x_window = xlim; % get the xlim of the current axis
        % x_edge = (x_window(2)-x_window(1))/10; % use the 10% of the x_window as and edge
        % x_window = [x_window(1)-x_edge, x_window(2)+x_edge]; % add edge to both sides of x_window
    end
    x_ticks = [x_window(1):xtickInt:x_window(2)];
    set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
    xticks(x_ticks);
    xlabel('time (s)')


    % xticks([x_window(1):xtickInt:x_window(2)]);


    % if exist('x_ticks')~=0 && ~isempty(x_ticks) % if variable 'x_ticks' exists and is not empty
    %     xticks(x_ticks) % draw x_ticks 
    % end

    varargout{1} = TemporalData_all;
end

