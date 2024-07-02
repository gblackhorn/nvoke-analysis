function [barInfo,varargout] = barplot_with_errBar(barData,varargin)
    % bar plot with error bar (standard error)
    % data: numeric or cell array
    %   - row vector: each number is a bar value
    %   - column vector: each column for a bar. calculate the mean and ste for bar and error bar, respectively
    %   - cell: each cell for a bar

    % Defaults
    jitterAmount = 0.5;

    % Create input parser
    p = inputParser;
    
    % Required argument
    addRequired(p, 'barData', @(x) isnumeric(x) || iscell(x));
    
    % Optional parameters with default values
    addParameter(p, 'errBarVal', [], @isnumeric);
    addParameter(p, 'dataNumVal', [], @isnumeric);
    addParameter(p, 'barNamePrefix', 'Category', @ischar);
    addParameter(p, 'unit_width', 0.4, @isnumeric);
    addParameter(p, 'unit_height', 0.4, @isnumeric);
    addParameter(p, 'column_lim', 1, @isnumeric);
    addParameter(p, 'TickAngle', 0, @isnumeric);
    addParameter(p, 'barEdgeColor', 'none', @ischar);
    addParameter(p, 'barFaceColor', '#4D4D4D', @ischar);
    addParameter(p, 'errBarLineWidth', 2, @isnumeric);
    addParameter(p, 'errBarCapSize', 10, @isnumeric);
    addParameter(p, 'FontSize', 14, @isnumeric);
    addParameter(p, 'FontWeight', 'bold', @ischar);
    addParameter(p, 'plotWhere', []);
    addParameter(p, 'barX', [], @isnumeric);
    addParameter(p, 'barNames', [], @(x) iscell(x) || ischar(x));
    
    % Parse inputs
    parse(p, barData, varargin{:});
    
    % Assign parsed values to variables
    params = p.Results;
    
    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if isempty(params.plotWhere)
        f = figure('Units', 'normalized', 'Position', [0.1, 0.1, params.unit_width, params.unit_height]);
    else
        axes(params.plotWhere);
    end
    hold on

    % Check the barData type and make the calculation for plot if necessary 
    [barVal, errBarVal, dataNumVal, barNum] = calculateBarValues(params.barData, params.errBarVal, params.dataNumVal);
    
    if isempty(params.barX)
        params.barX = 1:barNum;
    end
    
    nNumStr = arrayfun(@num2str, dataNumVal, 'UniformOutput', false);
    
    % Bar name for each bar
    if isempty(params.barNames)
        params.barNames = arrayfun(@(x) sprintf('%s %d', params.barNamePrefix, x), 1:barNum, 'UniformOutput', false);
    end

    % Plot bar 
    hB = bar(gca, params.barX, barVal, 'EdgeColor', params.barEdgeColor, 'FaceColor', params.barFaceColor);

    % Plot error bar
    if iscell(params.barX)
        params.barX = categorical(params.barX);
    end
    hEB = errorbar(gca, params.barX, barVal, errBarVal, 'LineStyle', 'None');
    set(hEB, 'Color', 'k', 'LineWidth', params.errBarLineWidth, 'CapSize', params.errBarCapSize);

    % Plot scatter points with jitter
    plotScatterWithJitter(params.barData, params.barX, barNum, jitterAmount);

    % Add data number to the bottom of each bar
    addDataNumber(params.barX, dataNumVal);

    % Modify the style of plot
    stylePlot(gca, params.TickAngle, params.FontSize, params.FontWeight, params.barNames, params.barX);

    % Save the calculated data (mean for bar and ste for error bar) to a structure
    barInfo = struct('barNames', params.barNames, 'barVal', num2cell(barVal), 'errBarVal', num2cell(errBarVal));

    hold off
end

