% Prepare Latex stat table

% % Template
% Description = "Fig2 E3. Cluster fold PO vs. DAO. Mann-Whitney U test (ranksum)";
% Group = {'PO'; 'DAO'};
% nNum = [; ];
% Mean = [; ];
% Median = [; ];
% STD = [; ];
% SEM = NaN(size(STD));
% for i = length(STD)
% 	SEM(i) = STD(i) / sqrt(nNum(i));
% end
% pValue = {[]; };
% hValue = {[]; };

% statTab = table(Group, nNum, Mean, Median, STD, SEM, pValue, hValue);
% statTab.Properties.Description = Description;
% columnAdjust = 'XXXXXXXX';

% Description = "Fig2 E3. Cluster fraction PO vs. DAO. Mann-Whitney U test (ranksum)";
% Group = {'PO'; 'DAO'};
% nNum = [16; 14];
% Mean = [0.38; 0.29];
% Median = [0.34; 0.21];
% STD = [0.15; 0.20];
% SEM = NaN(size(STD));
% for i = length(STD)
% 	SEM(i) = STD(i) / sqrt(nNum(i));
% end
% pValue = {[]; 0.0357};
% hValue = {[]; 1};

% statTab = table(Group, nNum, Mean, Median, STD, SEM, pValue, hValue);
% statTab.Properties.Description = Description;
% columnAdjust = 'XXXXXXXX';


% Description = "Fig2 E3. Cluster fold PO vs. DAO. Mann-Whitney U test (ranksum)";
% Group = {'PO'; 'DAO'};
% nNum = [16; 14];
% Mean = [32.42; 36.63];
% Median = [19.04; 31.26];
% STD = [34.80; 31.32];
% SEM = NaN(size(STD));
% for i = length(STD)
% 	SEM(i) = STD(i) / sqrt(nNum(i));
% end
% pValue = {[]; 1};
% hValue = {[]; 0};

% statTab = table(Group, nNum, Mean, Median, STD, SEM, pValue, hValue);
% statTab.Properties.Description = Description;
% columnAdjust = 'XXXXXXXX';

% Clustering Analysis
%% ==========
tabDiscript = "Fig2 E3. Cluster fraction PO vs. DAO. Mann-Whitney U test (ranksum)";
statData = STATS_CLUST_SPONT_PODAO_FIG2E.ClusterFractions;

%% ==========
tabDiscript = "Fig2 E3. Cluster fold PO vs. DAO. Mann-Whitney U test (ranksum)";
statData = STATS_CLUST_SPONT_PODAO_FIG2E.ClusterFoldValues;

%% ==========
tabDiscript = "Fig3 C1. Cluster fraction spon vs AP. Mann-Whitney U test (ranksum)";
statData = STATS_clustering_AP_PO.clusterFractions;

%% ==========
tabDiscript = "Fig3 C1. Cluster fold spon vs AP. Mann-Whitney U test (ranksum)";
statData = STATS_clustering_AP_PO.clusterFoldValues;

%% ==========
tabDiscript = "Fig4 D. Cluster fraction spon vs OGdelay. Mann-Whitney U test (ranksum)";
statData = STATS_CLUST_SPONT_OGDELAY_FIG4D.clusterFractions;

%% ==========
tabDiscript = "Fig4 D. Cluster fold spon vs OGdelay. Mann-Whitney U test (ranksum)";
statData = STATS_CLUST_SPONT_OGDELAY_FIG4D.clusterFoldValues;


% No median
% %% ==========
% tabDiscript = "Fig4 supp3. Cluster fraction spon vs rebound. Mann-Whitney U test (ranksum)";
% statData = STATS_CLUST_SPONT_RB_ALL_FIG4supp3.allClusterFractions  ;

% %% ==========
% tabDiscript = "Fig4 supp3. Cluster fold spon vs rebound. Mann-Whitney U test (ranksum)";
% statData = STATS_CLUST_SPONT_RB_ALL_FIG4supp3.allClusterFoldValues  ;



% Pre- post-interval analysis
%% ==========
tabDiscript = "Fig3 E. pre and post intervals of AP";
statData = statsResults_PrePostIntervals;

%% ==========
tabDiscript = "Fig3 E. pre and post ratios of AP. Cluster vs Single";
statData = statsResultsClustSingPrePost;



% Stim efficacy
%% ==========
tabDiscript = "Fig5 E. StimEfficacy PO AP vs. N-O_AP";
statData = STATS_stimEfficacy_FIG5E.Efficacy;

%% ==========
tabDiscript = "Fig5 E. Probability PO AP vs. N-O_AP";
statData = STATS_stimEfficacy_FIG5E.Probability;

%% ==========
tabDiscript = "Fig5 E. EfficacyNoZeros PO AP vs. N-O_AP";
statData = STATS_stimEfficacy_FIG5E.EfficacyNoZeros;



%% ==========
% Convert the Latex tabs to long table format
% Specify the folder containing the .tex files
folderPath = 'D:\guoda\Documents\Workspace\manuscript\Paper\VIIO\DATA\LatexTab';

% Get a list of all .tex files in the folder
fileList = dir(fullfile(folderPath, '*.tex'));

% Extract the file names without extensions
fileNames = {fileList.name}; % Extract names into a cell array
fileNamesNoExt = cellfun(@(x) erase(x, '.tex'), fileNames, 'UniformOutput', false);

% Display the result
disp('List of file names without extensions:');
disp(fileNamesNoExt);

FolderPathVA.fig = chooseFolderWithGUI(folderPath, 'Choose a folder containing Latex tables');
for n = 1:numel(fileNamesNoExt)
	fileKeyword = fileNamesNoExt{n};
	vertConcatLatexTab(FolderPathVA.fig, fileKeyword, fileKeyword);
end
