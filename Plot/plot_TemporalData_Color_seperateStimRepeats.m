function [f,varargout] = plot_TemporalData_Color_seperateStimRepeats(plotWhere,fluroData,timeData,stimInfo,varargin)
	% Plot a color plot. Every ROI trace is cut to several sections using stimulation repeat. One
	% row contains the start of stim to the start of the next stim. Each ROI contains the stim
	% repeat number of rows

	% Use function [get_TrialTraces_from_alignedData] to get the timeData and fluroData from alignedData
		% [timeData,fluroData] = get_TrialTraces_from_alignedData(alignedData_trials,...
		% 'norm_FluorData',norm_FluorData); 


	% Defaults
	preTime = 0; % include time before stimulation starts for plotting
	postTime = []; % include time after stimulation ends for plotting. []: until the next stimulation starts

	eventsTime = NaN; % -1: do not filter stimRanges with eventsTime. Use all of them
	eventsTimeSort = 'off'; % 'off'/'inROI','all'. sort traces according to eventsTime
	followEventsTime = NaN; % time of the following events
	followDelayType = 'stim'; % stim/stimEvent. Calculate the delay of the following events using the stimulation start or the stim-evoked event time
	stimRefType = 'end';

	eventCat = {}; % -1: do not filter stimRanges with eventsTime. Use all of them
	stimEventCat = '';
	followEventCat = '';

	markEvents = true; % true/false. Mark events in the heatmap if true
	shadeData = {};
	shadeColor = {'#F05BBD','#4DBEEE','#ED8564'};
    colorLUT = 'turbo'; % default look up table (LUT)/colormap. Other sets are: 'parula','hot','jet', etc.
    show_colorbar = true; % true/false. Show color next to the plot if true.
    xtickInt = 1; % interval between x ticks

    unit_width = 0.45; % normalized size of a single plot to the display
    unit_height = 0.4; % nomralized size of a single plot to the display
    column_lim = 1;

    debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-4)
        if strcmpi('rowNames', varargin{ii})
            rowNames = varargin{ii+1}; % cell array containing strings used to label y_ticks
        elseif strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1}; 
        elseif strcmpi('postTime', varargin{ii})
            postTime = varargin{ii+1}; 
        elseif strcmpi('eventCat', varargin{ii})
            eventCat = varargin{ii+1}; 
        elseif strcmpi('eventsTime', varargin{ii})
            eventsTime = varargin{ii+1}; 
        elseif strcmpi('eventsTimeSort', varargin{ii})
            eventsTimeSort = varargin{ii+1}; % 
        elseif strcmpi('followEventCat', varargin{ii})
            followEventCat = varargin{ii+1}; % 
        elseif strcmpi('stimEventCat', varargin{ii})
            stimEventCat = varargin{ii+1}; % 
        elseif strcmpi('stimRefType', varargin{ii})
            stimRefType = varargin{ii+1}; % 
        elseif strcmpi('roiNames', varargin{ii})
            roiNames = varargin{ii+1}; % 
        elseif strcmpi('followEventsTime', varargin{ii})
            followEventsTime = varargin{ii+1}; % 
        elseif strcmpi('followDelayType', varargin{ii})
            followDelayType = varargin{ii+1}; % 
        elseif strcmpi('markEvents', varargin{ii})
            markEvents = varargin{ii+1}; % a single number to set the interval between x ticks
        elseif strcmpi('xtickInt', varargin{ii})
            xtickInt = varargin{ii+1}; % a single number to set the interval between x ticks
        elseif strcmpi('colorLUT', varargin{ii})
            colorLUT = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        end
	end	

	% create roiNames if it's empty
	if ~exist('roiNames','var')
		roiNum = size(fluroData,2);
		roiNames = cell(roiNum,1);
		for rn = 1:roiNum
			roiNames{rn} = sprintf('roi-%g',rn);
		end
	end


	% Sort the peri-stimulation traces according to the events time
	[sortedIDX,sortedFdSection,sortedEventMarker,sortedRowNames,timeDuration,posNum,sortedEventNumIDX] = sortPeriStimTraces(fluroData,timeData,...
			eventsTime,stimInfo,'preTime',preTime,'postTime',postTime,...
			'eventCat',eventCat,'stimEventCat',stimEventCat,'followEventCat',followEventCat,...
			'stimRefType',stimRefType,'roiNames',roiNames,'debugMode',debug_mode);

    f = fig_canvas(2,'unit_width',unit_width,'unit_height',unit_height,'column_lim',1,...
	    	'fig_name',titleStr); % create a figure
	if ~isempty(sortedIDX)

	% % Create rowNames if it doesn't exist 
    % if exist('rowNames')==0 || isempty(rowNames)
    %     rowNames = NumArray2StringCell(size(fluroData,2));
    % end

    % % Get necessary information from stimInfo 
    % stimRanges = stimInfo.UnifiedStimDuration.range;


    % % Get the time range for plotting
    % stimPlusRange = NaN(size(stimRanges));
    % stimPlusRange(:,1) = stimRanges(:,1)-preTime;
    % if ~isempty(postTime)
    % 	stimPlusRange(:,2) = stimRanges(:,2)+postTime;
    % end


    % % Screen the traces with stimulation related events if eventsTime exists and is a cell var
    % if exist('eventsTime','var') && iscell(eventsTime)
    % 	filterStim = true;
    % 	eventsFrame = cellfun(@(x) time2frame(x,timeData),eventsTime,'UniformOutput',false); % get the locations of events in timeData
    % 	eventsTimesToStim = cell(size(eventsTime));
    % 	eventsTimesToStimSortROI = cell(size(eventsTime));
    % 	posRowIDX = cell(size(eventsTime));
    % 	negRowIDX = cell(size(eventsTime));
    % else
    % 	filterStim = false;
    % end

    % if exist('followEventsTime','var') && iscell(followEventsTime)
    % 	filterFollow = true;
    % 	followEventsFrame = cellfun(@(x) time2frame(x,timeData),followEventsTime,'UniformOutput',false); % get the locations of events in timeData
    % 	followEventsTimesDelay = cell(size(followEventsTime));
    % 	followEventsTimesDelaySortROI = cell(size(followEventsTime));
    % 	% posRowIDX = cell(size(followEventsTime));
    % else
    % 	filterFollow = false;
    % end

    
    % if ~isempty(stimPlusRange) && ~stimInfo.UnifiedStimDuration.varied
	%     % Get the closest recording time for stimulation repeats
	%     stimNum = size(stimRanges,1);
	%     stimPlusRangeIDX = NaN(size(stimRanges));
	%     [stimPlusRange(:,1),stimPlusRangeIDX(:,1)] = find_closest_in_array(stimPlusRange(:,1),timeData);
	%     [stimRanges(:,1),stimRangesIDX(:,1)] = find_closest_in_array(stimRanges(:,1),timeData);
	%     if ~isempty(postTime)
	% 	    [stimPlusRange(:,2),stimPlusRangeIDX(:,2)] = find_closest_in_array(stimPlusRange(:,2),timeData);
	% 	end


	%     % Get the number of data points for the first stim start to the first stim end. And use this
	%     % number for all the following stimulations
	%     plotRangeIDX = NaN(size(stimRanges));
	%     plotRangeIDX(1,1) = stimPlusRangeIDX(1,1); % start from the 1st stimulation 
	%     if isempty(postTime)
	%     	plotRangeIDX(1,2) = stimRangesIDX(2,1)-1; % end just before the 2nd stimulation
	%     else
	%     	plotRangeIDX(1,2) = stimPlusRangeIDX(1,2);
	%     end
	%     stimPlusRange(1,2) = timeData(plotRangeIDX(1,2));
	%     datapointNum = plotRangeIDX(1,2)-plotRangeIDX(1,1)+1;
	%     timeRange = timeData(plotRangeIDX(1,2))-timeData(plotRangeIDX(1,1));
	%     for sn = 2:stimNum
	%     	plotRangeIDX(sn,1) = stimPlusRangeIDX(sn,1);
	%     	plotRangeIDX(sn,2) = stimPlusRangeIDX(sn,1)+datapointNum-1;
	%     	stimPlusRange(sn,2) = timeData(plotRangeIDX(sn,2));
	%     end


	%     % Create a new fluroData called fdSection contains roiNum * stimNum of traces for plotting
	%     roiNum = size(fluroData,2);
	%     fdSection = NaN(roiNum*stimNum,datapointNum);
	%     rowNamesSection = cell(roiNum*stimNum,1);
	%     eventsMark = cell(roiNum*stimNum,1);
	%     followEventsMark = cell(roiNum*stimNum,1);
	%     for rn = 1:roiNum
	%     	if debug_mode
	%     		fprintf(' - roi %d/%d: %s\n',rn,roiNum,rowNames{rn})
	%     		% if rn == 2
	%     		% 	pause
	%     		% end
	%     	end
	%     	% Filter stimRanges with events
	%     	if filterStim
	%     		[posStimPlusRange,posRangeIDX,negRangeIDX] = getRangeIDXwithEvents(eventsTime{rn},stimPlusRange);

	%     		posStimRange = stimRanges(posRangeIDX,:);
	%     		negRangeIDX = reshape(negRangeIDX,[],1); % make sure that negRangeIDX is a column vector
	%     		if filterFollow && ~isempty(eventsTime{rn})
	%     			falsePosRangeIDX = [];
	%     			for en = 1:numel(eventsTime{rn})
	%     				if isnan(followEventsTime{rn}(en)) || followEventsTime{rn}(en) > posStimPlusRange(en,2) % following event time is after the end of trace time range
	%     					falsePosRangeIDX = [falsePosRangeIDX;en];
	%     					% eventsTime{rn}(en) = []; % delete
	%     					% posStimPlusRange(en,:) = []; % delete the range
	%     					% negRangeIDX = [negRangeIDX;posRangeIDX(en)] % add the range index to the negRangeIDX list
	%     					% posRangeIDX(en) = []; % delete the range index from the posRangeIDX list
	%     				end
	%     			end
	%     			eventsTime{rn}(falsePosRangeIDX) = []; % delete eventsTime if the following events cannot be found in the time window
	%     			eventsFrame{rn}(falsePosRangeIDX) = []; % delete eventsTime if the following events cannot be found in the time window
	%     			followEventsTime{rn}(falsePosRangeIDX) = [];
	%     			followEventsFrame{rn}(falsePosRangeIDX) = [];
	%     			posStimPlusRange(falsePosRangeIDX,:) = []; % delete the range
	%     			posStimRange(falsePosRangeIDX,:) = []; % delete the range
	%     			negRangeIDX = sort([negRangeIDX;posRangeIDX(falsePosRangeIDX)]); % add the range index to the negRangeIDX list
	%     			posRangeIDX(falsePosRangeIDX) = []; % delete the range index from the posRangeIDX list
	%     		end

	%     		eventsTimeROI = reshape(eventsTime{rn},1,[]);
	%     		stimStartTimeROI = reshape(posStimRange(:,1),1,[]);
	%     		eventsTimesToStim{rn} =  eventsTimeROI-stimStartTimeROI;
	%     		[~,eventsTimesToStimSortROI{rn}] = sort(eventsTimesToStim{rn});

	%     		% Calculate the delay of the following events in a ROI using either the stimulation time or the stim-related events time
	%     		if filterFollow && ~isempty(followEventsTime{rn})
	%     			switch followDelayType
	%     				case 'stim'
	%     					followEventsTimesDelay{rn} =  reshape(followEventsTime{rn},1,[])-stimStartTimeROI;
	%     				case 'stimEvent'
	%     					followEventsTimesDelay{rn} = reshape(followEventsTime{rn},1,[])-eventsTimeROI;
	%     			end
	%     			[~,followEventsTimesDelaySortROI{rn}] = sort(followEventsTimesDelay{rn});
	%     		end
	%     	end

	%     	for sn = 1:stimNum
	%     		rowIDX = (rn-1)*stimNum+sn;
	%     		rowNamesSection{rowIDX} = sprintf('%s-s%g',rowNames{rn},sn);
	%     		sTrace = fluroData((plotRangeIDX(sn,1):plotRangeIDX(sn,2)),rn); % Get a section trace from one ROI from fluroData
	%     		sTraceRow = reshape(sTrace,[1,numel(sTrace)]); % ensure that sTraceRow is a row vector
	%     		fdSection(rowIDX,:) = sTraceRow;

	%     		% Calculate the indices of events in the sections
	%     		if filterStim
	%     			eventsMark{rowIDX} = eventsTime{rn}(find(eventsTime{rn}>=stimPlusRange(sn,1) & eventsTime{rn}<=stimPlusRange(sn,2)));
	%     			eventsMark{rowIDX} = eventsMark{rowIDX}-stimPlusRange(sn,1)-preTime;
	%     			% eventsMark{rowIDX} = eventsFrame{rn}(find(eventsFrame{rn}>=plotRangeIDX(sn,1) & eventsFrame{rn}<=plotRangeIDX(sn,2)));
	%     			% eventsMark{rowIDX} = eventsMark{rowIDX}-plotRangeIDX(sn,1)+1;
	%     		end
	%     		if filterFollow
	%     			followEventsMark{rowIDX} = followEventsTime{rn}(find(followEventsTime{rn}>=stimPlusRange(sn,1) & followEventsTime{rn}<=stimPlusRange(sn,2)));
	%     			followEventsMark{rowIDX} = followEventsMark{rowIDX}-stimPlusRange(sn,1)-preTime;
	%     			% followEventsMark{rowIDX} = followEventsFrame{rn}(find(followEventsFrame{rn}>=plotRangeIDX(sn,1) & followEventsFrame{rn}<=plotRangeIDX(sn,2)));
	%     			% followEventsMark{rowIDX} = followEventsMark{rowIDX}-plotRangeIDX(sn,1)+1;
	%     		end
	%     	end
	%     	% discard stim ranges without stimulation related events
	%     	if filterStim
	%     		posRowIDX{rn} = arrayfun(@(x) (rn-1)*stimNum+x,posRangeIDX);
	%     		negRowIDX{rn} = arrayfun(@(x) (rn-1)*stimNum+x,negRangeIDX);
	%     	end
	%     	if strcmpi(eventsTimeSort,'inROI')
	%     		posRowIDX{rn} = posRowIDX{rn}(eventsTimesToStimSortROI{rn});
	%     	end
	%     end
	%     % convert posRowIDX from cell to number array and reshape it to a column vector
	%     % posRowIDX = cell2mat(posRowIDX);
	%     % posRowIDX = reshape(posRowIDX,[],1);
	%     posRowIDX = vertcat(posRowIDX{:});
	%     negRowIDX = vertcat(negRowIDX{:});
	%     posNegRowIDX = vertcat(posRowIDX,negRowIDX);

	%     % delete traces and row names without stimulation related events
	%     eventsMarkPos = {};
	%     followEventsMarkPos = {};
	%     if filterStim 
	%     	rowNamesSectionPos = rowNamesSection(posRowIDX);
	%     	fdSectionPos = fdSection(posRowIDX,:);
	%     	eventsMarkPos = eventsMark(posRowIDX);
	    	
	%     	rowNamesSectionNeg = rowNamesSection(negRowIDX);
	%     	fdSectionNeg = fdSection(negRowIDX,:);

	%     	posNum = numel(posRowIDX);
	%     	negNum = numel(negRowIDX);

	%     	if filterFollow
	%     		followEventsMarkPos = followEventsMark(posRowIDX);
	%     	end
	%     end

	%     % sort all traces using the stimulation related event time delay
	%     if filterStim && strcmpi(eventsTimeSort,'all')
	%     	eventsTimesToStim = cell2mat(eventsTimesToStim);
	%     	eventsTimesToStim = reshape(eventsTimesToStim,[],1);

	%     	if filterFollow
	%     		followEventsTimesDelay = reshape(cell2mat(followEventsTimesDelay),[],1); % combine all the delay time and reshape array to a column vector
	%     		[~,sortFollowEventDelay] = sort(followEventsTimesDelay);
	%     		rowNamesSectionPos = rowNamesSectionPos(sortFollowEventDelay);
	%     		fdSectionPos = fdSectionPos(sortFollowEventDelay,:);
	%     		eventsMarkPos = eventsMarkPos(sortFollowEventDelay);
	%     		followEventsMarkPos = followEventsMarkPos(sortFollowEventDelay);
	%     	else
	%     		[~,sortAllStimEventsTime] = sort(eventsTimesToStim);
	%     		rowNamesSectionPos = rowNamesSectionPos(sortAllStimEventsTime);
	%     		fdSectionPos = fdSectionPos(sortAllStimEventsTime,:);
	%     		eventsMarkPos = eventsMarkPos(sortAllStimEventsTime);
	%     		% followEventsMarkPos = followEventsMarkPos(sortAllStimEventsTime);
	%     	end
	%     end 

	%     % Collect the eventsMarkPos and the followEventsMarkPos to mark events in the heatmap
	%     % created by 'plot_TemporalData_Color'
	%     markerIDX = {eventsMarkPos,followEventsMarkPos};
	%     emptyTFmarkerIDX = cellfun(@(x) isempty(x),markerIDX);
	%     % emptyTFmarkerIDX = cellfun(@(x) isempty(x),markerIDX,'UniformOutput',false);
	%     if all(emptyTFmarkerIDX) || ~markEvents
	%     	markerIDX = NaN;
	%     end


	% 	rowNamesSection = vertcat(rowNamesSectionPos,rowNamesSectionNeg);
	% 	fdSection = vertcat(fdSectionPos,fdSectionNeg);

	    % plot the heatmap using function [plot_TemporalData_Color]
	    % Creat a figure to plot raster (first ax) and histogram (second ax)
	    % f = fig_canvas(2,'unit_width',0.4,'unit_height',0.4,'column_lim',1,...
	    % 	'fig_name',titleStr); % create a figure
	    tlo = tiledlayout(f, 13, 1); % setup tiles
	    ax = nexttile(tlo,[12 1]); % activate the ax for color plot
	    if ~exist('posNum','var')
	    	posNum = NaN;
	    end
	    plot_TemporalData_Color(gca,sortedFdSection,...
				'rowNames',sortedRowNames,'x_window',[-preTime -preTime+timeDuration],'xtickInt',xtickInt,...
				'show_colorbar',show_colorbar,'breakerLine',posNum,'markerIDX',sortedEventMarker);
	    % plot_TemporalData_Color(gca,fdSection,...
		% 		'rowNames',rowNamesSection,'x_window',[-preTime -preTime+timeRange],'xtickInt',xtickInt,...
		% 		'show_colorbar',show_colorbar,'breakerLine',posNum,'markerIDX',markerIDX);
	    xlabel('time (s)')

	    	% add a shade plot to display the stimulation range
	    ax = nexttile(tlo);
	    xlim([-preTime -preTime+timeDuration]);
	    ylim([0 1]);
	    if ~isempty(stimInfo)
		    stimTypeNum = numel(stimInfo.StimDuration);
		    shadeDataAligned = cell(stimTypeNum,1);
		    shadeNames = cell(stimTypeNum,1);
		    for  stn= 1:stimTypeNum
			    shadeDataAligned{stn} = stimInfo.StimDuration(stn).patch_coor(1:4,1:2); % Get the first 4 rows for the first repeat of stimulation
			    shadeDataAligned{stn}(1:2,1) = stimInfo.StimDuration(stn).range_aligned(1); % Replace the first 2 x values (stimu gpio rising) with the 1st element from range_aligned
			   	shadeDataAligned{stn}(3:4,1) = stimInfo.StimDuration(stn).range_aligned(2); % Replace the last 2 x values (stimu gpio falling) with the 2nd element from range_aligned
			   	shadeNames{stn} = stimInfo.StimDuration(stn).type;

			   	draw_WindowShade(gca,shadeDataAligned{stn},'shadeColor',shadeColor{stn});
			end
	        legend(shadeNames,'Location', 'Best') % 'northeastoutside'
	        set(gca,'XTickLabel',[]); % remove the x-axis labels
	        set(gca,'YTickLabel',[]); % remove the y-axis labels
	        box off; % remove the box around the plot
	        title('stimulation(s)')
	    end

	    sgtitle(titleStr)

	    varargout{1} = sortedFdSection; % fluorescence data
	    varargout{2} = sortedRowNames; % names for each row of fluorescence data
	    varargout{3} = [0 timeDuration]; % xdata
	else
		varargout{1} = []; % fluorescence data
		varargout{2} = []; % names for each row of fluorescence data
		varargout{3} = []; % xdata
	end
end

