function [fullModel, varargout] = mixed_model_analysis(dataStruct, responseVar, groupVar, hierarchicalVars, varargin)
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
    % - dataStruct: A structure containing the data to be analyzed. Fields: responseVar, groupVar,
    %               hierarchicalVars.
    % - responseVar: A string specifying the name of the response variable (e.g., 'FWHM').
    % - groupVar: A string specifying the name of the grouping variable (e.g., 'subNuclei').
    % - hierarchicalVars: A cell array of strings specifying the names of the hierarchical variables
    %   (e.g., {'trialName', 'roiName'}).
    % - varargin: Optional parameters including:
    %   - 'modelType': 'GLMM' (default) or 'LMM'
    %   - 'distribution': Distribution for GLMM 
    %   - 'link': Link function for GLMM 
    %   - 'dispStat': true (default is false) to display statistics
    %   - 'groupVarType': 'double', 'categorical', 'datetime', 'string', 'logical', etc.
    %   - 'binVar': Optional string specifying the name of the bin variable (e.g., 'binIDX')

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
        % Normal Distribution (for continuous, normally distributed data)
            % Use When: Your response variable is continuous and approximately normally distributed.
            % This is commonly used when analyzing data with a linear relationship between variables.
            % Distribution: 'normal' (Note: In MATLAB, this is the default for linear mixed models (LMM), not GLMM)
            % Link Function: 'identity' (linear relationship)
            % Example: Analyzing normally distributed data such as height, weight, or other continuous measurements.
            
        % Note on Normal Distribution:
        % If your data is normally distributed, consider using Linear Mixed Models (LMM) instead of GLMM.
        % LMM is appropriate for normally distributed data where the relationship between predictors and 
        % the response variable is linear.
    
    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'modelType', 'GLMM', @(x) ismember(x, {'LMM', 'GLMM'}));
    addParameter(p, 'distribution', 'gamma', @ischar);
    addParameter(p, 'link', 'log', @ischar);
    addParameter(p, 'dispStat', false, @islogical);
    addParameter(p, 'groupVarType', '', @ischar); % 'double', 'categorical', 'datetime', 'string', 'logical', etc.
    addParameter(p, 'binVar', '', @ischar);  % New optional bin variable
    parse(p, varargin{:});
    modelType = p.Results.modelType;
    distribution = p.Results.distribution;
    link = p.Results.link;
    dispStat = p.Results.dispStat;
    groupVarType = p.Results.groupVarType;
    binVar = p.Results.binVar;  % New bin variable

    % Convert the specified fields to categorical and collect all necessary fields
    responseValues = [dataStruct.(responseVar)]';
    
    % Find valid indices (non-NaN) for response values
    validIndices = ~isnan(responseValues);
    
    % Filter out NaNs from response values and corresponding fields
    MMdata.(responseVar) = responseValues(validIndices);
    MMdata.(groupVar) = {dataStruct(validIndices).(groupVar)}';
    
    for i = 1:length(hierarchicalVars)
        MMdata.(hierarchicalVars{i}) = categorical({dataStruct(validIndices).(hierarchicalVars{i})}');
    end

    % Include bin variable if provided
    if ~isempty(binVar)
        MMdata.(binVar) = [dataStruct(validIndices).(binVar)]';
        MMdata.(binVar) = categorical(MMdata.(binVar));
    end

    switch groupVarType % if empty, keep the type of groupVar data
        case 'double'
            MMdata.(groupVar) = double(MMdata.(groupVar));
        case 'categorical'
            if isnumeric(dataStruct(1).(groupVar)) || islogical(dataStruct(1).(groupVar))
                MMdata.(groupVar) = cellfun(@num2str, MMdata.(groupVar), 'UniformOutput', false);
            end
            MMdata.(groupVar) = categorical(MMdata.(groupVar));
        case 'string'
            MMdata.(groupVar) = string(MMdata.(groupVar));
        case 'logical'
            MMdata.(groupVar) = logical(MMdata.(groupVar));
        case ''
    end

    % Convert the structured data to a table
    tbl = struct2table(MMdata);

    if ~isempty(tbl) && numel(MMdata.(responseVar)) > 1
        if iscell(tbl.(groupVar)) && isnumeric(tbl.(groupVar){1})
            tbl.(groupVar) = cell2mat(tbl.(groupVar));
        end
        
        % Construct the formula for the mixed model
        hierachiRandom = sprintf('(1|%s)', hierarchicalVars{1});
        if length(hierarchicalVars) > 1
            for i = 2:length(hierarchicalVars)
                hierachiRandom = strcat(hierachiRandom, sprintf(' + (1|%s:%s)', hierarchicalVars{i-1}, hierarchicalVars{i}));
            end
        end
        
        % Add interaction with bin variable if provided
        if ~isempty(binVar)
            formula = sprintf('%s ~ 1 + %s*%s + %s', responseVar, groupVar, binVar, hierachiRandom);
            formula_noFix = sprintf('%s ~ 1 + %s + %s', responseVar, binVar, hierachiRandom);
        else
            formula = sprintf('%s ~ 1 + %s + %s', responseVar, groupVar, hierachiRandom);
            formula_noFix = sprintf('%s ~ 1 + %s', responseVar, hierachiRandom);
        end


        % Generate a string for the model
        switch modelType
            case 'LMM'
                modelInfoStr = sprintf('LMM');
            case 'GLMM'
                modelInfoStr = sprintf('GLMM [Distribution: %s. Link: %s]', distribution, link);
        end

        
        % Fit the model
        if strcmp(modelType, 'LMM')
            fullModel = fitlme(tbl, formula);
            reducedModel = fitlme(tbl, formula_noFix);
        elseif strcmp(modelType, 'GLMM')
            fullModel = fitglme(tbl, formula, 'Distribution', distribution, 'Link', link);
            reducedModel = fitglme(tbl, formula_noFix, 'Distribution', distribution, 'Link', link);
        else
            error('Unsupported model type');
        end

        % % Optionally display the model summary
        % if dispStat
        %     disp(fullModel);
        %     visualizeFitting(fullModel, );
        % end

        % Extract fixed effects
        [fixedEffectsEstimates, ~, fixedEffectsStats] = fixedEffects(fullModel);
        
        % Optionally display fixed effects
        if dispStat
            disp('Fixed Effects:');
            disp(fixedEffectsEstimates);
        end
        
        % Extract random effects
        randomEffectsTable = randomEffects(fullModel);
        
        % Optionally display random effects
        if dispStat
            disp('Random Effects:');
            disp(randomEffectsTable);
        end

        % Extract the coefficients and p-values
        intercept = fullModel.Coefficients.Estimate(1);
        groupEffect = fullModel.Coefficients.Estimate(2:end);
        pValueGroup = fullModel.Coefficients.pValue(2:end);

        % Optionally display the results in a readable format
        if dispStat
            fprintf('Intercept (Baseline): %.4f\n', intercept);
            for i = 1:length(groupEffect)
                fprintf('Effect of %s (compared to baseline): %.4f (p-value: %.4f)\n', fullModel.Coefficients.Name{i+1}, groupEffect(i), pValueGroup(i));
            end
        end

        % Extract group variable levels
        groupCategories = categorical(tbl.(groupVar));
        groupLevels = categories(groupCategories);
        
        % Extract bin variable levels if provided
        if ~isempty(binVar)
            binCategories = categorical(tbl.(binVar));
            binLevels = categories(binCategories);
        end

        % Replace the Name of fixed effect with the categories in the groupVar field
        fixedEffectsStats.Name = groupLevels; 

        % Convert the values on log scale to linear scale
        if strcmpi(modelType,'GLMM') && strcmpi(fullModel.Link.Name,'log')
            fixedEffectsStats = log2linear(fixedEffectsStats);
        end
        fixedEffectsStats = dataset2table(fixedEffectsStats); % Convert the dataset to a table
        varargout{1} = fixedEffectsStats;
        
        % ANOVA is performed on the fitted model using the anova function to test the significance of
        % the fixed effects.
        anovaResults = anova(fullModel);
        
        if dispStat && strcmp(modelType, 'LMM')
            disp('ANOVA Results:');
            disp(anovaResults);
        end
        

        % Prepare output variables
        if fullModel.LogLikelihood > reducedModel.LogLikelihood
            chiLRT = compare(reducedModel, fullModel);
            chiLRT.Formula = {formula_noFix; formula}; % add formulas to the dataset
            chiLRT = dataset2table(chiLRT); % Convert the dataset to a table
            chiLRT{:,1} = categorical(chiLRT{:,1}); % Change the Model names to categorical for easier display

            % Get the current column order
            columnOrder = chiLRT.Properties.VariableNames;

            % Rearrange the column order to move 'formula' after 'Model'
            newColumnOrder = ['Model', 'Formula', columnOrder(~ismember(columnOrder, {'Model', 'Formula'}))];

            % Reorder the table columns
            chiLRT = chiLRT(:, newColumnOrder);
        else
            chiLRT = createDummyChiLRTtab(reducedModel, fullModel);
        end
        varargout{2} = chiLRT;

        % Initialize multi-comparison results
        multiComparisonResults = [];
        mmPvalue = struct('method', {}, 'group1', {}, 'group2', {}, 'p', {}, 'h', {});
        
        % Perform multiple comparisons for groups if there are more than 2 groups
        if length(groupLevels) > 2 && any(fixedEffectsStats.pValue < 0.05)
            [multiComparisonResults, mmPvalue] = performPostHocGroupComparisons(fullModel, groupLevels, dispStat, modelType);
        end

        % Perform bin comparisons if binVar is provided
        if ~isempty(binVar) && any(fixedEffectsStats.pValue < 0.05)
            [multiComparisonResults, mmPvalue] = performPostHocBinComparisons(fullModel, groupVar, groupLevels, binLevels, dispStat, modelType);
        end

    else
        mmPvalue = [];
        multiComparisonResults = [];
        fullModel = '';
        fixedEffectsStats = [];
        chiLRT = [];
    end

    varargout{3} = mmPvalue;
    varargout{4} = multiComparisonResults;
    statInfo.modelInfoStr = modelInfoStr;
    statInfo.method = fullModel;
    statInfo.fixedEffectsStats = fixedEffectsStats;
    statInfo.chiLRT = chiLRT;
    statInfo.mmPvalue = mmPvalue;
    statInfo.multCompare = multiComparisonResults;
    varargout{5} = statInfo;
end

function [results, mmPvalue] = performPostHocGroupComparisons(fullModel, groupLevels, dispStat, modelType)
    % Extract the fixed effects and their covariance matrix
    [fixedEffectsEstimates, ~, fixedEffectsSE] = fixedEffects(fullModel);
    covarianceMatrix = fullModel.CoefficientCovariance;
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
        seDiff = sqrt(SEs(group1)^2 + SEs(group2)^2);
        
        % Calculate confidence intervals and p-values
        tValue = estimateDiff / seDiff;
        df = fullModel.DFE;
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
                results(i, 3) - 1.96*results(i, 4), results(i, 3) + 1.96*results(i, 4), results(i, 7), results(i, 8));
        end
    end
