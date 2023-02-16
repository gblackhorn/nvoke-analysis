function [f1,f2,varargout] = plot_Trace_n_Events_alignedData(alignedData_trial,varargin)
	% Plot calcium fluorescence as traces and color, and plot calcium events using scatter
	% (show the event number in time bins in the histogram). Use the data from one trial in the
	% format of aligneData (a structure var) accquired from function "get_event_trace_allTrials"

	% Example:
	%	[f1,f2] = plot_trace_events_alignedData(alignedData_trial,'pick',[1 3 5 7],'norm_FluorData',true); 
	%		get the 1st, 3rd, 5th and 7th roi traces from alignedData_trial and normalize them with their
	% 		max values

	% Defaults
	pick = nan; 
	norm_FluorData = false; % true/false. whether to normalize the FluroData
	event_type = 'rise_time'; % events plotted in scatter. 'rise_time','peak_time', etc.
	stim_effect_filter = [nan nan nan]; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	%	Use nan (inactive filter), true (active effect), and false (inactive effect) to filter ROIs
	%	[true false nan]: stimulation has excitation effect, no inhibitory effect, rebound effect is not considered

	plot_unit_width = 0.4; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display

	show_colorbar = false; % true/false. Show color scale next to the fluorescence signal color plot.
	hist_binsize = 5; % the size of the histogram bin, used to calculate the edges of the bins
	xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale. Use by figure 2

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('pick', varargin{ii})
	        pick = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('norm_FluorData', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        norm_FluorData = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('plot_unit_width', varargin{ii})
            plot_unit_width = varargin{ii+1};
	    elseif strcmpi('plot_unit_height', varargin{ii})
            plot_unit_height = varargin{ii+1};
	    elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents

	% Get the stimulation patch info for plotting the shades to indicate stimulation
	[patchCoor,stimName,stimTypeNum] = get_TrialStimPatchCoor_from_alignedData(alignedData_trial);

	% Filter ROIs if 'pick' is input as varargin
	trace_event_data = alignedData_trial.traces; % roi names, calcium fluorescence data, events' time info are all in the field 'traces'
	[trace_event_data] = Filter_AlignedDataTraces_withStimEffect(trace_event_data,...
		'ex',stim_effect_filter(1),'in',stim_effect_filter(2),'rb',stim_effect_filter(3));
	alignedData_trial.traces = trace_event_data; % replace the trace_event_data with the filtered one

	
	% Get the ROI names
	rowNames = {alignedData_trial.traces.roi};


	% Get the time information and traces
	[timeData,FluroData] = get_TrialTraces_from_alignedData(alignedData_trial,...
		'norm_FluorData',norm_FluorData); 


	% Get the events' time
	[event_riseTime] = get_TrialEvents_from_alignedData(alignedData_trial,'rise_time');
	[event_peakTime] = get_TrialEvents_from_alignedData(alignedData_trial,'peak_time');


	% Compose the stem part of figure title
	trialName = alignedData_trial.trialName(1:15); % Get the date (yyyymmdd-hhmmss) part from trial name
	stimName = alignedData_trial.stim_name; % Get the stimulation name
	title_str_stem = sprintf('%s %s',trialName,stimName); % compose a stem str used for both fig 1 and 2


	% Figure 1: Plot the calcium fluorescence as traces and color (2 plots)
		% trace plot (default xtick interval is 10)
	if norm_FluorData
		norm_str = 'norm';
	else
		norm_str = '';
	end
	f1_title = sprintf('%s %s fluorescence signal',title_str_stem,norm_str); % Create the title string
	f(1) = fig_canvas(2,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
		'column_lim',1,'fig_name',f1_title); % create a figure
	tlo = tiledlayout(f, 2, 1); % setup tiles
	ax = nexttile(tlo); % activate the ax for trace plot
	plot_TemporalData_Trace(gca,timeData,FluroData,...
		'ylabels',rowNames,'plot_marker',true,...
		'marker1_xData',event_peakTime,'marker2_xData',event_riseTime);
	trace_xlim = xlim;

		% color plot (default xtick interval is 10)
	FluroData_trans = FluroData.'; % transpose the FluroData. row of matrix will be plotted as rows in color plot
	ax = nexttile(tlo); % activate the ax for color plot
	plot_TemporalData_Color(plotWhere,TemporalData,...
		'rowNames',rowNames,'x_window',trace_xlim,'show_colorbar',show_colorbar);


	% Figure 2: Plot the calcium events as scatter and show the events number in a histogram (2 plots)
	f2_title = sprintf('%s event raster and histbin',title_str_stem);
	f(2) = plot_raster_with_hist(event_riseTime,trace_xlim,...
		'rowNames',rowNames,'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,...
		'titleStr',f2_title);
end