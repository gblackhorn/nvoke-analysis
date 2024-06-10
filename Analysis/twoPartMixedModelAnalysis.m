function [GLMMresults, varargout] = twoPartMixedModelAnalysis(dataStruct, responseVar, groupVar, hierarchicalVars, varargin)
    % This function is designed to analyze data with a hierarchical or nested structure, where
    % observations are not independent. It can be used to analyze data using either Linear Mixed
    % Models (LMM) or Generalized Linear Mixed Models (GLMM). Data will be first anlyzed as binary
    % data (zero vs non-zero). Non-zero data will be then analyzed as continueous data

    % This is for analyzing zero-inflated continuous data, which can not be dealt by poisson, gamma,
    % and inverse gaussian distribution 

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

        % Distribution and Link Function for GLMM part 1: Binomial (default: zero vs non-zero).
            % Distribution: 'Binomial'
            % Link Function: 'logit'

        % Choosing Distribution and Link Functions for GLMM part 2. 
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
    addParameter(p, 'distribution1', 'Binomial', @ischar);
    addParameter(p, 'link1', 'logit', @ischar);
    addParameter(p, 'distribution2', 'gamma', @ischar);
    addParameter(p, 'link2', 'log', @ischar);
    addParameter(p, 'dispStat', false, @islogical);
    addParameter(p, 'groupVarType', '', @ischar); % 'double', 'categorical', 'datetime', 'string', 'logical', etc.

    parse(p, varargin{:});
    modelType = p.Results.modelType;
    distribution1 = p.Results.distribution1;
    link1 = p.Results.link1;
    distribution2 = p.Results.distribution2;
    link2 = p.Results.link2;
    dispStat = p.Results.dispStat;
    groupVarType = p.Results.groupVarType;


    % Create an empty structure to store the GLMM results
    GLMMresultsFields = {'method', 'detail', 'fixedEffectsStats', 'chiLRT', 'mmPvalue', 'multCompare'};
    GLMMresults = empty_content_struct(GLMMresultsFields, 2);

    % Binary response for presence/absence of event
    valBinary = [dataStruct.(responseVar)] ~= 0;
    valBinaryCell = num2cell(valBinary);
    [dataStruct.valBinary] = valBinaryCell{:};

    % Run the part 1 model
    [me1,fixedEffectsStats1,chiLRT1,mmPvalue1,multiComparisonResults1]= mixed_model_analysis(dataStruct,...
        'valBinary', groupVar, hierarchicalVars, 'groupVarType', groupVarType,...
        'modelType',modelType,'distribution',distribution1,'link',link1);
    GLMMresults(1).method = modelType;
    GLMMresults(1).detail = me1;
    GLMMresults(1).fixedEffectsStats = fixedEffectsStats1;
    GLMMresults(1).chiLRT = chiLRT1;
    GLMMresults(1).mmPvalue = mmPvalue1;
    GLMMresults(1).multCompare = multiComparisonResults1;

    % Display the summary of the binary model
    if dispStat
        disp('')
        disp(fixedEffectsStats1);

        % Plot the original data and the fit data to examine the fitting
        visualizeMeFitting(me1, groupVar,...
            'titlePrefix','[binary model]', 'figName', 'OriginalData-vs-fitData_binary');
    end


    % Filter non-zero data
    nonZeroDataStruct = dataStruct([dataStruct.(responseVar)] > 0);

    % Run the part 2 model
    [me2,fixedEffectsStats2,chiLRT2,mmPvalue2,multiComparisonResults2]= mixed_model_analysis(nonZeroDataStruct,...
        responseVar, groupVar, hierarchicalVars, 'groupVarType', groupVarType,...
        'modelType',modelType,'distribution',distribution2,'link',link2);
    GLMMresults(2).method = modelType;
    GLMMresults(2).detail = me2;
    GLMMresults(2).fixedEffectsStats = fixedEffectsStats2;
    GLMMresults(2).chiLRT = chiLRT2;
    GLMMresults(2).mmPvalue = mmPvalue2;
    GLMMresults(2).multCompare = multiComparisonResults2;


    % Display the summary of the non-binary model
    if dispStat
        disp('')
        disp(fixedEffectsStats1);

        % Plot the original data and the fit data to examine the fitting
        visualizeMeFitting(me2, groupVar,...
            'titlePrefix','[nonBinary model]', 'figName', 'OriginalData-vs-fitData_nonBinary');
    end

end