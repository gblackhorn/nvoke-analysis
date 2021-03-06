function [ROIdata_peakevent] = nvoke_event_detection(ROIdata,plot_traces, pause_step)
%nvoke_event_detection 
% smooth data and find out peaks
% need structure array generated by "ROIinfo2matlab.m"
% Input:
% 		- plot_traces: 1-plot, 2-plot and save
% 		- pause_step: 1-pause after ploting every figure, 0-no pause
%   Detailed explanation goes here
%
% nvoke_event_detection(ROIdata,1, 1)

figfolder_default = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data\peaks';
lowpass_fpass = 0.1;

if nargin < 2
	plot_traces = 0;
	pause_step = 0;
elseif nargin == 2
	if plot_traces == 1 || 2
		pause_step = 1;
	else
		pause_step = 0;
	end
end


recording_num = size(ROIdata, 1);
if plot_traces == 2
	figfolder = uigetdir(figfolder_default,...
		'Select a folder to save figures');
end
for rn = 1:recording_num
	if isstruct(ROIdata{rn,2})
		single_recording = ROIdata{rn,2}.decon;
		lowpass_for_peak = false; % use lowpassed data for peak detaction off
		peak_table_row = 1; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 1st row (peak row)
	else
		single_recording = ROIdata{rn,2};
		lowpass_for_peak = true; % use lowpassed data for peak detaction on
		peak_table_row = 3; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 3rd row (peak row)
	end
	
	[single_recording, recording_time, roi_num] = ROI_calc_plot(single_recording);

	% roi_num = size(single_recording, 2)-1;
	time_info = table2array(single_recording(:, 1));
	recording_fr = 1/(time_info(2)-time_info(1));
	peak_loc_mag = cell([3 roi_num]); % first row for non-smoothed data, second row for smoothed data, 3rd row for lowpassed data
	peak_rise_fall = cell([2 roi_num]); % store rise and fall locs of peaks. 1st row for turning, 2nd row for slope changing
	% single_recording_smooth = single_recording;
	single_recording_smooth = zeros(size(single_recording{:, :}));
	single_recording_highpassed = zeros(size(single_recording{:, :}));
    single_recording_min_height = zeros(size(single_recording{:, :}));
	single_recording_lowpassed = zeros(size(single_recording{:, :}));

	single_recording_smooth(:, 1) = time_info; 
	single_recording_highpassed(:, 1) = time_info;
	single_recording_min_height(:, 1) = time_info;
	single_recording_lowpassed(:, 1) = time_info;
	% single_recording_smooth = zeros(size(single_recording));
	peak_loc_mag_table_variable = cell(1, roi_num); % column name for output, peak_loc_mag_table
	peak_info_variable = {'Peak_loc', 'Peak_mag', 'Rise_start', 'Decay_stop',...
	 'Peak_loc_s_', 'Rise_start_s_', 'Decay_stop_s_', 'Rise_duration_s_', 'decay_duration_s_', 'Peak_mag_relative'};
	for n = 1:roi_num
		roi_readout = table2array(single_recording(:, (n+1)));
		roi_readout_smooth = smooth(time_info, roi_readout, 0.1, 'loess');
		roi_highpassed = highpass(roi_readout, 2, recording_fr); % passband 2Hz, sampling frequency 10Hz
		roi_lowpassed = lowpass(roi_readout, lowpass_fpass, recording_fr); % passband 0.5Hz, sampling frequency 10Hz
		single_recording_smooth(:, n+1) = roi_readout_smooth;
		single_recording_highpassed(:, n+1) = roi_highpassed;
		single_recording_lowpassed(:, n+1) = roi_lowpassed;

		% % peakfinder criteria
		% sel = (max(roi_readout)-min(roi_readout))/4; % default value: max(roi_readout)-min(roi_readout)/4
		% sel_smooth = (max(roi_readout_smooth)-min(roi_readout_smooth))/4;
		% sel_lowpassed = (max(roi_lowpassed)-min(roi_lowpassed))/4;
		% thresh = mean(roi_highpassed)+5*std(roi_highpassed);
		% single_recording_thresh(:, n+1) = ones(size(time_info))*thresh;

		% % use pickfinder to find peaks
		% [peakloc, peakmag] = peakfinder(roi_readout, sel, thresh);
		% [peakloc_smooth, peakmag_smooth] = peakfinder(roi_readout_smooth, sel_smooth);
		% [peakloc_lowpassed, peakmag_lowpassed] = peakfinder(roi_lowpassed, sel_lowpassed);


		% use findpeaks instead of pickfinder function
		% findpeaks criteria
		prominences = (max(roi_readout)-min(roi_readout))/4; % default value: max(roi_readout)-min(roi_readout)/4
		prominences_smooth = (max(roi_readout_smooth)-min(roi_readout_smooth))/4;
		prominences_lowpassed = (max(roi_lowpassed)-min(roi_lowpassed))/4;
		min_height = mean(roi_highpassed)+5*std(roi_highpassed);
		single_recording_min_height(:, n+1) = ones(size(time_info))*min_height;

		% find peaks
		% [peakmag, peakloc] = findpeaks(roi_readout, 'MinPeakProminence', prominences, 'MinPeakHeight', min_height);
		[peakmag, peakloc] = findpeaks(roi_readout);
		[peakmag_smooth, peakloc_smooth] = findpeaks(roi_readout_smooth, 'MinPeakProminence', prominences_smooth);
		[peakmag_lowpassed, peakloc_lowpassed] = findpeaks(roi_lowpassed, 'MinPeakProminence', prominences_lowpassed);


		if lowpass_for_peak % use lowpassed data for peak detection
			roi_readout_select = roi_lowpassed;
			peakmag_select = peakmag_lowpassed;
			peakloc_select = peakloc_lowpassed;
		else % use CNMF-e processed data for peak detection
			roi_readout_select = roi_readout;
			peakmag_select = peakmag;
			peakloc_select = peakloc;
		end

		turning_loc = zeros(size(peakloc_select, 1), 3);
		speed_chang_loc = zeros(size(peakloc_select, 1), 2);
		for pn = 1:length(peakloc_select) % counting number of peaks in lowpassed data
			if pn ==1 % first peak
				check_start = 1;
				if length(peakloc_select) == 1 % there is only 1 peak
					check_end = length(time_info);
				else
					check_end = peakloc_select(pn+1); % next peak loc
				end
			elseif pn > 1 && pn < length(peakloc_select) % peaks in the middle
				check_start = peakloc_select(pn-1); % previous peak loc
				check_end = peakloc_select(pn+1); % next peak loc
			elseif pn == length(peakloc_select)
				check_start = peakloc_select(pn-1); % previous peak loc
				check_end = length(time_info);
			end		

			turning_loc_rising = check_start+find(diff(roi_readout_select(check_start:peakloc_select(pn)))<=0, 1, 'last');
			decay_diff_value = diff(roi_readout_select(peakloc_select(pn):check_end)); % diff value from peak to check_end
			diff_turning_value = min(decay_diff_value); % when the diff of decay is smallest. Decay stop loc will be looked for from here
			diff_turning_loc = peakloc_select(pn)+find(decay_diff_value==diff_turning_value, 1, 'first');
			decay_diff_value_after_turning = diff(roi_readout_select(diff_turning_loc:check_end)); % from decay diff_turning_loc to check_end;
			if find(decay_diff_value_after_turning<=0) % if decay continue after the decay_diff_value_after_turning
				decay_stop_diff_value = max(decay_diff_value_after_turning(decay_diff_value_after_turning<=0)); % discard 
				turning_loc_decay = diff_turning_loc+find(diff(roi_readout_select(diff_turning_loc:check_end))==decay_stop_diff_value, 1, 'first');
			else % most likely another activity jump in before complete recorvery
				turning_loc_decay = diff_turning_loc;
			end


			% if isempty(find(diff(roi_readout_select(diff_turning_loc:check_end)))>=0) % if the decay doesn't stop (especially for the last peak), find the smallest value for decay stop
			% 	decay_stop_diff_value = max(diff(roi_readout_select(diff_turning_loc:check_end))); % the max value of decay diff which is closest to 0
			% else
			% 	decay_stop_diff_value = max(diff(roi_readout_select(peakloc_select(pn):check_end))<=0);
			% end
			% turning_loc_decay = peakloc_select(pn)+find(diff(roi_readout_select(peakloc_select(pn):check_end))==decay_stop_diff_value, 1, 'first');

			% turning_loc_decay = peakloc_select(pn)+find(diff(roi_readout_select(peakloc_select(pn):check_end))>=0, 1, 'first')-1; % temperal solution. -1 in case CNMFe processed data too smooth
			if isempty(turning_loc_rising)
				turning_loc_rising = peakloc_select(pn); % when no results, assign peak location to it
			end
			if isempty(turning_loc_decay)
				turning_loc_decay = peakloc_select(pn); % when no results, assign peak location to it
			end
			turning_loc(pn, 1) = turning_loc_rising;
			turning_loc(pn, 2) = turning_loc_decay;
			turning_loc(pn, 3) = max((peakmag_select(pn)-roi_readout_select(turning_loc_rising)), (peakmag_select(pn)-roi_readout_select(turning_loc_decay)));

			% tolerance = 1e-4;
			% accelerate_loc = check_start+find(abs(diff(roi_lowpassed(check_start:peakloc_lowpassed(pn))))<tolerance, 1, 'last');
			% decelerate_loc = peakloc_lowpassed(pn)+find(abs(diff(roi_lowpassed(peakloc_lowpassed(pn):check_end)))<tolerance, 1, 'first');
			% if isempty(accelerate_loc)
			% 	accelerate_loc = peakloc_lowpassed(pn); % when no results, assign peak location to it
			% end
			% if isempty(decelerate_loc)
			% 	decelerate_loc = peakloc_lowpassed(pn); % when no results, assign peak location to it
			% end
			% speed_chang_loc(pn, 1) = accelerate_loc;
			% speed_chang_loc(pn, 2) = decelerate_loc;
		end

		peak_loc_mag{1, n}(:, 1) = peakloc;
		peak_loc_mag{1, n}(:, 2) = peakmag;
		peak_loc_mag{2, n}(:, 1) = peakloc_smooth;
		peak_loc_mag{2, n}(:, 2) = peakmag_smooth;
		peak_loc_mag{3, n}(:, 1) = peakloc_lowpassed;
		peak_loc_mag{3, n}(:, 2) = peakmag_lowpassed;
		peak_loc_mag{peak_table_row, n}(:, 3:4) = turning_loc(:, 1:2);

		peak_loc_mag{1, n}(:, 5) = time_info(peakloc);
		peak_loc_mag{2, n}(:, 5) = time_info(peakloc_smooth);
		peak_loc_mag{3, n}(:, 5) = time_info(peakloc_lowpassed);
		peak_loc_mag{peak_table_row, n}(:, 6) = time_info(turning_loc(:, 1)); % rise time
		peak_loc_mag{peak_table_row, n}(:, 7) = time_info(turning_loc(:, 2)); % decay time
		peak_loc_mag{peak_table_row, n}(:, 8) = time_info(peakloc_select)-time_info(turning_loc(:, 1)); % duration of rise time
		peak_loc_mag{peak_table_row, n}(:, 9) = time_info(turning_loc(:, 2))-time_info(peakloc_select); % duration of rise time
		peak_loc_mag{peak_table_row, n}(:, 10)= turning_loc(pn, 3); % peak value relative to rise/decay point (use the bigger one)
		% peak_rise_fall{1, n}(:, 1:2) = turning_loc;
		% peak_rise_fall{2, n}(:, 1:2) = speed_chang_loc;
		peak_loc_mag_table_variable{1, n} = single_recording.Properties.VariableNames{n+1};
		for pt1 = 1:3
			if pt1 == peak_table_row
				peak_table{pt1,n} = array2table(peak_loc_mag{pt1, n}, 'VariableNames', peak_info_variable);
			else
				peak_table{pt1,n} = array2table(peak_loc_mag{pt1, n}, 'VariableNames', peak_info_variable(1:5));
			end
		end
	end

	peak_loc_mag_table_row = {'peak'; 'peak_smooth'; 'Peak_lowpassed'};
	peak_loc_mag_table = array2table(peak_table, 'VariableNames', peak_loc_mag_table_variable, 'RowNames', peak_loc_mag_table_row);

	if nargin >= 2
		if plot_traces == 1 || 2 % 1: only plot. 2: plot and save
			if isempty(ROIdata{rn, 3}) 
				GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
			else
				GPIO_trace = 1; % show GPIO trace representing stimulation
				stimulation = ROIdata{rn, 3}{1, 1};
				channel = ROIdata{rn, 4}; % GPIO channels
			end

			% ROI_residual = roi_num-floor(roi_num/5)*5; % number of ROIs in the last column of plot (5x4 of ROI)
	  %           if ROI_residual ~= 0
	  %               filler_array = zeros(size(single_recording,1), (5-ROI_residual));
	  %               single_recording = [single_recording array2table(filler_array)];
	  %           end

			% traces are subplotted in 5x2 size 
			plot_col_num = ceil(roi_num/5);
			plot_fig_num = ceil(plot_col_num/2);
			close all
			for p = 1:plot_fig_num % figure num
				peak_plot_handle(p) = figure (p);
				set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]
				for q = 1:2 % column num
					if (plot_col_num-(p-1)*2-q) >= 0

						% roi_trace_first = (p-1)*10+(q-1)*5+1+1; % fist +1 to get the real count of ROI, second +1 to get ROI column in table
						% roi_trace_last = (p-1)*10+q*5+1;
						% subplot(5, 2, q:2:(q+2*4))
						% stackedplot(single_recording)

						% last row number of last column
						if plot_col_num > (p-1)*2+q
							last_row = 5;
						else
							last_row = roi_num-(p-1)*10-(q-1)*5;
						end
						for m = 1:last_row
							roi_plot = (p-1)*10+(q-1)*5+m; % the number of roi to be plot
							roi_col_loc = roi_plot+1; % the column number of this roi in single_recording (ROI_table)
							roi_col_data = table2array(single_recording(:, roi_col_loc)); % roi data 
							peak_time_loc = peak_loc_mag{1, roi_plot}(:, 5); % peak_loc in time
							peak_value = peak_loc_mag{1, roi_plot}(:, 2); % peak magnitude


							roi_col_data_smooth = single_recording_smooth(:, roi_col_loc);
							peak_time_loc_smooth = peak_loc_mag{2, roi_plot}(:, 5);
							peak_value_smooth = peak_loc_mag{2, roi_plot}(:, 2);


							roi_col_data_lowpassed = single_recording_lowpassed(:, roi_col_loc);
							peak_time_loc_lowpassed = peak_loc_mag{3, roi_plot}(:, 5);
							peak_value_lowpassed = peak_loc_mag{3, roi_plot}(:, 2);

							if lowpass_for_peak
								roi_col_data_select = roi_col_data_lowpassed;
								peak_time_loc_select = peak_time_loc_lowpassed;
								peak_value_select = peak_value_lowpassed;
							else
								roi_col_data_select = roi_col_data;
								peak_time_loc_select = peak_time_loc;
								peak_value_select = peak_value;
							end

							peak_rise_turning_loc = peak_loc_mag{peak_table_row, roi_plot}(:, 6);
							peak_rise_turning_value = roi_col_data_select(peak_loc_mag{peak_table_row, roi_plot}(:, 3));
							peak_decay_turning_loc = peak_loc_mag{peak_table_row, roi_plot}(:, 7);
							peak_decay_turning_value = roi_col_data_select(peak_loc_mag{peak_table_row, roi_plot}(:, 4));


							% peak_rise_speedup_loc = time_info(peak_rise_fall{2, roi_plot}(:, 1));
							% peak_rise_speedup_value = roi_col_data_lowpassed(peak_rise_fall{2, roi_plot}(:, 1));
							% peak_rise_slowdown_loc = time_info(peak_rise_fall{2, roi_plot}(:, 2));
							% peak_rise_slowdown_value = roi_col_data_lowpassed(peak_rise_fall{2, roi_plot}(:, 2));



							roi_col_data_highpassed = single_recording_highpassed(:, roi_col_loc);
							thresh_data = single_recording_min_height(:, roi_col_loc);

							sub_handle(roi_plot) = subplot(6, 2, q+(m-1)*2);
							plot(time_info, roi_col_data, 'k') % plot original data
							hold on
							if lowpass_for_peak
								plot(time_info, roi_col_data_lowpassed, 'm'); % plot lowpass filtered data
							end

							% plot detected peaks and their starting and ending points
							plot(peak_time_loc_select, peak_value_select, 'yo', 'linewidth', 2) %plot lowpassed data peak marks
							plot(peak_rise_turning_loc, peak_rise_turning_value, '>b', peak_decay_turning_loc, peak_decay_turning_value, '<b', 'linewidth', 2) % plot start and end of transient, turning point

							set(get(sub_handle(roi_plot), 'YLabel'), 'String', ['C', num2str(roi_plot-1)]);
							ylim_roi_max = max(roi_col_data)*1.1; % max value of ROI trace y axis
							ylim_roi_min = min(roi_col_data) - abs(min(roi_col_data)*0.1);
							axis([0 recording_time ylim_roi_min ylim_roi_max]); 
							hold off

						end
					end
					if GPIO_trace == 1
						subplot(6, 2, 10+q);
						for nc = 1:length(channel)-2
							gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
							x = channel(nc+2).time_value(:, 1);
							y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
							stairs(x, y{nc});
							hold on
						end
						axis([0 recording_time 0 max(y{1})+1])
						hold off
						legend(stimulation, 'Location', "SouthOutside");
					end
				end
				sgtitle(ROIdata{rn, 1}, 'Interpreter', 'none');
				if plot_traces == 2 && ~isempty(figfolder)
					figfile = [ROIdata{rn,1}(1:(end-4)), '-', num2str(p), '.fig'];
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
	ROIdata{rn,5} = peak_loc_mag_table;

	clearvars peak_table 
	clearvars peak_loc_mag_table

end
ROIdata_peakevent = ROIdata;
end


