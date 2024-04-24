function [varargout] = periStimEventFreqAnalysis(alignedData,varargin)
	% Return a new eventProp including event baseDiff 

	% alignedData: output of function 'get_event_trace_allTrials'


	% Defaults
	filter_roi_tf = false; % true/false. If true, screen ROIs
	stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	diffPair = {[1 3], [2 3]}; % binned freq will be compared between stimualtion groups. cell number = stimulation pairs. [1 3] mean stimulation 1 vs stimulation 2

	propName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
	binWidth = 1; % the width of histogram bin. the default value is 1 s.
	stimIDX = []; % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
	preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
	postStim_duration = 10; % unit: second. include events happened after the end of stimulations

	customizeEdges = false; % customize the bins using function 'setPeriStimSectionForEventFreqCalc'
	stimEffectDuration = 1; % unit: second. Use this to set the end for the stimulation effect range

	splitLongStim = [1]; % If the stimDuration is longer than stimEffectDuration, the stimDuration 
						%  part after the stimEffectDuration will be splitted. If it is [1 1], the
						% time during stimulation will be splitted using edges below
						% [stimStart, stimEffectDuration, stimEffectDuration+splitLongStim, stimEnd] 

	stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
	stimEvents(1).stimName = 'og-5s';
	stimEvents(1).eventCat = 'rebound';
	stimEvents(2).stimName = 'ap-0.1s';
	stimEvents(2).eventCat = 'trig';
	stimEvents(3).stimName = 'og-5s ap-0.1s';
	stimEvents(3).eventCat = 'rebound';

	normToBase = true; % true/false. normalize the data to baseline (data before baseBinEdge)
	baseBinEdgestart = -preStim_duration; % where to start to use the bin for calculating the baseline. -1
	baseBinEdgeEnd = -2; % 0
	apCorrection = false; % true/false. If true, correct baseline bin used for normalization. 

	groupAforNormB = 'og-5s'; % plot the normB (the fold of dataA) in fig C if the groupA is this
	xTickAngle = 45;
	errorBarColor = {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'};
	scatterColor = errorBarColor;
	scatterSize = 20;
	scatterAlpha = 0.5;
	stimShadeColorA = {'#F05BBD','#4DBEEE','#ED8564'};
	stimShadeColorB = {'#F05BBD','#4DBEEE','#ED8564'};
	shadeHeightScale = 0.05; % percentage of y axes
	shadeGapScale = 0.01; % diff between two shade in percentage of y axes

	save_fig = false; % true/false
	save_dir = '';
	gui_save = 'off';

	debug_mode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('filter_roi_tf', varargin{ii})
	        filter_roi_tf = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stim_names', varargin{ii})
	        stim_names = varargin{ii+1};
        elseif strcmpi('filters', varargin{ii})
	        filters = varargin{ii+1};
        elseif strcmpi('diffPair', varargin{ii})
	        diffPair = varargin{ii+1};
        elseif strcmpi('propName', varargin{ii})
	        propName = varargin{ii+1};
        elseif strcmpi('binWidth', varargin{ii})
	        binWidth = varargin{ii+1};
        elseif strcmpi('stimIDX', varargin{ii})
	        stimIDX = varargin{ii+1};
        elseif strcmpi('preStim_duration', varargin{ii})
	        preStim_duration = varargin{ii+1};
        elseif strcmpi('postStim_duration', varargin{ii})
	        postStim_duration = varargin{ii+1};
        elseif strcmpi('customizeEdges', varargin{ii}) 
            customizeEdges = varargin{ii+1}; 
        elseif strcmpi('PeriBaseRange', varargin{ii}) 
            PeriBaseRange = varargin{ii+1}; 
        elseif strcmpi('stimEffectDuration', varargin{ii}) 
            stimEffectDuration = varargin{ii+1}; 
        elseif strcmpi('splitLongStim', varargin{ii})
	        splitLongStim = varargin{ii+1};
        elseif strcmpi('stimEventsPos', varargin{ii})
	        stimEventsPos = varargin{ii+1};
        elseif strcmpi('stimEvents', varargin{ii})
	        stimEvents = varargin{ii+1};
        elseif strcmpi('normToBase', varargin{ii})
	        normToBase = varargin{ii+1};
        elseif strcmpi('xTickAngle', varargin{ii})
	        xTickAngle = varargin{ii+1};
        elseif strcmpi('baseBinEdgestart', varargin{ii})
	        baseBinEdgestart = varargin{ii+1};
        elseif strcmpi('baseBinEdgeEnd', varargin{ii})
	        baseBinEdgeEnd = varargin{ii+1};
        elseif strcmpi('apCorrection', varargin{ii})
	        apCorrection = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
        elseif strcmpi('gui_save', varargin{ii})
	        gui_save = varargin{ii+1};
        elseif strcmpi('debug_mode', varargin{ii})
	        debug_mode = varargin{ii+1};
	    end
	end	

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
        'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
		'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,'binWidth',binWidth,...
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

	% % Fig C. Plot the diff. dataB is normalized to the means of dataA (every bin is normalized separately)
	% [fDiff2,~,~] = fig_canvas(diffPairNum,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
	% 	'fig_name','diff between event freq normDataB'); % create a figure
	% tloDiff2 = tiledlayout(fDiff2,fDiff_rowNum,fDiff_colNum);
	% [fDiffStat2,~,~] = fig_canvas(diffPairNum,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
	% 	'fig_name','diff between event freq stat normDataB'); % create a figure
	% tloDiffStat2 = tiledlayout(fDiffStat2,fDiff_rowNum,fDiff_colNum);


	% organize the data in PSEF to compare peri-stim event frequencies from recordings applied with
	% different stimulation
	[diffStat] = organizeDataForDiffComp(PSEF_Data,diffPair);

	% plot fig B and fig C. compare the peri-stim event frequencies from recordings applied with
	% different stimulation
	for dpn = 1:diffPairNum
		figTitleStrCell{dpn} = sprintf('diff between %s and %s in %gs bins%s%s',...
			diffStat(dpn).groupA,diffStat(dpn).groupB,binWidth,normToBaseStr);

		new_xticks = diffStat(dpn).xA;
		new_xticksLabel = diffStat(dpn).binNamesAB;

		% if diffStat(dpn).shiftBins
		% 	new_xticks = diffStat(dpn).xA;
		% 	new_xticksLabel = diffStat(dpn).binNamesAB;
		% else
		% 	new_xticks = diffStat(dpn).binEdgesA;
		% 	new_xticksLabel = {};
		% end

		% fig B
		ax = nexttile(tloDiff);
		[diffStat(dpn).ttestAB,diffStat(dpn).diffAB]=plot_diff_usingRawData(diffStat(dpn).xA,diffStat(dpn).dataA,diffStat(dpn).dataB,...
			'legStrA',diffStat(dpn).groupA,'legStrB',diffStat(dpn).groupB,'ylabelStr',ylabelStr,...
			'new_xticks',new_xticks,'new_xticksLabel',new_xticksLabel,'figTitleStr',figTitleStrCell{dpn},...
			'stimShadeDataA',diffStat(dpn).shadeA.shadeData,'stimShadeDataB',diffStat(dpn).shadeB.shadeData,...
			'stimShadeColorA',diffStat(dpn).shadeA.color,'stimShadeColorB',diffStat(dpn).shadeB.color,...
			'xTickAngle',xTickAngle,'save_fig',false,'save_dir',save_dir,'plotWhere',gca);

		% fig B stat
		ax = nexttile(tloDiffStat);
		ttestP1TableVarNames = NumArray2StringCell(diffStat(dpn).xA);
		ttestP1Table = array2table(diffStat(dpn).ttestAB,...
			'VariableNames',ttestP1TableVarNames(1:length(diffStat(dpn).ttestAB)),'RowNames',{'p','h'});
		plotUItable(fDiffStat,ax,ttestP1Table);

		% % fig C
		% ax = nexttile(tloDiff2);
		% [diffStat(dpn).ttestABnorm,diffStat(dpn).diffABnorm]=plot_diff_usingRawData(diffStat(dpn).xA,diffStat(dpn).dataA,diffStat(dpn).dataBnorm,...
		% 	'legStrA',diffStat(dpn).groupA,'legStrB',diffStat(dpn).groupB,'ylabelStr',ylabelStr,...
		% 	'new_xticks',new_xticks,'new_xticksLabel',new_xticksLabel,'figTitleStr',figTitleStrCell{dpn},...
		% 	'stimShadeDataA',diffStat(dpn).shadeA.shadeData,'stimShadeDataB',diffStat(dpn).shadeB.shadeData,...
		% 	'stimShadeColorA',diffStat(dpn).shadeA.color,'stimShadeColorB',diffStat(dpn).shadeB.color,...
		% 	'save_fig',false,'save_dir',save_dir,'plotWhere',gca);

		% % fig C stat
		% ax = nexttile(tloDiffStat2);
		% % ttestP1TableVarNames = NumArray2StringCell(diffStat(dpn).xA);
		% ttestP1TableNorm = array2table(diffStat(dpn).ttestABnorm,...
		% 	'VariableNames',ttestP1TableVarNames(1:length(diffStat(dpn).ttestABnorm)),'RowNames',{'p','h'});
		% plotUItable(fDiffStat2,ax,ttestP1TableNorm);
	end

	% Fig C. Plot the dataB normalized to the means of dataA (every bin is normalized separately,
	% so these are the multiples of dataA)
	titleStrBnorm = sprintf('event freq as n-fold of %s data\n%sData normalized to %s data',...
		groupAforNormB,normToBaseStr,groupAforNormB);
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

		titleStr = sprintf('periStimEventFreqDiff in %g s bins [%s]%s',binWidth,propName,normToBaseStr);
		titleStr = strrep(titleStr,'_',' ');
		titleStrNormB = sprintf('event freq as n-fold of %s data %s',groupAforNormB,normToBaseStr);
		titleStrNormBstat = sprintf('event freq as n-fold of %s data %s stat',groupAforNormB,normToBaseStr);
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