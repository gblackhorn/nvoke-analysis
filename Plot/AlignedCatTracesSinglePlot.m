function [varargout] = AlignedCatTracesSinglePlot(alignedData,stimNames,eventCat,varargin)
	% Plot aligned traces of a certain event category

	% alignedData: A struct var output by the function 'get_event_trace_allTrials'

	% stimNames: A string containing the stimulation names. Recording applied with stimulations
	% specified in the string will be kept. If the input is empty, {''}, all stimulations will be
	% kept

	% eventCat: A character var. Events belong to this event category, such as 'spon', 'trig', etc.,
	% will be plot


	% Note: 'event_type' for alignedData must be 'detected_events'

	% Defaults
	plot_combined_data = true; % plot the mean value of all trace and add a shade using std
	subNucleiType = ''; % Name of subnucleiType in which ROI will be picked
	shadeType = 'std'; % std/ste
	showRawtraces = true; % true: plot the traces in the trace_data
	showMedian = false;
	medianProp = 'FWHM';

	y_range = [-20 30];
	yRangeMargin = 0.5; % yRange will be calculated using max and min of mean and shade data. This will increase the range as margin
	sponNorm = false; % true/false
	normalized = false; % true/false. normalize the traces to their own peak amplitudes.
	% tile_row_num = 1;
	tickInt_time = 1; % interval of tick for timeInfo (x axis)
	% fig_position = [0.1 0.1 0.9 0.6]; % [left bottom width height]

	plotUnitWidth = 0.25; % normalized size of a single plot to the display
	plotUnitHeight = 0.4; % nomralized size of a single plot to the display


	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1}; 
        elseif strcmpi('subNucleiType', varargin{ii})
	        subNucleiType = varargin{ii+1};
	    elseif strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1}; 
	    elseif strcmpi('shadeType', varargin{ii})
	        shadeType = varargin{ii+1}; 
	    elseif strcmpi('showRawtraces', varargin{ii})
	        showRawtraces = varargin{ii+1}; 
        elseif strcmpi('showMedian', varargin{ii})
            showMedian = varargin{ii+1};
        elseif strcmpi('medianProp', varargin{ii})
            medianProp = varargin{ii+1};
        elseif strcmpi('fname', varargin{ii})
	        fname = varargin{ii+1};
        elseif strcmpi('y_range', varargin{ii})
	        y_range = varargin{ii+1};
        elseif strcmpi('tickInt_time', varargin{ii})
	        tickInt_time = varargin{ii+1};
        elseif strcmpi('sponNorm', varargin{ii})
	        sponNorm = varargin{ii+1};
        elseif strcmpi('normalized', varargin{ii})
	        normalized = varargin{ii+1};
        elseif strcmpi('yRangeMargin', varargin{ii})
	        yRangeMargin = varargin{ii+1};
        elseif strcmpi('debugMode', varargin{ii})
	        debugMode = varargin{ii+1};
	    end
	end


	% Keep recordings applied with specified stimulations. If stimNames is empty, keep all
	if ~isempty(stimNames)
		[alignedData] = filter_entries_in_structure(alignedData,'stim_name',...
			'tags_keep',stimNames);
	end

	% Keep ROIs in specified subNucleiType and remove others
	if ~isempty(subNucleiType)
		[alignedData] = screenSubNucleiROIs(alignedData,subNucleiType);
		fNameSubNucleiType = ['-',subNucleiType];
	else
		fNameSubNucleiType = '';
	end


	if numel(stimNames) == 1 
		% If the recording has been screened to only keep 1 stimulation above
		stimName = stimNameNames;
	else
		% If there are more than one stimNames, combine the events from recordings applied with various
		% stimulations
		stimName = 'VariousStimRec';
	end

	if isempty(stimNames)
		stimNames = 'allStims';
	end

	% If trace with the median value ('medianProp') will be plot, add a string to figure name
	if showMedian
		showMedianStr = '_MedianTrace';
	else
		showMedian = '';
	end

	% Create a figure name using event category and specified subnulei 
	if ~exist('fname','var')
		fname = sprintf('alignedCalTraces-%s%s_shade-%s%s',...
			eventCat,fNameSubNucleiType,shadeType,showMedian);
	end

	% Decide where to plot the traces
	if ~exist('plotWhere','var') || isempty(plotWhere) 
	    fig_canvas(1,'unit_width',0.3,'unit_height',0.3,'fig_name',fname);
	    plotWhere = gca;
	end


	% Create a structure to store the info of aligned traces
	traceInfo_fields = {'fname','eventCat','subNucleiType','stim','stimNames','timeInfo',...
		'mean_val','ste_val','recNum','recDateNum','roiNum','tracesNum','eventProps'};
		% 'stim': The one displayed in the plot. If multiple stimulations were input, it will be the one in C
		% 'stimNames': funtion input, it includes all the stimulation names
	traceInfo = empty_content_struct(traceInfo_fields,1); 


	if debugMode
		% fprintf('\nstimName (%g/%g): %s\n',n,num_C,stimName);
		% if n == 1
		% 	pause
		% end
	end

	% IDX_trial = find(ic == n);
	timeInfo = alignedData(1).time;
	num_stimTrial = numel(alignedData); % number of trials applied with the same stim
	traceData_cell_trials = cell(1, num_stimTrial); 
	eventProp_cell_trials = cell(1, num_stimTrial); 
	
	for i = 1:num_stimTrial
		trialName = alignedData(i).trialName;
		recDateTimeInfo = trialName(1:15);
		% if debugMode
		% 	fprintf(' recName (%g/%g): %s\n',nst,num_stimTrial,trialName);
		% 	if nst == 16
		% 		pause
		% 	end

		% end

		traceInfo_trial = alignedData(i).traces;
		num_roi = numel(traceInfo_trial);
		traceData_cell_rois = cell(1, num_roi);
		eventProp_cell_rois = cell(1, num_roi);
		for j = 1:num_roi
			eventCat_info = {traceInfo_trial(j).eventProp.peak_category};
			event_idx = find(strcmpi(eventCat_info,eventCat));
			if ~isempty(event_idx)
				roiName = alignedData(i).traces(j).roi;

				if debugMode
					fprintf('  - roi (%g/%g): %s\n',j,num_roi,roiName);
				end

				traceData_cell_rois{j} = traceInfo_trial(j).value(:,event_idx);
				eventProp_cell_rois{j} = traceInfo_trial(j).eventProp(event_idx);

				if normalized
					peakMagDelta = [traceInfo_trial(j).eventProp(event_idx).peak_mag_delta];
					peakMagDelta = reshape(peakMagDelta,1,[]);
					traceData_cell_rois{j} = traceData_cell_rois{j}./peakMagDelta;
				end

				DateTimeRoi = sprintf('%s_%s',recDateTimeInfo,roiName);
				[eventProp_cell_rois{j}.DateTimeRoi] = deal(DateTimeRoi);
			end
			if sponNorm
				sponAmp = traceInfo_trial(j).sponAmp;
				traceData_cell_rois{j} = traceData_cell_rois{j}/sponAmp;
			end
		end
		traceData_cell_trials{i} = [traceData_cell_rois{:}];
		eventProp_cell_trials{i} = [eventProp_cell_rois{:}];
	end

	% Downsample the high sampling frequency data before concatenate 
	[traceData_cell_trials] = downSampleHighFreqCell(traceData_cell_trials);

	tracesData = [traceData_cell_trials{:}];
	eventProp_trials = [eventProp_cell_trials{:}];


	[tracesAverage,tracesShade,nNum,titleName] = plotAlignedTracesAverage(plotWhere,tracesData,timeInfo,...
		'eventsProps',eventProp_trials,'shadeType',shadeType,...
		'plot_median',showMedian,'medianProp',medianProp,...
		'plot_combined_data',plot_combined_data,'plot_raw_races',showRawtraces,...
		'y_range',y_range,'tickInt_time',tickInt_time,'stimName',stimName,'eventCat',eventCat);


	traceInfo.fname = fname;
	traceInfo.group = eventCat;
	traceInfo.subNucleiType = subNucleiType;
	traceInfo.stim = stimName; 
	traceInfo.stimNames = stimNames;
	traceInfo.timeInfo = timeInfo;
	traceInfo.traces = tracesData;
	traceInfo.mean_val = tracesAverage;
	traceInfo.ste_val = tracesShade;
	traceInfo.eventProps = eventProp_trials;
	traceInfo.recNum = nNum.recNum;
	traceInfo.recDateNum = nNum.recDateNum;
	traceInfo.roiNum = nNum.roiNum;
	traceInfo.tracesNum = nNum.tracesNum;
	% end
	varargout{1} = gca;
	varargout{2} = traceInfo;