function [barVal, errBarVal, dataNumVal, barNum] = calculateBarValues(barData, errBarVal, dataNumVal)
    if isnumeric(barData) && isrow(barData) % Use the given barData and errBar to plot directly
        barVal = barData;
        barNum = numel(barData);
    elseif isnumeric(barData) && ismatrix(barData) % Calculate mean and ste of every column for plotting
        barVal = mean(barData, 1);
        errBarVal = arrayfun(@(cn) ste(barData(:,cn)), 1:size(barData,2));
        barNum = size(barData, 2);
        dataNumVal = repmat(size(barData, 1), 1, barNum);
    elseif iscell(barData) % Calculate mean and ste of every cell for plotting
        barVal = cellfun(@(x) mean(x(:), "omitnan"), barData);
        errBarVal = cellfun(@(x) ste(x, 'omitnan', true), barData);
        barNum = numel(barData);
        dataNumVal = cellfun(@(x) sum(~isnan(x)), barData);
    end
end

function plotScatterWithJitter(barData, barX, barNum, jitterAmount)
    if isnumeric(barData) && ismatrix(barData)
        for cn = 1:barNum
            jitterX = barX(cn) + (rand(size(barData(:, cn))) - 0.5) * jitterAmount;
            scatter(jitterX, barData(:, cn), 'k');
        end
    elseif iscell(barData)
        for cn = 1:barNum
            jitterX = barX(cn) + (rand(length(barData{cn}), 1) - 0.5) * jitterAmount;
            scatter(jitterX, barData{cn}, 'k');
        end
    end
end

function addDataNumber(barX, dataNumVal)
    yL = ylim;
    nNumYval = yL(1) + 0.05 * (yL(2) - yL(1));
    nNumY = repmat(nNumYval, 1, numel(barX));
    nNumStr = arrayfun(@num2str, dataNumVal, 'UniformOutput', false);
    text(barX, nNumY, nNumStr, 'vert', 'bottom', 'horiz', 'center', 'Color', 'white');
end

function stylePlot(gcaHandle, TickAngle, FontSize, FontWeight, barNames, barX)
    set(gcaHandle, 'box', 'off');
    set(gcaHandle, 'TickDir', 'out');
    set(gcaHandle, 'FontSize', FontSize);
    set(gcaHandle, 'FontWeight', FontWeight);
    xtickangle(TickAngle);
    set(gcaHandle, 'XTick', barX);
    set(gcaHandle, 'xticklabel', barNames);
end








% function [barInfo,varargout] = barplot_with_errBar(barData,varargin)
%     % bar plot with error bar (standard error)

%     % data:  or cell array
%     %   - row vector: each number is a bar value
%     %   - column vector: each column for a bar. calculate the mean and ste for bar and error bar, respectively
%     %   - cell: each cell for a bar

%     % Defaults
%     errBarVal = [];
%     dataNumVal = [];
%     % errBarType = 'ste'; % ste/std
%     barNamePrefix = 'Category';
%     % default figure parameters
%     unit_width = 0.4; % normalized to display
%     unit_height = 0.4; % normalized to display
%     column_lim = 1; % number of axes column

%     TickAngle = 0;
%     barEdgeColor = 'none';
%     barFaceColor = '#4D4D4D';
%     errBarLineWidth = 2;
%     errBarCapSize = 10;
%     FontSize = 14;
%     FontWeight = 'bold';


%     for ii = 1:2:(nargin-1)
%         if strcmpi('barX', varargin{ii})
%             barX = varargin{ii+1};
%         elseif strcmpi('barNames', varargin{ii})
%             barNames = varargin{ii+1};
%         elseif strcmpi('errBarVal', varargin{ii})
%             errBarVal = varargin{ii+1};
%         elseif strcmpi('dataNumVal', varargin{ii})
%             dataNumVal = varargin{ii+1};
%         elseif strcmpi('plotWhere', varargin{ii})
%             plotWhere = varargin{ii+1};
%         elseif strcmpi('TickAngle', varargin{ii})
%             TickAngle = varargin{ii+1};
%         elseif strcmpi('FontSize', varargin{ii})
%             FontSize = varargin{ii+1};
%         elseif strcmpi('FontWeight', varargin{ii})
%             FontWeight = varargin{ii+1};
%         end
%     end


