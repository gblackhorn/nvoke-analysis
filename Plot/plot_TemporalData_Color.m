function [varargout] = plot_TemporalData_Color(plotWhere,TemporalData,varargin)
    % Create a plot for temporal related data using color
    % Note: the rows in 'TemporalData' will be plotted to rows

    % Can be used to plot: 
    %   1. Calcium fluorescence level in ROIs
    %   2. Calcium fluorescence level aligned to stimulation 

    % Example: plot_TemporalData_Color(plotWhere,TemporalData) "PlotWhere" is used to specify the
    % axis where the plot will be created."TemporalData" is a matrix containing the temporal related
    % values. Each row of "TemporalData" contains a single set of temporal related data.

    % Defaults
    colorLUT = 'turbo'; % default look up table (LUT)/colormap. Other sets are: 'parula','hot','jet', etc.
    show_colorbar = true; % true/false. Show color next to the plot if true.
    xtickInt = 10; % interval between x ticks

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('rowNames', varargin{ii})
            rowNames = varargin{ii+1}; % cell array containing strings used to label y_ticks
        elseif strcmpi('x_window', varargin{ii})
            x_window = varargin{ii+1}; % [a b] numerical array. Used to display time
        elseif strcmpi('xtickInt', varargin{ii})
            xtickInt = varargin{ii+1}; % a single number to set the interval between x ticks
        elseif strcmpi('colorLUT', varargin{ii})
            colorLUT = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        end
    end

    if exist('rowNames')==0 || isempty(rowNames)
        rowNames = NumArray2StringCell(size(TemporalData,1));
        % rowNames = [1:size(TemporalData,1)]; % Create a numerical array 
        % rowNames = arrayfun(@num2str,rowNames,'UniformOutput',0); % The NUM2STR function converts a number 
        % to the string representation of that number. This function is applied to each cell in the A array/matrix 
        % using ARRAYFUN. The 'UniformOutput' parameter is set to 0 to instruct CELLFUN to encapsulate the outputs into a cell array.
    end


    y_range = [1:size(TemporalData,1)]; % use the row number as y tick
    if exist('x_window') && ~isempty(x_window)
        p_handle = imagesc(plotWhere,x_window,y_range,TemporalData);

        set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
        xticks([x_window(1):xtickInt:x_window(2)]);
    else
        p_handle = imagesc(plotWhere,TemporalData);
        set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
        set(gca,'xtick',[])
        set(gca,'xticklabel',[])
    end
    set(gca,'box','off')
    yticks(y_range); % only tick the value in y_range
    yticklabels(rowNames); % label yticks

end
