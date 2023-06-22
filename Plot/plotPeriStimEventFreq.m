function [varargout] = plotPeriStimEventFreq(alignedData,varargin)
	% Plot the event frequency in specified time bins to examine the effect of stimulation and
	% compare each pair of bins
	% ROIs can be filtered according to the effect of stimulations on them

	% Note: When using 'normToBase', trials applied with 'ap-0.1s' will be normalized to an earlier
	% bin (decided by baseBinEdgeEnd_apCorrection)

	% Example:
	%	plot_calcium_signals_alignedData_allTrials(alignedData,'filter_roi_tf',true); 
	%		

	% Defaults
	filter_roi_tf = false; % do not filter ROIs by default
	stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound

	plot_unit_width = 0.4; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display

	normToBase = false; % normalize the data to baseline (data before baseBinEdgeEnd)
	baseBinEdgestart = -1; % where to start to use the bin for calculating the baseline
	baseBinEdgeEnd = 0;
	baseBinEdgeEnd_apCorrection = -1; % use an earlier bin for AP stimulation
	apCorrection = true;
	
	PropName = 'rise_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
	stimIDX = []; % specify stimulation repeats around which the events will be gathered 
	% plotHisto = false; % true/false [default].Plot histogram if true.

	AlignEventsToStim = true; % align the EventTimeStamps to the onsets of the stimulations: subtract EventTimeStamps with stimulation onset time
	preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
	postStim_duration = 5; % unit: second. include events happened after the end of stimulations
	round_digit_sig = 2; % round to the Nth significant digit for duration

	stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
	stimEvents(1).stimName = 'og-5s';
	stimEvents(1).eventCat = 'rebound';
	stimEvents(2).stimName = 'ap-0.1s';
	stimEvents(2).eventCat = 'trig';
	stimEvents(3).stimName = 'og-5s ap-0.1s';
	stimEvents(3).eventCat = 'rebound';

	xlabelStr = 'Time (s)';
	ylabelStr = '';
	shadeColors = {'#F05BBD','#4DBEEE','#ED8564'}; % og, ap, others

	save_fig = false;
	save_dir = '';
	gui_save = false;

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('filter_roi_tf', varargin{ii})
	        filter_roi_tf = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('stim_names', varargin{ii})
	        stim_names = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('filters', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        filters = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('baseBinEdgestart', varargin{ii})
            baseBinEdgestart = varargin{ii+1};
	    elseif strcmpi('baseBinEdgeEnd', varargin{ii})
            baseBinEdgeEnd = varargin{ii+1};
	    elseif strcmpi('normToBase', varargin{ii})
            normToBase = varargin{ii+1};
	    elseif strcmpi('apCorrection', varargin{ii})
            apCorrection = varargin{ii+1};
	    elseif strcmpi('binWidth', varargin{ii})
            binWidth = varargin{ii+1};
	    elseif strcmpi('PropName', varargin{ii})
            PropName = varargin{ii+1};
	    elseif strcmpi('stimIDX', varargin{ii})
            stimIDX = varargin{ii+1};
	    elseif strcmpi('preStim_duration', varargin{ii})
            preStim_duration = varargin{ii+1};
	    elseif strcmpi('postStim_duration', varargin{ii})
            postStim_duration = varargin{ii+1};
	    elseif strcmpi('stimEventsPos', varargin{ii})
            stimEventsPos = varargin{ii+1};
	    elseif strcmpi('stimEvents', varargin{ii})
            stimEvents = varargin{ii+1};
	    elseif strcmpi('round_digit_sig', varargin{ii})
            round_digit_sig = varargin{ii+1};
	    elseif strcmpi('plot_unit_width', varargin{ii})
            plot_unit_width = varargin{ii+1};
	    elseif strcmpi('plot_unit_height', varargin{ii})
            plot_unit_height = varargin{ii+1};
	    elseif strcmpi('xlabelStr', varargin{ii})
            xlabelStr = varargin{ii+1};
	    elseif strcmpi('ylabelStr', varargin{ii})
            ylabelStr = varargin{ii+1};
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



	% Use the settings below to modify the title string for figures 
	% indicate that the bin used to normalize the ap data is shifted by 'baseBinEdgeEnd_apCorrection'
	if apCorrection
		apCorrectionStr = ' apBaseBinShift'; 
	else
		apCorrectionStr = '';
	end
	% indicate that the data are normalized to baseline
	if normToBase
		normToBaseStr = ' normToBase';
	else
		normToBaseStr = '';
	end

	% Filter the ROIs in all trials according to the stimulation effect
	if filter_roi_tf
		[alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
			'stim_names',stim_names,'filters',filters);
		title_prefix = 'filtered';
	else
		title_prefix = '';
	end 

	% Show the event frequencies in time bins with bar plot
	% one plot for one stimulation type

		% Get the subplot number and create a title string for the figure
	stim_type_num = numel(stim_names); % Get the number of stimulation types
	stimShadeDataAll = empty_content_struct({'stimTypeName','shadeData','stimName','color'},stim_type_num);
	% if normToBase
	% 	titleStr = sprintf('event freq in %g s bins [%s] normToBase',binWidth,PropName);
	% else
	% 	titleStr = sprintf('event freq in %g s bins [%s]',binWidth,PropName);
	% end
	titleStr = sprintf('event freq in %g s bins [%s]%s%s',binWidth,PropName,normToBaseStr,apCorrectionStr);
	titleStr = strrep(titleStr,'_',' ');












	

		% Create a figure and start to plot 
	barStat = empty_content_struct({'stim','method','multiComp','data','binEdges','baseRange','recNum','recDateNum','roiNum','stimRepeatNum'},...
		stim_type_num);
	[f,f_rowNum,f_colNum] = fig_canvas(stim_type_num,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);
	[fstat,fstat_rowNum,fstat_colNum] = fig_canvas(stim_type_num,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tloStat = tiledlayout(fstat,fstat_rowNum,fstat_colNum);
	for stn = 1:stim_type_num
		[EventFreqInBins,binEdges,stimShadeData,stimShadeName,stimEventCatName] = get_EventFreqInBins_trials(alignedData,stim_names{stn},'PropName',PropName,...
			'binWidth',binWidth,'stimIDX',stimIDX,...
			'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
			'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,...
			'round_digit_sig',round_digit_sig,'debug_mode',debug_mode); % get event freq in time bins 

		% Calculate the number of recordings, the number of dates
		% (animal number), the number of neurons and the number of
		% stimulation repeats
		[barStat(stn).recNum,barStat(stn).recDateNum,barStat(stn).roiNum,barStat(stn).stimRepeatNum] = calcDataNum(EventFreqInBins);

		stimShadeDataAll(stn).stimTypeName = stim_names{stn};
		stimShadeDataAll(stn).shadeData = stimShadeData;
		stimShadeDataAll(stn).stimName = stimShadeName;
		% [EventFreqInBins,binEdges] = get_EventFreqInBins_AllTrials(alignedData,stim_names{stn},'PropName',PropName,...
		% 	'binWidth',binWidth,'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
		% 	'round_digit_sig',round_digit_sig,'debug_mode',debug_mode); % get event freq in time bins 
		

		% collect event frequencies from all rois and combine them to a matrix 
		ef_cell = {EventFreqInBins.EventFqInBins}; % collect EventFqInBins in a cell array
		ef_cell = ef_cell(:); % make sure that ef_cell is a vertical array
		ef = vertcat(ef_cell{:}); % concatenate ef_cell contents and create a number array


		% Find the start and end of time for baseline data
		% if stimulation is 'ap-0.1s', use an earlier bin for normalization
		if strcmpi(stim_names{stn},'ap-0.1s') && apCorrection
			baseEnd = baseBinEdgeEnd+baseBinEdgeEnd_apCorrection;
			baseStart = baseBinEdgestart+baseBinEdgeEnd_apCorrection;
		else
			baseEnd = baseBinEdgeEnd;
			baseStart = baseBinEdgestart;
		end
		idxBaseBinEdgeEnd = find(binEdges==baseEnd); 
		idxBaseBinEdgeStart = find(binEdges==baseStart); 
		idxBaseData = [idxBaseBinEdgeStart:idxBaseBinEdgeEnd-1]; % idx of baseline data in every cell in ef_cell 

		baseRangeStr = sprintf('%g to %g s',binEdges(idxBaseBinEdgeStart),binEdges(idxBaseBinEdgeEnd));


		% normalized all data to baseline level
		if normToBase
			ef = ef/mean(ef(:,idxBaseData),'all'); 
			barStat(stn).baseRange = [baseStart baseEnd];
		else
			barStat(stn).baseRange = [];
		end
		xdata = binEdges(1:end-1)+binWidth/2; % Use binEdges and binWidt to create xdata for bar plot

		ax = nexttile(tlo);
		filterStr = NumArray2StringCell(filters{stn});
		if stimEventsPos
			stimEventsStr = stimEventCatName;
		else
			stimEventsStr = 'none';
		end

		sub_titleStr = sprintf('%s: ex-%s in-%s rb-%s stimEventsPos-%s [%g animals %g cells %g stims]',...
		stim_names{stn},filterStr{1},filterStr{2},filterStr{3},stimEventsStr,...
		barStat(stn).recDateNum,barStat(stn).roiNum,barStat(stn).stimRepeatNum); % string for the subtitle
		[barInfo] = barplot_with_stat(ef,'xdata',xdata,'plotWhere',gca);

		% plot shade to indicate the stimulation period
		hold on
		for sn = 1:numel(stimShadeData)
			if strcmpi(stimShadeName{sn},'og')
				shadeColor = shadeColors{1};
			elseif strcmpi(stimShadeName{sn},'ap')
				shadeColor = shadeColors{2};
			else
				shadeColor = shadeColors{3};
			end
			stimShadeDataAll(stn).color{sn} = shadeColor;
			draw_WindowShade(gca,stimShadeData{sn},'shadeColor',shadeColor);
		end
		hold off


		xticks(binEdges);
		xticklabels(NumArray2StringCell(binEdges));
		xlabel(xlabelStr)
		ylabel(ylabelStr)
		title(sub_titleStr)

		barStat(stn).stim = stim_names{stn};
		barStat(stn).method = barInfo.stat.stat_method;
		barStat(stn).multiComp = barInfo.stat.c;
		barStat(stn).data = barInfo.data;
		barStat(stn).binEdges = binEdges;

		% combine baseline data and run anova to compare baseline and the rest bins
		xdataStr_combineBase = NumArray2StringCell(xdata);
		[xdataStr_combineBase{idxBaseData}] = deal(baseRangeStr);
		efDataCell = num2cell(ef,1);
		[efArray,xdataStr_combineBaseArray] = createDataAndGroupNameArray(efDataCell,xdataStr_combineBase);
		stat_combineBase = anova1_with_multiComp(efArray,xdataStr_combineBaseArray);

		barStat(stn).anovaCombineBase = stat_combineBase;
		% plot multiCompare stat on another figure
		MultCom_stat = barStat(stn).anovaCombineBase.c(:,["g1","g2","p","h"]);

		axStat = nexttile(tloStat);
		plotUItable(fstat,axStat,MultCom_stat);
	end
	sgtitle(titleStr)
	varargout{1} = barStat;
	varargout{2} = stimShadeDataAll;


	% Save figure and statistics
	if save_fig
		if isempty(save_dir)
			gui_save = 'on';
		end
		msg = 'Choose a folder to save plots of event freq around stimulation and statistics';
		save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
			'guiInfo',msg,'fname',titleStr);
		save_dir = savePlot(fstat,'save_dir',save_dir,'guiSave','off',...
			'guiInfo',msg,'fname',[titleStr,'_MultiComp']);
		save(fullfile(save_dir, [titleStr, '_stat']),...
		    'barStat');
	end 
	
	varargout{3} = save_dir;
end

function [recNum,recDateNum,roiNum,stimRepeatNum] = calcDataNum(EventFreqInBins)
	% calculte the n numbers using the structure var 'EventFreqInBins'

	% each entry of EventFreqInBins contains data for one roi
	% find the empty roi entries
	EventFqInBinsAll = {EventFreqInBins.EventFqInBins};
	emptyEntryIDX = find(cellfun(@(x) isempty(x),EventFqInBinsAll));
	EventFreqInBins(emptyEntryIDX) = [];

	% get the date and time info from trial names
	% one specific date-time (exp. 20230101-150320) represent one recording
	% one date, in general, represent one animal
	trialNamesAll = {EventFreqInBins.TrialNames};
	trialNamesAllDateTime = cellfun(@(x) x(1:15),trialNamesAll,'UniformOutput',false);
	trialNamesAllDate = cellfun(@(x) x(1:8),trialNamesAll,'UniformOutput',false);
	trialNameUniqueDateTime = unique(trialNamesAllDateTime);
	trialNameUniqueDate = unique(trialNamesAllDate);

	% get all the n numbers
	recNum = numel(trialNameUniqueDateTime);
	recDateNum = numel(trialNameUniqueDate);
	roiNum = numel(trialNamesAll);
	stimRepeatNum = sum([EventFreqInBins.stimNum]);
end