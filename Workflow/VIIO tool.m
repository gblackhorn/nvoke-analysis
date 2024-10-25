% VIIO tool

%% ==========
% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);


%% ==========
% Choose a folder and combine the meanSemTab and nNumInfo Latex tables
tab1Key = 'nNumInfo';
tab2Key = 'meanSemTab';
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
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');

propName = 'sponInterval'; % normalizedAmp
fileSuffix = '';
file1Keyword = 'meanSemTab nNumInfo';
file2Keyword = 'modelCompTab';
addPval2StatSummaryLatexTab(FolderPathVA.fig, file1Keyword, file2Keyword,...
	'optionalKeyword', propName, 'suffix', fileSuffix);


%% ==========
% Vertically combine the tables containing stat-summary and GLMM results 
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');
fileKeyword = 'ROI sponfq meanSemTab nNumInfo'; % normalizedAmp, FWHM, rise_duration 
tableCaption = 'ROI sponfq statSummary GLMM-result';
vertConcatLatexTab(FolderPathVA.fig, fileKeyword, tableCaption);