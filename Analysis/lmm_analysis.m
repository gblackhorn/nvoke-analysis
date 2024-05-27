function lmm_analysis(dataStruct, responseVar, groupVar, hierarchicalVars)
    % Convert the specified fields to categorical and collect all necessary fields
    LMMdata.(responseVar) = [dataStruct.(responseVar)]';
    LMMdata.(groupVar) = categorical({dataStruct.(groupVar)}');
    for i = 1:length(hierarchicalVars)
        LMMdata.(hierarchicalVars{i}) = categorical({dataStruct.(hierarchicalVars{i})}');
    end
    
    % Convert the structured data to a table
    tbl = struct2table(LMMdata);
    
    % Construct the formula for the linear mixed model
    hierachiRandom = sprintf('(1|%s)', hierarchicalVars{1});
    if length(hierarchicalVars) > 1
        for i = 2:length(hierarchicalVars)
            hierachiRandom = strcat(hierachiRandom, sprintf(' + (1|%s:%s)', hierarchicalVars{i-1}, hierarchicalVars{i}));
        end
    end
    formula = sprintf('%s ~ %s + %s', responseVar, groupVar, hierachiRandom);
    
    % Fit the linear mixed model
    lme = fitlme(tbl, formula);

    % Display the model summary
    disp(lme);

    % Extract fixed effects
    fixedEffectsEstimates = fixedEffects(lme);
    % disp('Fixed Effects:');
    % disp(fixedEffectsEstimates);
    
    % Extract and display random effects
    randomEffectsTable = randomEffects(lme);
    % disp('Random Effects:');
    % disp(randomEffectsTable);

    % Extract the coefficients and p-values
    intercept = lme.Coefficients.Estimate(1);
    groupEffect = lme.Coefficients.Estimate(2);
    pValueGroup = lme.Coefficients.pValue(2);

    % Display the results in a readable format
    fprintf('Intercept (Baseline): %.4f\n', intercept);
    fprintf('Effect of %s (compared to baseline): %.4f (p-value: %.4f)\n', groupVar, groupEffect, pValueGroup);
end