%     % Create a new figure window or use the existing axis if 'plotWhere' variable exists
%     if ~exist('plotWhere','var')
%         f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
%     else
%         plotWhere;
%     end
%     hold on


%     % check the barData type and make the calculation for plot if necessary 
%     if isnumeric(barData) && isrow(barData) % use the given barData and errBar to plot directly
%         barVal = barData;
%         % errBarVal = errBar;
%         barNum = numel(barData);
%     elseif isnumeric(barData) && ismatrix(barData) % calculate mean and ste of every column for plotting
%         barVal = mean(barData,1);
%         errBarVal = NaN(size(barVal));
%         for cn = 1:size(barData,2)
%             errBarVal(cn) = ste(barData(:,cn));
%         end
%         barNum = size(barData,2);
%         dataNumVal = repmat(size(barData,1),1,barNum);
%     elseif iscell(barData) % calculate mean and ste of every cell for plotting
%         barVal = cellfun(@(x) mean(x(:), "omitnan"),barData);
%         errBarVal = cellfun(@(x) ste(x, 'omitnan', true),barData);
%         barNum = numel(barData);
%         dataNumVal = cellfun(@(x) sum(~isnan(x)),barData);
%         % dataNumVal = cellfun(@(x) numel(x),barData);
%     end

%     if ~exist('barX','var')
%         barX = 1:barNum;
%     end
%     nNumStr = num2cell(dataNumVal(:)');
%     nNumStr = cellfun(@(x) num2str(x),nNumStr,'UniformOutput',false);

%     % bar name for each bar
%     if ~exist('barNames','var')
%         barSN = num2cell([1:barNum]); % serial numbers of bars
%         barNames = cellfun(@(x) sprintf('%s %d',barNamePrefix,x),barSN,'UniformOutput',false);
%     end

%     % plot bar 
%     hB = bar(gca,barX,barVal,'EdgeColor', barEdgeColor, 'FaceColor', barFaceColor);

%     % plot error bar
%     if iscell(barX)
%         barX = categorical(barX);
%     end
%     hEB = errorbar(gca,barX,barVal,errBarVal,'LineStyle','None');
%     set(hEB,'Color','k','LineWidth',errBarLineWidth,'CapSize',errBarCapSize);

%     % plot scatter points with jitter
%     jitterAmount = 0.5; % Adjust jitter amount as needed
%     if isnumeric(barData) && ismatrix(barData)
%         for cn = 1:barNum
%             jitterX = barX(cn) + (rand(size(barData(:, cn))) - 0.5) * jitterAmount;
%             scatter(jitterX, barData(:, cn), 'k'); % , 'filled'
%         end
%     elseif iscell(barData)
%         for cn = 1:barNum
%             jitterX = barX(cn) + (rand(length(barData{cn}), 1) - 0.5) * jitterAmount;
%             scatter(jitterX, barData{cn}, 'k'); % , 'filled'
%         end
%     end

%     % add data number to the bottom of each bar
%     yL = ylim;
%     nNumYval = yL(1)+0.05*(yL(2)-yL(1));
%     nNumY = repmat(nNumYval,1,barNum);
%     text(barX,nNumY,nNumStr,'vert','bottom','horiz','center', 'Color', 'white');

%     % modify the style of plot
%     set(gca,'box','off')
%     set(gca,'TickDir','out')
%     set(gca, 'FontSize', FontSize)
%     set(gca, 'FontWeight', FontWeight)
%     xtickangle(TickAngle)
%     set(gca, 'XTick', barX)
%     set(gca, 'xticklabel', barNames)

%     % save the calculated data (mean for bar and ste for error bar) to a structure
%     barInfo = struct('barNames',barNames,'barVal',num2cell(barVal),'errBarVal',num2cell(errBarVal));

%     hold off
% end

