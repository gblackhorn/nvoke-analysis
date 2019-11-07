function [modified_ROIdata] = nvoke_correct_peakdata(ROIdata,plot_traces,pause_step)
% After manually discarding ROIs and correcting peak rise and fall point.
% Correct the rise_loc, decay_loc, etc.
% Input:
% 		- plot_traces: 1-plot, 2-plot and save, 3-plot original traces and stimuli triggered response, 4-plot 3 and save
% 		- pause_step: 1-pause after ploting every figure, 0-no pause
% 
% 
% 
%   Detailed explanation goes here
%
%[modified_ROIdata] = nvoke_correct_peakdata(ROIdata,plot_traces,pause_step)

if nargin < 2
	plot_traces = 0;
	pause_step = 0;
elseif nargin >= 2
	% if plot_traces ~= 0
	% 	pause_step = 1;
	% else
	% 	pause_step = 0;
	% end
	if plot_traces == 3 || 4
		stimuli_triggered_response = 1;
	else
		stimuli_triggered_response = 0;
	end
elseif nargin > 3
	error('Too many input. Maximum 3. Read document of function "nvoke_correct_peakdata"')
end

lowpass_fpass = 0.1;
highpass_fpass = 0.1;
peakinfo_row_name = 'Peak_lowpassed';

if plot_traces == 2
	figfolder = uigetdir('G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data\peaks',...
		'Select a folder to save figures');
end

