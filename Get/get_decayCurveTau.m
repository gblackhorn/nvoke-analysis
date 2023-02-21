function [varargout] = get_decayCurveTau(alignedData_trials,varargin)
	% 

	% Defaults
	filter_roi_tf = false; % do not filter ROIs by default

	stimName = 'og-5s';
	stimEffect_filter = [nan 1 nan]; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	rsquare_thresh = 0.7;

	norm_FluorData = false; % true/false. whether to normalize the FluroData

	save_fig = false; % Do not save figures by default
	gui_save = 'off'; % Do not use gui to save
	save_dir = '';

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('filter_roi_tf', varargin{ii})
	        filter_roi_tf = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('stimName', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        stimName = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    % elseif strcmpi('stim_effect_filter', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	    %     stim_effect_filter = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('stimEffect_filter', varargin{ii})
            stimEffect_filter = varargin{ii+1};
	    elseif strcmpi('rsquare_thresh', varargin{ii})
            rsquare_thresh = varargin{ii+1};
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
	% Get trials applied with specified stimulation (use 'stimName')
	trial_stimNames = {alignedData_trials.stim_name}; % Get stimulation names from all trials
	tf_stimName = strcmpi('trial_stimNames',stimName); % Compare the stim names with the specified one
	alignedData_trials = alignedData_trials(tf_stimName); % Keep the trials applied with the specified stimulation


	% Filter the ROIs in trials using the stimulation effect (Optional)
	if filter_roi_tf
		[alignedData_trials] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_trials,...
			'stim_names',stimName,'filters',stimEffect_filter);
	end 


	% Go through every ROI in every trial and get the decay tau
	trial_num = numel(alignedData_trials); 
	roi_tauInfo_cell = cell(1,trial_num);
	for tn = 1:trial_num
		% Get the data for curve fitting: timeData, timeRanges for curvefitting, 
		trialName = alignedData_trials.trialName{1:15}; % yyyymmdd-hhmmss
		[timeData,FluroData] = get_TrialTraces_from_alignedData(alignedData_trials,...
			'norm_FluorData',norm_FluorData); 
		timeRanges = alignedData_trials.stimInfo.UnifiedStimDuration.range;

		% Go through ROIs in a single trial and get the decay curve fitting information
		roi_num = numel(alignedData_trials.traces);
		roi_tauInfo_cell{tn} = empty_content_struct({'trialName','roiName','yfit','tauInfo','tauMean'})
		for rn = 1:roi_num
			roiName = alignedData_allTrials.traces(rn).roi;
			roi_FluroData = FluroData(:,rn);
			roi_eventTime = [alignedData_allTrials.traces(rn).eventProp.rise_time];  
			[curvefit,tauInfo] = GetDecayFittingInfo_neuron(timeData,roi_FluroData,...
				timeRanges,EventTime,rsquare_thresh);
			% Add decay tau to alignedData structure
			alignedData_allTrials.traces(rn).tauInfo = tauInfo;

			% Create a new structure containing ROI names, their trial name, curvefit info, and mean tau for
			% output
			roi_tauInfo_cell{tn}(rn).trialName = trialName;
			roi_tauInfo_cell{tn}(rn).roiName = roiName;
			roi_tauInfo_cell{tn}(rn).yfit = curvefit;
			roi_tauInfo_cell{tn}(rn).tauInfo = tauInfo;
			roi_tauInfo_cell{tn}(rn).tauMean = tauInfo.mean;
		end
	end
	roi_tauInfo = roi_tauInfo_cell{:};




























	% Get the stimulation patch info for plotting the shades to indicate stimulation
	[patchCoor,stimName,stimTypeNum] = get_TrialStimPatchCoor_from_alignedData(alignedData_trial);

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


	% Get the time information and traces
	[timeData,FluroData] = get_TrialTraces_from_alignedData(alignedData_trial,...
		'norm_FluorData',norm_FluorData); 


	if ~isempty(FluroData)
		% Get the events' time
		[event_riseTime] = get_TrialEvents_from_alignedData(alignedData_trial,'rise_time');
		[event_peakTime] = get_TrialEvents_from_alignedData(alignedData_trial,'peak_time');


		% Compose the stem part of figure title
		trialName = alignedData_trial.trialName(1:15); % Get the date (yyyymmdd-hhmmss) part from trial name
		stimName = alignedData_trial.stim_name; % Get the stimulation name
		if ~isempty(title_prefix)
			title_prefix = sprintf('%s ', title_prefix); % add a space after the title_prefix in increase the readibility when combine with other strings
		end
		title_str_stem = sprintf('%s %s',trialName,stimName); % compose a stem str used for both fig 1 and 2
		fig_title = cell(1,2);


		% Figure 1: Plot the calcium fluorescence as traces and color (2 plots)
			% trace plot (default xtick interval is 10)
		if norm_FluorData
			norm_str = 'norm';
		else
			norm_str = '';
		end
		fig_title{1} = sprintf('%s %s fluorescence signal',title_str_stem,norm_str); % Create the title string
		f(1) = fig_canvas(2,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',1,'fig_name',fig_title{1}); % create a figure
		tlo = tiledlayout(f, 2, 1); % setup tiles
		ax = nexttile(tlo); % activate the ax for trace plot
		plot_TemporalData_Trace(gca,timeData,FluroData,...
			'ylabels',rowNames,'plot_marker',true,...
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
		fig_title{2} = sprintf('%s event raster and histbin',title_str_stem);
		f(2) = plot_raster_with_hist(event_riseTime,trace_xlim,'shadeData',patchCoor,...
			'rowNames',rowNames,'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,...
			'titleStr',fig_title{2});
		sgtitle(fig_title{2})


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