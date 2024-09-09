function [mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType, varargin)
    % Initialize the settings for func 'plotEventPropMultiGroups' to plot and analyze the eventProp 

    % me: The output of mixed-model, such as fitglme
    %   - me = fitglme(...)

    % groupVar: The name of the fixed effect in the formula
    %    - Data in it must be numeric or categorical


    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'seperateSPONT', false, @islogical);
    addParameter(p, 'dataDist', 'posSkewed', @ischar); % 'posSkewed', 'norm'
    % addParameter(p, 'figName', 'OriginalData vs fitData', @ischar);

    parse(p, varargin{:});
    seperateSPONT = p.Results.seperateSPONT;
    dataDist = p.Results.dataDist;
    % figName = p.Results.figName;


    % Mixed model used for the analysis
    mmHierarchicalVars = {'trialName', 'roiName'};
    switch dataDist
        case 'posSkewed'
            mmModel = 'GLMM'; 
            mmDistribution = 'gamma'; % For continuous, positively skewed data
            mmLink = 'log'; % For continuous, positively skewed data
        case 'norm'
            mmModel = 'LMM'; 
            mmDistribution = ''; % LMM works on normal distribution data on default. Dist is not required
            mmLink = ''; % LMM works on normal distribution data on default. Link function is not required
    end

    % Set up the title stem, group key words and the fixed effects for MM analysis
    if ~seperateSPONT
        % When SPONT are from all the neurons
        switch groupSettingsType
            case 'subN'
                % Focus on the difference between subN; Compare between stimEvents and SPONT in the same subN
                organizeStruct(1).title = 'SPONT SubN';
                organizeStruct(1).keepGroups = {'spon'};
                organizeStruct(1).mmFixCat = 'subNuclei';

                organizeStruct(2).title = 'OG-SPONT subN';
                organizeStruct(2).keepGroups = {'opto-delay [og-5s]'};
                organizeStruct(2).mmFixCat = 'subNuclei';

                organizeStruct(3).title = 'OG-SPONT2SPONT DAO';
                organizeStruct(3).keepGroups = {'spon-DAO', 'opto-delay [og-5s]-DAO'};
                organizeStruct(3).mmFixCat = 'peak_category';

                organizeStruct(4).title = 'OG-SPONT2SPONT PO';
                organizeStruct(4).keepGroups = {'spon-PO', 'opto-delay [og-5s]-PO'};
                organizeStruct(4).mmFixCat = 'peak_category';

                organizeStruct(5).title = 'OGOFF subN';
                organizeStruct(5).keepGroups = {'rebound [og-5s]'};
                organizeStruct(5).mmFixCat = 'subNuclei';

                organizeStruct(6).title = 'OGOFF2SPONT DAO';
                organizeStruct(6).keepGroups = {'spon-DAO', 'rebound [og-5s]-DAO'};
                organizeStruct(6).mmFixCat = 'peak_category';

                organizeStruct(7).title = 'OGOFF2SPONT PO';
                organizeStruct(7).keepGroups = {'spon-PO', 'rebound [og-5s]-PO'};
                organizeStruct(7).mmFixCat = 'peak_category';

                organizeStruct(8).title = 'AP-TRIG subN';
                organizeStruct(8).keepGroups = {'trig [ap-0.1s]'};
                organizeStruct(8).mmFixCat = 'subNuclei';

                organizeStruct(9).title = 'AP-TRIG2SPONT DAO';
                organizeStruct(9).keepGroups = {'spon-DAO', 'trig [ap-0.1s]-DAO'};
                organizeStruct(9).mmFixCat = 'peak_category';

                organizeStruct(10).title = 'AP-TRIG2SPONT PO';
                organizeStruct(10).keepGroups = {'spon-PO', 'trig [ap-0.1s]-PO'};
                organizeStruct(10).mmFixCat = 'peak_category';

                organizeStruct(11).title = 'AP-TRIG2OGAP-TRIG PO';
                organizeStruct(11).keepGroups = {'trig [ap-0.1s]-PO', 'trig-ap [og-5s ap-0.1s]-PO'};
                organizeStruct(11).mmFixCat = 'peak_category';

                organizeStruct(12).title = 'OGAP-TRIG2SPONT PO';
                organizeStruct(12).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO', 'spon-PO'};
                organizeStruct(12).mmFixCat = 'peak_category';

            case 'subN OG subNall'
                % Focus on the difference between OG events and SPONT. Combine the subN to increase nNum
                organizeStruct(1).title = 'OG-SPONT2SPONT ALL';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]', 'spon'};
                organizeStruct(1).mmFixCat = 'peak_category';

                organizeStruct(2).title = 'OGOFF2SPONT ALL';
                organizeStruct(2).keepGroups = {'rebound [og-5s]', 'spon'};
                organizeStruct(2).mmFixCat = 'peak_category';
            case 'syncTag SPONT'
                % Compare the SPONT with sync/async tags
                organizeStruct(1).title = 'syncVSasync SPONT PO';
                organizeStruct(1).keepGroups = {'spon-PO'};
                organizeStruct(1).mmFixCat = 'type'; % For sync vs async
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = 'syncVSasync SPONT DAO';
                organizeStruct(2).keepGroups = {'spon-DAO'};
                organizeStruct(2).mmFixCat = 'type';
                organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

                organizeStruct(3).title = 'SPONT subN sync';
                organizeStruct(3).keepGroups = {'-synch'};
                organizeStruct(3).mmFixCat = 'subNuclei';
                organizeStruct(3).colorGroup = {'#00AAD4', '#FF00CC'};

                organizeStruct(4).title = 'SPONT subN async';
                organizeStruct(4).keepGroups = {'-asynch'};
                organizeStruct(4).mmFixCat = 'subNuclei';
                organizeStruct(4).colorGroup = {'#003264', '#8C0383'};

            case 'syncTag OG-SPONT'
                % Compare sync vs async OG-SPONT in various subN
                organizeStruct(1).title = 'OG-SPONT syncVSasync PO';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]-PO'};
                organizeStruct(1).mmFixCat = 'type';
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = 'OG-SPONT syncVSasync DAO';
                organizeStruct(2).keepGroups = {'opto-delay [og-5s]-DAO'};
                organizeStruct(2).mmFixCat = 'type';
                organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

            case 'syncTag OG-SPONT subNall'
                % Compare sync vs async OG-SPONT (Combine subN for bigger nNum)
                organizeStruct.title = 'OG-SPONT syncVSasync ALL';
                organizeStruct.keepGroups = {'opto-delay [og-5s]'};
                organizeStruct.mmFixCat = 'type';

            case 'synctag OGOFF-TRIG'
                % Compare sync vs async OGOFF-TRIG in various subN
                organizeStruct(1).title = 'OGOFF-TRIG syncVSasync PO';
                organizeStruct(1).keepGroups = {'rebound [og-5s]-PO'};
                organizeStruct(1).mmFixCat = 'type';
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = 'OGOFF-TRIG syncVSasync DAO';
                organizeStruct(2).keepGroups = {'rebound [og-5s]-DAO'};
                organizeStruct(2).mmFixCat = 'type';
                organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

            case 'syncTag OGOFF-TRIG subNall'
                % Compare sync vs async OGOFF-TRIG (Combine subN for bigger nNum)
                organizeStruct.title = 'OGOFF-TRIG syncVSasync ALL';
                organizeStruct.keepGroups = {'rebound [og-5s]'};
                organizeStruct.mmFixCat = 'type';

            case 'synctag AP-TRIG'
                % Compare sync vs async AP-TRIG in various subN
                organizeStruct(1).title = 'AP-TRIG syncVSasync PO';
                organizeStruct(1).keepGroups = {'trig [ap-0.1s]-PO'};
                organizeStruct(1).mmFixCat = 'type';
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = 'AP-TRIG syncVSasync DAO';
                organizeStruct(2).keepGroups = {'trig [ap-0.1s]-DAO'};
                organizeStruct(2).mmFixCat = 'type';
                organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};
        end

    else
        % SPONT are spearated according to the stimulation applied
        switch groupSettingsType
            case 'subN'
                % Compare stimEvents and SPONT from same ROI groups. 
                organizeStruct(1).title = 'OG-SPONT2SPONT DAO';
                organizeStruct(1).keepGroups = {'spon [og-5s]-DAO', 'opto-delay [og-5s]-DAO'};
                organizeStruct(1).mmFixCat = 'peak_category';

                organizeStruct(2).title = 'OG-SPONT2SPONT PO';
                organizeStruct(2).keepGroups = {'spon [og-5s]-PO', 'opto-delay [og-5s]-PO'};
                organizeStruct(2).mmFixCat = 'peak_category';

                organizeStruct(3).title = 'OGOFF2SPONT DAO';
                organizeStruct(3).keepGroups = {'spon [og-5s]-DAO', 'rebound [og-5s]-DAO'};
                organizeStruct(3).mmFixCat = 'peak_category';

                organizeStruct(4).title = 'OGOFF2SPONT PO';
                organizeStruct(4).keepGroups = {'spon [og-5s]-PO', 'rebound [og-5s]-PO'};
                organizeStruct(4).mmFixCat = 'peak_category';

                organizeStruct(5).title = 'AP-TRIG2SPONT DAO';
                organizeStruct(5).keepGroups = {'spon [ap-0.1s]-DAO', 'trig [ap-0.1s]-DAO'};
                organizeStruct(5).mmFixCat = 'peak_category';

                organizeStruct(6).title = 'AP-TRIG2SPONT PO';
                organizeStruct(6).keepGroups = {'spon [ap-0.1s]-PO', 'trig [ap-0.1s]-PO'};
                organizeStruct(6).mmFixCat = 'peak_category';

                organizeStruct(7).title = 'OGAP-TRIG2SPONT PO';
                organizeStruct(7).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO', 'spon [og-5s ap-0.1s]-PO'};
                organizeStruct(7).mmFixCat = 'peak_category';

            case 'subN OG subNall'
                % Compare the difference between OG events and SPONT. Combine the subN to increase nNum
                % Use SPONT from the OG recordings
                organizeStruct(1).title = 'OG-SPONT2SPONT ALL';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]', 'spon [og-5s]'};
                organizeStruct(1).mmFixCat = 'peak_category';

                organizeStruct(2).title = 'OGOFF2SPONT ALL';
                organizeStruct(2).keepGroups = {'rebound [og-5s]', 'spon [og-5s]'};
                organizeStruct(2).mmFixCat = 'peak_category';
        end
    end
end
