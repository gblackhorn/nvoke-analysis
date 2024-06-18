function [varargout] = plot_calcium_signals_alignedData_allTrials(alignedData,varargin)
	% Plot calcium fluorescence as traces and color, and plot calcium events using scatter(show the
	% event number in time bins in the histogram) for multiple trials. Use aligneData (a structure
	% var) accquired from function "get_event_trace_allTrials"

	% Example:
	%	plot_calcium_signals_alignedData_allTrials(alignedData,'filter_roi_tf',true,'norm_FluorData',true); 
	%		

	% Defaults
	filter_roi_tf = false; % do not filter ROIs by default
	stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = {[nan 1 nan], [1 nan nan], [nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound

	event_type = 'peak_time'; % use peak_time for event time
	norm_FluorData = false; % true/false. whether to normalize the FluroData
	sortROI = false; % true/false. Sort ROIs according to the event number: high to low

	preTime = 0; % fig3 include time before stimulation starts for plotting
	postTime = []; % fig3 include time after stimulation ends for plotting. []: until the next stimulation starts

	activeHeatMap = true; % true/false. If true, only plot the traces with specified events in figure 3
	stimEvents(1).stimName = 'og-5s';
	stimEvents(1).eventCat = 'rebound';
	stimEvents(2).stimName = 'ap-0.1s';
	stimEvents(2).eventCat = 'trig';
	stimEvents(3).stimName = 'og-5s ap-0.1s';
	stimEvents(3).eventCat = 'rebound';
	followDelayType = 'stimEvent'; % stim/stimEvent. Calculate the delay of the following events using the stimulation start or the stim-evoked event time
	eventsTimeSort = 'off'; % 'off'/'inROI','all'. sort traces according to eventsTime

	plot_unit_width = 0.4; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display

	show_colorbar = true; % true/false. Show color scale next to the fluorescence signal color plot.
	hist_binsize = 5; % the size of the histogram bin, used to calculate the edges of the bins
	xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale. Use by figure 2

	save_fig = false;
	save_dir = '';

	% pause_plot = true;

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('filter_roi_tf', varargin{ii})
	        filter_roi_tf = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('stim_names', varargin{ii})
	        stim_names = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('filters', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        filters = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('norm_FluorData', varargin{ii})
            norm_FluorData = varargin{ii+1};
	    elseif strcmpi('sortROI', varargin{ii})
            sortROI = varargin{ii+1};
        elseif strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1}; 
        elseif strcmpi('postTime', varargin{ii})
        	postTime = varargin{ii+1}; 
	    elseif strcmpi('activeHeatMap', varargin{ii})
            activeHeatMap = varargin{ii+1};
	    elseif strcmpi('stimEvents', varargin{ii})
            stimEvents = varargin{ii+1};
	    elseif strcmpi('followDelayType', varargin{ii})
            followDelayType = varargin{ii+1};
	    elseif strcmpi('eventsTimeSort', varargin{ii})
            eventsTimeSort = varargin{ii+1};
	    elseif strcmpi('plot_unit_width', varargin{ii})
            plot_unit_width = varargin{ii+1};
	    elseif strcmpi('plot_unit_height', varargin{ii})
            plot_unit_height = varargin{ii+1};
	    elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
	    end
	end

	% ====================
	% Main contents

	% Filter the ROIs in all trials using the stimulation effect
	if filter_roi_tf
		[alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
			'stim_names',stim_names,'filters',filters);
		title_prefix = 'filtered';
	else
		alignedData_filtered = alignedData;
		title_prefix = '';
	end 


	% Get the save location with UI if save_fig is true
	if save_fig
		save_dir = uigetdir(save_dir,'Choose a folder to save plots');
		if save_dir == 0
			error('Folder for saving figures is not selected')
		end
	end


	% Plot calcium fluorescence as traces and color (fig1), and plot calcium events using scatter
	% (show the event number in time bins in the histogram) (fig2).
	trial_num = numel(alignedData_filtered);
	for tn = 1:trial_num
		pause_plot = false;
		close all

		if debug_mode
			fprintf('trial %d/%d: %s\n',tn,trial_num,alignedData_filtered(tn).trialName)
			if tn == 17
				pause
			end
		end

		plot_Trace_n_Events_alignedData(alignedData_filtered(tn),...
			'event_type',event_type,'norm_FluorData',norm_FluorData,'sortROI',sortROI,...
			'preTime',preTime,'postTime',postTime,'followDelayType',followDelayType,...
			'activeHeatMap',activeHeatMap,'stimEvents',stimEvents,'eventsTimeSort',eventsTimeSort,...
			'plot_unit_width',plot_unit_width,'plot_unit_height',plot_unit_height,...
			'show_colorbar',show_colorbar,'hist_binsize',hist_binsize,'xtickInt_scale',xtickInt_scale,...
			'title_prefix',title_prefix,'save_fig',save_fig,'save_dir',save_dir,...
			'debug_mode',debug_mode);

		if save_fig
			pause_plot = false;
		end
		if pause_plot
			pause
		end
	end

	varargout{1} = save_dir;	
end