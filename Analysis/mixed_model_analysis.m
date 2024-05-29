function [varargout] = mixed_model_analysis(dataStruct, responseVar, groupVar, hierarchicalVars, varargin)
    % This function is designed to analyze data with a hierarchical or nested structure, where
    % observations are not independent. It can be used to analyze data using either Linear Mixed Models (LMM)
    % or Generalized Linear Mixed Models (GLMM).

    % - Hierarchical Data: Data with multiple levels of grouping (e.g., measurements nested within
    % ROIs, which are nested within trials, which are nested within animals).
    % - Fixed Effects: Effects of interest (e.g., treatment effects or subNuclei locations) can be
    % modeled as fixed effects.
    % - Random Effects: Variability within and between these nested levels can be modeled as random
    % effects.
    % - GLMM: Allows for non-normal distributions and link functions.

    % Input:
    % - dataStruct: A structure containing the data to be analyzed.
    % - responseVar: A string specifying the name of the response variable (e.g., 'FWHM').
    % - groupVar: A string specifying the name of the grouping variable (e.g., 'subNuclei').
    % - hierarchicalVars: A cell array of strings specifying the names of the hierarchical variables
    %   (e.g., {'trialName', 'roiName'}).
    % - varargin: Optional parameters including:
    %   - 'modelType': 'LMM' (default) or 'GLMM'
    %   - 'distribution': Distribution for GLMM 
    %   - 'link': Link function for GLMM 
    %   - 'dispStat': true (default is false) to display statistics

    % Choosing Distribution and Link Functions for GLMM
        % Poisson Distribution (for count data)
            % Use When: Your response variable represents counts (e.g., number of events).
            % Distribution: 'poisson'
            % Link Function: 'log'
            % Example: Analyzing the number of occurrences of an event in a fixed period.
        % Binomial Distribution (for binary or proportion data)
            % Use When: Your response variable is binary (e.g., success/failure) or proportions.
            % Distribution: 'binomial'
            % Link Function: 'logit'
            % Example: Analyzing the presence or absence of a trait.
        % Gamma Distribution (for continuous, positively skewed data)
            % Use When: Your response variable is continuous and positively skewed.
            % Distribution: 'gamma'
            % Link Function: 'log'
            % Example: Analyzing skewed continuous variables like response times or expenditures.
        % Inverse Gaussian Distribution (for continuous, positively skewed data)
            % Use When: Your response variable is continuous and positively skewed, especially when data variance increases with the mean.
            % Distribution: 'inverse gaussian'
            % Link Function: 'log'
            % Example: Analyzing highly skewed continuous variables where the variance is related to the mean.
        % Negative Binomial Distribution (for overdispersed count data)
            % Use When: Your count data shows overdispersion (variance greater than the mean).
            % Distribution: 'negative binomial'
            % Link Function: 'log'
            % Example: Analyzing count data with overdispersion, like the number of customer complaints per day.

    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'modelType', 'LMM', @(x) ismember(x, {'LMM', 'GLMM'}));
    addParameter(p, 'distribution', 'gamma', @ischar);
    addParameter(p, 'link', 'log', @ischar);
    addParameter(p, 'dispStat', false, @islogical);
    parse(p, varargin{:});
    modelType = p.Results.modelType;
    distribution = p.Results.distribution;
    link = p.Results.link;
    dispStat = p.Results.dispStat;

    % Convert the specified fields to categorical and collect all necessary fields
    LMMdata.(responseVar) = [dataStruct.(responseVar)]';
    LMMdata.(groupVar) = categorical({dataStruct.(groupVar)}');
    for i = 1:length(hierarchicalVars)
        LMMdata.(hierarchicalVars{i}) = categorical({dataStruct.(hierarchicalVars{i})}');
    end
    
    % Convert the structured data to a table
    tbl = struct2table(LMMdata);
    
    % Construct the formula for the mixed model
    % - Fixed effects: groupVar
    % - Random effects: hierachiRandom
    hierachiRandom = sprintf('(1|%s)', hierarchicalVars{1});
    if length(hierarchicalVars) > 1
        for i = 2:length(hierarchicalVars)
            hierachiRandom = strcat(hierachiRandom, sprintf(' + (1|%s:%s)', hierarchicalVars{i-1}, hierarchicalVars{i}));
        end
    end
    formula = sprintf('%s ~ 1 + %s + %s', responseVar, groupVar, hierachiRandom);
    
    % Fit the model
    if strcmp(modelType, 'LMM')
        lme = fitlme(tbl, formula);
    elseif strcmp(modelType, 'GLMM')
        lme = fitglme(tbl, formula, 'Distribution', distribution, 'Link', link);
    else
        error('Unsupported model type');
    end

    % Optionally display the model summary
    if dispStat
        disp(lme);
    end

    % Extract fixed effects
    fixedEffectsEstimates = fixedEffects(lme);
    
    % Optionally display fixed effects
    if dispStat
        disp('Fixed Effects:');
        disp(fixedEffectsEstimates);
    end
    
    % Extract random effects
    randomEffectsTable = randomEffects(lme);
    
    % Optionally display random effects
    if dispStat
        disp('Random Effects:');
        disp(randomEffectsTable);
    end

    % Extract the coefficients and p-values
    intercept = lme.Coefficients.Estimate(1);
    groupEffect = lme.Coefficients.Estimate(2:end);
    pValueGroup = lme.Coefficients.pValue(2:end);

    % Optionally display the results in a readable format
    if dispStat
        fprintf('Intercept (Baseline): %.4f\n', intercept);
        for i = 1:length(groupEffect)
            fprintf('Effect of %s (compared to baseline): %.4f (p-value: %.4f)\n', lme.Coefficients.Name{i+1}, groupEffect(i), pValueGroup(i));
        end
    end
    
    % ANOVA is performed on the fitted model using the anova function to test the significance of
    % the fixed effects. It tells whether there are any statistically significant differences
    % between the groups.
    if strcmp(modelType, 'LMM')
        anovaResults = anova(lme);
    else
        anovaResults = []; % ANOVA is not typically used for GLMMs in the same way
    end
    
    % Optionally display ANOVA results
    if dispStat && strcmp(modelType, 'LMM')
        disp('ANOVA Results:');
        disp(anovaResults);
    end
    
    % Prepare output variables
    varargout{1} = lme;
    varargout{2} = anovaResults;

    % Initialize multi-comparison results
    multiComparisonResults = [];
    statInfo = struct('method', {}, 'group1', {}, 'group2', {}, 'p', {}, 'h', {});

    % Extract group variable levels
    groupLevels = categories(tbl.(groupVar));
    
    % Perform multiple comparisons if the group effect is significant
    if strcmp(modelType, 'LMM') && any(anovaResults.pValue < 0.05)
        if length(groupLevels) > 2
            % Perform multiple comparisons manually
            [multiComparisonResults, statInfo] = performPostHocComparisons(lme, groupLevels, dispStat);
        else
            % Extract the p-value from the fixed effects for two groups
            pValue = pValueGroup(1);
            hValue = pValue < 0.05;
            statInfo = struct('method', 'Linear-mixed-model', 'group1', groupLevels{1}, 'group2', groupLevels{2}, 'p', pValue, 'h', hValue);
            if dispStat
                fprintf('\nFixed Effects Results:\n%s vs. %s: p-value = %.4f, h = %d\n', ...
                    groupLevels{1}, groupLevels{2}, pValue, hValue);
            end
        end
    elseif strcmp(modelType, 'GLMM') && length(groupLevels) == 2
        % Perform post-hoc comparison for GLMM with two groups
        pValue = pValueGroup(1);
        hValue = pValue < 0.05;
        statInfo = struct('method', 'Generalized-linear-mixed-model', 'group1', groupLevels{1}, 'group2', groupLevels{2}, 'p', pValue, 'h', hValue);
        if dispStat
            fprintf('\nFixed Effects Results:\n%s vs. %s: p-value = %.4f, h = %d\n', ...
                groupLevels{1}, groupLevels{2}, pValue, hValue);
        end
    end

    % Add multi-comparison results and statInfo to the output
    varargout{3} = multiComparisonResults;
    varargout{4} = statInfo;
end

function [results, statInfo] = performPostHocComparisons(lme, groupLevels, dispStat)
    % Extract the fixed effects and their covariance matrix
    fixedEffectsEstimates = fixedEffects(lme);
    covarianceMatrix = lme.CoefficientCovariance;

    % Number of groups
    numGroups = length(groupLevels);

    % Prepare results storage
    comparisons = nchoosek(1:numGroups, 2);
    results = [];
    statInfo = struct('method', {}, 'group1', {}, 'group2', {}, 'p', {}, 'h', {});

    % Perform pairwise comparisons
    for i = 1:size(comparisons, 1)
        group1 = comparisons(i, 1);
        group2 = comparisons(i, 2);
        
        % Estimate difference and its standard error
        estimateDiff = fixedEffectsEstimates(group1 + 1) - fixedEffectsEstimates(group2 + 1);
        seDiff = sqrt(covarianceMatrix(group1 + 1, group1 + 1) + covarianceMatrix(group2 + 1, group2 + 1) - 2 * covarianceMatrix(group1 + 1, group2 + 1));
        
        % Calculate confidence intervals and p-values
        tValue = estimateDiff / seDiff;
        df = lme.DFE;
        pValue = 2 * tcdf(-abs(tValue), df);
        hValue = pValue < 0.05;
        
        % Store the results
        results = [results; group1, group2, estimateDiff, seDiff, tValue, df, pValue, hValue];
        
        % Append results to statInfo
        statInfo(end+1) = struct('method', 'Linear-mixed-model', 'group1', groupLevels{group1}, 'group2', groupLevels{group2}, 'p', pValue, 'h', hValue); %#ok<AGROW>
    end

    % Optionally display pairwise comparison results
    if dispStat
        fprintf('\nPairwise Comparisons:\n');
        for i = 1:size(results, 1)
            fprintf('%s vs. %s: Difference = %.4f, 95%% CI = [%.4f, %.4f], p-value = %.4f, h = %d\n', ...
                groupLevels{results(i, 1)}, groupLevels{results(i, 2)}, results(i, 3), ...
                results(i, 4), results(i, 5), results(i, 6), results(i, 7));
        end
    end
end
