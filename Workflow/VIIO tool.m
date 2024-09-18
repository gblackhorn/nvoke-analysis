% VIIO tool

%% ==========
% Initiate the folder path for saving data
GUI_chooseFolder = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder
FolderPathVA = initProjFigPathVIIO(GUI_chooseFolder);


%% ==========
% Choose a folder and combine the meanSemTab and nNumInfo Latex tables
tab1Key = 'meanSemTab';
tab2Key = 'nNumInfo';
FolderPathVA.fig = chooseFolderWithGUI(FolderPathVA.fig, 'Choose a folder containing Latex tables');
filePairs = findAllTexFilePairs(FolderPathVA.fig, tab1Key, tab2Key);


for n = 1:numel(filePairs)
	if ~isempty(filePairs(n).outputFile)
		combineLatexTables(filePairs(n).inputFile, filePairs(n).outputFile, 'saveToFile', true,...
			'combinedFileName', filePairs(n).combinedFilename);
	end
end



