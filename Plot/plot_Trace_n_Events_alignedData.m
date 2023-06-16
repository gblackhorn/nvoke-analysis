function [f,varargout] = plot_Trace_n_Events_alignedData(alignedData_trial,varargin)
	% Plot calcium fluorescence as traces and color, and plot calcium events using scatter
	% (show the event number in time bins in the histogram). Use the data from one trial in the
	% format of aligneData (a structure var) accquired from function "get_event_trace_allTrials"

	% Example:
	%	[f1,f2] = plot_trace_events_alignedData(alignedData_trial,'pick',[1 3 5 7],'norm_FluorData',true); 
	%		get the 1st, 3rd, 5th and 7th roi traces from alignedData_trial and normalize them with their
	% 		max values

	% Defaults
	pick = nan; 
	norm_FluorData = true; % true/false. whether to normalize the FluroData
	event_type = 'peak_time'; % events plotted in scatter. 'rise_time','peak_time', etc.
	% stim_effect_filter = [nan nan nan]; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	% %	Use nan (inactive filter), true (active effect), and false (inactive effect) to filter ROIs
	% %	[true false nan]: stimulation has excitation effect, no inhibitory effect, rebound effect is not considered

	sortROI = false; % true/false. Sort ROIs according to the event number: high to low

	preTime = 5; % fig3 include time before stimulation starts for plotting
	postTime = 10; % fig3 include time after stimulation ends for plotting. []: until the next stimulation starts

	activeHeatMap = true; % true/false. If true, only plot the traces with specified events in figure 3
	stimEvents(1).stimName = 'og-5s';
	stimEvents(1).eventCat = 'rebound';
	stimEvents(1).eventCatFollow = 'spon'; % The category of first event following the eventCat one
	stimEvents(1).stimRefType = 'end'; % The category of first event following the eventCat one
	stimEvents(2).stimName = 'ap-0.1s';
	stimEvents(2).eventCat = 'trig';
	stimEvents(2).eventCatFollow = 'spon'; % The category of first event following the eventCat one
	stimEvents(2).stimRefType = 'start'; % The category of first event following the eventCat one
	stimEvents(3).stimName = 'og-5s ap-0.1s';
	stimEvents(3).eventCat = 'rebound';
	stimEvents(3).eventCatFollow = 'spon'; % The category of first event following the eventCat one
	stimEvents(3).stimRefType = 'end'; % The category of first event following the eventCat one
	followDelayType = 'stim'; % stim/stimEvent. Calculate the delay of the following events using the stimulation start or the stim-evoked event time
	eventsTimeSort = 'off'; % 'off'/'inROI','all'. sort traces according to eventsTime

	plot_marker = true; % true/false. Mark events in traces and heatmap if this is true
	plot_unit_width = 0.4; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display

	show_colorbar = false; % true/false. Show color scale next to the fluorescence signal color plot.
	hist_binsize = 5; % the size of the histogram bin, used to calculate the edges of the bins
	xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale. Use by figure 2

	title_prefix = '';

	save_fig = false; % Do not save figures by default
	gui_save = 'off'; % Do not use gui to save
	save_dir = '';

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('pick', varargin{ii})
	        pick = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('norm_FluorData', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        norm_FluorData = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('event_type', varargin{ii}) % 
	        event_type = varargin{ii+1}; % 
        elseif strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1}; 
        elseif strcmpi('postTime', varargin{ii})
        	postTime = varargin{ii+1}; 
	    elseif strcmpi('sortROI', varargin{ii})
            sortROI = varargin{ii+1};
	    elseif strcmpi('activeHeatMap', varargin{ii})
            activeHeatMap = varargin{ii+1};
	    elseif strcmpi('stimEvents', varargin{ii})
            stimEvents = varargin{ii+1};
	    elseif strcmpi('followDelayType', varargin{ii})
            followDelayType = varargin{ii+1};
	    elseif strcmpi('eventsTimeSort', varargin{ii})
            eventsTimeSort = varargin{ii+1};
	    elseif strcmpi('plot_marker', varargin{ii})
            plot_marker = varargin{ii+1};
	    elseif strcmpi('plot_unit_width', varargin{ii})
            plot_unit_width = varargin{ii+1};
	    elseif strcmpi('plot_unit_height', varargin{ii})
            plot_unit_height = varargin{ii+1};
	    elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1};
	    elseif strcmpi('hist_binsize', varargin{ii})
            hist_binsize = varargin{ii+1};
	    elseif strcmpi('xtickInt_scale', varargin{ii})
            xtickInt_scale = varargin{ii+1};
	    elseif strcmpi('title_prefix', varargin{ii})
            title_prefix = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
	    elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents

	% Get the stimulation patch info for plotting the shades to indicate stimulation
	[patchCoor,stimTypes,stimTypeNum] = get_TrialStimPatchCoor_from_alignedData(alignedData_trial);
	% combinedStimRange = alignedData_trial.stimInfo.UnifiedStimDuration.range;
	stimInfo = alignedData_trial.stimInfo;

	% Filter ROIs if 'pick' is input as varargin
	trace_event_data = alignedData_trial.traces; % roi names, calcium fluorescence data, events' time info are all in the field 'traces'
	if ~isnan(pick)
		trace_event_data = trace_event_data(pick);
	end
	% [trace_event_data] = Filter_AlignedDataTraces_withStimEffect(trace_event_data,...
	% 	'ex',stim_effect_filter(1),'in',stim_effect_filter(2),'rb',stim_effect_filter(3));
	alignedData_trial.traces = trace_event_data; % replace the trace_event_data with the filtered one

	
	% Get the ROI names
	rowNames = {alignedData_trial.traces.roi};
	roiNum = numel(alignedData_trial.traces);
	% fluroData = cell(1,roiNum);
	eventsTime = cell(roiNum,1);
	eventCat = cell(roiNum,1);
	for rn = 1:roiNum
		% fluroData{rn} = alignedData_trial.traces(rn).fullTrace;
		eventsTime{rn} = [alignedData_trial.traces(rn).eventProp.peak_time];
		eventCat{rn} = {alignedData_trial.traces(rn).eventProp.peak_category};
	end
	% fluroData = horzcat(fluroData{:});


	% Get the time information and traces
	[timeData,FluroData] = get_TrialTraces_from_alignedData(alignedData_trial,...
		'norm_FluorData',norm_FluorData); 


	if ~isempty(FluroData)
		% Get the events' time
		[event_riseTime] = get_TrialEvents_from_alignedData(alignedData_trial,'rise_time');
		[event_peakTime] = get_TrialEvents_from_alignedData(alignedData_trial,'peak_time');
		[event_eventCat] = get_TrialEvents_from_alignedData(alignedData_trial,'peak_category');



		% Calculate the numbers of events in each roi and sort the order of roi according to this (descending)
		if sortROI
			eventNums = cellfun(@(x) numel(x),event_riseTime);
			[~,descendIDX] = sort(eventNums,'descend');
			rowNames = rowNames(descendIDX);
			FluroData = FluroData(:,descendIDX);
			event_riseTime = event_riseTime(descendIDX);
			event_peakTime = event_peakTime(descendIDX);
            event_eventCat = event_eventCat(descendIDX);
			% event_eventCat = event_eventCat(descendIDX);
		end

		if strcmpi(event_type,'rise_time')
			eventTime = event_riseTime;
		elseif strcmpi(event_type,'peak_time')
			eventTime = event_peakTime;
		end


		if ~activeHeatMap || isempty(stimEvents)  % no filter for stimEvents (~activeHeatMap) or the information of stim and related events are missing
			StimEventsTime = NaN;
			firstSponEventsTime = NaN;
		else
			% find the location of trial stim name in the stimEvents.stimName
			stimEventsIDX = find(strcmpi({stimEvents.stimName},alignedData_trial.stim_name));
			% sponEventsIDX = find(strcmpi({stimEvents.eventCatFollow},alignedData_trial.stim_name));
			if ~isempty(stimEventsIDX)
				eventCat = stimEvents(stimEventsIDX).eventCat;
				eventCatFollow = stimEvents(stimEventsIDX).eventCatFollow; 
				stimRefType = stimEvents(stimEventsIDX).stimRefType; 
				eventsIDX = cellfun(@(x) find(strcmpi(x,eventCat)),event_eventCat,'UniformOutput',false);
				followEventCatIDX = cellfun(@(x) find(strcmpi(x,eventCatFollow)),event_eventCat,'UniformOutput',false); % the index of events with eventCatFollow
				followEventIDX = cellfun(@(x) x+1,eventsIDX,'UniformOutput',false); % the index of events after the stim-related events

				% get the stimEventTime for each roi
				StimEventsTime = cell(size(eventsIDX));
				followEventsTime = cell(size(eventsIDX));
				for rn = 1:numel(trace_event_data)
					StimEventsTime{rn} = eventTime{rn}(eventsIDX{rn});
					eventNumROI = numel(eventTime{rn}); % number of stim events in the current ROI

					if ~isempty(followEventCatIDX{rn}) % && ~isempty(afterStimSponIDX{rn})
						for m = 1:numel(followEventIDX{rn})
							if isempty(find(followEventCatIDX{rn}==followEventIDX{rn}(m)))
								followEventIDX{rn}(m) = NaN;
								followEventsTime{rn}(m) = NaN;
							else
								followEventsTime{rn}(m) = eventTime{rn}(followEventIDX{rn}(m));
							end
						end
					end
					% firstSponIDX_outOfRange = find(followEventIDX{rn}>eventNumROI);
					% followEventIDX{rn}(firstSponIDX_outOfRange) = NaN;
					% followEventsTime{rn} = eventTime{rn}(followEventIDX{rn});
				end
			else
				eventCat = '';
				eventCatFollow = '';
				StimEventsTime = NaN;
				followEventsTime = NaN;
				activeHeatMap = false;
			end
		end


		% Compose the stem part of figure title
		trialName = alignedData_trial.trialName(1:15); % Get the date (yyyymmdd-hhmmss) part from trial name
		stimName = alignedData_trial.stim_name; % Get the stimulation name
		if ~isempty(title_prefix)
			title_prefix = sprintf('%s ', title_prefix); % add a space after the title_prefix in increase the readibility when combine with other strings
		end
		title_str_stem = sprintf('%s %s',trialName,stimName); % compose a stem str used for both fig 1 and 2
		fig_title = cell(1,3);


		% Figure 1: Plot the calcium fluorescence as traces and color (2 plots)
			% trace plot (default xtick interval is 10)
		if norm_FluorData
			norm_str = 'norm';
		else
			norm_str = '';
		end
		if sortROI
			sortStr = 'Sorted-with-eventNum';
		else
			sortStr = '';
		end
		fig_title{1} = sprintf('%s %s fluorescence signal %s',title_str_stem,norm_str,sortStr); % Create the title string
		f(1) = fig_canvas(2,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',1,'fig_name',fig_title{1}); % create a figure
		tlo = tiledlayout(f(1), 3, 1); % setup tiles
		ax = nexttile(tlo,[2,1]); % activate the ax for trace plot
		plot_TemporalData_Trace(gca,timeData,FluroData,...
			'ylabels',rowNames,'plot_marker',plot_marker,...
			'marker1_xData',event_peakTime,'marker2_xData',event_riseTime,'shadeData',patchCoor);
		trace_xlim = xlim;
		f1_xticks = xticks;
		sgtitle(fig_title{1})

			% color plot (default xtick interval is 10)
		FluroData_trans = FluroData.'; % transpose the FluroData. row of matrix will be plotted as rows in color plot
		ax = nexttile(tlo); % activate the ax for color plot
		plot_TemporalData_Color(gca,FluroData_trans,...
			'rowNames',rowNames,'x_window',trace_xlim,'show_colorbar',show_colorbar);


		% Figure 2: Plot the calcium events as scatter and show the events number in a histogram (2 plots)
		fig_title{2} = sprintf('%s event [%s] raster and histbin %s',title_str_stem,event_type,sortStr);
		f(2) = plot_raster_with_hist(eventTime,trace_xlim,'shadeData',patchCoor,...
			'rowNames',rowNames,'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,...
			'titleStr',fig_title{2});
		sgtitle(fig_title{2})


		% Figure 3: Plot a color plot. Difference between this one and the one in figure 1 is every
		% ROI trace is cut to several sections using stimulation repeat. One row contains the start
		% of stim to the start of the next stim. Each ROI contains the stim repeat number of rows
		fig_title{3} = sprintf('%s %s single-stim fluorescence signal %s stimEventsDelaySort-%s',...
			title_str_stem,norm_str,sortStr,eventsTimeSort); % Create the title string
		
		f(3) = plot_TemporalData_Color_seperateStimRepeats(gca,FluroData,timeData,stimInfo,...
			'preTime',preTime,'postTime',postTime,...
			'eventsTime',eventTime,'eventsTimeSort',eventsTimeSort,'markEvents',plot_marker,...
			'rowNames',rowNames,'show_colorbar',show_colorbar,'titleStr',fig_title{3},'debug_mode',debug_mode); % ,'shadeData',patchCoor,'stimTypes',stimTypes
		sgtitle(fig_title{3})
		
		fig_title{4} = sprintf('%s %s single-stim fluorescence signal %s firstSponAfterStimDelaySort-%s',...
			title_str_stem,norm_str,sortStr,eventsTimeSort); % Create the title string
		f(4) = plot_TemporalData_Color_seperateStimRepeats(gca,FluroData,timeData,stimInfo,...
			'preTime',preTime,'postTime',postTime,'eventCat',event_eventCat,...
			'eventsTime',eventTime,'eventsTimeSort',eventsTimeSort,'stimEventCat',eventCat,...
			'followEventCat',eventCatFollow,'markEvents',plot_marker,...
			'rowNames',rowNames,'show_colorbar',show_colorbar,'titleStr',fig_title{4},'debug_mode',debug_mode); % ,'shadeData',patchCoor,'stimTypes',stimTypes
		sgtitle(fig_title{4})


		% % Figure 3: Plot a color plot. Difference between this one and the one in figure 1 is every
		% % ROI trace is cut to several sections using stimulation repeat. One row contains the start
		% % of stim to the start of the next stim. Each ROI contains the stim repeat number of rows
		% fig_title{3} = sprintf('%s %s single-stim fluorescence signal %s stimEventsDelaySort-%s',...
		% 	title_str_stem,norm_str,sortStr,eventsTimeSort); % Create the title string
		
		% f(3) = plot_TemporalData_Color_seperateStimRepeats(gca,FluroData,timeData,stimInfo,...
		% 	'preTime',preTime,'postTime',postTime,...
		% 	'eventsTime',StimEventsTime,'eventsTimeSort',eventsTimeSort,'markEvents',plot_marker,...
		% 	'rowNames',rowNames,'show_colorbar',show_colorbar,'titleStr',fig_title{3},'debug_mode',debug_mode); % ,'shadeData',patchCoor,'stimTypes',stimTypes
		% sgtitle(fig_title{3})
		
		% fig_title{4} = sprintf('%s %s single-stim fluorescence signal %s firstSponAfterStimDelaySort-%s',...
		% 	title_str_stem,norm_str,sortStr,eventsTimeSort); % Create the title string
		% f(4) = plot_TemporalData_Color_seperateStimRepeats(gca,FluroData,timeData,stimInfo,...
		% 	'preTime',preTime,'postTime',postTime,...
		% 	'eventsTime',StimEventsTime,'eventsTimeSort',eventsTimeSort,'followEventsTime',followEventsTime,...
		% 	'followDelayType',followDelayType,'markEvents',plot_marker,...
		% 	'rowNames',rowNames,'show_colorbar',show_colorbar,'titleStr',fig_title{4},'debug_mode',debug_mode); % ,'shadeData',patchCoor,'stimTypes',stimTypes
		% sgtitle(fig_title{4})


		% Save figures
		fig_num = numel(f);
		if save_fig
			for fn = 1:fig_num
				if isempty(save_dir)
					gui_save = 'on';
				end
				msg = 'Choose a folder to save calcium traces and events plots';
				savePlot(f(fn),'save_dir',save_dir,'guiSave',gui_save,...
					'guiInfo',msg,'fname',fig_title{fn});
			end
			close all
		end
	end
end