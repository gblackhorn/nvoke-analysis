function [yFit,PearsonCorrCoef,rsq,varargout] = LinearFitPlotTest(xData,yData,varargin)
    % Linear fit the xData and yData
    % Return the fitted y, PearsonCorrCoef, and R-squared (rsq)

    % Pearson Correlation Coefficient: Typically, a value above 0.7 or below -0.7 indicates a strong
    % correlation. Values between 0.5 to 0.7 (or -0.5 to -0.7) suggest a moderate correlation, and
    % values below 0.3 (or above -0.3) indicate a weak correlation.

    % R-squared Value: Higher R-squared values, closer to 1, suggest a better fit of the model to
    % your data. Generally, an R-squared value above 0.7 is considered good, indicating that a
    % significant proportion of the variance in your dependent variable is explained by the
    % independent variable(s) in your model.


    % default
    plotLine = false; % true/false. If true, plot the fitting line
    unit_width = 0.4; % normalized to display
    unit_height = 0.4; % normalized to display
    column_lim = 1; % number of axes column

    LineColor = 'k';
    LineWidth = 2;

    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('plotLine', varargin{ii})
            plotLine = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('LineColor', varargin{ii})
            LineColor = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('LineWidth', varargin{ii})
            LineWidth = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        end
    end 

    % Create a new figure window or use the existing axis if 'plotWhere' variable exists
    if ~exist('plotWhere','var')
        f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
    else
        plotWhere;
    end

    % Linear fitting 
    [polyCoef,errEstStruct] = polyfit(xData,yData,1);
    yFit = polyval(polyCoef,xData,errEstStruct);



    % Pearson Correlation Test

    % R (Correlation Coefficients Matrix): R(1,2) and R(2,1) are the Pearson correlation
    % coefficients between x and y. These two values are identical and represent the
    % strength and direction of the linear relationship between x and y.

    % P (P-values Matrix): This matrix also has the same structure. The p-values corresponding to
    % the correlation coefficients (usually P(1,2) and P(2,1)) indicate the statistical
    % significance of the correlation.

    [R, P] = corrcoef(xData, yData);
    PearsonCorrCoef = R(1,2);
    PearsonCorrCoefPval = P(1,2);



    % Calculating the R-squared (rsq)
    yResid = yData - yFit; 
    ssResid = sum(yResid.^2); 
    ssTotal = (length(yData)-1) * var(yData); 
    rsq = 1 - ssResid/ssTotal;


    if plotLine
        plot(gca, xData, yFit, '-', 'Color', LineColor, 'LineWidth', LineWidth); 
    end

    varargout{1} = PearsonCorrCoefPval;
    varargout{2} = polyCoef;
    varargout{3} = errEstStruct;
end
