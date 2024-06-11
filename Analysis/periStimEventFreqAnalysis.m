function [varargout] = periStimEventFreqAnalysis(alignedData,varargin)
	% Generate plots showing the event frequency in various period of the peri-stimulation window

	% varargout contains the statistics comparing the event frequency in recordings applied with
	% various stimulations
	%		varargout{1} = barStat;
	% 		varargout{2} = diffStat;
	% 		varargout{3} = save_dir;


	% alignedData: output of function 'get_event_trace_allTrials'

	% Initialize input parser
	p = inputParser;

	% Add parameters to the parser with default values and comments
	addParameter(p, 'filter_roi_tf', false); % true/false. If true, screen ROIs
	addParameter(p, 'stim_names', {'og-5s','ap-0.1s','og-5s ap-0.1s'}); % compare the alignedData.stim_name with these strings and decide what filter to use
	addParameter(p, 'filters', {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}); % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	addParameter(p, 'subNucleiFilter', '',...
					@(x) any(validatestring(x,{'','PO','DAO'}))); % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	addParameter(p, 'diffPair', {[1 3], [2 3]}); % binned freq will be compared between stimulation groups. cell number = stimulation pairs. [1 3] mean stimulation 1 vs stimulation 2
	addParameter(p, 'propName', 'peak_time'); % 'rise_time'/'peak_time'. Choose one to find the locations of events
	addParameter(p, 'binWidth', 1); % the width of histogram bin. the default value is 1 s.
	addParameter(p, 'stimIDX', []); % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
	addParameter(p, 'preStim_duration', 5); % unit: second. include events happened before the onset of stimulations
	addParameter(p, 'postStim_duration', 10); % unit: second. include events happened after the end of stimulations
	addParameter(p, 'customizeEdges', false); % customize the bins using function 'setPeriStimSectionForEventFreqCalc'
	addParameter(p, 'stimEffectDuration', 1); % unit: second. Use this to set the end for the stimulation effect range
	addParameter(p, 'splitLongStim', [1]); % If the stimDuration is longer than stimEffectDuration, the stimDuration 
	                                      % part after the stimEffectDuration will be splitted. If it is [1 1], the
	                                      % time during stimulation will be splitted using edges below
	                                      % [stimStart, stimEffectDuration, stimEffectDuration+splitLongStim, stimEnd]
	addParameter(p, 'stimEventsPos', false); % true/false. If true, only use the peri-stim ranges with stimulation related events
	addParameter(p, 'stimEvents', struct('stimName', {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}, 'eventCat', {'rebound', 'trig', 'rebound'}));
	addParameter(p, 'normToBase', true); % true/false. normalize the data to baseline (data before baseBinEdge)
	addParameter(p, 'baseBinEdgestart', -5); % where to start to use the bin for calculating the baseline. -1
	addParameter(p, 'baseBinEdgeEnd', -2); % 0
	addParameter(p, 'apCorrection', false); % true/false. If true, correct baseline bin used for normalization. 
	addParameter(p, 'groupAforNormB', 'og-5s'); % plot the normB (the fold of dataA) in fig C if the groupA is this
	addParameter(p, 'xTickAngle', 45);
	addParameter(p, 'errorBarColor', {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'});
	addParameter(p, 'scatterColor', {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'});
	addParameter(p, 'scatterSize', 20);
	addParameter(p, 'scatterAlpha', 0.5);
	addParameter(p, 'stimShadeColorA', {'#F05BBD','#4DBEEE','#ED8564'});
	addParameter(p, 'stimShadeColorB', {'#F05BBD','#4DBEEE','#ED8564'});
	addParameter(p, 'shadeHeightScale', 0.05); % percentage of y axes
	addParameter(p, 'shadeGapScale', 0.01); % diff between two shades in percentage of y axes
	addParameter(p, 'save_fig', false); % true/false
	addParameter(p, 'save_dir', ''); 
	addParameter(p, 'gui_save', false);
	addParameter(p, 'debug_mode', false); % true/false

	% Parse the inputs
	parse(p, varargin{:});

	% Assign parsed values to variables
	filter_roi_tf = p.Results.filter_roi_tf;
	stim_names = p.Results.stim_names;
	filters = p.Results.filters;
	subNucleiFilter = p.Results.subNucleiFilter;
	diffPair = p.Results.diffPair;
	propName = p.Results.propName;
	binWidth = p.Results.binWidth;
	stimIDX = p.Results.stimIDX;
	preStim_duration = p.Results.preStim_duration;
	postStim_duration = p.Results.postStim_duration;
	customizeEdges = p.Results.customizeEdges;
	stimEffectDuration = p.Results.stimEffectDuration;
	splitLongStim = p.Results.splitLongStim;
	stimEventsPos = p.Results.stimEventsPos;
	stimEvents = p.Results.stimEvents;
	normToBase = p.Results.normToBase;
	baseBinEdgestart = p.Results.baseBinEdgestart;
	baseBinEdgeEnd = p.Results.baseBinEdgeEnd;
	apCorrection = p.Results.apCorrection;
	groupAforNormB = p.Results.groupAforNormB;
	xTickAngle = p.Results.xTickAngle;
	errorBarColor = p.Results.errorBarColor;
	scatterColor = p.Results.scatterColor;
	scatterSize = p.Results.scatterSize;
	scatterAlpha = p.Results.scatterAlpha;
	stimShadeColorA = p.Results.stimShadeColorA;
	stimShadeColorB = p.Results.stimShadeColorB;
	shadeHeightScale = p.Results.shadeHeightScale;
	shadeGapScale = p.Results.shadeGapScale;
	save_fig = p.Results.save_fig;
	save_dir = p.Results.save_dir;
	gui_save = p.Results.gui_save;
	debug_mode = p.Results.debug_mode;


	% Create the label string
	if normToBase
		normToBaseStr = ' normToBase';
	else
		normToBaseStr = '';
	end
	ylabelStr = sprintf('eventFreq %s',normToBaseStr);
	xlabelStr = 'time (s)';

	% Fig A. plot the peri-stim event frequencies in bins for all the stimulation types in alignedData
	[barStat,stimShadeDataAll,save_dir] = plot_event_freq_alignedData_allTrials(alignedData,'propName',propName,...
	    'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,'stimIDX',stimIDX,...
	    'normToBase',normToBase,'apCorrection',apCorrection,...
	    'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
	    'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim,...
	    'xlabelStr',xlabelStr,'ylabelStr',ylabelStr,'xTickAngle',xTickAngle,...
        'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,'binWidth',binWidth,...
		'subNucleiFilter',subNucleiFilter,'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
		'save_fig',save_fig,'save_dir',save_dir,'gui_save',gui_save,'debug_mode',debug_mode);

	% Get the binned data from barStat
	stimTypeNum = numel(stim_names);
	PSEF_Data = empty_content_struct({'stim','binEdges','binNames','xData','binData','binMean','binSte','stimShade'},stimTypeNum); % peri-stim event frequency (PSEF) data
	for stn = 1:stimTypeNum
		PSEF_Data(stn).stim = stim_names{stn};
		[PSEF_Data(stn).xData,PSEF_Data(stn).binMean,PSEF_Data(stn).binSte,PSEF_Data(stn).binEdges,PSEF_Data(stn).binData,PSEF_Data(stn).binNames] = get_mean_ste_from_barStat(barStat,PSEF_Data(stn).stim);

		shadeStimTypeNames = {stimShadeDataAll.stimTypeName};
		IDXstimShade = find(strcmpi(PSEF_Data(stn).stim,shadeStimTypeNames));
		PSEF_Data(stn).stimShade = stimShadeDataAll(IDXstimShade);
		% PSEF_Data(stn).periStimGroups = stimShadeDataAll(IDXstimShade);
	end


	% Fig B. Plot the diff (two groups as a pair ('diffPair')). Data is organized by the function 'organizeDataForDiffComp'
	% create fig canvas for plotting diff between different stimulations. Create struct var to save data
	diffPairNum = numel(diffPair);
	% diffStat = empty_content_struct({'groupA','groupB','xA','xB','dataA','dataB','binA','binB','xGroupA','xGroupB','shadeA','shadeB','ABdiff','ttestTab','scatterNum'},diffPairNum);
	figTitleStrCell = cell(diffPairNum,1);
	[fDiff,fDiff_rowNum,fDiff_colNum] = fig_canvas(diffPairNum,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
		'fig_name','diff between event freq'); % create a figure
	tloDiff = tiledlayout(fDiff,fDiff_rowNum,fDiff_colNum);
	[fDiffStat,~,~] = fig_canvas(diffPairNum,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
		'fig_name','diff between event freq stat'); % create a figure
	tloDiffStat = tiledlayout(fDiffStat,fDiff_rowNum,fDiff_colNum);


	% organize the data in PSEF to compare peri-stim event frequencies from recordings applied with
	% different stimulation
	[diffStat] = organizeDataForDiffComp(PSEF_Data,diffPair);

	% plot fig B and fig C. compare the peri-stim event frequencies from recordings applied with
	% different stimulation
	for dpn = 1:diffPairNum
		figTitleStrCell{dpn} = sprintf('%s diff between %s and %s in %gs bins%s%s',...
			subNucleiFilter, diffStat(dpn).groupA,diffStat(dpn).groupB,binWidth,normToBaseStr);

		new_xticks = diffStat(dpn).xA;
		new_xticksLabel = diffStat(dpn).binNamesAB;


		% fig B
		ax = nexttile(tloDiff);
		[diffStat(dpn).ttestAB,diffStat(dpn).diffAB]=plot_diff_usingRawData(diffStat(dpn).xA,diffStat(dpn).dataA,diffStat(dpn).dataB,...
			'legStrA',diffStat(dpn).groupA,'legStrB',diffStat(dpn).groupB,'ylabelStr',ylabelStr,...
			'new_xticks',new_xticks,'new_xticksLabel',new_xticksLabel,'figTitleStr',figTitleStrCell{dpn},...
			'stimShadeDataA',diffStat(dpn).shadeA.shadeData,'stimShadeDataB',diffStat(dpn).shadeB.shadeData,...
			'xTickAngle',xTickAngle,'save_fig',false,'save_dir',save_dir,'plotWhere',gca);
		%'stimShadeColorA',diffStat(dpn).shadeA.color,'stimShadeColorB',diffStat(dpn).shadeB.color,...

		% fig B stat
		ax = nexttile(tloDiffStat);
		ttestP1TableVarNames = NumArray2StringCell(diffStat(dpn).xA);
		ttestP1Table = array2table(diffStat(dpn).ttestAB,...
			'VariableNames',ttestP1TableVarNames(1:length(diffStat(dpn).ttestAB)),'RowNames',{'p','h'});
		plotUItable(fDiffStat,ax,ttestP1Table);

	end

	% Fig C. Plot the dataB normalized to the means of dataA (every bin is normalized separately,
	% so these are the multiples of dataA)
	titleStrBnorm = sprintf('%s event freq as n-fold of %s data\n%sData normalized to %s data',...
		subNucleiFilter, groupAforNormB,normToBaseStr,groupAforNormB);
	titleStrBnorm = strrep(titleStrBnorm,'_', ' ');
	[fdataBnorm,~,~] = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
		'fig_name',titleStrBnorm); % create a figure

	% get the groupB data from diff if the groupA is groupAforNormB
	BnormIDX = find(strcmpi({diffStat.groupA},groupAforNormB));
	diffStatBnorm = diffStat(BnormIDX);
	xDataCells = {diffStatBnorm.xB};
	yDataCells = {diffStatBnorm.dataBnorm};
	xlabelStr = '';
	ylabelStr = sprintf('n-fold of %s data',groupAforNormB);
	legStr = {diffStatBnorm.groupB};
	stimShadeData = {diffStatBnorm.shadeB};

	[~,longerDataIDX] = max(cellfun(@numel,{diffStatBnorm.xB}));
	new_xticks = diffStatBnorm(longerDataIDX).xB;
	new_xticksLabel = diffStatBnorm(longerDataIDX).binNamesAB;

	[ttestNormB] = plot_errorBarLines_with_scatter_stimShade(xDataCells,yDataCells,...
		'legStr',legStr,'stimShadeData',stimShadeData,'xlabelStr',xlabelStr,'ylabelStr',ylabelStr,...
		'new_xticks',new_xticks,'new_xticksLabel',new_xticksLabel,'figTitleStr',titleStrBnorm,...
		'xTickAngle',xTickAngle,'plotWhere',gca);

	if ~isempty(ttestNormB)
		[~,shorterDataIDX] = min(cellfun(@numel,{diffStatBnorm.xB}));
		ttestNormBvarNames = diffStatBnorm(shorterDataIDX).binNamesAB;
		ttestNormBtable = array2table(ttestNormB,...
			'VariableNames',ttestNormBvarNames,'RowNames',{'p','h'});
		titleStrBnormStat = sprintf('%s\ntwo-sample ttest',titleStrBnorm);
		[fstatBnorm,~,~] = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
			'fig_name',titleStrBnormStat); % create a figure

		plotUItable(fstatBnorm,gca,ttestNormBtable);
	end


	% Save figure and statistics
	if save_fig

		titleStr = sprintf('%s periStimEventFreqDiff in %g s bins [%s]%s',subNucleiFilter, binWidth,propName,normToBaseStr);
		titleStr = strrep(titleStr,'_',' ');
		titleStrNormB = sprintf('%s event freq as n-fold of %s data %s',subNucleiFilter,groupAforNormB,normToBaseStr);
		titleStrNormBstat = sprintf('%s event freq as n-fold of %s data %s stat',subNucleiFilter,groupAforNormB,normToBaseStr);
		% titleStrNormB = strrep(titleStrNormB,'_',' ');

		save_dir = savePlot(fDiff,'save_dir',save_dir,'guiSave','off',...
			'fname',titleStr);
		save_dir = savePlot(fDiffStat,'save_dir',save_dir,'guiSave','off',...
			'fname',[titleStr,'ttest']);

		if ~isempty(ttestNormB)
			save_dir = savePlot(fdataBnorm,'save_dir',save_dir,'guiSave','off',...
				'fname',titleStrNormB);
			save_dir = savePlot(fstatBnorm,'save_dir',save_dir,'guiSave','off',...
				'fname',titleStrNormBstat);
		end
		% save_dir = savePlot(fDiffStat2,'save_dir',save_dir,'guiSave','off',...
		% 	'fname',[titleStrNormB,'ttest']);
		save(fullfile(save_dir, ['periStimEventAnalysisStat']),...
		    'barStat','diffStat');
	end 
	varargout{1} = barStat;
	varargout{2} = diffStat;
	varargout{3} = save_dir;
end