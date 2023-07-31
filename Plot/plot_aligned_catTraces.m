function [varargout] = plot_aligned_catTraces(alignedData,varargin)
	% Plot aligned traces of a certain event category
	% Note: 'event_type' for alignedData must be 'detected_events'
	% ste is used to plot the shade

	% Defaults
	eventCat = 'spon';
	combineStim = false; % if true, combine the same eventCat from recordings applied with various stimulations
	plot_combined_data = true; % plot the mean value of all trace and add a shade using std
	shadeType = 'std'; % std/ste
	plot_raw_races = true; % true: plot the traces in the trace_data
	plot_median = false;
	medianProp = 'FWHM';

	y_range = [-20 30];
	yRangeMargin = 0.5; % yRange will be calculated using max and min of mean and shade data. This will increase the range as margin
	sponNorm = false; % true/false
	normalized = false; % true/false. normalize the traces to their own peak amplitudes.
	tile_row_num = 1;
	tickInt_time = 1; % interval of tick for timeInfo (x axis)
	% fig_position = [0.1 0.1 0.9 0.6]; % [left bottom width height]

	plotUnitWidth = 0.25; % normalized size of a single plot to the display
	plotUnitHeight = 0.4; % nomralized size of a single plot to the display

	stimDiscard = {''};

	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1}; 
	    elseif strcmpi('shadeType', varargin{ii})
	        shadeType = varargin{ii+1}; 
	    elseif strcmpi('plot_raw_races', varargin{ii})
	        plot_raw_races = varargin{ii+1}; 
        elseif strcmpi('plot_median', varargin{ii})
            plot_median = varargin{ii+1};
        elseif strcmpi('medianProp', varargin{ii})
            medianProp = varargin{ii+1};
        elseif strcmpi('eventCat', varargin{ii})
	        eventCat = varargin{ii+1};
        elseif strcmpi('fname', varargin{ii})
	        fname = varargin{ii+1};
        elseif strcmpi('y_range', varargin{ii})
	        y_range = varargin{ii+1};
        elseif strcmpi('tickInt_time', varargin{ii})
	        tickInt_time = varargin{ii+1};
        elseif strcmpi('tile_row_num', varargin{ii})
	        tile_row_num = varargin{ii+1};
        elseif strcmpi('sponNorm', varargin{ii})
	        sponNorm = varargin{ii+1};
        elseif strcmpi('normalized', varargin{ii})
	        normalized = varargin{ii+1};
        elseif strcmpi('stimKeep', varargin{ii})
	        stimKeep = varargin{ii+1};
        elseif strcmpi('combineStim', varargin{ii})
	        combineStim = varargin{ii+1};
        elseif strcmpi('stimDiscard', varargin{ii})
	        stimDiscard = varargin{ii+1};
        elseif strcmpi('yRangeMargin', varargin{ii})
	        yRangeMargin = varargin{ii+1};
        elseif strcmpi('debugMode', varargin{ii})
	        debugMode = varargin{ii+1};
	    end
	end


	if ~exist('stimKeep','var')
		stimKeep = unique({alignedData.stim_name});
	end

	% filter the recordings according to the stimulations applied to them
	[alignedData] = filter_entries_in_structure(alignedData,'stim_name',...
		'tags_discard',stimDiscard,'tags_keep',stimKeep);

	% If combineStim is not true, find out how many different stimulations were applied
	% If combineStim is true, collect the events belong to the same category from all recordings
	if ~combineStim
		[C, ia, ic] = unique({alignedData.stim_name});
	else
		C = {'allRec'};
		ic = ones(1,numel(alignedData));
	end
	num_C = numel(C);


	if ~exist('fname','var')
		fname = sprintf('aligned_catTraces_%s',eventCat);
	end

	f_trace_win = fig_canvas(3,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'column_lim',3,'fig_name',fname); % create a figure

	% f_trace_win = figure('Name',fname);
	% set(gcf, 'Units', 'normalized', 'Position', fig_position)
	
	tile_col_num = ceil(num_C/tile_row_num);
	tlo = tiledlayout(f_trace_win, tile_row_num, tile_col_num);

	traceInfo_fields = {'group','stim','timeInfo','mean_val','ste_val',...
		'recNum','recDateNum','roiNum','tracesNum','eventProps'};
	traceInfo = empty_content_struct(traceInfo_fields,num_C); 

	for n = 1:num_C
		stimName = C{n};

		if debugMode
			fprintf('\nstimName (%g/%g): %s\n',n,num_C,stimName);
			if n == 1
				pause
			end
		end

		IDX_trial = find(ic == n);
		timeInfo = alignedData(IDX_trial(1)).time;
		num_stimTrial = numel(IDX_trial); % number of trials applied with the same stim
		traceData_cell_trials = cell(1, num_stimTrial); 
		eventProp_cell_trials = cell(1, num_stimTrial); 
		
		for nst = 1:num_stimTrial
			trialName = alignedData(IDX_trial(nst)).trialName;
			recDateTimeInfo = trialName(1:15);
			if debugMode
				fprintf(' recName (%g/%g): %s\n',nst,num_stimTrial,trialName);
			end

			traceInfo_trial = alignedData(IDX_trial(nst)).traces;
			num_roi = numel(traceInfo_trial);
			traceData_cell_rois = cell(1, num_roi);
			eventProp_cell_rois = cell(1, num_roi);
			for nr = 1:num_roi
				eventCat_info = {traceInfo_trial(nr).eventProp.peak_category};
				event_idx = find(strcmpi(eventCat_info,eventCat));
				if ~isempty(event_idx)
					roiName = alignedData(IDX_trial(nst)).traces(nr).roi;

					if debugMode
						fprintf('  - roi (%g/%g): %s\n',nr,num_roi,roiName);
					end

					traceData_cell_rois{nr} = traceInfo_trial(nr).value(:,event_idx);
					eventProp_cell_rois{nr} = traceInfo_trial(nr).eventProp(event_idx);

					if normalized
						peakMagDelta = [traceInfo_trial(nr).eventProp(event_idx).peak_mag_delta];
						peakMagDelta = reshape(peakMagDelta,1,[]);
						traceData_cell_rois{nr} = traceData_cell_rois{nr}./peakMagDelta;
					end

					DateTimeRoi = sprintf('%s_%s',recDateTimeInfo,roiName);
					[eventProp_cell_rois{nr}.DateTimeRoi] = deal(DateTimeRoi);
				end
				if sponNorm
					sponAmp = traceInfo_trial(nr).sponAmp;
					traceData_cell_rois{nr} = traceData_cell_rois{nr}/sponAmp;
				end
			end
			traceData_cell_trials{nst} = [traceData_cell_rois{:}];
			eventProp_cell_trials{nst} = [eventProp_cell_rois{:}];
		end
		tracesData = [traceData_cell_trials{:}];
		eventProp_trials = [eventProp_cell_trials{:}];

		ax = nexttile(tlo);

		[tracesAverage,tracesShade,nNum,titleName] = plotAlignedTracesAverage(gca,tracesData,timeInfo,...
			'eventsProps',eventProp_trials,'shadeType',shadeType,...
			'plot_median',plot_median,'medianProp',medianProp,...
			'plot_combined_data',plot_combined_data,'plot_raw_races',plot_raw_races,...
			'y_range',y_range,'tickInt_time',tickInt_time,'stimName',stimName,'eventCat',eventCat);


		traceInfo(n).group = titleName;
		traceInfo(n).stim = stimName;
		traceInfo(n).timeInfo = timeInfo;
		traceInfo(n).traces = tracesData;
		traceInfo(n).mean_val = tracesAverage;
		traceInfo(n).ste_val = tracesShade;
		traceInfo(n).eventProps = eventProp_trials;
		traceInfo(n).recNum = nNum.recNum;
		traceInfo(n).recDateNum = nNum.recDateNum;
		traceInfo(n).roiNum = nNum.roiNum;
		traceInfo(n).tracesNum = nNum.tracesNum;
	end
	varargout{1} = gcf;
	varargout{2} = traceInfo;
end

function [recNum,recDateNum,roiNum,tracesNum] = calcDataNum(eventProp_trials)
	% calculte the n numbers using the structure var 'eventProp_trials'

	% get the date and time info from trial names
	% one specific date-time (exp. 20230101-150320) represent one recording
	% one date, in general, represent one animal
	if ~isempty(eventProp_trials)
		dateTimeRoiAll = {eventProp_trials.DateTimeRoi};
		dateTimeAllRec = cellfun(@(x) x(1:15),dateTimeRoiAll,'UniformOutput',false);
		dateAllRec = cellfun(@(x) x(1:8),dateTimeRoiAll,'UniformOutput',false);
		dateTimeRoiUnique = unique(dateTimeRoiAll);
		dateTimeUnique = unique(dateTimeAllRec);
		dateUnique = unique(dateAllRec);

		% get all the n numbers
		recNum = numel(dateTimeUnique);
		recDateNum = numel(dateUnique);
		roiNum = numel(dateTimeRoiUnique);
		tracesNum = numel(dateTimeRoiAll);
	else
		recNum = 0;
		recDateNum = 0;
		roiNum = 0;
		tracesNum = 0;
	end
end