end

% function [recNum,recDateNum,roiNum,tracesNum] = calcDataNum(eventProp_trials)
% 	% calculte the n numbers using the structure var 'eventProp_trials'

% 	% get the date and time info from trial names
% 	% one specific date-time (exp. 20230101-150320) represent one recording
% 	% one date, in general, represent one animal
% 	if ~isempty(eventProp_trials)
% 		dateTimeRoiAll = {eventProp_trials.DateTimeRoi};
% 		dateTimeAllRec = cellfun(@(x) x(1:15),dateTimeRoiAll,'UniformOutput',false);
% 		dateAllRec = cellfun(@(x) x(1:8),dateTimeRoiAll,'UniformOutput',false);
% 		dateTimeRoiUnique = unique(dateTimeRoiAll);
% 		dateTimeUnique = unique(dateTimeAllRec);
% 		dateUnique = unique(dateAllRec);

% 		% get all the n numbers
% 		recNum = numel(dateTimeUnique);
% 		recDateNum = numel(dateUnique);
% 		roiNum = numel(dateTimeRoiUnique);
% 		tracesNum = numel(dateTimeRoiAll);
% 	else
% 		recNum = 0;
% 		recDateNum = 0;
% 		roiNum = 0;
% 		tracesNum = 0;
% 	end
% end

function [CellArrayDataDS] = downSampleHighFreqCell(CellArrayData)
	% Check the datapoint number in every cell of CellArrayData. Downsample the high frequency cell 

	CellArrayDataDS = CellArrayData;

	% Get the data numbers in every cell
	CellArrayDataNum = cellfun(@(x) size(x,1),CellArrayData);

	% Get the unique numbers
	CellArrayDataNumUnique = unique(CellArrayDataNum);

	% Get the smalles non-zero number. Cells with bigger data number will be downsampled to this
	% number
	idx = find(CellArrayDataNumUnique,1);
	targetLength = CellArrayDataNumUnique(idx);

	% Downsample data
	if ~isempty(targetLength)
	biggerLengthIDX = find(CellArrayDataNum>targetLength);
		if ~isempty(biggerLengthIDX) && ~isempty(targetLength)
			for n = 1:numel(biggerLengthIDX)
				cellIDX = biggerLengthIDX(n);
				originalLength = CellArrayDataNum(cellIDX);
				CellArrayDataDS{cellIDX} = resample(CellArrayData{cellIDX},targetLength,originalLength);
			end
		end
	end
end