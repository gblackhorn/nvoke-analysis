function [mmModel, mmHierarchicalVars, mmDistribution, mmLink, organizeStruct] = VIIOinitEventPropAnalysis(groupSettingsType, varargin)
    % Initialize the settings for func 'plotEventPropMultiGroups' to plot and analyze the eventProp 

    % me: The output of mixed-model, such as fitglme
    %   - me = fitglme(...)

    % groupVar: The name of the fixed effect in the formula
    %    - Data in it must be numeric or categorical


    % Parse optional parameters
    p = inputParser;
    addParameter(p, 'separateSPONT', false, @islogical);
    addParameter(p, 'dataDist', 'posSkewed', @ischar); % 'posSkewed', 'norm'
    % addParameter(p, 'figName', 'OriginalData vs fitData', @ischar);

    parse(p, varargin{:});
    separateSPONT = p.Results.separateSPONT;
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
    if ~separateSPONT
        % When SPONT are from all the neurons
        switch groupSettingsType
            case 'subN'
                % Focus on the difference between subN; Compare between stimEvents and SPONT in the same subN
                organizeStruct(1).title = '[SPONT] PO2DAO';
                organizeStruct(1).keepGroups = {'spon'};
                organizeStruct(1).mmFixCat = 'subNuclei';

                organizeStruct(2).title = '[OG-SPONT] PO2DAO';
                organizeStruct(2).keepGroups = {'opto-delay [og-5s]'};
                organizeStruct(2).mmFixCat = 'subNuclei';

                organizeStruct(3).title = '[OG-SPONT]2[SPONT] DAO';
                organizeStruct(3).keepGroups = {'opto-delay [og-5s]-DAO', 'spon-DAO'};
                organizeStruct(3).mmFixCat = 'peak_category';

                organizeStruct(4).title = '[OG-SPONT]2[SPONT] PO';
                organizeStruct(4).keepGroups = {'opto-delay [og-5s]-PO', 'spon-PO'};
                organizeStruct(4).mmFixCat = 'peak_category';

                organizeStruct(5).title = '[OGOFF-TRIG] PO2DAO';
                organizeStruct(5).keepGroups = {'rebound [og-5s]'};
                organizeStruct(5).mmFixCat = 'subNuclei';

                organizeStruct(6).title = '[OGOFF-TRIG]2[SPONT] DAO';
                organizeStruct(6).keepGroups = {'rebound [og-5s]-DAO', 'spon-DAO'};
                organizeStruct(6).mmFixCat = 'peak_category';

                organizeStruct(7).title = '[OGOFF-TRIG]2[SPONT] PO';
                organizeStruct(7).keepGroups = {'rebound [og-5s]-PO', 'spon-PO'};
                organizeStruct(7).mmFixCat = 'peak_category';

                organizeStruct(8).title = '[AP-TRIG] PO2DAO';
                organizeStruct(8).keepGroups = {'trig [ap-0.1s]'};
                organizeStruct(8).mmFixCat = 'subNuclei';

                organizeStruct(9).title = '[AP-TRIG]2[SPONT] DAO';
                organizeStruct(9).keepGroups = {'trig [ap-0.1s]-DAO', 'spon-DAO'};
                organizeStruct(9).mmFixCat = 'peak_category';

                organizeStruct(10).title = '[AP-TRIG]2[SPONT] PO';
                organizeStruct(10).keepGroups = {'trig [ap-0.1s]-PO', 'spon-PO'};
                organizeStruct(10).mmFixCat = 'peak_category';

                organizeStruct(11).title = '[AP-TRIG]2[OGAP-TRIG] PO';
                organizeStruct(11).keepGroups = {'trig [ap-0.1s]-PO', 'trig-ap [og-5s ap-0.1s]-PO'};
                organizeStruct(11).mmFixCat = 'peak_category';

                organizeStruct(12).title = '[OGAP-TRIG]2[SPONT] PO';
                organizeStruct(12).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO', 'spon-PO'};
                organizeStruct(12).mmFixCat = 'peak_category';

            case 'ALLsubN for OG'
                % Focus on the difference between OG events and SPONT. Combine the subN to increase nNum
                organizeStruct(1).title = '[OG-SPONT]2[SPONT] ALLsubN';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]', 'spon [og-5s]'};
                organizeStruct(1).mmFixCat = 'peak_category';

                organizeStruct(2).title = '[OGOFF-TRIG]2[SPONT] ALLsubN';
                organizeStruct(2).keepGroups = {'rebound [og-5s]', 'spon [og-5s]'};
                organizeStruct(2).mmFixCat = 'peak_category';

            case 'syncTag subN'
                % SPONT 
                organizeStruct(1).title = '[SPONT] cluster2single PO';
                organizeStruct(1).keepGroups = {'spon-PO'};
                organizeStruct(1).mmFixCat = 'type'; % For sync vs async
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = '[SPONT] cluster2single DAO';
                organizeStruct(2).keepGroups = {'spon-DAO'};
                organizeStruct(2).mmFixCat = 'type';
                organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

                organizeStruct(3).title = '[SPONT] PO2DAO cluster';
                organizeStruct(3).keepGroups = {'spon-PO-synch', 'spon-DAO-synch'};
                organizeStruct(3).mmFixCat = 'subNuclei';
                organizeStruct(3).colorGroup = {'#00AAD4', '#FF00CC'};

                organizeStruct(4).title = '[SPONT] PO2DAO single';
                organizeStruct(4).keepGroups = {'spon-PO-asynch', 'spon-DAO-asynch'};
                organizeStruct(4).mmFixCat = 'subNuclei';
                organizeStruct(4).colorGroup = {'#003264', '#8C0383'};

                % AP-TRIG: sync vs async
                organizeStruct(5).title = '[AP-TRIG] cluster2single PO';
                organizeStruct(5).keepGroups = {'trig [ap-0.1s]-PO'};
                organizeStruct(5).mmFixCat = 'type';
                organizeStruct(5).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(6).title = '[AP-TRIG] cluster2single DAO';
                organizeStruct(6).keepGroups = {'trig [ap-0.1s]-DAO'};
                organizeStruct(6).mmFixCat = 'type';
                organizeStruct(6).colorGroup = {'#003264', '#00AAD4'};

                organizeStruct(7).title = '[AP-TRIG]2[SPONT] cluster PO';
                organizeStruct(7).keepGroups = {'trig [ap-0.1s]-PO-synch', 'spon-PO-synch'};
                organizeStruct(7).mmFixCat = 'peak_category';
                organizeStruct(7).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(8).title = '[AP-TRIG]2[SPONT] single PO';
                organizeStruct(8).keepGroups = {'trig [ap-0.1s]-PO-asynch', 'spon-PO-asynch'};
                organizeStruct(8).mmFixCat = 'peak_category';
                organizeStruct(8).colorGroup = {'#003264', '#00AAD4'};

                % OGAP-TRIG 
                organizeStruct(9).title = '[OGAP-TRIG] cluster2single PO';
                organizeStruct(9).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO'};
                organizeStruct(9).mmFixCat = 'type';
                organizeStruct(9).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(10).title = '[OGAP-TRIG]2[AP-TRIG] cluster PO';
                organizeStruct(10).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO-synch', 'trig [ap-0.1s]-PO-synch'};
                organizeStruct(10).mmFixCat = 'peak_category';
                organizeStruct(10).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(11).title = '[OGAP-TRIG]2[AP-TRIG] single PO';
                organizeStruct(11).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO-asynch', 'trig [ap-0.1s]-PO-asynch'};
                organizeStruct(11).mmFixCat = 'peak_category';
                organizeStruct(11).colorGroup = {'#8C0383', '#FF00CC'};


                % % OG-SPONT: Compare sync vs async
                % organizeStruct(10).title = '[OG-SPONT] cluster2single PO';
                % organizeStruct(10).keepGroups = {'opto-delay [og-5s]-PO'};
                % organizeStruct(10).mmFixCat = 'type';
                % organizeStruct(10).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(11).title = '[OG-SPONT] cluster2single DAO';
                % organizeStruct(11).keepGroups = {'opto-delay [og-5s]-DAO'};
                % organizeStruct(11).mmFixCat = 'type';
                % organizeStruct(11).colorGroup = {'#003264', '#00AAD4'};

                % organizeStruct(12).title = '[OG-SPONT]2[SPONT] cluster PO';
                % organizeStruct(12).keepGroups = {'opto-delay [og-5s]-PO-synch', 'spon-PO-synch'};
                % organizeStruct(12).mmFixCat = 'type';
                % organizeStruct(12).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(13).title = '[OG-SPONT]2[SPONT] single PO';
                % organizeStruct(13).keepGroups = {'opto-delay [og-5s]-PO-asynch', 'spon-PO-asynch'};
                % organizeStruct(13).mmFixCat = 'type';
                % organizeStruct(13).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(14).title = '[OG-SPONT]2[SPONT] cluster DAO';
                % organizeStruct(14).keepGroups = {'opto-delay [og-5s]-DAO-synch', 'spon-DAO-synch'};
                % organizeStruct(14).mmFixCat = 'type';
                % organizeStruct(14).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(15).title = '[OG-SPONT]2[SPONT] single DAO';
                % organizeStruct(15).keepGroups = {'opto-delay [og-5s]-DAO-asynch', 'spon-DAO-asynch'};
                % organizeStruct(15).mmFixCat = 'type';
                % organizeStruct(15).colorGroup = {'#8C0383', '#FF00CC'};

                % % OGOFF-TRIG: sync vs async
                % organizeStruct(16).title = '[OGOFF-TRIG] cluster2single PO';
                % organizeStruct(16).keepGroups = {'rebound [og-5s]-PO'};
                % organizeStruct(16).mmFixCat = 'type';
                % organizeStruct(16).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(17).title = '[OGOFF-TRIG] cluster2single DAO';
                % organizeStruct(17).keepGroups = {'rebound [og-5s]-DAO'};
                % organizeStruct(17).mmFixCat = 'type';
                % organizeStruct(17).colorGroup = {'#003264', '#00AAD4'};

            case 'syncTag ALLsubN for OG'
                % OG-SPONT (Combine subN for bigger nNum)
                organizeStruct(1).title = '[OG-SPONT] cluster2single ALLsubN';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]'};
                organizeStruct(1).mmFixCat = 'type';
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = '[OG-SPONT]2[SPONT] cluster ALLsubN';
                organizeStruct(2).keepGroups = {'opto-delay [og-5s]-synch', 'spon [og-5s]-synch'};
                organizeStruct(2).mmFixCat = 'peak_category';
                organizeStruct(2).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(3).title = '[OG-SPONT]2[SPONT] single ALLsubN';
                organizeStruct(3).keepGroups = {'opto-delay [og-5s]-asynch', 'spon [og-5s]-asynch'};
                organizeStruct(3).mmFixCat = 'peak_category';
                organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

                % OGOFF-TRIG (Combine subN for bigger nNum)
                organizeStruct(4).title = '[OGOFF-TRIG] cluster2single ALL';
                organizeStruct(4).keepGroups = {'rebound [og-5s]'};
                organizeStruct(4).mmFixCat = 'type';
                organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(5).title = '[OGOFF-TRIG]2[SPONT] cluster ALLsubN';
                organizeStruct(5).keepGroups = {'rebound [og-5s]-synch', 'spon [og-5s]-synch'};
                organizeStruct(5).mmFixCat = 'peak_category';
                organizeStruct(5).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(6).title = '[OGOFF-TRIG]2[SPONT] single ALLsubN';
                organizeStruct(6).keepGroups = {'rebound [og-5s]-asynch', 'spon [og-5s]-asynch'};
                organizeStruct(6).mmFixCat = 'peak_category';
                organizeStruct(6).colorGroup = {'#8C0383', '#FF00CC'};
        end

    elseif separateSPONT
        % SPONT are spearated according to the stimulation applied
        switch groupSettingsType
            case 'subN'
                % Compare stimEvents and SPONT from same ROI groups. 
                organizeStruct(1).title = '[OG-SPONT]2[SPONT] DAO';
                organizeStruct(1).keepGroups = {'spon [og-5s]-DAO', 'opto-delay [og-5s]-DAO'};
                organizeStruct(1).mmFixCat = 'peak_category';

                organizeStruct(2).title = '[OG-SPONT]2[SPONT] PO';
                organizeStruct(2).keepGroups = {'spon [og-5s]-PO', 'opto-delay [og-5s]-PO'};
                organizeStruct(2).mmFixCat = 'peak_category';

                organizeStruct(3).title = '[OGOFF-TRIG]2[SPONT] DAO';
                organizeStruct(3).keepGroups = {'spon [og-5s]-DAO', 'rebound [og-5s]-DAO'};
                organizeStruct(3).mmFixCat = 'peak_category';

                organizeStruct(4).title = '[OGOFF-TRIG]2[SPONT] PO';
                organizeStruct(4).keepGroups = {'spon [og-5s]-PO', 'rebound [og-5s]-PO'};
                organizeStruct(4).mmFixCat = 'peak_category';

                organizeStruct(5).title = '[AP-TRIG]2[SPONT] DAO';
                organizeStruct(5).keepGroups = {'spon [ap-0.1s]-DAO', 'trig [ap-0.1s]-DAO'};
                organizeStruct(5).mmFixCat = 'peak_category';

                organizeStruct(6).title = '[AP-TRIG]2[SPONT] PO';
                organizeStruct(6).keepGroups = {'spon [ap-0.1s]-PO', 'trig [ap-0.1s]-PO'};
                organizeStruct(6).mmFixCat = 'peak_category';

                organizeStruct(7).title = '[OGAP-TRIG]2[SPONT] PO';
                organizeStruct(7).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO', 'spon [og-5s ap-0.1s]-PO'};
                organizeStruct(7).mmFixCat = 'peak_category';

            case 'ALLsubN for OG'
                % Compare the difference between OG events and SPONT. Combine the subN to increase nNum
                % Use SPONT from the OG recordings
                organizeStruct(1).title = '[OG-SPONT]2[SPONT] ALL';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]', 'spon [og-5s]'};
                organizeStruct(1).mmFixCat = 'peak_category';

                organizeStruct(2).title = '[OGOFF-TRIG]2[SPONT] ALL';
                organizeStruct(2).keepGroups = {'rebound [og-5s]', 'spon [og-5s]'};
                organizeStruct(2).mmFixCat = 'peak_category';

            % case 'syncTag OG-SPONT'


            case 'syncTag subN'
                % AP-TRIG
                organizeStruct(1).title = '[AP-TRIG]2[SPONT] cluster PO';
                organizeStruct(1).keepGroups = {'trig [ap-0.1s]-PO-synch', 'spon [ap-0.1s]-PO-synch'};
                organizeStruct(1).mmFixCat = 'peak_category';
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = '[AP-TRIG]2[SPONT] single PO';
                organizeStruct(2).keepGroups = {'trig [ap-0.1s]-PO-asynch', 'spon [ap-0.1s]-PO-asynch'};
                organizeStruct(2).mmFixCat = 'peak_category';
                organizeStruct(2).colorGroup = {'#003264', '#00AAD4'};

                % OGAP-TRIG
                organizeStruct(3).title = '[OGAP-TRIG]2[SPONT] cluster PO';
                organizeStruct(3).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO-synch', 'spon [og-5s ap-0.1s]-synch'};
                organizeStruct(3).mmFixCat = 'peak_category';
                organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(4).title = '[OGAP-TRIG]2[SPONT] single PO';
                organizeStruct(4).keepGroups = {'trig-ap [og-5s ap-0.1s]-PO-asynch', 'spon [og-5s ap-0.1s]-asynch'};
                organizeStruct(4).mmFixCat = 'peak_category';
                organizeStruct(4).colorGroup = {'#8C0383', '#FF00CC'};

                % % OG-SPONT
                % organizeStruct(5).title = '[OG-SPONT]2[SPONT] cluster PO';
                % organizeStruct(5).keepGroups = {'opto-delay [og-5s]-PO-synch', 'spon [og-5s]-PO-synch'};
                % organizeStruct(5).mmFixCat = 'type';
                % organizeStruct(5).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(6).title = '[OG-SPONT]2[SPONT] single PO';
                % organizeStruct(6).keepGroups = {'opto-delay [og-5s]-PO-asynch', 'spon [og-5s]-PO-asynch'};
                % organizeStruct(6).mmFixCat = 'type';
                % organizeStruct(6).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(7).title = '[OG-SPONT]2[SPONT] cluster DAO';
                % organizeStruct(7).keepGroups = {'opto-delay [og-5s]-DAO-synch', 'spon [og-5s]-DAO-synch'};
                % organizeStruct(7).mmFixCat = 'type';
                % organizeStruct(7).colorGroup = {'#8C0383', '#FF00CC'};

                % organizeStruct(8).title = '[OG-SPONT]2[SPONT] single DAO';
                % organizeStruct(8).keepGroups = {'opto-delay [og-5s]-DAO-asynch', 'spon [og-5s]-DAO-asynch'};
                % organizeStruct(8).mmFixCat = 'type';
                % organizeStruct(8).colorGroup = {'#8C0383', '#FF00CC'};


            case 'syncTag ALLsubN for OG'
                % OG-SPONT (Combine subN for bigger nNum)
                organizeStruct(1).title = '[OG-SPONT]2[SPONT] cluster ALLsubN';
                organizeStruct(1).keepGroups = {'opto-delay [og-5s]-synch', 'spon [og-5s]-synch'};
                organizeStruct(1).mmFixCat = 'peak_category';
                organizeStruct(1).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(2).title = '[OG-SPONT]2[SPONT] single ALLsubN';
                organizeStruct(2).keepGroups = {'opto-delay [og-5s]-asynch', 'spon [og-5s]-asynch'};
                organizeStruct(2).mmFixCat = 'peak_category';
                organizeStruct(2).colorGroup = {'#8C0383', '#FF00CC'};

                % OGOFF-TRIG (Combine subN for bigger nNum)
                organizeStruct(3).title = '[OGOFF-TRIG]2[SPONT] cluster ALLsubN';
                organizeStruct(3).keepGroups = {'rebound [og-5s]-synch', 'spon [og-5s]-synch'};
                organizeStruct(3).mmFixCat = 'peak_category';
                organizeStruct(3).colorGroup = {'#8C0383', '#FF00CC'};

                organizeStruct(4).title = '[OGOFF-TRIG]2[SPONT] single ALLsubN';
                organizeStruct(4).keepGroups = {'rebound [og-5s]-asynch', 'spon [og-5s]-asynch'};
                organizeStruct(4).mmFixCat = 'peak_category';
                organizeStruct(4).colorGroup = {'#8C0383', '#FF00CC'};
        end
    end
end
