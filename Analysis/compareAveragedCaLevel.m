function [varargout] = compareAveragedCaLevel(alignedData,pairStruct,binWidth,varargin)
	% Collect the calcium level from recordings applied with 'stimName' and plot the averaged trace

	% groupA/groupB: Struct vars containing fields 'stimName' and 'subNucleiType'


	% Defaults
	plotUnitWidth = 0.3;
	plotUnitHeight = 0.2;
	columnLim = 3;
	yRangeMargin = 0.5;

	colorGroupA = '#00FFFF';
	colorGroupB = '#FF00FF';

	stimBinRange = [3, 7]; % Run LMM on the these bins. 

	% Stat model setting
	modelType = 'LMM';
	groupVarType = 'categorical';


	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);
	addRequired(p, 'pairStruct', @isstruct);
	% addRequired(p, 'groupB', @isstruct);
	addRequired(p, 'binWidth', @isnumeric);

	% Add optional parameters to the input p
	addParameter(p, 'plotCombinedData', true, @islogical);
	addParameter(p, 'plotRawTraces', false, @islogical); % 'pre'/'post'. The location of relevent event. Pre or post to the ref event
	addParameter(p, 'shadeType', 'ste', @ischar); 
	addParameter(p, 'tickInt_time', 1, @isnumeric);
	addParameter(p, 'titlePrefix', '', @ischar);
	addParameter(p, 'titleSubfix', '', @ischar);
	addParameter(p, 'filterROIs', false, @islogical);
	addParameter(p, 'filterROIsStimTags', {}, @iscell);
	addParameter(p, 'filterROIsStimEffects', {}, @iscell);
	addParameter(p, 'norm2hpStd', true, @islogical);
	addParameter(p, 'saveFig', false, @islogical);
	addParameter(p, 'saveDir', '', @ischar);
	addParameter(p, 'debugMode', false, @islogical);

	% Parse inputs
	parse(p, alignedData, pairStruct, binWidth, varargin{:});

	% Retrieve parsed values
	plotCombinedData = p.Results.plotCombinedData;
	plotRawTraces = p.Results.plotRawTraces;
	shadeType = p.Results.shadeType;
	tickInt_time = p.Results.tickInt_time;
	titlePrefix = p.Results.titlePrefix;
	titleSubfix = p.Results.titleSubfix;
	filterROIs = p.Results.filterROIs;
	filterROIsStimTags = p.Results.filterROIsStimTags;
	filterROIsStimEffects = p.Results.filterROIsStimEffects;
	norm2hpStd = p.Results.norm2hpStd;
	saveFig = p.Results.saveFig;
	saveDir = p.Results.saveDir;
	debugMode = p.Results.debugMode;


	% Filter the neurons by checking their response to certain stimulations
	if filterROIs
		[alignedData,tfIdxWithSubNucleiInfo,roiNumAll,roiNumKep,roiNumDis] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
			'stim_names',filterROIsStimTags,'filters',filterROIsStimEffects);
	end



	% Get the data using the settings in groupA and groupB
	[caLevelDataA,nNumA,binX,binDataA] = getAveragedCaLevel(alignedData,pairStruct.stimNameA,binWidth,...
		'subNuclei',pairStruct.subNucleiTypeA,'stimEventCat', pairStruct.stimEventCatA,...
		'stimEventKeepOrDis', pairStruct.stimEventKeepOrDisA,'norm2hpStd',norm2hpStd);
	[caLevelDataB,nNumB,binX,binDataB] = getAveragedCaLevel(alignedData,pairStruct.stimNameB,binWidth,...
		'subNuclei',pairStruct.subNucleiTypeB,'stimEventCat', pairStruct.stimEventCatB,...
		'stimEventKeepOrDis', pairStruct.stimEventKeepOrDisB,'norm2hpStd',norm2hpStd);

	% [caLevelDataA,caLevelDataNnumA,binX,binDataCellA,binDataA] = getAveragedCaLevel(alignedData,...
	% 	groupA.stimName,groupA.subNucleiType,binWidth);
	% [caLevelDataB,caLevelDataNnumB,binX,binDataCellB,binDataStructB] = getAveragedCaLevel(alignedData,...
	% 	groupB.stimName,groupB.subNucleiType,binWidth);


	% Create a figure with tiles
	groupAstr = sprintf('[%s %s %s %s]', pairStruct.stimNameA, pairStruct.subNucleiTypeA, pairStruct.stimEventCatA, pairStruct.stimEventKeepOrDisA);
	groupBstr = sprintf('[%s %s %s %s]', pairStruct.stimNameB, pairStruct.subNucleiTypeB, pairStruct.stimEventCatB, pairStruct.stimEventKeepOrDisB);
	titleStr = sprintf('%s vs %s %s', groupAstr, groupBstr, titleSubfix);
	[f, fRowNum, fColNum] = fig_canvas(9, 'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'row_lim',3,'column_lim',3,'fig_name',titleStr);
	tlo = tiledlayout(f,fRowNum,fColNum);


	% Combine all the data to extract max and min value for setting the yRange
	caLevelDataAverageCombine = [mean(caLevelDataA.data,2); mean(caLevelDataB.data,2)];
	yMax = max(caLevelDataAverageCombine);
	yMin = min(caLevelDataAverageCombine);
	yDiff = yMax - yMin;
	yRange = [yMin - yDiff * yRangeMargin, yMax + yDiff * yRangeMargin];

	% Plot the traces
	axTrace = nexttile(1, [2,1]);
	[~, ~] = plotAlignedTracesAverage(axTrace, caLevelDataA.data, caLevelDataA.time,...
		'shadeType', shadeType, 'plot_combined_data', plotCombinedData,'plot_raw_traces', plotRawTraces,...
		'color', colorGroupA, 'y_range', yRange, 'tickInt_time', tickInt_time);
	hold on
	[~, ~] = plotAlignedTracesAverage(axTrace, caLevelDataB.data, caLevelDataB.time,...
		'shadeType', shadeType, 'plot_combined_data', plotCombinedData,'plot_raw_traces', plotRawTraces,...
		'color', colorGroupB, 'y_range', yRange, 'tickInt_time', tickInt_time);

	legend(groupAstr, '', groupBstr, '', 'FontSize', 8);
	title(titleStr,'FontSize',10)

	% Plot the numbers
	axNum = nexttile(7);
	title('nNumber','FontSize',10)
	nNumA.group = groupAstr;
	nNumA = orderfields(nNumA, [4 1 2 3]);
	nNumB.group = groupBstr;
	nNumB = orderfields(nNumB, [4 1 2 3]);
	nNumTab = nNumberUItable(axNum,nNumA,nNumB);


	% Keep the bins during the optogenetic stimulation
	combinedBinDataStruct = [binDataA, binDataB]; 
	combinedBinDataStruct = filterByBinIDX(combinedBinDataStruct, 'binIDX', stimBinRange);

	% GLMM stat test
	[me, ~, ~, ~, ~, meStatReport] = mixed_model_analysis(combinedBinDataStruct,...
		'binVal', pairStruct.mmGroupVar, {'recRoiTags'}, 'binVar', 'binIDX', 'modelType', 'LMM', 'groupVarType', 'categorical');

	% Plot LMM results
	axGlmmTitle = nexttile(2,[1,2]);
	glmmTitleStr = sprintf('(Top) %s model comparison: no-fixed-effects vs fixed-effects\n[%s]\nVS\n[%s]\n(Bottom) Group comparison',...
		modelType, char(meStatReport.chiLRT.Formula{1}), char(meStatReport.chiLRT.Formula{2}));
	set(axGlmmTitle, 'XColor', 'none', 'YColor', 'none'); % Hide X and Y axis lines, ticks, and labels
	% title(axGlmmTitle, glmmTitleStr); % Add a title to the axis
	text(axGlmmTitle, 'Units', 'normalized', 'Position', [0.5, 0.5], 'String', glmmTitleStr, ...
	     'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 12);
	set(axGlmmTitle, 'Box', 'off');

	axStat1 = nexttile(5,[1,2]);
	title('comparing models','FontSize',10)
	axStat2 = nexttile(8,[1,2]);
	title('Holm-Bonferroni multiple comparison','FontSize',10)
	plot_stat_table(axStat1, axStat2, meStatReport)


	% Add nNum table to the meStatReport
	meStatReport.nNumTab = nNumTab;

	% Save 
	if saveFig
		% Save the plot
		saveDir = savePlot(f,'save_dir',saveDir,'guiSave',true,'fname',titleStr);

		% Save the n number
		nNumTabName = sprintf('%s nNumTab.tex',titleStr);
		tableToLatex(meStatReport.nNumTab, 'saveToFile',true,'filename',fullfile(saveDir,nNumTabName),...
			'caption', [titleStr, ' nNum']);


		% Save the model comparison table in latex format
		modelCompTabName = sprintf('%s modelCompTab.tex',titleStr);
		tableToLatex(meStatReport.chiLRT, 'saveToFile',true,'filename',fullfile(saveDir,modelCompTabName),...
			'caption', sprintf('%s %s modelComp', titleStr, meStatReport.modelInfoStr));
	end

	varargout{1} = saveDir;
	varargout{2} = meStatReport;
	varargout{3} = combinedBinDataStruct;
	varargout{3} = combinedBinDataStruct;


	% [~,CaLevel_box_statInfo] = boxPlot_with_scatter(binDataCell,'groupNames',NumArray2StringCell(xData),...
	% 	'stat',true,'plotScatter',false);
	% titleStr = sprintf('%s CaLevel box', subNucleiTypes{sn});
	% title(titleStr)
	% ylim([-4 4]);

end

%% ==========
% Subfunctions


function filteredData = filterByBinIDX(dataStruct, fieldName, binRange)
    % Validate inputs
    if ~isstruct(dataStruct)
        error('dataStruct must be a structure array.');
    end
    if ~isfield(dataStruct, fieldName)
        error('Field "%s" does not exist in the data structure.', fieldName);
    end
    if length(binRange) ~= 2
        error('binRange must be a two-element vector [minBin, maxBin].');
    end

    % Extract binIDX values
    binIDXValues = [dataStruct.(fieldName)];

    % Create a logical mask to keep only the desired binIDX values
    mask = binIDXValues >= binRange(1) & binIDXValues <= binRange(2);

    % Apply the mask to filter the data structure
    filteredData = dataStruct(mask);
end


function nNumTab = nNumberUItable(ax,nNumA,nNumB)
	nNumAcell = ensureHorizontal(struct2cell(nNumA));
	nNumBcell = ensureHorizontal(struct2cell(nNumB));
	nNumCell = [nNumAcell; nNumBcell];

	nNumTab = cell2table(nNumCell, 'VariableNames', fieldnames(nNumA));

	figure(ax.Parent.Parent)

	% Delete the tick labels
	set(ax, 'XTickLabel', []);
	set(ax, 'YTickLabel', []);

	% Get the position and units of the axis
	uit_pos = get(ax, 'Position');
	uit_unit = get(ax, 'Units');

	% Create the uitable in the figure
	uit = uitable('Data', nNumCell, 'ColumnName', fieldnames(nNumA), 'Units', uit_unit, 'Position', uit_pos);
	
	% Adjust table appearance
	jScroll = findjobj(uit);
	jTable = jScroll.getViewport.getView;
	jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
	drawnow;
end



function plot_stat_table(ax_stat1, ax_stat2, meStatReport)
    % Set the current figure to the one containing ax_stat1
    figure(ax_stat1.Parent.Parent);

    set(ax_stat1, 'XTickLabel', []);
    set(ax_stat1, 'YTickLabel', []);
    set(ax_stat2, 'XTickLabel', []);
    set(ax_stat2, 'YTickLabel', []);
    
    uit_pos1 = get(ax_stat1, 'Position');
    uit_unit1 = get(ax_stat1, 'Units');
    uit_pos2 = get(ax_stat2, 'Position');
    uit_unit2 = get(ax_stat2, 'Units');

    % Create the table in the correct figure and context
    if isfield(meStatReport, 'fixedEffectsStats') % if LMM or GLMM (mixed models) are used
        chiLRTCell = table2cell(meStatReport.chiLRT);
        chiLRTCell = convertCategoricalToChar(chiLRTCell);
        uit = uitable('Data', chiLRTCell, 'ColumnName', meStatReport.chiLRT.Properties.VariableNames,...
                    'Units', uit_unit1, 'Position', uit_pos1);

        binCompPosthoc = struct2table(meStatReport.mmPvalue);
        binCompPosthoc = table2cell(binCompPosthoc);
        uit = uitable('Data', binCompPosthoc, 'ColumnName', fieldnames(meStatReport.mmPvalue),...
                    'Units', uit_unit2, 'Position', uit_pos2);
    end
    
    % Adjust table appearance
    jScroll = findjobj(uit);
    jTable = jScroll.getViewport.getView;
    jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
    drawnow;
end

function convertedCellArray = convertCategoricalToChar(cellArray)
    % Check and convert categorical or nominal data to char in a cell array
    convertedCellArray = cellArray;  % Copy the input cell array
    
    % Iterate through each element in the cell array
    for i = 1:numel(cellArray)
        % Check if the current element is categorical or nominal
        if iscategorical(cellArray{i}) || isa(cellArray{i}, 'nominal')
            % Convert to char
            convertedCellArray{i} = char(cellArray{i});
        end
    end
end

