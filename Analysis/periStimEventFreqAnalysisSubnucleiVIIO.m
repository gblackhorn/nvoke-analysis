function [barStat, diffStat, varargout] = periStimEventFreqAnalysisSubnucleiVIIO(alignedData,varargin)
	% Generate plots showing the event frequency in various period of the peri-stimulation window

	% varargout contains the statistics comparing the event frequency in recordings applied with
	% various stimulations
	%		varargout{1} = barStat;
	% 		varargout{2} = diffStat;
	% 		varargout{3} = saveDir;


	% alignedData: output of function 'get_event_trace_allTrials'

	% Initialize input parser
	p = inputParser;

	% Add parameters to the parser with default values and comments
	addParameter(p, 'filter_roi_tf', true); % true/false. If true, screen ROIs
	addParameter(p, 'stim_names', {'og-5s','ap-0.1s','og-5s ap-0.1s'}); % compare the alignedData.stim_name with these strings and decide what filter to use
	addParameter(p, 'filters', {[0 nan nan nan], [nan nan nan nan], [0 nan nan nan]}); % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	% addParameter(p, 'subNucleiFilter', '',...
	% 				@(x) any(validatestring(x,{'','PO','DAO'}))); % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	addParameter(p, 'diffPair', {[1 3], [2 3], [1 2]}); % binned freq will be compared between stimulation groups. cell number = stimulation pairs. [1 3] mean stimulation 1 vs stimulation 2
	addParameter(p, 'propName', 'peak_time'); % 'rise_time'/'peak_time'. Choose one to find the locations of events
	addParameter(p, 'binWidth', 1); % the width of histogram bin. the default value is 1 s.
	addParameter(p, 'stimIDX', []); % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
	addParameter(p, 'preStim_duration', 5); % unit: second. include events happened before the onset of stimulations
	addParameter(p, 'postStim_duration', 15); % unit: second. include events happened after the end of stimulations
	addParameter(p, 'customizeEdges', true); % customize the bins using function 'setPeriStimSectionForEventFreqCalc'
	addParameter(p, 'stimEffectDuration', 1); % unit: second. Use this to set the end for the stimulation effect range
	addParameter(p, 'splitLongStim', [1]); % If the stimDuration is longer than stimEffectDuration, the stimDuration 
	                                      % part after the stimEffectDuration will be splitted. If it is [1 1], the
	                                      % time during stimulation will be splitted using edges below
	                                      % [stimStart, stimEffectDuration, stimEffectDuration+splitLongStim, stimEnd]
	addParameter(p, 'stimEventsPos', false); % true/false. If true, only use the peri-stim ranges with stimulation related events
	addParameter(p, 'stimEvents', struct('stimName', {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}, 'eventCat', {'rebound', 'trig', 'rebound'}, 'eventCatFollow', {'spon', 'spon', 'spon'}));
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
	addParameter(p, 'saveDir', ''); 
	addParameter(p, 'gui_save', false);
	addParameter(p, 'debug_mode', false); % true/false

	% Parse the inputs
	parse(p, varargin{:});

	% Assign parsed values to variables
	filter_roi_tf = p.Results.filter_roi_tf;
	stim_names = p.Results.stim_names;
	filters = p.Results.filters;
	% subNucleiFilter = p.Results.subNucleiFilter;
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
	saveDir = p.Results.saveDir;
	gui_save = p.Results.gui_save;
	debug_mode = p.Results.debug_mode;



	% Loop through DAO and PO groups
	subNucleiTypes = {'DAO', 'PO'};
	barStat = empty_content_struct(subNucleiTypes,1);
	diffStat = empty_content_struct(subNucleiTypes,1);
	for i = 1:numel(subNucleiTypes)
		subNucleiFilter = subNucleiTypes{i};

		if i ~= 1
			gui_save = false;
		end

		[barStat.(subNucleiFilter),diffStat.(subNucleiFilter),saveDir] = periStimEventFreqAnalysis(alignedData,'propName',propName,...
			'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,'subNucleiFilter',subNucleiFilter,...
			'diffPair',diffPair,'binWidth',binWidth,'stimIDX',stimIDX,'normToBase',normToBase,...
			'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
			'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,'splitLongStim',splitLongStim,...
			'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
			'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,...
			'save_fig',save_fig,'save_dir',saveDir,'gui_save',gui_save,'debug_mode',debug_mode);


		% Compare the fold change of AP (norm to AP baseline) and OGAP (norm to the AP bin in OG recordings)
		normToFirst = false; % true/false. violinPlot: normalize all the data to the mean of the first group (first stimNames)

		if normToFirst
			normStr = sprintf(' normTo[%s]',violinStimNames{1});
		else
			normStr = '';
		end


		% Compare event frequency of bins from different or same stimualtion recordings and create violin plots
		% Modify the 'violinStimNames' and 'violinBinIDX' to specify the bins to be compared
		% event freq comparison: OG vs OGAP in AP bin

		% Airpuff effect is almost only seen in the caudal PO. DAO rarely shows airpuff response
		if strcmpi(subNucleiFilter, 'PO') 
			violinStimNames = {'og-5s ap-0.1s','og-5s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. these groups will be used for the violin plot
			violinBinIDX = [4,4]; % [4,3,4]. violinPlot: the nth bin from the data listed in stimNames
			titleStr = sprintf('%s violinPlot of a single bin from periStim freq%s',subNucleiFilter, normStr);
			[violinData1,statInfo1] = violinplotPeriStimFreq2(barStat.(subNucleiFilter),violinStimNames,violinBinIDX,...
				'normToFirst',normToFirst,'titleStr',titleStr,...
				'save_fig',save_fig,'save_dir',saveDir,'gui_save','off');

			% event freq comparison: baseline of AP vs AP
			violinStimNames = {'ap-0.1s','ap-0.1s'}; % {'og-5s','ap-0.1s','og-5s ap-0.1s'}. these groups will be used for the violin plot
			violinBinIDX = [1,3]; % [4,3,4]. violinPlot: the nth bin from the data listed in stimNames
			titleStr = sprintf('%s violinPlot of a single bin from periStim freq%s',subNucleiFilter, normStr);
			[violinData2,statInfo2] = violinplotPeriStimFreq2(barStat.(subNucleiFilter),violinStimNames,violinBinIDX,...
				'normToFirst',normToFirst,'titleStr',titleStr,...
				'save_fig',save_fig,'save_dir',saveDir,'gui_save','off');

			% bar plot of the fold-change of event frequency in statInfo1 and statInfo2
			% APstim/APbaseline VS OGAP/OG
			% Require the 'statInfo1' and 'statInfo2' above
			titleStrFold = sprintf('%s foldChange of eventFreq caused by AP with and without OG',subNucleiFilter);
			[f,f_rowNum,f_colNum] = fig_canvas(2,'unit_width',0.4,'unit_height',0.4,...
				'column_lim',2,...
			    'fig_name',[titleStrFold,' bar']); % create a figure
			tlo = tiledlayout(f, 1, 2); % setup tiles
			% Bar plot
			axBar = nexttile(tlo,[1 1]); 
			foldDataOGAP = statInfo1.data.OGAP/mean(statInfo1.data.OG);  
			foldDataAP = statInfo2.data.APfirstStim/mean(statInfo2.data.APbaseline);
			[barInfo,~,barInfoStatTab] = barplot_with_stat({foldDataAP,foldDataOGAP},'plotWhere',axBar,...
				'group_names',{'AP without OG','AP with OG'},'ylabelStr','eventFreq fold-change',...
				'save_fig',false,'save_dir',saveDir,'gui_save',false); % 'title_str',title_str,
			% plot stat results next to bars
			axStat = nexttile(tlo,[1 1]);
			plotUItable(gcf,axStat,barInfoStatTab);
			title(barInfo.stat.method)
			if save_fig
				savePlot(f,'save_dir',saveDir,'guiSave','off','fname',titleStr);
			end
			violinplotWithStat({foldDataAP,foldDataOGAP},'groupNames',{'AP without OG','AP with OG'},...
			    'titleStr',[titleStrFold,' violin'],'save_fig',save_fig,'save_dir',saveDir);
		end
	end

	% Save stat data
	if save_fig
		save(fullfile(saveDir, ['periStimStatInfo_subNuclei']), 'barStat', 'diffStat');
	end

	varargout{1} = saveDir;
end