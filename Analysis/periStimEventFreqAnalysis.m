function [varargout] = periStimEventFreqAnalysis(alignedData,varargin)
	% Return a new eventProp including event baseDiff 

	% eventProp: a structure containing event properties for a single ROI
	% stimRange: a n x 2 array. n is the repeat times of a stim in a trial
	% timeInfo: time information for a single trial recording
	% roiTrace: trace data for a single roi. It has the same length as the timeInfo

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
        elseif strcmpi('stimEventsPos', varargin{ii})
	        stimEventsPos = varargin{ii+1};
        elseif strcmpi('stimEvents', varargin{ii})
	        stimEvents = varargin{ii+1};
        elseif strcmpi('normToBase', varargin{ii})
	        normToBase = varargin{ii+1};
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

	% plot the peri-stim event frequencies in bins for all the stimulation types in alignedData
	[barStat,stimShadeDataAll,save_dir] = plot_event_freq_alignedData_allTrials(alignedData,'propName',propName,...
	    'baseBinEdgestart',baseBinEdgestart,'baseBinEdgeEnd',baseBinEdgeEnd,'stimIDX',stimIDX,...
	    'normToBase',normToBase,'apCorrection',apCorrection,...
	    'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
	    'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,...
	    'xlabelStr',xlabelStr,'ylabelStr',ylabelStr,...
        'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
		'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,'binWidth',binWidth,...
		'save_fig',save_fig,'save_dir',save_dir,'gui_save',gui_save,'debug_mode',debug_mode);

	% Get the binned data from barStat
	stimTypeNum = numel(stim_names);
	PSEF_Data = empty_content_struct({'stim','binEdges','xData','binData','binMean','binSte','stimShade'},stimTypeNum); % peri-stim event frequency (PSEF) data
	for stn = 1:stimTypeNum
		PSEF_Data(stn).stim = stim_names{stn};
		[PSEF_Data(stn).xData,PSEF_Data(stn).binMean,PSEF_Data(stn).binSte,PSEF_Data(stn).binEdges,PSEF_Data(stn).binData] = get_mean_ste_from_barStat(barStat,PSEF_Data(stn).stim);

		shadeStimTypeNames = {stimShadeDataAll.stimTypeName};
		IDXstimShade = find(strcmpi(PSEF_Data(stn).stim,shadeStimTypeNames));
		PSEF_Data(stn).stimShade = stimShadeDataAll(IDXstimShade);
	end

	% Plot diff between different stimulations
	diffPairNum = numel(diffPair);
	diffStat = empty_content_struct({'groupA','groupB','xA','xB','dataA','dataB','binA','binB','shadeA','shadeB','ABdiff','ttestTab','scatterNum'},diffPairNum);
	figTitleStrCell = cell(diffPairNum,1);
	[fDiff,fDiff_rowNum,fDiff_colNum] = fig_canvas(diffPairNum,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
		'fig_name','diff between event freq'); % create a figure
	tloDiff = tiledlayout(fDiff,fDiff_rowNum,fDiff_colNum);
	[fDiffStat,fDiff_rowNum,fDiff_colNum] = fig_canvas(diffPairNum,'unit_width',0.4,'unit_height',0.4,'column_lim',2,...
		'fig_name','diff between event freq stat'); % create a figure
	tloDiffStat = tiledlayout(fDiffStat,fDiff_rowNum,fDiff_colNum);

	for dpn = 1:diffPairNum
		ax = nexttile(tloDiff);
		stimPairs = stim_names(diffPair{dpn});
		diffStat(dpn).groupA = PSEF_Data(diffPair{dpn}(1)).stim;
		diffStat(dpn).groupB = PSEF_Data(diffPair{dpn}(2)).stim;
		diffStat(dpn).xA = PSEF_Data(diffPair{dpn}(1)).xData;
		diffStat(dpn).xB = PSEF_Data(diffPair{dpn}(2)).xData;
		diffStat(dpn).binA = PSEF_Data(diffPair{dpn}(1)).binEdges;
		diffStat(dpn).binB = PSEF_Data(diffPair{dpn}(2)).binEdges;

		% Shift ap only data, if stim pairs all contains og, and one of them contains ap
		shiftDataPairIDX = find(contains(stimPairs,'ap') & contains(stimPairs,'og')); % index in diffPair{dpn}
		noShiftDataPairIDX = find(contains(stimPairs,'ap') & ~contains(stimPairs,'og')); % index in diffPair{dpn}
		% noShiftDataIDX = diffPair{dpn}(noShiftDataPairIDX); % index in stim_names
		if ~isempty(shiftDataPairIDX) && ~isempty(noShiftDataPairIDX) % all(contains(stimPairs,'og')) && ~isempty(noShiftDataPairIDX)
			noShiftDataIDX = diffPair{dpn}(noShiftDataPairIDX); % index in stim_names
			% shiftDataPairIDX = find(diffPair{dpn}~=noShiftDataIDX); % index in diffPair{dpn}
			shiftDataIDX = diffPair{dpn}(shiftDataPairIDX); % index in stim_names

			shiftData = PSEF_Data(shiftDataIDX).binData(2:end);
			shiftShade = PSEF_Data(shiftDataIDX).stimShade;
			for n = 1:numel(shiftShade.shadeData)
				shiftShade.shadeData{n}(:,1) = shiftShade.shadeData{n}(:,1)-1;
			end

			if noShiftDataPairIDX == 1
				diffStat(dpn).dataA = PSEF_Data(noShiftDataIDX).binData;
				diffStat(dpn).dataB = shiftData;

				diffStat(dpn).shadeA = PSEF_Data(noShiftDataIDX).stimShade;
				diffStat(dpn).shadeB = shiftShade;
			else
				diffStat(dpn).dataA = shiftData;
				diffStat(dpn).dataB = PSEF_Data(noShiftDataIDX).binData;

				diffStat(dpn).shadeA = shiftShade;
				diffStat(dpn).shadeB = PSEF_Data(noShiftDataIDX).stimShade;
			end
		else
			diffStat(dpn).dataA = PSEF_Data(diffPair{dpn}(1)).binData;
			diffStat(dpn).dataB = PSEF_Data(diffPair{dpn}(2)).binData;
			diffStat(dpn).shadeA = PSEF_Data(diffPair{dpn}(1)).stimShade;
			diffStat(dpn).shadeB = PSEF_Data(diffPair{dpn}(2)).stimShade;
		end

		figTitleStrCell{dpn} = sprintf('diff between %s and %s in %gs bins%s%s',...
			diffStat(dpn).groupA,diffStat(dpn).groupB,binWidth,normToBaseStr);

		[ttestVal,diffVal,scatterNum]=plot_diff_usingRawData(diffStat(dpn).xA,diffStat(dpn).dataA,diffStat(dpn).dataB,...
			'legStrA',diffStat(dpn).groupA,'legStrB',diffStat(dpn).groupB,'new_xticks',diffStat(dpn).binA,...
			'ylabelStr',ylabelStr,'figTitleStr',figTitleStrCell{dpn},...
			'stimShadeDataA',diffStat(dpn).shadeA.shadeData,'stimShadeDataB',diffStat(dpn).shadeB.shadeData,...
			'stimShadeColorA',diffStat(dpn).shadeA.color,'stimShadeColorB',diffStat(dpn).shadeB.color,...
			'save_fig',false,'save_dir',save_dir,'plotWhere',gca);
		ax = nexttile(tloDiffStat);
		ttestP1TableVarNames = NumArray2StringCell(diffStat(dpn).xA);
		ttestP1Table = array2table(ttestVal,'VariableNames',ttestP1TableVarNames(1:length(ttestVal)),'RowNames',{'p','h'});
		plotUItable(fDiffStat,ax,ttestP1Table);
	end

		% Save figure and statistics
	if save_fig
		% if isempty(save_dir)
		% 	gui_save = 'on';
		% end
		% msg = 'Choose a folder to save plots of peri-stim event frequency and the difference between stim groups';

		titleStr = sprintf('periStimEventFreqDiff in %g s bins [%s]%s',binWidth,propName,normToBaseStr);
		titleStr = strrep(titleStr,'_',' ');

		save_dir = savePlot(fDiff,'save_dir',save_dir,'guiSave','off',...
			'fname',titleStr);
		save_dir = savePlot(fDiffStat,'save_dir',save_dir,'guiSave','off',...
			'fname',[titleStr,'ttest']);
		save(fullfile(save_dir, ['periStimEventAnalysisStat']),...
		    'barStat','diffStat');
	end 
	varargout{1} = barStat;
	varargout{2} = diffStat;
	varargout{3} = save_dir;
end