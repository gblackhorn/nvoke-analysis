function statTab = VIIOclusteringStat2Tab(statData, varargin)
    % Collect info from clustering stat vars and create a table

    % statData is a struct var and contains these field:
    %   - dataNames
    %   - testType
    %   - DescriptiveStatistics
    %   - (value of testType)




    % Parse optional inputs
    p = inputParser;
    addParameter(p, 'tabDiscript', '', @(x) ischar(x) || isstring(x)); % Accepts both
    % addParameter(p, 'filename', 'table_output.tex', @ischar);  % Filename for the output .tex file
    % addParameter(p, 'caption', 'Your caption here', @ischar);  % Caption for the LaTeX table
    % addParameter(p, 'label', 'tab:tableLabel', @ischar);  % Label for the LaTeX table
    % addParameter(p, 'columnAdjust', '', @ischar);  % Optional input for column adjustments
    parse(p, varargin{:});
    
    tabDiscript = p.Results.tabDiscript;
    % filename = p.Results.filename;
    % caption = p.Results.caption;
    % label = p.Results.label;
    % columnAdjust = p.Results.columnAdjust;


    % Calculate the number of group
    % There should only be 2 groups
    groupNum = length(statData.dataNames);



    % Collect data from fields. Ensure all the arrays/cells are verticle

    % Pre-allo RAM
    Group = cell(groupNum, 1);
    nNum = NaN(groupNum, 1);
    Mean = NaN(groupNum, 1);
    Median = NaN(groupNum, 1);
    STD = NaN(groupNum, 1);
    SEM = NaN(groupNum, 1);
    pValue = cell(groupNum, 1);
    hValue = cell(groupNum, 1);

    % Loop through the values in 'DescriptiveStatistics' field
    for i = 1:groupNum
        groupName = statData.dataNames{i};

        % Get the values for the i-th group
        descriptVal = statData.DescriptiveStatistics.(groupName);

        Group{i} = groupName;
        nNum(i) = descriptVal.n;
        Mean(i) = descriptVal.mean;
        Median(i) = descriptVal.median;
        STD(i) = descriptVal.std;
        SEM(i) = STD(i) / sqrt(nNum(i));

        if i == groupNum
            testStat = statData.(statData.testType);
            pValue{i} = testStat.pValue;
            hValue{i} = testStat.hValue;
        end
    end

    statTab = table(Group, nNum, Mean, Median, STD, SEM, pValue, hValue);
    statTab.Properties.Description = tabDiscript;
    % columnAdjust = 'XXXXXXXX';
end


