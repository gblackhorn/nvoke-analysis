function visualizeMeFitting(me, groupVar, varargin)
    % Visualize the fitting of mixed-model (me)

    % me: The output of mixed-model, such as fitglme
    %   - me = fitglme(...)

    % groupVar: The name of the fixed effect in the formula
    %    - Data in it must be numeric or categorical


    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'titlePrefix', '', @ischar);
    addParameter(p, 'figName', 'OriginalData vs fitData', @ischar);

    parse(p, varargin{:});
    titlePrefix = p.Results.titlePrefix;
    figName = p.Results.figName;


    % Get the formula of the mixed-model
    formulaStr = char(me.Formula);

    % Get the name of the response
    responseVar = me.ResponseName; 

    % Get the group data
    groupData = me.Variables.(groupVar);

    % Get the responseData
    responseData = me.Variables.(responseVar);

    % Check if groupVar is categorical
    if iscategorical(groupData)
        groupLevels = categories(groupData);
        groupRange = categorical(groupLevels);
        numericGroupData = double(groupData); % Convert categorical to numeric for plotting
        numericGroupRange = double(groupRange); % Convert categorical to numeric for predictions
    else
        % Generate predictions over a range of numeric xdata values
        numericGroupData = groupData;
        groupRange = linspace(min(groupData), max(groupData), 100)';
        numericGroupRange = groupRange;
    end

    newData = table(groupRange, 'VariableNames', {groupVar});

    % Add columns for other variables in the model with default values
    otherVars = me.Variables.Properties.VariableNames;
    otherVars = setdiff(otherVars, {groupVar, responseVar});

    for i = 1:length(otherVars)
        varName = otherVars{i};
        if iscategorical(me.Variables.(varName))
            % Use the first category as default
            newData.(varName) = repmat(me.Variables.(varName)(1), height(newData), 1);
        elseif isnumeric(me.Variables.(varName))
            % Use the mean of the variable as default
            newData.(varName) = repmat(mean(me.Variables.(varName)), height(newData), 1);
        end
    end

    % Predict using the model (newData should contain only predictor variables)
    predictions = predict(me, newData);

    % Visualize the original data and GLMM fit in grouped bar style
    figure('Name', figName);
    hold on;

    % Define colors
    rawColor = [0.3, 0.3, 0.8];  % Soft blue
    fitColor = [0.8, 0.3, 0.3];  % Soft red

    % Compute the mean of response data for each group (for categorical data)
    if iscategorical(groupData)
        [grp, ~, grpIdx] = unique(groupData);
        meanResponse = splitapply(@mean, responseData, grpIdx);
        
        % Grouped bar plot for original and fitted data
        barData = [meanResponse, predictions];
        bar(categorical(groupRange), barData, 'grouped');
        legend({'Original Data', 'GLMM Fit'}, 'Location', 'Best');
    else
        % Compute mean response for each unique groupData value
        [uniqueGroupData, ~, grpIdx] = unique(groupData);
        meanResponse = splitapply(@mean, responseData, grpIdx);

        % Grouped bar plot for original and fitted data
        barData = [meanResponse, predictions];
        bar(uniqueGroupData, barData, 'grouped');
        legend({'Original Data', 'GLMM Fit'}, 'Location', 'Best');
    end

    xlabel(groupVar);
    ylabel(responseVar);
    titleStr = sprintf('%s %s', titlePrefix, formulaStr);
    title(titleStr);
    grid on;
    hold off;
end
