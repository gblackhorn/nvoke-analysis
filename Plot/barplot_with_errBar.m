function [barInfo,varargout] = barplot_with_errBar(barData,varargin)
    % bar plot with error bar (standard error)

    % data:  or cell array
    %   - row vector: each number is a bar value
    %   - column vector: each column for a bar. calculate the mean and ste for bar and error bar, respectively
    %   - cell: each cell for a bar

    % Defaults
    errBarVal = [];
    dataNumVal = [];
    % errBarType = 'ste'; % ste/std
    barNamePrefix = 'Category';
    % default figure parameters
    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    TickAngle = 0;
    barEdgeColor = 'none';
    barFaceColor = '#4D4D4D';
    errBarLineWidth = 2;
    errBarCapSize = 10;
    FontSize = 14;
    FontWeight = 'bold';


    for ii = 1:2:(nargin-1)
        if strcmpi('barNames', varargin{ii})
            barNames = varargin{ii+1};
        elseif strcmpi('errBarVal', varargin{ii})
            errBarVal = varargin{ii+1};
        elseif strcmpi('dataNumVal', varargin{ii})
            dataNumVal = varargin{ii+1};
        elseif strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1};
        elseif strcmpi('TickAngle', varargin{ii})
            TickAngle = varargin{ii+1};
        elseif strcmpi('FontSize', varargin{ii})
            FontSize = varargin{ii+1};
        elseif strcmpi('FontWeight', varargin{ii})
            FontWeight = varargin{ii+1};
        end
    end


    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end
    hold on


    % check the barData type and make the calculation for plot if necessary 
    if isnumeric(barData) && isrow(barData) % use the given barData and errBar to plot directly
        barVal = barData;
        % errBarVal = errBar;
        barNum = numel(barData);
    elseif isnumeric(barData) && ismatrix(barData) % calculate mean and ste of every column for plotting
        barVal = mean(barData,1);
        errBarVal = NaN(size(barVal));
        for cn = 1:size(barData,2)
            errBarVal(cn) = ste(barData(:,cn));
        end
        barNum = size(barData,2);
        dataNumVal = repmat(size(barData,1),1,barNum);
    elseif iscell(barData) % calculate mean and ste of every cell for plotting
        barVal = cellfun(@(x) mean(x(:)),barData);
        errBarVal = cellfun(@(x) ste(x),barData);
        barNum = numel(barData);
        dataNumVal = cellfun(@(x) numel(x),barData);
    end
    barX = 1:barNum;
    nNumStr = num2cell(dataNumVal(:)');
    nNumStr = cellfun(@(x) num2str(x),nNumStr,'UniformOutput',false);

    % bar name for each bar
    if ~exist('barNames','var')
        barSN = num2cell([1:barNum]); % serial numbers of bars
        barNames = cellfun(@(x) sprintf('%s %d',barNamePrefix,x),barSN,'UniformOutput',false);
    end

    % plot bar 
    hB = bar(gca,barX,barVal,'EdgeColor', barEdgeColor, 'FaceColor', barFaceColor);

    % plot error bar
    hEB = errorbar(gca,barX,barVal,errBarVal,'LineStyle','None');
    set(hEB,'Color','k','LineWidth',errBarLineWidth,'CapSize',errBarCapSize);

    % add data number to the bottom of each bar
    yL = ylim;
    nNumYval = yL(1)+0.05*(yL(2)-yL(1));
    nNumY = repmat(nNumYval,1,barNum);
    text(barX,nNumY,nNumStr,'vert','bottom','horiz','center', 'Color', 'white');

    % modify the style of plot
    set(gca,'box','off')
    set(gca,'TickDir','out')
    set(gca, 'FontSize', FontSize)
    set(gca, 'FontWeight', FontWeight)
    xtickangle(TickAngle)
    set(gca, 'XTick', barX)
    set(gca, 'xticklabel', barNames)

    % save the calculated data (mean for bar and ste for error bar) to a structure
    barInfo = struct('barNames',barNames,'barVal',num2cell(barVal),'errBarVal',num2cell(errBarVal));

    hold off
end