end

function [results, mmPvalue] = performPostHocBinComparisons(fullModel, groupVar, groupLevels, binLevels, dispStat, modelType)
    % Extract the fixed effects and their standard errors
    [fixedEffectsEstimates, ~, fixedEffectsSE] = fixedEffects(fullModel);
    SEs = fixedEffectsSE.SE;

    % Initialize results storage
    results = [];
    mmPvalue = struct('method', {}, 'group1', {}, 'group2', {}, 'bin', {}, 'p', {}, 'h', {});

    pValues = [];

    % Perform pairwise comparisons within each bin
    for b = 1:numel(binLevels)
        binVal = binLevels{b};  % Extract the bin value from the cell array
        
        if b == 1 % strcmp(binVal, '1')
            estimateGroup1 = fixedEffectsEstimates(1); % Intercept
            SE_Group1 = SEs(1);
            
            estimateGroup2 = fixedEffectsEstimates(1) + fixedEffectsEstimates(2); % Intercept + group effect
            SE_Group2 = sqrt(SEs(1)^2 + SEs(2)^2);
        else
            indexBinEffect = find(contains(fullModel.Coefficients.Name, sprintf('binIDX_%s', binVal)) & ...
                                  ~contains(fullModel.Coefficients.Name, groupVar));
            indexInteractionEffect = find(contains(fullModel.Coefficients.Name, sprintf('%s_%s:binIDX_%s', groupVar, groupLevels{2}, binVal)));
            
            estimateGroup1 = fixedEffectsEstimates(1) + fixedEffectsEstimates(indexBinEffect);
            SE_Group1 = sqrt(SEs(1)^2 + SEs(indexBinEffect)^2);

            estimateGroup2 = fixedEffectsEstimates(1) + fixedEffectsEstimates(2) + ...
                             fixedEffectsEstimates(indexBinEffect) + fixedEffectsEstimates(indexInteractionEffect);
            SE_Group2 = sqrt(SEs(1)^2 + SEs(2)^2 + SEs(indexBinEffect)^2 + SEs(indexInteractionEffect)^2);
        end

        estimateDiff = estimateGroup2 - estimateGroup1;
        seDiff = sqrt(SE_Group1^2 + SE_Group2^2);

        tValue = estimateDiff / seDiff;
        df = fullModel.DFE;
        pValue = 2 * (1 - tcdf(abs(tValue), df));
        pValues = [pValues; pValue]; %#ok<AGROW>

        results = [results; 1, 2, b, estimateDiff, seDiff, tValue, df, pValue, 0];
    end

    % Apply Holm-Bonferroni correction
    [sortedP, sortIdx] = sort(pValues);
    m = length(pValues);
    hValues = zeros(size(pValues));

    for i = 1:m
        if sortedP(i) <= 0.05 / (m - i + 1)
            hValues(sortIdx(i)) = 1;
        else
            break;  % No need to check further; remaining p-values cannot be significant
        end
    end

    % Update results with Holm-Bonferroni-corrected significance
    for i = 1:length(hValues)
        results(i, end) = hValues(i);
        mmPvalue(end+1) = struct('method', modelType, 'group1', groupLevels{1}, 'group2', groupLevels{2}, 'bin', binLevels{results(i, 3)}, 'p', results(i, 8), 'h', hValues(i)); %#ok<AGROW>
    end

    if dispStat
        fprintf('\nPairwise Comparisons by Bin (Holm-Bonferroni corrected):\n');
        for i = 1:size(results, 1)
            fprintf('%s vs. %s in bin %s: Difference = %.4f, 95%% CI = [%.4f, %.4f], p-value = %.4f, h = %d\n', ...
                groupLevels{results(i, 1)}, groupLevels{results(i, 2)}, binLevels{results(i, 3)}, results(i, 4), ...
                results(i, 4) - 1.96*results(i, 5), results(i, 4) + 1.96*results(i, 5), results(i, 8), results(i, 9));
        end
    end
end



function fixedEffectsStatsLinear = log2linear(fixedEffectsStatsLog)
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

function dummyChiLRTtab = createDummyChiLRTtab(mmResult1, mmResult2)
    dummyChiLRTtab = [mmResult1.ModelCriterion; mmResult2.ModelCriterion];
    dummyChiLRTtab.Model = {'reducedModel';'fullModel'};
    dummyChiLRTtab.Formula = {char(mmResult1.Formula); char(mmResult2.Formula)};
    dummyChiLRTtab = dataset2table(dummyChiLRTtab); % Convert the dataset to a table

    % Delete the Deviance
    dummyChiLRTtab.Deviance = [];

    % Get the current column order
    columnOrder = dummyChiLRTtab.Properties.VariableNames;

    % Rearrange the column order to move 'formula' after 'Model'
    newColumnOrder = ['Model', 'Formula', columnOrder(~ismember(columnOrder, {'Model', 'Formula'}))];

    % Reorder the table columns
    dummyChiLRTtab = dummyChiLRTtab(:, newColumnOrder);
end



