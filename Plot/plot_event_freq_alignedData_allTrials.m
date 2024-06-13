function [varargout] = plot_event_freq_alignedData_allTrials(alignedData, varargin)
    % Plot the event frequency in specified time bins to examine the effect of stimulation and
    % compare each pair of bins.
    % ROIs can be filtered according to the effect of stimulations on them.
    %
    % Note: When using 'normToBase', trials applied with 'ap-0.1s' will be normalized to an earlier
    % bin (decided by baseBinEdgeEnd_apCorrection).
    %
    % Example:
    %   plot_calcium_signals_alignedData_allTrials(alignedData, 'filter_roi_tf', true);
    %

    % Initialize input parser
    p = inputParser;

    % Define required inputs
    addRequired(p, 'alignedData', @isstruct);

    % Add optional parameters to the parser with default values and comments
    addParameter(p, 'filter_roi_tf', false, @islogical); % Filter ROIs by stimulation effect
    addParameter(p, 'stim_names', {'og-5s','ap-0.1s','og-5s ap-0.1s'}, @iscell); % Names of stimulations to compare
    addParameter(p, 'filters', {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}, @iscell); % Filters for different stimulations
    addParameter(p, 'subNucleiFilter', '', @ischar); % Filter for sub-nuclei ('', 'DAO', 'PO')
    addParameter(p, 'plot_unit_width', 0.4, @isnumeric); % Width of a single plot (normalized)
    addParameter(p, 'plot_unit_height', 0.4, @isnumeric); % Height of a single plot (normalized)
    addParameter(p, 'normToBase', false, @islogical); % Normalize data to baseline
    addParameter(p, 'baseBinEdgestart', -1, @isnumeric); % Start of baseline bin
    addParameter(p, 'baseBinEdgeEnd', 0, @isnumeric); % End of baseline bin
    addParameter(p, 'baseBinEdgeEnd_apCorrection', -1, @isnumeric); % End of baseline bin for AP correction
    addParameter(p, 'apCorrection', true, @islogical); % Apply AP correction
    addParameter(p, 'splitLongStim', [1], @isnumeric); % Split long stimulations
    addParameter(p, 'binWidth', 1, @isnumeric); % Width of histogram bins (s)
    addParameter(p, 'PropName', 'rise_time', @ischar); % Property name ('rise_time', 'peak_time')
    addParameter(p, 'stimIDX', [], @isnumeric); % Indices of stimulation repeats
    addParameter(p, 'AlignEventsToStim', true, @islogical); % Align events to stimulation onsets
    addParameter(p, 'preStim_duration', 5, @isnumeric); % Duration before stimulation onset (s)
    addParameter(p, 'postStim_duration', 5, @isnumeric); % Duration after stimulation end (s)
    addParameter(p, 'round_digit_sig', 2, @isnumeric); % Significant digits for duration rounding
    addParameter(p, 'customizeEdges', false, @islogical); % Customize histogram bins
    addParameter(p, 'stimEffectDuration', 1, @isnumeric); % Duration of stimulation effect (s)
    addParameter(p, 'stimEventsPos', false, @islogical); % Use peri-stim ranges with stimulation events
    addParameter(p, 'stimEvents', struct('stimName', {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}, 'eventCat', {'rebound', 'trig', 'rebound'}), @isstruct); % Stimulation events
    addParameter(p, 'xlabelStr', 'Time (s)', @ischar); % X-axis label
    addParameter(p, 'xTickAngle', 45, @isnumeric); % Angle of X-axis tick labels
    addParameter(p, 'ylabelStr', '', @ischar); % Y-axis label
    addParameter(p, 'shadeColors', {'#F05BBD','#4DBEEE','#ED8564'}, @iscell); % Colors for shading stimulation periods
    addParameter(p, 'mmType', 'GLMM', @ischar); % Type of mixed-model for stat
    addParameter(p, 'mmlHierarchicalVars', {'trialNames','roiNames'}, @iscell); % Hierarchical vars used fo nested random effects
    addParameter(p, 'mmDistribution', 'Poisson', @ischar); % mix-model distribution
    addParameter(p, 'mmLink', 'log', @ischar); % mix-model link function
    addParameter(p, 'save_fig', false, @islogical); % Save figure
    addParameter(p, 'save_dir', '', @ischar); % Directory to save figure
    addParameter(p, 'gui_save', false, @islogical); % GUI save option
    addParameter(p, 'debug_mode', false, @islogical); % Enable debug mode

    % Parse the inputs
    parse(p, alignedData, varargin{:});

    % Assign parsed values to variables
    alignedData = p.Results.alignedData;
    filter_roi_tf = p.Results.filter_roi_tf;
    stim_names = p.Results.stim_names;
    filters = p.Results.filters;
    subNucleiFilter = p.Results.subNucleiFilter;
    plot_unit_width = p.Results.plot_unit_width;
    plot_unit_height = p.Results.plot_unit_height;
    normToBase = p.Results.normToBase;
    baseBinEdgestart = p.Results.baseBinEdgestart;
    baseBinEdgeEnd = p.Results.baseBinEdgeEnd;
    baseBinEdgeEnd_apCorrection = p.Results.baseBinEdgeEnd_apCorrection;
    apCorrection = p.Results.apCorrection;
    splitLongStim = p.Results.splitLongStim;
    binWidth = p.Results.binWidth;
    PropName = p.Results.PropName;
    stimIDX = p.Results.stimIDX;
    AlignEventsToStim = p.Results.AlignEventsToStim;
    preStim_duration = p.Results.preStim_duration;
    postStim_duration = p.Results.postStim_duration;
    round_digit_sig = p.Results.round_digit_sig;
    customizeEdges = p.Results.customizeEdges;
    stimEffectDuration = p.Results.stimEffectDuration;
    stimEventsPos = p.Results.stimEventsPos;
    stimEvents = p.Results.stimEvents;
    xlabelStr = p.Results.xlabelStr;
    xTickAngle = p.Results.xTickAngle;
    ylabelStr = p.Results.ylabelStr;
    shadeColors = p.Results.shadeColors;
    mmType = p.Results.mmType;
    mmlHierarchicalVars = p.Results.mmlHierarchicalVars;
    mmDistribution = p.Results.mmDistribution;
    mmLink = p.Results.mmLink;
    save_fig = p.Results.save_fig;
    save_dir = p.Results.save_dir;
    gui_save = p.Results.gui_save;
    debug_mode = p.Results.debug_mode;



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
	titleStr = sprintf('%s event freq in %g s bins [%s]%s%s',subNucleiFilter,binWidth,PropName,normToBaseStr,apCorrectionStr);
	titleStr = strrep(titleStr,'_',' ');

		% Create a figure and start to plot 
	barStat = empty_content_struct({'stim','data','dataStruct','binEdges','binNames','baseRange','recNum','recDateNum','roiNum','stimRepeatNum','GLMMstat','anovaCombineBase'},...
		stim_type_num);
	[f,f_rowNum,f_colNum] = fig_canvas(stim_type_num,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);
	[fstat,fstat_rowNum,fstat_colNum] = fig_canvas(stim_type_num,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tloStat = tiledlayout(fstat,fstat_rowNum,fstat_colNum);
	for stn = 1:stim_type_num
		PeriBaseRange = [baseBinEdgestart baseBinEdgeEnd];
		[EventFreqInBins,binEdges,stimShadeData,stimShadeName,stimEventCatName,binNames] = get_EventFreqInBins_trials(alignedData,stim_names{stn},'PropName',PropName,...
			'binWidth',binWidth,'stimIDX',stimIDX,...
			'preStim_duration',preStim_duration,'postStim_duration',postStim_duration,...
			'customizeEdges',customizeEdges,'stimEffectDuration',stimEffectDuration,'PeriBaseRange',PeriBaseRange,...
			'stimEventsPos',stimEventsPos,'stimEvents',stimEvents,'splitLongStim',splitLongStim,...
			'round_digit_sig',round_digit_sig,'debug_mode',debug_mode); % get event freq in time bins 

		% Filter the 'EventFreqInBins' using the subNucleiFilter input if it is not empty
		if ~isempty(subNucleiFilter)
			% Logical indexing to find entries where the field subNulei is (subNucleiFilter)
			isSubNucleiTF = arrayfun(@(x) strcmp(x.subNuclei, subNucleiFilter), EventFreqInBins);

			% Extract the entries
			EventFreqInBins = EventFreqInBins(isSubNucleiTF);
		end

		% Calculate the number of recordings, the number of dates
		% (animal number), the number of neurons and the number of
		% stimulation repeats
		[barStat(stn).recNum,barStat(stn).recDateNum,barStat(stn).roiNum,barStat(stn).stimRepeatNum] = calcDataNum(EventFreqInBins);

		stimShadeDataAll(stn).stimTypeName = stim_names{stn};
		stimShadeDataAll(stn).shadeData = stimShadeData;
		stimShadeDataAll(stn).stimName = stimShadeName;
		

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
		xdata = binEdges(1:end-1)+diff(binEdges)/2; % Use binEdges and binWidt to create xdata for bar plot
		% xdata = binEdges(1:end-1)+binWidth/2; % Use binEdges and binWidt to create xdata for bar plot

		ax = nexttile(tlo);
		filterStr = NumArray2StringCell(filters{stn});
		if stimEventsPos
			stimEventsStr = stimEventCatName;
		else
			stimEventsStr = 'none';
		end

		sub_titleStr = sprintf('%s %s: ex-%s in-%s rb-%s exApOg-%s stimEventsPos-%s \n[%g animals %g cells %g stims]',...
		subNucleiFilter,stim_names{stn},filterStr{1},filterStr{2},filterStr{3},filterStr{4},stimEventsStr,...
		barStat(stn).recDateNum,barStat(stn).roiNum,barStat(stn).stimRepeatNum); % string for the subtitle

		% Convert the ef array to a structure var for plotting and GLMM analysis
		efStruct = efArray2struct(ef, EventFreqInBins, xdata);

		% Replace the contents in xdata, center of bin time, to binNames
		xdataUnique = unique(xdata);
		xdataUnique = num2cell(xdataUnique(:)); % convert xdataUnique from number to cell
		replacementCell = [xdataUnique, binNames(:)]; % Create a replacementCell, in which old xdata and binNames are paired
		% efStruct = replaceFieldValues(efStruct, 'xdata', replacementCell);


		barInfo = empty_content_struct({'data', 'stat'}, 1);

		% Bar plot of the event freq in various time 
		% barInfo.data = barplot_with_stat(ef,'xdata',xdata,'plotWhere',gca);
		barStat(stn).data = barPlotOfStructData(efStruct, 'val', 'xdata', 'plotWhere', ax);
		barStat(stn).dataStruct = efStruct;

		% Run GLMM to evaluate the difference of every freq in various time bins
        barStat(stn).GLMMstat = twoPartMixedModelAnalysis(efStruct, 'val', 'xdata', mmlHierarchicalVars,...
        	'groupVarType', 'categorical', 'dispStat', false);
		% barInfo.stat = GLMManalysis(efStruct, 'val', 'xdata', mmlHierarchicalVars,...
		% 	mmType, mmDistribution, mmLink);

		% % plot shade to indicate the stimulation period
		% ax;
		% hold on
		% for sn = 1:numel(stimShadeData) 
		% 	if strcmpi(stimShadeName{sn},'og')  
		% 		shadeColor = shadeColors{1};
		% 	elseif strcmpi(stimShadeName{sn},'ap')
		% 		shadeColor = shadeColors{2};
		% 	else
		% 		shadeColor = shadeColors{3};
		% 	end
		% 	stimShadeDataAll(stn).color{sn} = shadeColor;
		% 	draw_WindowShade(ax,stimShadeData{sn},'shadeColor',shadeColor);
		% end
		% hold off

		% xlim([binEdges(1) binEdges(end)])

		% mark the bar with the customized binName
		% xticklabels(binNames)
		xlabel(xlabelStr)
		xtickangle(xTickAngle)

		ylabel(ylabelStr)
		title(sub_titleStr)

		barStat(stn).stim = stim_names{stn};
		% barStat(stn).method = barInfo.stat.method;
		% barStat(stn).multiComp = barInfo.stat.c;
		% barStat(stn).data = barInfo.data;
		barStat(stn).binEdges = binEdges;
		barStat(stn).binNames = binNames;

		% combine baseline data and run anova to compare baseline and the rest bins
		% xdataStr_combineBase = NumArray2StringCell(xdata);
		% [xdataStr_combineBase{idxBaseData}] = deal(baseRangeStr);
		efDataCell = num2cell(ef,1);
		[efArray,xdataStr_combineBaseArray] = createDataAndGroupNameArray(efDataCell,binNames);
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


function efStruct = efArray2struct(ef, EventFreqInBins, xdata)
	% Convert the ef double array to a structure var for GLMM analysis and plot

	% Borrow 'TrialNames', 'roiNames', 'subNuclei', and 'stimNum' from struct var 'EventFreqInBins'

	% xdata is used to tag various columns of ef data

	% Get the ROI number and the bin number
	roiNum = size(ef, 1);
	binNum = size(ef, 2);

	% Validate the data
	if roiNum ~=  length(EventFreqInBins)
		error('The row number of ef and the length of EventFreqInBins must be the same')
	end
	if binNum ~= length(xdata)
		error('The col number of ef and the length of xdata must be the same')
	end

	% Create an empty cell to pre-allocate RAM
	efStructCell = cell(1, binNum);
	% efStructFieldNames = {'val', 'xdata', 'trialNames', 'roiNames', 'subNuclei', 'stimNum'};

	% Extract the fields' content from EventFreqInBins
	trialNames = {EventFreqInBins.TrialNames};
	roiNames = {EventFreqInBins.roiNames};
	subNuclei = {EventFreqInBins.subNuclei};
	stimNum = [EventFreqInBins.stimNum];

	% Loop through the columns of ef
	for i = 1:binNum
		efDataCell = ensureHorizontal(num2cell(ef(:, i)));
		xdataCell = num2cell(repmat(xdata(i), 1, roiNum));
		efStructCell{i} = struct('val', efDataCell, 'xdata', xdataCell,...
			'trialNames', trialNames, 'roiNames', roiNames, 'subNuclei', subNuclei, 'stimNum', stimNum);
	end

	% Concatenate the cell
	efStruct = horzcat(efStructCell{:});
end

function statInfo = GLMManalysis(structData, responseVar, groupVar, hierarchicalVars, mmType, mmDistribution, mmLink)
	% Statistics
	% GLMM analysis
	[me,fixedEffectsStats,chiLRT,mmPvalue,multiComparisonResults]= mixed_model_analysis(structData,...
		responseVar, groupVar, hierarchicalVars,'modelType',mmType,'distribution',mmDistribution,'link',mmLink);
	statInfo.method = mmType;
	statInfo.detail = me;
	statInfo.fixedEffectsStats = fixedEffectsStats;
	statInfo.chiLRT = chiLRT;
	statInfo.mmPvalue = mmPvalue;
	statInfo.multCompare = multiComparisonResults;

end