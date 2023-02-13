function [varargout] = plot_TemporalData_Trace(plotWhere,xData,yData,varargin)
    % Create a plot for temporal related data
    % xData can be [].

    % Can be used to plot: 
    %   1. Calcium fluorescence traces in ROIs
    %   2. Calcium fluorescence level aligned to stimulation 

    % Example: 

    % plot_TemporalData_Trace(plotWhere,xData,yData) "PlotWhere" is used to specify the
    % axis where the plot will be created."yData" is a matrix containing the temporal related
    % values. Each column of "yData" contains a single set of temporal related data.

    % Defaults
    plotInterval = 20; % offset for traces on y axis to seperate them
    % vis = 'on'; % set the 'visible' of figures
    % decon = true; % true/false plot decon trace
    marker_type1 = {}; % plot markers for peaks. if xData exist, 
    marker_type2 = {}; % plot markers for rise and decay frames
    LineWidth = 1;
    line_color = '#616887';
    % line_color_decon = '#24283B';
    marker_type1_color = '#8D73BA';
    % markerPeak_color_decon = '#5B7A87';
    marker_type2_color = '#BA9973';

    % Optionals for inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('plotInterval', varargin{ii})
            plotInterval = varargin{ii+1}; 
        elseif strcmpi('ylabels', varargin{ii})
            ylabels = varargin{ii+1}; 
        elseif strcmpi('marker_type1', varargin{ii}) 
            marker_type1 = varargin{ii+1}; % cell array. size equals to yData column. index of some yData datapoints 
        elseif strcmpi('marker_type2', varargin{ii})
            marker_type2 = varargin{ii+1};  % cell array. size equals to yData column. index of some yData datapoints 
        elseif strcmpi('marker_type1_color', varargin{ii})
            marker_type1_color = varargin{ii+1}; 
        elseif strcmpi('marker_type2_color', varargin{ii})
            marker_type2_color = varargin{ii+1}; 
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; 
        end
    end

    if exist('ylabels')==0 || isempty(ylabels)
        ylabels = NumArray2StringCell(size(TemporalData,2));
        % rowNames = [1:size(TemporalData,1)]; % Create a numerical array 
        % rowNames = arrayfun(@num2str,rowNames,'UniformOutput',0); % The NUM2STR function converts a number 
        % to the string representation of that number. This function is applied to each cell in the A array/matrix 
        % using ARRAYFUN. The 'UniformOutput' parameter is set to 0 to instruct CELLFUN to encapsulate the outputs into a cell array.
    end

    if isempty(plotWhere)
        fig_canvas(1,'unit_width',0.9,unit_height,0.9);
        plotWhere = gca;
    end

    trace_num = size(yData,2); % number of traces = number of yData columns
    trace_length = size(yData,2); % data point number of yData
    trace_y_pos = [0:-20:(trace_num-1)*-20];
    trace_y_shift = repmat(trace_y_pos,trace_length,1);
    yData_shift = yData-trace_y_shift;
    trace_y_tick = ylabels;
    % spikeFrames_all_cell = cell(trace_num,1);

    if ~xData
        plot(xData,yData_shift,'LineWidth',LineWidth,'Color',line_color);
    else
        plot(yData_shift,'LineWidth',LineWidth,'Color',line_color);
    end
    hold on


    if ~isempty(marker_type1) || ~isempty(marker_type2)
        for tn = 1:trace_num
             
        end
    end

end
