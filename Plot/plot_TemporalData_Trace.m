function [varargout] = plot_TemporalData_Trace(plotWhere,xData,yData,varargin)
    % Create a plot for temporal related data

    % Can be used to plot: 
    %   1. Calcium fluorescence traces in ROIs
    %   2. Calcium fluorescence level aligned to stimulation 

    % Example: 

    % plot_TemporalData_Trace(plotWhere,xData,yData) "PlotWhere" is used to specify the axis where
    % the plot will be created. "xData" is the time information. "yData" is a matrix containing the
    % temporal related values. Each column of "yData" contains a single set of temporal related
    % data.

    % Defaults
    plotInterval = 10; % offset for traces on y axis to seperate them
    xtickInt = 10; % unit: second. x tick interval. 

    % vis = 'on'; % set the 'visible' of figures
    % decon = true; % true/false plot decon trace
    plot_marker = false; % true/false
    marker1_xData = {}; % plot markers for peaks. 
    marker2_xData = {}; % plot markers for rise and decay frames

    LineWidth = 1;
    line_color = '#616887';
    % line_color_decon = '#24283B';
    marker1_style = 'o';
    marker2_style = '>';
    marker1_color = '#8D73BA';
    % markerPeak_color_decon = '#5B7A87';
    marker2_color = '#BA9973';

    shadeData = {};
    shadeColor = {'#F05BBD','#4DBEEE','#ED8564'};

    titleStr = '';

    % Optionals for inputs
    for ii = 1:2:(nargin-3)
        if strcmpi('plotInterval', varargin{ii})
            plotInterval = varargin{ii+1}; 
        elseif strcmpi('ylabels', varargin{ii})
            ylabels = varargin{ii+1}; 
        elseif strcmpi('xtickInt', varargin{ii})
            xtickInt = varargin{ii+1};  % cell array. size equals to yData column. Each cell contains time information can be found in xData
        elseif strcmpi('plot_marker', varargin{ii}) 
            plot_marker = varargin{ii+1}; 
        elseif strcmpi('marker1_xData', varargin{ii}) 
            marker1_xData = varargin{ii+1}; % cell array. size equals to yData column. Each cell contains time information can be found in xData 
        elseif strcmpi('marker2_xData', varargin{ii})
            marker2_xData = varargin{ii+1};  % cell array. size equals to yData column. Each cell contains time information can be found in xData
        elseif strcmpi('marker1_style', varargin{ii})
            marker1_style = varargin{ii+1}; 
        elseif strcmpi('marker2_style', varargin{ii})
            marker2_style = varargin{ii+1}; 
        elseif strcmpi('marker1_color', varargin{ii})
            marker1_color = varargin{ii+1}; 
        elseif strcmpi('marker2_color', varargin{ii})
            marker2_color = varargin{ii+1}; 
        elseif strcmpi('shadeData', varargin{ii})
            shadeData = varargin{ii+1}; 
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; 
        end
    end

    if exist('ylabels')==0 || isempty(ylabels)
        ylabels = NumArray2StringCell(size(yData,2));
        % rowNames = [1:size(TemporalData,1)]; % Create a numerical array 
        % rowNames = arrayfun(@num2str,rowNames,'UniformOutput',0); % The NUM2STR function converts a number 
        % to the string representation of that number. This function is applied to each cell in the A array/matrix 
        % using ARRAYFUN. The 'UniformOutput' parameter is set to 0 to instruct CELLFUN to encapsulate the outputs into a cell array.
    end

    if isempty(plotWhere)
        fig_canvas(1,'unit_width',0.9,'unit_height',0.9);
        plotWhere = gca;
    end

    trace_num = size(yData,2); % number of traces = number of yData columns
    trace_length = size(yData,1); % data point number of yData
    trace_y_pos = [0:-20:(trace_num-1)*-20];
    trace_y_shift = repmat(trace_y_pos,trace_length,1);
    yData_shift = yData+trace_y_shift;
    trace_y_tick = ylabels;
    % spikeFrames_all_cell = cell(trace_num,1);

    plot(xData,yData_shift,'LineWidth',LineWidth,'Color',line_color);
    xlim([xData(1) xData(end)]); % set the x-axis limit to the beginnin and the end of xData
    ymax = max(yData_shift(:,1)); % Get the largest y value
    ymin = min(yData_shift(:,end)); % Get the smallest y value
    ylim([ymin-plotInterval ymax+plotInterval]) % add plotInterval to ymax and ymin and use them for ylim
    hold on

    if isempty(marker1_xData)
        marker1_xData = cell(1,trace_num);
    end
    if isempty(marker2_xData)
        marker2_xData = cell(1,trace_num);
    end

    if plot_marker
        for tn = 1:trace_num
            marker1_xData_trace = marker1_xData{tn};
            [~,~,marker1_xData_idx] = intersect(marker1_xData_trace,xData); % Get the locations of the time points in xData
            marker1_yData_trace = yData_shift(marker1_xData_idx,tn); % y values of trace at the marker1_xData
            scatter(marker1_xData_trace,marker1_yData_trace,marker1_style,...
                'MarkerEdgeColor',marker1_color,'LineWidth', 1);

            marker2_xData_trace = marker2_xData{tn};
            [~,~,marker2_xData_idx] = intersect(marker2_xData_trace,xData); % Get the locations of the time points in xData
            marker2_yData_trace = yData_shift(marker2_xData_idx,tn); % y values of trace at the marker2_xData
            scatter(marker2_xData_trace,marker2_yData_trace,marker2_style,...
                'MarkerEdgeColor',marker2_color,'LineWidth', 1);
        end
    end

    set(gca,'box','off')
    set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
    yticks(flip(trace_y_pos));
    yticklabels(flip(trace_y_tick));
    set(gca,'Xtick',[xData(1):xtickInt:xData(end)]);

    if ~isempty(shadeData)
        shade_type_num = numel(shadeData);
        for stn = 1:shade_type_num
            draw_WindowShade(plotWhere,shadeData{stn},'shadeColor',shadeColor{stn});
        end
    end

    set(gca,'children',flipud(get(gca,'children')))

    title(titleStr);
    xlabel ('Time (s)');
end