recording_num = size(ROIdata, 1);
for rn = 1:recording_num
	recording_name = ROIdata{rn, 1};

	% % next line is used for debug. show file name
	% rn
	% display(recording_name)

	peakinfo_row = find(strcmp(peakinfo_row_name, ROIdata{rn, 5}.Properties.RowNames));
	recording_rawdata = ROIdata{rn,2};
	[recording_rawdata, recording_time, roi_num_all] = ROI_calc_plot(recording_rawdata);
	recording_timeinfo = recording_rawdata{:, 1}; % array not table
	recording_fr = 1/(recording_timeinfo(2)-recording_timeinfo(1));
    recording_code = rn;
	roi_num = size(ROIdata{rn, 5}, 2); % total roi numbers after handpick

	recording_highpassed = ROIdata{rn,2};
    recording_thresh = ROIdata{rn,2};
	recording_lowpassed = ROIdata{rn,2};

	for roi_n = 1:roi_num
		roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_n};
		roi_rawdata_loc = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames));

		roi_rawdata = recording_rawdata{:, roi_rawdata_loc};
		roi_lowpasseddata = lowpass(roi_rawdata, lowpass_fpass, recording_fr);
		roi_highpassed = highpass(roi_rawdata, highpass_fpass, recording_fr);

		recording_highpassed{:, roi_rawdata_loc} = roi_highpassed;
		recording_lowpassed{:, roi_rawdata_loc} = roi_lowpasseddata;

		thresh = mean(roi_highpassed)+5*std(roi_highpassed);
		recording_thresh{:, roi_rawdata_loc} = ones(size(recording_timeinfo))*thresh;;

		peak_loc_time = ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_loc_s_'); % peaks' time
		rise_start_time = ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Rise_start_s_');
		decay_stop_time = ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Decay_stop_s_');

		peak_num = length(peak_loc_time);
		for pn = 1:peak_num
			[min_peak closestIndex_peak] = min(abs(recording_timeinfo-peak_loc_time(pn)));
			[min_rise closestIndex_rise] = min(abs(recording_timeinfo-rise_start_time(pn)));
			[min_decay closestIndex_decay] = min(abs(recording_timeinfo-decay_stop_time(pn)));

			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_loc')(pn) = closestIndex_peak;
			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Rise_start')(pn) = closestIndex_rise;
			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Decay_stop')(pn) = closestIndex_decay;

			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_mag')(pn) = roi_lowpasseddata(closestIndex_peak);
			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Rise_duration_s_')(pn) = peak_loc_time(pn)-rise_start_time(pn);
			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('decay_duration_s_')(pn) = decay_stop_time(pn)-peak_loc_time(pn);

			peakmag_relative_rise = roi_lowpasseddata(closestIndex_peak)-roi_lowpasseddata(closestIndex_rise);
			peakmag_relative_decay = roi_lowpasseddata(closestIndex_peak)-roi_lowpasseddata(closestIndex_decay);
			ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_mag_relative')(pn) = max(peakmag_relative_rise, peakmag_relative_decay);
		end
	end

	if nargin >= 2
		% if plot_traces == 1 || 2
		% 	% plot_col_num = ceil(roi_num/5);
		% 	% plot_fig_num = ceil(plot_col_num/2);
		% 	% subplot_multi_factor = 1;
		% 	% close all
		% elseif plot_traces == 3 || 4
			plot_col_num = ceil(roi_num/5)*3; % one column of triggered response plot for each 2-column wide original traces
			plot_fig_num = ceil(plot_col_num/6); % 3 columns for 1 group of data (*5 ROIs)
			subplot_multi_factor = 3;
			close all
		% end

		if isempty(ROIdata{rn, 3}) 
			GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
		else
			GPIO_trace = 1; % show GPIO trace representing stimulation
			stimulation = ROIdata{rn, 3}{1, 1};
			channel = ROIdata{rn, 4}; % GPIO channels
			gpio_signal = cell(1, (length(channel)-2)); % pre-allocate number of stimulation to gpio_signal used to store signal time and value
			gpio_x = cell(1, (length(channel)-2)); % pre-allocate gpio_x
			gpio_y = cell(1, (length(channel)-2)); % pre-allocate gpio_y
			for nc = 1:(length(channel)-2) % number of GPIOs used for stimulation
				gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
				gpio_signal{nc}(:, 1) = channel(nc+2).time_value(:, 1); % time value of GPIO signal
				gpio_signal{nc}(:, 2) = channel(nc+2).time_value(:, 2); % voltage value of GPIO signal
				gpio_rise_loc = find(gpio_signal{nc}(:, 2)); % locations of GPIO voltage not 0, ie stimuli start
				gpio_rise_num = length(gpio_rise_loc); % number of GPIO voltage rise

				% Looking for stimulation groups. Many stimuli are train signal. Ditinguish trains by finding rise time interval >=5s
				% Next line calculate time interval between to gpio_rise. (Second:End stimuli_time)-(first:Second_last stimuli_time)
				gpio_rise_interval{nc} = gpio_signal{nc}(gpio_rise_loc(2:end), 1)-gpio_signal{nc}(gpio_rise_loc(1:(end-1)), 1);
				train_interval_loc{nc} = find(gpio_rise_interval{1, nc} >= 5); % If time interval >=5s, this is between end of a train and start of another train
				train_end_loc{nc} = [gpio_rise_loc(train_interval_loc{nc}); gpio_rise_loc(end)]; % time of the train_end rises start
				train_start_loc{nc} = [gpio_rise_loc(1); gpio_rise_loc(train_interval_loc{nc}+1)]; % time of the train_start rises start

				gpio_train_start_time{nc} = gpio_signal{nc}(train_start_loc{nc}, 1); % time point when GPIO trains start
				gpio_train_end_time{nc} = gpio_signal{nc}(train_end_loc{nc}+1, 1); % time point when GPIO trains end

				% gpio_x = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_x used to plot GPIO with "patch" function
				% gpio_y = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_y used to plot GPIO with "patch" function
				for ng = 1:gpio_rise_num % number of GPIO voltage rise, ie stimuli
					gpio_x{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
					gpio_x{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
					gpio_x{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);
					gpio_x{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);

					gpio_y{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
					gpio_y{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
					gpio_y{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
					gpio_y{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
				end
				gpio_lim_loc{nc, 1} = find(gpio_y{nc}(:, 1) == 0); % location of gpio voltage ==0 in gpio_y
				gpio_lim_loc{nc, 2} = find(gpio_y{nc}(:, 1)); % location of gpio voltage ~=0 in gpio_y
			end
		end
			
		for p = 1:plot_fig_num % figure number
			peak_plot_handle(p) = figure (p);
			set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]

			for q = 1:2 % column group num for ROI. When plot_traces=1||2, subplot column = q, when 3||4 subplot column == q*4
				if (plot_col_num/subplot_multi_factor-(p-1)*2-q) > 0
						last_row = 5;
				else
						last_row = roi_num-(p-1)*10-(q-1)*5;
				end
				for m = 1:last_row
					roi_plot = (p-1)*10+(q-1)*5+m; % the number of roi to be plot
					roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_plot}; % roi name ('C0, C1...')
					roi_col_loc_data = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames)); % the column number of this roi in recording_rawdata (ROI_table)
					roi_col_loc_cal = find(strcmp(roi_name, ROIdata{rn, 5}.Properties.VariableNames)); % the column number of this roi in recording_rawdata (ROI_table)

					roi_col_data = recording_rawdata{:, roi_col_loc_data}; % roi data 
					peak_time_loc = ROIdata{rn, 5}{1, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
					peak_value = ROIdata{rn, 5}{1, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

					roi_col_data_lowpassed = recording_lowpassed{:, roi_col_loc_data}; % roi data 
					peak_time_loc_lowpassed = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
					peak_value_lowpassed = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

					peak_rise_turning_loc = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Rise_start_s_');
					peak_rise_turning_value = roi_col_data_lowpassed(ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Rise_start'));
					peak_decay_turning_loc = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Decay_stop_s_');
					peak_decay_turning_value = roi_col_data_lowpassed(ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Decay_stop'));

					roi_col_data_highpassed = recording_highpassed{:, roi_col_loc_data}; % roi data 
					thresh_data = recording_thresh{:, roi_col_loc_data};

					% sub_handle(roi_plot) = subplot(6, 2, q+(m-1)*2);
					sub_handle(roi_plot) = subplot(6, 8, [(q*4-3)+(m-1)*8, (q*4-3)+(m-1)*8+1]);
					plot(recording_timeinfo, roi_col_data, 'k') % plot original data
					hold on
					% plot(peak_time_loc, peak_value, 'ro', 'linewidth', 2) % plot peak marks
					% plot(recording_timeinfo, roi_col_data_highpassed, 'b') % plot highpass filtered data
					% plot(recording_timeinfo, thresh_data, '--k'); % plot thresh hold line
					plot(recording_timeinfo, roi_col_data_lowpassed, 'm'); % plot lowpass filtered data
					% plot(peak_time_loc_lowpassed, peak_value_lowpassed, 'yo', 'linewidth', 2) %plot lowpassed data peak marks
					% plot(peak_rise_turning_loc, peak_rise_turning_value, '>b', peak_decay_turning_loc, peak_decay_turning_value, '<b', 'linewidth', 2) % plot start and end of transient, turning point
					ylim_gpio = ylim;

					if GPIO_trace == 1
						gpio_color = {'cyan', 'magenta', 'yellow'};
						for ncp = 1:(length(channel)-2) % number of channel plot
							% loc_nonzero = find(gpio_y(:, ncp));
							gpio_y{ncp}(gpio_lim_loc{ncp, 2} , 1) = ylim_gpio(2); % expand gpio_y upper lim to max of y-axis
							% loc_zero = find(gpio_y(:, ncp)==0); % loction of gpio value =0 in gpio_y
							gpio_y{ncp}(gpio_lim_loc{ncp, 1} , 1) = ylim_gpio(1); % expand gpio_y lower lim to min of y-axis
							patch(gpio_x{ncp}(:, 1), gpio_y{ncp}(:, 1), gpio_color{ncp}, 'EdgeColor', 'none', 'FaceAlpha', 0.7)
						end
					end
					axis([0 recording_timeinfo(end) ylim_gpio(1) ylim_gpio(2)])
					set(get(sub_handle(roi_plot), 'YLabel'), 'String', roi_name);
					hold off

					% Plot stimuli triggered response. No criteria yet
					if GPIO_trace == 1
						subplot(6, 8, (q*4+(m-1)*8-1)) % plot stimulation triggered responses. All sweeps
						pre_stimuli_duration = 3; % duration before stimulation onset
						post_stimuli_duration = 6; % duration after stimulation end
						baseline_duration = 1; % time duration before stimulation used to calculate baseline for y-axis aligment 
						pre_stimuli_time = gpio_train_start_time{1}-pre_stimuli_duration; % plot from 3s before stimuli start. The "first GPIO stimuli"
						post_stimuli_time = gpio_train_end_time{1}+post_stimuli_duration; % plot until 6s after stimuli end
						plot_duration = post_stimuli_time-pre_stimuli_time; % duration of plot

						first_gpio_train_start_loc = find(gpio_x{1}(:, 1)==gpio_train_start_time{1}(1), 1); % location of first train starts
						first_gpio_train_end_loc = find(gpio_x{1}(:, 1)==gpio_train_end_time{1}(1), 1, 'last'); % location of first train ends
						gpio_x_trig_plot = gpio_x{1}(first_gpio_train_start_loc:first_gpio_train_end_loc, 1); % gpio_x of the first train
						gpio_x_trig_plot = gpio_x_trig_plot-gpio_x_trig_plot(1, 1); % gpio_x starts from 0
						gpio_y_trig_plot = gpio_y{1}(first_gpio_train_start_loc:first_gpio_train_end_loc); % gpio_y of the first train
						patch(gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7)
						hold on
						for tn = 1:length(pre_stimuli_time) % number of stimulation trains
							[val_min, idx_min] = min(abs(recording_timeinfo-pre_stimuli_time(tn)));
							[val_max, idx_max] = min(abs(recording_timeinfo-post_stimuli_time(tn)));
							recording_timeinfo_trig_plot{tn} = recording_timeinfo(idx_min:idx_max)-gpio_train_start_time{1}(tn);

							idx_min_base = idx_min+recording_fr*(pre_stimuli_duration-baseline_duration); % loc of first data point of "baseline_duration" before stimulation
							[val_max_base, idx_max_base] = find((recording_timeinfo-gpio_train_start_time{1}(tn))<0, 1, 'last'); % loc of last data point of "baseline_duration" before stimulation
							roi_col_data_base = mean(roi_col_data(idx_min_base:idx_max_base)); % baseline before 'tn' stimulation

							roi_col_data_trig_plot{tn} = roi_col_data(idx_min:idx_max)-roi_col_data_base;
							% roi_col_data_lowpassed_trig_plot = roi_col_data_lowpassed(idx_min:idx_max);
							data_point_num(tn) = length(recording_timeinfo_trig_plot{tn}); % data points of each triggered plot

							plot(recording_timeinfo_trig_plot{tn}, roi_col_data_trig_plot{tn}, 'k'); % plot raw data sweeps
							% plot(recording_timeinfo_trig_plot, roi_col_data_lowpassed_trig_plot, 'm'); % plot lowpassed data
						end
						hold off
						data_point_num_unique = unique(data_point_num, 'sorted'); % unique data points length
						datapoint_for_average = cell(1, length(data_point_num_unique));
						average_datapoint = cell(1, length(data_point_num_unique));
						std_datapoint  = cell(1, length(data_point_num_unique));
						if length(data_point_num_unique) ~= 1
							for sn = 1:length(data_point_num_unique) % segment (according to number of datapoints) number of datapoints with different length
								if sn == 1
									segment_start = 1;
								else
									segment_start = data_point_num_unique(sn-1)+1;
								end
								segment_end = data_point_num_unique(sn); 
								available_sweeps = find(data_point_num >= segment_end);
								for swn = 1:length(available_sweeps) % swn: sweep number
									if swn == 1
										datapoint_for_average{sn} = roi_col_data_trig_plot{available_sweeps(swn)}(segment_start:segment_end);
									else
										datapoint_for_average{sn} = [datapoint_for_average{sn} roi_col_data_trig_plot{available_sweeps(swn)}(segment_start:segment_end)];
									end
								end
								average_datapoint{sn} = mean(datapoint_for_average{sn}, 2);
								% ste_datapoint{sn} = std(datapoint_for_average{sn}, 0, 2)/sqrt(size(datapoint_for_average{sn}, 2));
								std_datapoint{sn} = std(datapoint_for_average{sn}, 0, 2);
								if sn == 1
									average_data_trig_plot = average_datapoint{sn};
									std_data_trig_plot = std_datapoint{sn};
								else
									average_data_trig_plot = [average_data_trig_plot; average_datapoint{sn}];
									std_data_trig_plot = [std_data_trig_plot; std_datapoint{sn}];
								end
							end
						else
							datapoint_for_average = cat(2, roi_col_data_trig_plot{:});
							average_data_trig_plot = mean(datapoint_for_average, 2);
							std_data_trig_plot = std(datapoint_for_average, 0, 2)/sqrt(size(datapoint_for_average, 2));
						end
						std_plot_upper_line = average_data_trig_plot+std_data_trig_plot;
						std_plot_lower_line = average_data_trig_plot-std_data_trig_plot;
						std_plot_area_y = [std_plot_upper_line; flip(std_plot_lower_line)];
						% loc_longest_time_trig_plot = find(sort(data_point_num), 1, 'last');
						[longest_time_trig_plot,loc_longest_time_trig_plot] = max(data_point_num, [],'linear')
						average_data_trig_plot_x = recording_timeinfo_trig_plot{loc_longest_time_trig_plot};
						std_plot_area_x = [average_data_trig_plot_x; flip(average_data_trig_plot_x)];
						subplot(6, 8, (q*4+(m-1)*8)) % plot stimulation triggered responses. Averaged
						patch(gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7)
						hold on
						plot(average_data_trig_plot_x, average_data_trig_plot, 'k');
						patch(std_plot_area_x, std_plot_area_y, 'yellow', 'EdgeColor', 'none', 'FaceAlpha', 0.3) %'#EDB120'
					end

				end
				if GPIO_trace == 1
					subplot(6, 8, [40+(q-1)*4+1,40+(q-1)*4+2]);
					for nc = 1:length(channel)-2
						gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
						x = channel(nc+2).time_value(:, 1);
						y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
						stairs(x, y{nc});
						hold on
					end
					axis([0 recording_timeinfo(end) 0 max(y{1})+1])
					hold off
					legend(stimulation, 'Location', "SouthOutside");
				end
				% if GPIO_trace == 1
				% 	subplot(6, 2, 10+q);
				% 	for nc = 1:length(channel)-2
				% 		gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
				% 		x = channel(nc+2).time_value(:, 1);
				% 		y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
				% 		stairs(x, y{nc});
				% 		hold on
				% 	end
				% 	axis([0 recording_time 0 max(y{1})+1])
				% 	hold off
				% 	legend(stimulation, 'Location', "SouthOutside");
				% end
			end
			sgtitle(ROIdata{rn, 1}, 'Interpreter', 'none');
			if plot_traces == 2 && ~isempty(figfolder)
				figfile = [ROIdata{rn,1}(1:(end-4)), '-handpick-', num2str(p), '.fig'];
				figfullpath = fullfile(figfolder,figfile);
				savefig(gcf, figfullpath);
				jpgfile_name = [figfile(1:(end-3)), 'jpg'];
				jpgfile_fullpath = fullfile(figfolder, jpgfile_name);
				saveas(gcf, jpgfile_fullpath);
				svgfile_name = [figfile(1:(end-3)), 'svg'];
				svgfile_fullpath = fullfile(figfolder, svgfile_name);
				saveas(gcf, svgfile_fullpath);
			end	
			if pause_step == 1
				disp('Press any key to continue')
				pause;
			end
		end
		
	end
end
modified_ROIdata = ROIdata;

end

