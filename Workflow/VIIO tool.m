% VIIO tool

%% ==========
% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);


%% ==========
% Combine the meanSemTab and nNumInfo Latex tables (Recognize pair with filename stemb) in a single folder
tab1Key = 'nNumInfo'; % eventProp: nNumInfo. 
tab2Key = 'meanSemTab'; % eventProp: meanSemTab
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');
filePairs = findAllTexFilePairs(FolderPathVA.fig, tab1Key, tab2Key);


for n = 1:numel(filePairs)
	if ~isempty(filePairs(n).outputFile)
		combineLatexTables(filePairs(n).inputFile, filePairs(n).outputFile, 'saveToFile', true,...
			'combinedFileName', filePairs(n).combinedFilename);
	end
end

%% ==========
% Rename the 'peak_delta_norm_hpstd' files to 'normalizedAmp'
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');
originalChars = 'peak_delta_norm_hpstd';
newChars = 'normalizedAmp';
batchRenameFiles(FolderPathVA.fig, originalChars, newChars);


%% ==========
% Add p and h value to the StatSummary Latex tables
% Note: The filename stem here is the part before file1Keyword/file2Keyword 
% Note: The function only works with 'LMM/GLMM' stat files
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');

propName = ''; % normalizedAmp, sponInterval
fileSuffix = '';
file1Keyword = 'summaryStats nNum'; % descriptive files. eventProp: meanSemTab nNumInfo. periStim: summaryStats nNum
file2Keyword = 'stat'; % p value files. eventProp: modelCompTab. periStim: stat
addPval2StatSummaryLatexTab(FolderPathVA.fig, file1Keyword, file2Keyword,...
	'optionalKeyword', propName, 'suffix', fileSuffix);


%% ==========
% Vertically combine the tables containing stat-summary and GLMM results 
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');
fileKeyword = 'PO periStimFreq summaryStats nNum'; % normalizedAmp, FWHM, rise_duration 
tableCaption = 'PO periStimFreq summaryStats nNum longTab';
vertConcatLatexTab(FolderPathVA.fig, fileKeyword, tableCaption);