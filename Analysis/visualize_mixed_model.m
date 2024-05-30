function visualize_mixed_model(lme, dataStruct, responseVar, groupVar, hierarchicalVars)
    % Extract observed values from the data structure
    observedValues = [dataStruct.(responseVar)]';
    
    % Remove NaNs from observed values and corresponding fields
    validIndices = ~isnan(observedValues);
    observedValues = observedValues(validIndices);
    
    % Extract predicted (fitted) values from the model
    predictedValues = fitted(lme);
    predictedValues = predictedValues(validIndices);
    
    % Plot observed vs. predicted values
    figure;
    scatter(observedValues, predictedValues, 'filled');
    hold on;
    plot([min(observedValues), max(observedValues)], [min(observedValues), max(observedValues)], 'r--');
    xlabel('Observed Values');
    ylabel('Predicted Values');
    title('Observed vs. Predicted Values');
    legend('Data points', 'Ideal fit', 'Location', 'Best');
    hold off;
    
    % Calculate model residuals
    modelResiduals = residuals(lme);
    modelResiduals = modelResiduals(validIndices);
    
    % Plot residuals vs. predicted values
    figure;
    scatter(predictedValues, modelResiduals, 'filled');
    xlabel('Predicted Values');
    ylabel('Residuals');
    title('Residuals vs. Predicted Values');
    refline(0, 0); % Add a horizontal reference line at zero
    
    % Extract random effects
    reffects = randomEffects(lme);
    reffectsTable = array2table(reffects, 'VariableNames', {'Estimate'});
    
    % Prepare the grouping variable for random effects
    groupLevels = {};
    for i = 1:length(hierarchicalVars)
        levels = unique({dataStruct(validIndices).(hierarchicalVars{i})});
        groupLevels = [groupLevels; levels(:)']; %#ok<AGROW>
    end
    
    % Ensure the grouping levels match the random effects table rows
    if length(groupLevels) > height(reffectsTable)
        groupLevels = groupLevels(1:height(reffectsTable));
    elseif length(groupLevels) < height(reffectsTable)
        groupLevels = [groupLevels, repmat({'Other'}, 1, height(reffectsTable) - length(groupLevels))];
    end
    
    reffectsTable.Group = categorical(groupLevels);
    
    % Visualize random effects
    figure;
    boxplot(reffectsTable.Estimate, reffectsTable.Group);
    xlabel('Grouping Factor Levels');
    ylabel('Random Effect Estimates');
    title('Random Effects by Grouping Factor Levels');
    
    % Ensure groupVar is categorical
    for i = 1:length(dataStruct)
        if ischar(dataStruct(i).(groupVar))
            dataStruct(i).(groupVar) = categorical(cellstr(dataStruct(i).(groupVar)));
        elseif iscell(dataStruct(i).(groupVar))
            dataStruct(i).(groupVar) = categorical(dataStruct(i).(groupVar));
        end
    end
    
    % Calculate predicted values for each group
    uniqueGroups = unique({dataStruct(validIndices).(groupVar)});
    predictedByGroup = arrayfun(@(grp) mean(predict(lme, struct2table(dataStruct(strcmp({dataStruct.(groupVar)}, grp))))), uniqueGroups);
    
    % Plot predicted values for each group
    figure;
    bar(categorical(uniqueGroups), predictedByGroup);
    xlabel('Group');
    ylabel('Predicted Values');
    title('Predicted Values by Group');
end
