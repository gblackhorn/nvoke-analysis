function [me, varargout] = mixed_model_analysis(dataStruct, responseVar, groupVar, hierarchicalVars, varargin)
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

        % Choosing Distribution and Link Functions for GLMM. 
        % Note: When 'log' is used for 'link', the 'Estimate', 'Lower', and 'Upper' bounds in the 
        % results will be on log scale 
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
    addParameter(p, 'modelType', 'GLMM', @(x) ismember(x, {'LMM', 'GLMM'}));
    addParameter(p, 'distribution', 'gamma', @ischar);
    addParameter(p, 'link', 'log', @ischar);
    addParameter(p, 'dispStat', false, @islogical);
    parse(p, varargin{:});
    modelType = p.Results.modelType;
    distribution = p.Results.distribution;
    link = p.Results.link;
    dispStat = p.Results.dispStat;

    % Convert the specified fields to categorical and collect all necessary fields
    responseValues = [dataStruct.(responseVar)]';
    
    % Find valid indices (non-NaN) for response values
    validIndices = ~isnan(responseValues);
    
    % Filter out NaNs from response values and corresponding fields
    MMdata.(responseVar) = responseValues(validIndices);
    MMdata.(groupVar) = {dataStruct(validIndices).(groupVar)}';
    % MMdata.(groupVar) = categorical({dataStruct(validIndices).(groupVar)}');
    for i = 1:length(hierarchicalVars)
        MMdata.(hierarchicalVars{i}) = categorical({dataStruct(validIndices).(hierarchicalVars{i})}');
    end

    % Convert the groupVar to string if they are numbers. Check the first entry
    if isnumeric(dataStruct(1).(groupVar))
        MMdata.(groupVar) = cellfun(@num2str, MMdata.(groupVar), 'UniformOutput',false);
    end

    % Convert the groupVar to categorical
    MMdata.(groupVar) = categorical(MMdata.(groupVar));

    % Convert the structured data to a table
    tbl = struct2table(MMdata);
    
    % Construct the formula for the mixed model
    % - Fixed effects: groupVar
    % - Random effects: hierarchicalVars
    hierachiRandom = sprintf('(1|%s)', hierarchicalVars{1});
    if length(hierarchicalVars) > 1
        for i = 2:length(hierarchicalVars)
            hierachiRandom = strcat(hierachiRandom, sprintf(' + (1|%s:%s)', hierarchicalVars{i-1}, hierarchicalVars{i}));
        end
    end
    formula = sprintf('%s ~ 1 + %s + %s', responseVar, groupVar, hierachiRandom);
    formula_noFix = sprintf('%s ~ 1 + %s', responseVar, hierachiRandom); % plug off the fixed effect
    
    % Fit the model
    if strcmp(modelType, 'LMM')
        me = fitlme(tbl, formula);
        me_noFix = fitlme(tbl, formula_noFix);
    elseif strcmp(modelType, 'GLMM')
        me = fitglme(tbl, formula, 'Distribution', distribution, 'Link', link);
        me_noFix = fitglme(tbl, formula_noFix, 'Distribution', distribution, 'Link', link);
    else
        error('Unsupported model type');
    end

    % Optionally display the model summary
    if dispStat
        disp(me);
    end

    % Extract fixed effects
    [fixedEffectsEstimates, ~, fixedEffectsStats] = fixedEffects(me);
    
    % Optionally display fixed effects
    if dispStat
        disp('Fixed Effects:');
        disp(fixedEffectsEstimates);
    end
    
    % Extract random effects
    randomEffectsTable = randomEffects(me);
    
    % Optionally display random effects
    if dispStat
        disp('Random Effects:');
        disp(randomEffectsTable);
    end

    % Extract the coefficients and p-values
    intercept = me.Coefficients.Estimate(1);
    groupEffect = me.Coefficients.Estimate(2:end);
    pValueGroup = me.Coefficients.pValue(2:end);

    % Optionally display the results in a readable format
    if dispStat
        fprintf('Intercept (Baseline): %.4f\n', intercept);
        for i = 1:length(groupEffect)
            fprintf('Effect of %s (compared to baseline): %.4f (p-value: %.4f)\n', me.Coefficients.Name{i+1}, groupEffect(i), pValueGroup(i));
        end
    end

    % Extract group variable levels
    groupLevels = categories(tbl.(groupVar));

    % Replace the Name of fixed effect with the categories in the groupVar field
    fixedEffectsStats.Name = groupLevels; 

    % Convert the values on log scale to linear scale
    if strcmpi(modelType,'GLMM') && strcmpi(me.Link.Name,'log')
        fixedEffectsStats = log2linear(fixedEffectsStats);
    end
    fixedEffectsStats = dataset2table(fixedEffectsStats); % Convert the dataset to a table
    varargout{1} = fixedEffectsStats;
    
    % ANOVA is performed on the fitted model using the anova function to test the significance of
    % the fixed effects. It tells whether there are any statistically significant differences
    % between the groups.
    anovaResults = anova(me);
    % if strcmp(modelType, 'LMM')
    %     anovaResults = anova(lme);
    % else
    %     anovaResults = []; % ANOVA is not typically used for GLMMs in the same way
    % end
    
    % Optionally display ANOVA results
    if dispStat && strcmp(modelType, 'LMM')
        disp('ANOVA Results:');
        disp(anovaResults);
    end
    
    % Prepare output variables
    % varargout{1} = lme;
    % varargout{2} = lme_noFix;
    % varargout{2} = anovaResults;

    % Compare the GLMM without the fix effects (groupVar), lme_noFix, to the GLMM with both fixed and
    % random effects, lme, and return the results of a likelihood ratio test (chiLRT)
    if me.LogLikelihood > me_noFix.LogLikelihood
        chiLRT = compare(me_noFix,me);
        chiLRT.formula = {formula_noFix; formula}; % add formulas to the dataset
        chiLRT = dataset2table(chiLRT); % Convert the dataset to a table
        chiLRT{:,1} = categorical(chiLRT{:,1}); % Change the Model names to categorical for easier display
    else
        chiLRT = createDummyChiLRTtab(me_noFix,me);
    end
    varargout{2} = chiLRT;


    % Initialize multi-comparison results
    multiComparisonResults = [];
    mmPvalue = struct('method', {}, 'group1', {}, 'group2', {}, 'p', {}, 'h', {});

    
    % Perform multiple comparisons if the group effect is significant
    if any(fixedEffectsStats.pValue < 0.05) % strcmp(modelType, 'LMM') && 
        if length(groupLevels) > 2
            % Perform multiple comparisons manually
            [multiComparisonResults, mmPvalue] = performPostHocComparisons(me, groupLevels, dispStat, modelType);
        else
            % Extract the p-value from the fixed effects for two groups
            pValue = pValueGroup(1);
            hValue = pValue < 0.05;
            mmPvalue = struct('method', modelType, 'group1', groupLevels{1}, 'group2', groupLevels{2}, 'p', pValue, 'h', hValue);
            if dispStat
                fprintf('\nFixed Effects Results:\n%s vs. %s: p-value = %.4f, h = %d\n', ...
                    groupLevels{1}, groupLevels{2}, pValue, hValue);
            end
        end
    % elseif strcmp(modelType, 'GLMM') && length(groupLevels) == 2
    %     % Perform post-hoc comparison for GLMM with two groups
    %     pValue = pValueGroup(1);
    %     hValue = pValue < 0.05;
    %     statInfo = struct('method', 'Generalized-linear-mixed-model', 'group1', groupLevels{1}, 'group2', groupLevels{2}, 'p', pValue, 'h', hValue);
    %     if dispStat
    %         fprintf('\nFixed Effects Results:\n%s vs. %s: p-value = %.4f, h = %d\n', ...
    %             groupLevels{1}, groupLevels{2}, pValue, hValue);
    %     end
    end

    % Add multi-comparison results and statInfo to the output
    varargout{3} = mmPvalue;
    varargout{4} = multiComparisonResults;
end

function [results, mmPvalue] = performPostHocComparisons(me, groupLevels, dispStat, modelType)
    % Extract the fixed effects and their covariance matrix
    [fixedEffectsEstimates, ~, fixedEffectsSE] = fixedEffects(me);
    covarianceMatrix = me.CoefficientCovariance;
    SEs = fixedEffectsSE.SE;

    % Number of groups
    numGroups = length(groupLevels);

    % Prepare results storage
    comparisons = nchoosek(1:numGroups, 2);
    results = [];
    mmPvalue = struct('method', {}, 'group1', {}, 'group2', {}, 'p', {}, 'h', {});

    % Perform pairwise comparisons
    for i = 1:size(comparisons, 1)
        group1 = comparisons(i, 1);
        group2 = comparisons(i, 2);
        
        % Estimate difference and its standard error
        estimateDiff = fixedEffectsEstimates(group1) - fixedEffectsEstimates(group2);
        % estimateDiff = fixedEffectsEstimates(group1 + 1) - fixedEffectsEstimates(group2 + 1);
        seDiff = sqrt(SEs(group1)^2 + SEs(group2)^2);
        % seDiff = sqrt(covarianceMatrix(group1 + 1, group1 + 1) + covarianceMatrix(group2 + 1, group2 + 1) - 2 * covarianceMatrix(group1 + 1, group2 + 1));
        
        % Calculate confidence intervals and p-values
        tValue = estimateDiff / seDiff;
        df = me.DFE;
        pValue = 2 * (1 - tcdf(abs(tValue), df));
        hValue = pValue < 0.05;


        % Store the results
        results = [results; group1, group2, estimateDiff, seDiff, tValue, df, pValue, hValue];
        
        % Append results to mmPvalue
        mmPvalue(end+1) = struct('method', modelType, 'group1', groupLevels{group1}, 'group2', groupLevels{group2}, 'p', pValue, 'h', hValue); %#ok<AGROW>
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

function fixedEffectsStatsLinear = log2linear(fixedEffectsStatsLog);
    % Convert the log-scaled values in fixedEffectsStats to linear scale

    % Convert the Estimate to the linear scale
    estimates = fixedEffectsStatsLog.Estimate;
    CI_lower = fixedEffectsStatsLog.Lower;
    CI_upper = fixedEffectsStatsLog.Upper;

    % Add the first estimate value to (2:end) estimate and CIs. (2:end) values use the first
    % inception's estimate as reference
    estimates(2:end) = estimates(2:end)+estimates(1);
    CI_lower(2:end) = CI_lower(2:end)+estimates(1);
    CI_upper(2:end) = CI_upper(2:end)+estimates(1);

    % Convert the estimates to linear
    estimatesLinear = arrayfun(@exp, estimates);
    CI_lowerLinear = arrayfun(@exp, CI_lower);
    CI_upperLinear = arrayfun(@exp, CI_upper);

    % Calculate the SE using CI
    SElinear = NaN(size(estimates));
    for i = 1:length(SElinear)
        SElinear(i) = (CI_upperLinear(i)-CI_lowerLinear(i))/2*1.96;
    end

    % Assign values from fixedEffectsStatsLog to fixedEffectsStatsLinear
    fixedEffectsStatsLinear = fixedEffectsStatsLog;

    % Replace values on log scale to linear scale
    fixedEffectsStatsLinear.Estimate = estimatesLinear;
    fixedEffectsStatsLinear.CI_lower = CI_lowerLinear;
    fixedEffectsStatsLinear.CI_upper = CI_upperLinear;
    fixedEffectsStatsLinear.SE = SElinear;
end

% function structVar = titledDataset2struct(tdsVar)
%     % Convert a titledDataset var to a structure var

%     % Get the variable names.
%     colNames = tdsVar.Properties.VarNames;

%     % Create an empty strucut var
%     structVar = empty_content_struct(colNames,size(tdsVar,1));

%     % Fill the values to the structvar
%     for i = 1:length(colNames)
%         % Get the contents
%         contents = tdsVar.(colNames{i});

%         % Check if the contents are number array
%         if isdouble(contents)
%             contents = num2cell(contents);
%         else
%             contents = cellstr(contents);
%         end

%         % Fill the structVar with the cell array contents
%         [structVar.(colNames{i})] = contents{:};
%     end
% end

function dummyChiLRTtab = createDummyChiLRTtab(mmResult1, mmResult2)
    dummyChiLRTtab = [mmResult1.ModelCriterion; mmResult2.ModelCriterion];
    dummyChiLRTtab.formula = {char(mmResult1.Formula); char(mmResult2.Formula)};
    % dummyChiLRTtab.formula = categorical({mmResult1.Formula; mmResult2.Formula});
    dummyChiLRTtab = dataset2table(dummyChiLRTtab); % Convert the dataset to a table
end