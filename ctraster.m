function [rec, peak_table] = ctraster(Input, varargin)

% raster plot calcium transient peaks If Input is the rawdata table (ROIdata), this function will organize data to 'rec'
% structure and plot. If Input is 'rec' structure, rec data will be used to plot directly. [rec, peak_table] =
% ctraster(Input, sort_col, save_plot, stim_duration, pre_stim_duration, post_stim_duration) 
%   varargin{1} - sort_col: 5-peakTotal, 6-prePeak, 7-peakDuringStim, 8-postPeak, 
%							9-prePeakDpeakTotal, 10-peakDuringStimDpeakTotal, 11-postPeakDpeakTotal
%	varargin{2} - save_plot: 1-save raster plot. 0-do not save raster plot
%	varargin{3} - stim_duration: 1s, 5s, or 10s. If other time duration is used, pre_stim_duration and post_stim_duration must be 
%				  specified.
%	varargin{4} - pre_stim_duration: calcium transients in this time duration before stimulation starts will be shown in plot
%	varargin{5} - post_stim_duration: calcium transients in this time duration after stimulation starts will be shown in plot 


	row_interval = 0.6; % interval of rows in raster plot. distance between row (center to center) is 1 in total
	figfolder_default = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks';
	peak_table_col_str = {'recording', 'calData', 'neuron', 'stimu_num', 'peak_s_aligned',...
	'peakTotal ', 'prePeak ', 'peakDuringStim ', 'postPeak ', 'prePeakDpeakTotal ',...
	'peakDuringStimDpeakTotal ', 'postPeakDpeakTotal ', 'peakDuringStimDprePeak ', 'peakDelayStim ', 'peakDelayStimEnd ',...
	'peakTotalFr ', 'prePeakFr ', 'peakDuringStimFr ', 'postPeakFr ', 'peakwoStimFr '};
	duration_pre_peak = 3; % time duration used to count peaks mentioned in 'peak_table_col_str' above
	duration_post_peak = 3;
	sort_col = 6; % 6-peakTotal, 7-prePeak, 8-peakDuringStim, 9-postPeak, 10-prePeakDpeakTotal, 
				  % 11-peakDuringStimDpeakTotal, 12-postPeakDpeakTotal, 13-peakduringstimDprepeak,14-peakDelayStim, 15-peakDelayStimEnd
	sort_direction = 'ascend'; % default = 'ascend'. 'descend'

	pre_stimuli_duration = 10; % default duration before stimulation onset. stimulation 10s
	post_stimuli_duration = 20; % default duration after stimulation end. stimulation 10s
	
	narginchk(1,6); % check the number of inputs	

	switch nargin
	case 1 % default setting for 10s opto stimulation
	case 2
	case 3
	case 4
	case 5
		error('Please specify post-stimulation as the forth input')
	case 6
	end


	if nargin >=2
		sort_col = varargin{1}; % 5-peakTotal, 6-prePeak, 7-peakDuringStim, 8-postPeak, 
				  				% 9-prePeakDpeakTotal, 10-peakDuringStimDpeakTotal, 11-postPeakDpeakTotal
	end
	if nargin >= 3
		if varargin{2} == 1
			save_raster_plot = true;
		else
			save_raster_plot = false;
		end
	else
		save_raster_plot = false;
	end
	if nargin >= 4
		if varargin{3} == 1
			pre_stimuli_duration = 5; % duration before stimulation onset
			post_stimuli_duration = 8; % duration after stimulation end
		elseif varargin{3} == 5
			pre_stimuli_duration = 5; % duration before stimulation onset
			post_stimuli_duration = 10; % duration after stimulation end
		elseif varargin{3} == 10
			pre_stimuli_duration = 5; % duration before stimulation onset
			post_stimuli_duration = 15; % duration after stimulation end
		else
			error('Please specify pre- and post-stimulation in the input as (data, stim_duration, pre-, post)')
		end
	end
	if nargin >= 6
		pre_stimuli_duration = varargin(4); % duration before stimulation onset
		post_stimuli_duration = varargin(5); % duration after stimulation end
	end
    
    

    recording_num = size(Input, 1);
    ptc = 1; % peak_tablec_counter
    if ~isstruct(Input)
	    % Organize peak and gpio data for plot
	    for rn = 1:recording_num
	    	
	    	if isstruct(Input{rn, 2})
	    		recording_rawdata = Input{rn,2}.decon;
	    		peak_info = table2array(Input{rn,5}(1, :)); 
	    		cnmf = 1;
	    		lowpass_for_peak = false; % use lowpassed data for peak detaction off
	    		% peakinfo_row = 1; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 1st row (peak row)
	    		peakinfo_row_name = 'peak';
	    	else
	    		recording_rawdata = Input{rn,2};
	    		peak_info = table2array(Input{rn,5}(3, :));
	    		cnmf = 0;
	    		lowpass_for_peak = true; % use lowpassed data for peak detaction on
	    		% peakinfo_row = 3; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 3rd row (peak row)
	    		peakinfo_row_name = 'Peak_lowpassed';
	    	end

	    	recording_fr = 1/(recording_rawdata.Time(2)-recording_rawdata.Time(1)); % recording frequency
	    	recording_time = round(recording_rawdata.Time(end)); % recording duration in s

	    	% Dig out gpio info
	    	stimulation = Input{rn, 3}{1, 1}; % name of stimulation
	    	channel = Input{rn, 4}; % GPIO channels
	    	gpio_signal= channel(3).time_value; % channel(1) is 'SYNC', channel(2) is 'EX-LED'
	    	gpio_rise_loc = find(gpio_signal(:, 2)); % locations of GPIO voltage not 0, ie stimuli start
	    	gpio_rise_num = length(gpio_rise_loc); % number of GPIO voltage rise
	    	gpio_rise_interval = gpio_signal(gpio_rise_loc(2:end), 1)-gpio_signal(gpio_rise_loc(1:(end-1)), 1);
	    	train_interval_loc = find(gpio_rise_interval >= 5);
	    	train_end_loc = [gpio_rise_loc(train_interval_loc); gpio_rise_loc(end)]; % time of the train_end rises start
	    	train_start_loc = [gpio_rise_loc(1); gpio_rise_loc(train_interval_loc+1)]; % time of the train_start rises start
	    	gpio_train_start_time = gpio_signal(train_start_loc, 1); % time points when GPIO trains start
	    	gpio_train_end_time = gpio_signal(train_end_loc+1, 1); % time points when GPIO trains end
	    	plot_start_time = gpio_train_start_time-pre_stimuli_duration; % start to plot: 'pre_stimuli_duration' before train starts
	    	plot_end_time = gpio_train_end_time+post_stimuli_duration;
	    	gpio_train_num = length(plot_start_time);
	    	gpio_duration = round(gpio_train_end_time(1)-gpio_train_start_time(1)); % duration of gpio train
	    	plot_duration = pre_stimuli_duration+gpio_duration+post_stimuli_duration; % time duration shown in plot

	    	rec(rn).name = Input{rn,1};
	    	rec(rn).gpio.train_num = gpio_train_num; % store number of gpio trains
	    	rec(rn).gpio.duration = gpio_duration; % duration of gpio train
	    	rec(rn).gpio.time(:, 1) = gpio_train_start_time;
	    	rec(rn).gpio.time(:, 2) = gpio_train_end_time;
	    	rec(rn).gpio.time_plot(:, 1) = plot_start_time;
	    	rec(rn).gpio.time_plot(:, 2) = plot_end_time;
	    	rec(rn).XLim = [-pre_stimuli_duration (gpio_duration+post_stimuli_duration)];

	    	peakinfo_row = find(strcmp(peakinfo_row_name, Input{rn, 5}.Properties.RowNames));
	    	roi_num = size(Input{rn, 5}, 2); % total roi numbers after handpick

	    	for roi_n = 1:roi_num % number of roi
	    		if ~isempty(peak_info{roi_n})
		    		peak_time = peak_info{roi_n}.Peak_loc_s_; % peak time in 's' from roi_n neuron
		    		for gn = 1:gpio_train_num % number of stimulation train
		    			% next 2 lines organize peaks (as seconds) in roi row and gpio column
		    			peakinfo_rows = find(peak_time>=plot_start_time(gn) & peak_time<=plot_end_time(gn)); % peaks in start and end time duration
		    			rec(rn).peak{roi_n, gn} = peak_time(peakinfo_rows);
		    			rec(rn).peak_gpio_align{roi_n, gn} = rec(rn).peak{roi_n, gn}-gpio_train_start_time(gn); % align peak time to stimulation
		    			peak_data = rec(rn).peak_gpio_align{roi_n, gn};
		    			peak_num = length(peak_data);

		    			peak_table_array{ptc, 1} = rec(rn).name;
		    			peak_table_array{ptc, 2}.calData = recording_rawdata{:, [1 (roi_n+1)]}; % calcium data
		    			if cnmf == 1
		    				peak_table_array{ptc, 2}.calData_raw = Input{rn,2}.raw{:, [1 (roi_n+1)]}; % if cnmf data exists, save both cnmf and raw data
		    			end
		    			peak_table_array{ptc, 2}.peakinfo= peak_info{roi_n}(peakinfo_rows, {'Peak_loc', 'Rise_start', 'Decay_stop', 'Peak_loc_s_', 'Rise_start_s_', 'Decay_stop_s_'});
		    			peak_table_array{ptc, 3} = roi_n;
		    			peak_table_array{ptc, 4} = gn;
		    			peak_table_array{ptc, 5} = rec(rn).peak_gpio_align{roi_n, gn};
		    			peak_table_array{ptc, 6} = peak_num;
		    			peak_table_array{ptc, 7} = length(peak_data(find(peak_data>=0-duration_pre_peak & peak_data<=0))); % number of pre_peaks
		    			peak_table_array{ptc, 8} = length(peak_data(find(peak_data>=0 & peak_data<=gpio_duration))); % number of peaks during stimulation
		    			peak_table_array{ptc, 9} = length(peak_data(find(peak_data>=gpio_duration & peak_data<=gpio_duration+duration_post_peak))); % number of post_peaks
		    			peak_table_array{ptc, 10}= peak_table_array{ptc, 7}/peak_table_array{ptc, 6};
		    			peak_table_array{ptc, 11}= peak_table_array{ptc, 8}/peak_table_array{ptc, 6}; 
		    			peak_table_array{ptc, 12}= peak_table_array{ptc, 9}/peak_table_array{ptc, 6}; 
		    			peak_table_array{ptc, 13}= peak_table_array{ptc, 8}/peak_table_array{ptc, 7}; 
		    			peak_table_array{ptc, 14}= peak_data(find(peak_data>=0 & peak_data<=gpio_duration, 1)); % time stamp of the first peak in stimulation duration
		    			peak_table_array{ptc, 15}= peak_data(find(peak_data>=gpio_duration & peak_data<=gpio_duration+duration_post_peak, 1)); % time stamp of the first peak in stimulation duration

		    			peak_table_array{ptc, 16}= peak_num/plot_duration; % frequency of peaks in the plotted time range
		    			peak_table_array{ptc, 17}= peak_table_array{ptc, 7}/duration_pre_peak; % frequency of pre-peak
		    			peak_table_array{ptc, 18}= peak_table_array{ptc, 8}/gpio_duration; % frequency of peaks during stimulation
		    			peak_table_array{ptc, 19}= peak_table_array{ptc, 9}/duration_post_peak; % frequency of post-peak
		    			peak_table_array{ptc, 20}= (peak_num-peak_table_array{ptc, 8}-peak_table_array{ptc, 9})/(plot_duration-gpio_duration-duration_post_peak); % frequency of peaks w/o stim (exclude stim-peak and post-peak)


		    			ptc = ptc+1;
		    			% peak_table_col_str = {'recording', 'neuron', 'stimu_num', 'peak_s_aligned',...
		    			%  'peak_total', 'pre_peak', 'peak_during_stim', 'post_peak',...
		    			%  'pre_peak/peak_total', 'peak_during_stim/peak_total', 'post_peak/peak_total'}
		    		end
		    	end
	    	end
	    end
	    peak_table = array2table(peak_table_array, 'VariableNames', peak_table_col_str);
	end

    % raster plot of peaks
    plot_row = 1; % figure row number of raster plot. each row has 1 stimulation train. start from plot_start_time, end at plot_end_time 
    recording_num = size(rec, 2); % size of structure 'rec'. This is the same as size(ROIdata, 1) in the beginning
    figure;
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ])
    raster_ax = gca;
    hold on


   	peak_table_array = table2array(peak_table); 
   	peak_table_array(cellfun(@isempty, peak_table_array(:, 14)), 14) = {nan};
   	peak_table_array(cellfun(@isempty, peak_table_array(:, 15)), 15) = {nan};
   	peak_table_array_sorted = sortrows(peak_table_array, sort_col, sort_direction);

   	stim_num = size(peak_table_array_sorted, 1); % total number of stimulations = rows of raster_plot
   	trace_fig_num = ceil(stim_num/25); % number of figures for calcium traces
   	for tfn = 1:trace_fig_num
   		calTrace(tfn) = figure;
   		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
   	end

   	raster_row_x = [rec(rn).XLim(1) rec(rn).XLim(2) rec(rn).XLim(2) rec(rn).XLim(1)]; % used to plot the row patch in raster plot
   	for sn = 1:stim_num % stimulation number
	   	plot_x = peak_table_array_sorted{sn, 5};
	   	plot_xx(1:3:(length(plot_x)*3-2)) = plot_x;
	   	plot_xx(2:3:(length(plot_x)*3-1)) = plot_x;
	   	plot_xx(3:3:(length(plot_x)*3)) = NaN;
	   	plot_y_low = plot_row-(1-row_interval)/2; % low lim of each line
	   	plot_y_high = plot_row+(1-row_interval)/2; % high lim of each line
	   	plot_yy(1:3:(length(plot_x)*3-2)) = plot_y_low;
	   	plot_yy(2:3:(length(plot_x)*3-1)) = plot_y_high;
	   	plot_yy(3:3:(length(plot_x)*3)) = NaN;
	   	if length(plot_x)~=0
	   		% line([plot_x plot_x], [plot_y_low plot_y_high], 'Color', 'k', 'LineWidth', 3);
	   		line(raster_ax, plot_xx, plot_yy, 'Color', 'k', 'LineWidth', 3);
	   		raster_row_y = [plot_y_low plot_y_low plot_y_high plot_y_high]; % used to plot the row patch in raster plot
	   		patch(raster_ax, raster_row_x, raster_row_y, 'k', 'EdgeColor', 'none', 'FaceAlpha', 0.05);
	   	end

	   	tfn_current = ceil((sn-25)/25)+1; % current figure number for cal trace (5x5 subplot)
	   	rec_name = peak_table_array_sorted{sn, 1}; % recording name
	   	rec_name_title = rec_name; % rec_name_title used in subplot title. replace '_' with '-'.
	   	rec_name_title(strfind(rec_name_title, '_')) = '-'; % replace '_' with '-'.
	   	neuron_id = peak_table_array_sorted{sn, 3}; % neuron ID
	   	stim_id = peak_table_array_sorted{sn, 4}; % xth stimulation 
	   	sub_title = {[num2str(sn), ': '], [rec_name_title], ['neuron', num2str(neuron_id), '-',num2str(stim_id)]};
	   	calData = peak_table_array_sorted{sn, 2}.calData;

	   	rec_loc_gpio = find(strcmp(rec_name, {rec.name})); % gpio info in rec(rec_loc_gpio).gpio
	   	trace_gpio = rec(rec_loc_gpio).gpio;
	   	trace_gpio_x = [trace_gpio.time(stim_id, 1) trace_gpio.time(stim_id, 2) trace_gpio.time(stim_id, 2) trace_gpio.time(stim_id, 1)]; % for patch

	   	% sp_ax = get(calTrace(tfn_current), 'CurrentAxes'); 
	   	set(0, 'CurrentFigure', calTrace(tfn_current))
	   	subplot(5, 5, (sn-(tfn_current-1)*25))
	   	plot(calData(:, 1), calData(:, 2), 'k', 'LineWidth', 1.5)
	   	hold on
	   	if isfield(peak_table_array_sorted{sn, 2}, 'calData_raw')
	   		calData_raw = peak_table_array_sorted{sn, 2}.calData_raw;
	   		plot(calData_raw(:, 1), calData_raw(:, 2), 'b', 'LineWidth', 0.01)
	   	end
	   	y_trace_gpio = ylim;
	   	trace_gpio_y = [y_trace_gpio(1) y_trace_gpio(1) y_trace_gpio(2) y_trace_gpio(2)];
	   	patch(trace_gpio_x, trace_gpio_y, 'm', 'EdgeColor', 'none', 'FaceAlpha', 0.2);
	   	ax = gca;
	   	ax.FontSize = 6;
        xlim_trace = xlim(ax);
        xticks(0:10:xlim_trace(2));
	   	title(sub_title, 'FontSize', 9);

	   	plot_row = plot_row+1;
   	end




    raster_ax.XLim = rec(1).XLim;
    raster_ax.YLim = [0 plot_row];

    gpio_x = [0 rec(1).gpio.duration rec(1).gpio.duration 0];
    gpio_y = [0 0 plot_row plot_row];
    patch(raster_ax, gpio_x, gpio_y, 'm', 'EdgeColor', 'none', 'FaceAlpha', 0.2);
    duration_pre_peak_x = [-duration_pre_peak 0 0 -duration_pre_peak];
    duration_post_peak_x = [rec(1).gpio.duration (rec(1).gpio.duration+duration_post_peak) (rec(1).gpio.duration+duration_post_peak) rec(1).gpio.duration];
    duration_pre_post_peak_y = [0 0 plot_row plot_row];
    patch(raster_ax, duration_pre_peak_x, duration_pre_post_peak_y, 'c', 'EdgeColor', 'none', 'FaceAlpha', 0.2);
    patch(raster_ax, duration_post_peak_x, duration_pre_post_peak_y, 'c', 'EdgeColor', 'none', 'FaceAlpha', 0.2);
    set(raster_ax,'children',flipud(get(raster_ax,'children')))

    yticks(raster_ax, [0:10:plot_row]);
    set(raster_ax, 'TickDir','out');
    xlabel(raster_ax,'Time(s)');
    ylabel(raster_ax,'Trials');
    title(raster_ax, [num2str(rec(1).gpio.duration), 's stimulation. ', 'Sort: ', peak_table_col_str{sort_col}, ' ', sort_direction]);

    if save_raster_plot
    	figfile_stem = [num2str(rec(1).gpio.duration), 's_stimulation', '_sort_', peak_table_col_str{sort_col}, '_', sort_direction];
    	figfile_png = [figfile_stem, '.png'];
    	figfile_fig = [figfile_stem, '.fig'];
    	fig_png_fullpath = fullfile(figfolder_default, figfile_png);
    	[figfile_png, figfolder_png] = uiputfile(fig_png_fullpath, 'Save raster plot');
		fig_png_fullpath = fullfile(figfolder_png, figfile_png);
		fig_fig_fullpath = fullfile(figfolder_png, figfile_fig);

    	saveas(raster_ax, fig_png_fullpath);
    	saveas(raster_ax, fig_fig_fullpath);

    	trace_folder = [figfolder_png, figfile_png(1:(end-4)), '_traces'];
    	mkdir(trace_folder);
    	for tfn = 1:length(calTrace)
    		tracefile_stem = [figfile_png(1:(end-4)), '-', 'calTrace-', num2str(tfn)];
    		tracefile_png = [tracefile_stem, '.png'];
    		trace_png_fullpath = fullfile(trace_folder, tracefile_png);
    		saveas(calTrace(tfn), trace_png_fullpath);
    	end
    end
end

