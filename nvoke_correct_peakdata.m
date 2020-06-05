function [modified_ROIdata] = nvoke_correct_peakdata(ROIdata,plot_traces,subplot_roi,pause_step)
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


lowpass_fpass = 1;
highpass_fpass = 2;
peakinfo_row_name = 'Peak_lowpassed';

criteria_riseT = [0 1.5]; % unit: second. filter to keep peaks with rise time in the range of [min max]
criteria_slope = [5 50]; % calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
criteria_pnr = 8; % peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
use_criteria = true; % choose to use criteria or not for picking peaks

if nargin < 2
	plot_traces = 0;
	pause_step = 0;
elseif nargin == 2
	if plot_traces == 3 || 4
		stimuli_triggered_response = 1;
	elseif plot_traces == 1 || 2
		pause_step = 1;
		subplot_roi = 1; % mode-1: 5x2 rois in 1 figure
	else
		stimuli_triggered_response = 0;
		pause_step = 0;
		subplot_roi = 2; % mode-2: 2x1 rois in 1 figure
	end
elseif nargin >= 3
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
elseif nargin > 4
	error('Too many input. Maximum 3. Read document of function "nvoke_correct_peakdata"')
end

if plot_traces == 2
	if ispc
		figfolder = uigetdir('G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks',...
			'Select a folder to save figures');
	elseif isunix
		figfolder = uigetdir('/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/plots',...
			'Select a folder to save figures');
	end
end

recording_num = size(ROIdata, 1);
for rn = 1:record`g_num
	recording_name = ROIdata{rn, 1};

	if plot_traces == 2
		if subplot_roi == 1
			fig_subfolder = figfolder; % do not creat subfolders when subplots are 5x2
		elseif subplot_roi == 2
			if ispc
				fig_subfolder = [figfolder, '\', ROIdata{rn, 1}(1:25)]; % when the size of subplots is 2x1, use subfolders
			elseif isunix
				fig_subfolder = [figfolder, '/', ROIdata{rn, 1}(1:25)]; % when the size of subplots is 2x1, use subfolders
			end
			if ~exist(fig_subfolder)
				mkdir(fig_subfolder);
			end
		end
	end

	% % next line is used for debug. show file name
	% rn
	% display(recording_name)

	if isstruct(ROIdata{rn, 2})
		recording_data = ROIdata{rn,2}.decon;
		recording_rawdata = ROIdata{rn,2}.raw;
		cnmfe_process = true; % data was processed by CNMFe
		lowpass_for_peak = false; % use lowpassed data for peak detaction off
		% peakinfo_row = 1; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 1st row (peak row)
		% peakinfo_row_name = 'peak';
		peakinfo_row_name = 'Peak_lowpassed'; % peaks were found in CNMFe processed data at first. These results were then used in lowpassed data to find peaks more precisly
		peakinfo_row_name_plot = 'peak';
	else
		recording_data = ROIdata{rn,2};
		recording_rawdata = ROIdata{rn,2};
		cnmfe_process = false; % data was not processed by CNMFe
		lowpass_for_peak = true; % use lowpassed data for peak detaction on
		% peakinfo_row = 3; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 3rd row (peak row)
		peakinfo_row_name = 'Peak_lowpassed';
		peakinfo_row_name_plot = 'Peak_lowpassed';
	end


	if isempty(ROIdata{rn, 3}) 
		GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
	else
		GPIO_trace = 1; % show GPIO trace representing stimulation
		stimulation = ROIdata{rn, 3}{1, 1};
		channel = ROIdata{rn, 4}; % GPIO channels
		gpio_signal = cell(1, (length(channel)-2)); % pre-allocate number of stimulation to gpio_signal used to store signal time and value

		gpio_train_patch_x = cell(1, (length(channel)-2)); % pre-allocate gpio_x
		gpio_train_patch_y = cell(1, (length(channel)-2)); % pre-allocate gpio_y
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

			gpio_train_start_time{nc} = gpio_signal{nc}(train_start_loc{nc}, 1); % time points when GPIO trains start
			gpio_train_end_time{nc} = gpio_signal{nc}(train_end_loc{nc}+1, 1); % time points when GPIO trains end

			ROIdata{rn, 4}(3).stim_range(:, 1) = gpio_train_start_time{nc}; % save stimulation signal start time info
			ROIdata{rn, 4}(3).stim_range(:, 2) = gpio_train_end_time{nc}; % save stimulation signal end time info

			% for peak_n = 1:size(peak_loc_mag{peakinfo_row, roi_n}{:, :}, 1) % number of peaks in this roi
			% 	for stim_n = 1:length(gpio_train_start_time{nc}) % number of stimulation

			% 	end
			% end

			for ngt = 1:length(gpio_train_start_time{nc})
				gpio_train_patch_x{nc}(1+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 1);
				gpio_train_patch_x{nc}(2+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 1);
				gpio_train_patch_x{nc}(3+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 1);
				gpio_train_patch_x{nc}(4+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 1);

				gpio_train_patch_y{nc}(1+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt)+1, 2);
				gpio_train_patch_y{nc}(2+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 2);
				gpio_train_patch_y{nc}(3+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt), 2);
				gpio_train_patch_y{nc}(4+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 2);
			end
			gpio_train_lim_loc{nc, 1} = find(gpio_train_patch_y{nc}(:, 1) == 0); % location of gpio voltage ==0 in gpio_train_lim_loc
			gpio_train_lim_loc{nc, 2} = find(gpio_train_patch_y{nc}(:, 1)); % location of gpio voltage ~=0 in gpio_train_lim_loc

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


	peak_loc_mag = ROIdata{rn, 5};
	peakinfo_row = find(strcmp(peakinfo_row_name, peak_loc_mag.Properties.RowNames));
	peakinfo_row_plot = find(strcmp(peakinfo_row_name_plot, peak_loc_mag.Properties.RowNames));
	[recording_rawdata, recording_time, roi_num_all] = ROI_calc_plot(recording_rawdata);
	timeinfo = recording_rawdata{:, 1}; % array not table
	recording_fr = 1/(timeinfo(10)-timeinfo(9));
    recording_code = rn;
	roi_num = size(peak_loc_mag, 2); % total roi numbers after handpick

	recording_highpassed = recording_rawdata;
    recording_thresh = recording_rawdata;
	recording_lowpassed = recording_rawdata;

	for roi_n = 1:roi_num
		roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_n};
		roi_data_loc = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames));

		roi_data = recording_data{:, roi_data_loc};
		roi_rawdata = recording_rawdata{:, roi_data_loc};

		roi_lowpasseddata = lowpass(roi_rawdata, lowpass_fpass, recording_fr);
		roi_highpassed = highpass(roi_rawdata, highpass_fpass, recording_fr);
		roi_highpassed_std = std(roi_highpassed);

		recording_highpassed{:, roi_data_loc} = roi_highpassed;
		recording_lowpassed{:, roi_data_loc} = roi_lowpasseddata;
		if ~cnmfe_process
			thresh = mean(roi_highpassed)+5*std(roi_highpassed);
			recording_thresh{:, roi_data_loc} = ones(size(timeinfo))*thresh;

			roi_data_peak_calc = roi_lowpasseddata;
		else
			roi_data_peak_calc = roi_lowpasseddata;
		end
		z_score_roi_data_peak_calc = zscore(roi_data_peak_calc);
		norm_roi_data_peak_calc = roi_data_peak_calc/roi_highpassed_std;

		% %debug=======
		% rn
		% roi_n
		% if rn == 1 && roi_n == 1
		% 	pause
		% end
		% %debug=======

		peak_loc_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_loc_s_'); % peaks' time
		rise_start_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_start_s_');
		decay_stop_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Decay_stop_s_');

		peak_num = length(peak_loc_time);
		discard_peak = []; % discard peaks not meet criteria listed in the beginning of the code (criteria_riseT, criteria_slope, etc.)
		for pn = 1:peak_num
			[min_peak closestIndex_peak] = min(abs(timeinfo-peak_loc_time(pn)));
			[min_rise closestIndex_rise] = min(abs(timeinfo-rise_start_time(pn)));
			[min_decay closestIndex_decay] = min(abs(timeinfo-decay_stop_time(pn)));

			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_loc')(pn) = closestIndex_peak;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_start')(pn) = closestIndex_rise;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Decay_stop')(pn) = closestIndex_decay;

			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_mag')(pn) = roi_data_peak_calc(closestIndex_peak);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_duration_s_')(pn) = peak_loc_time(pn)-rise_start_time(pn);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('decay_duration_s_')(pn) = decay_stop_time(pn)-peak_loc_time(pn);

			peakmag_relative_rise = roi_data_peak_calc(closestIndex_peak)-roi_data_peak_calc(closestIndex_rise);
			peakmag_relative_decay = roi_data_peak_calc(closestIndex_peak)-roi_data_peak_calc(closestIndex_decay);
			% peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_mag_relative')(pn) = max(peakmag_relative_rise, peakmag_relative_decay);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_mag_relative')(pn) = peakmag_relative_rise;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_relative_NormHP')(pn) = peakmag_relative_rise/roi_highpassed_std; % relative peak value normalized to highpass std

			peakmag_lowpassed_delta = roi_data_peak_calc(closestIndex_peak)-roi_data_peak_calc(closestIndex_rise); % delta peakmag: subtract rising point value
			peakmag_25per_cal = peakmag_lowpassed_delta*0.25+roi_data_peak_calc(closestIndex_rise); % 25% peakmag value 
			peakmag_75per_cal = peakmag_lowpassed_delta*0.75+roi_data_peak_calc(closestIndex_rise); % 25% peakmag value

			[peakmag_lowpassed_25per_diff peakloc_lowpassed_25per] = min(abs(roi_data_peak_calc(closestIndex_rise:closestIndex_peak)-peakmag_25per_cal)); % 25% loc in (rising:peak) range
			peakloc_lowpassed_25per = closestIndex_rise-1+peakloc_lowpassed_25per; % location of 25% peak value in data

			[peakmag_lowpassed_75per_diff peakloc_lowpassed_75per] = min(abs(roi_data_peak_calc(closestIndex_rise:closestIndex_peak)-peakmag_75per_cal)); % 75% loc in (rising:peak) range
			peakloc_lowpassed_75per = closestIndex_rise-1+peakloc_lowpassed_75per; % location of 75% peak value in data

			peakmag_lowpassed_25per = roi_data_peak_calc(peakloc_lowpassed_25per);
			peaktime_lowpassed_25per = timeinfo(peakloc_lowpassed_25per); % time stamp of 25% peak value in data
			peakmag_lowpassed_75per = roi_data_peak_calc(peakloc_lowpassed_75per);
			peaktime_lowpassed_75per = timeinfo(peakloc_lowpassed_75per); % time stamp of 75% peak value in data

			peakslope = (peakmag_lowpassed_75per-peakmag_lowpassed_25per)/(peaktime_lowpassed_75per-peaktime_lowpassed_25per);

			% rn
			% roi_n
			% pn
			% if rn==7 && roi_n==1 && pn==1
			% 	pause
			% end

			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakLoc25percent')(pn) = peakloc_lowpassed_25per;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakLoc75percent')(pn) = peakloc_lowpassed_75per;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakMag25percent')(pn) = peakmag_lowpassed_25per;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakMag75percent')(pn) = peakmag_lowpassed_75per;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakTime25percent')(pn) = peaktime_lowpassed_25per;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakTime75percent')(pn) = peaktime_lowpassed_75per;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakSlope')(pn) = peakslope;


			% check whether peak start to rise during stimulation
			if ~isempty(ROIdata{rn, 3})
				for stim_n = 1:length(gpio_train_start_time{nc}) % number of stimulation
					peak_rise_start_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_start_s_');
					if peak_rise_start_time(pn) >= gpio_train_start_time{nc}(stim_n) && peak_rise_start_time(pn) <= gpio_train_end_time{nc}(stim_n)
						peak_loc_mag{peakinfo_row, roi_n}{:, :}.('triggeredPeak')(pn) = 1;
					else
						peak_loc_mag{peakinfo_row, roi_n}{:, :}.('triggeredPeak')(pn) = 0;
					end
				end
			end
			

			% check whether to discard this peak
			peak_rise_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_duration_s_')(pn);
			peak_slope = peakslope;
			discard_logic = false;
			if peak_rise_time < criteria_riseT(1) || peak_rise_time > criteria_riseT(2)
				discard_logic = true;
			end
			if peak_slope < criteria_slope(1) || peak_slope > criteria_slope(2)
				discard_logic = true;
			end
			if peakmag_relative_rise/roi_highpassed_std <= criteria_pnr % discard peaks with small PNR (peakSignal/std)
				discard_logic = true;
			end
			if discard_logic == true
				discard_peak = [discard_peak pn];
			end
		end

		% delete discard_peak row(s)
		if use_criteria == false
			discard_peak = [];
		end

		if ~isempty(discard_peak)
			peak_loc_mag{peakinfo_row, roi_n}{:, :}(discard_peak, :) = [];
		end


		roi_peakloc = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_loc'); % accquire peak locations in roi_n
		peak_zscore = z_score_roi_data_peak_calc(roi_peakloc); % z-score value of peaks
		peak_norm_highpass = norm_roi_data_peak_calc(roi_peakloc); % peaks normalized by std of highpassed data
		Exist_Column = strcmp('PeakZscore',peak_loc_mag{peakinfo_row, roi_n}{:, :}.Properties.VariableNames);
		val = Exist_Column(Exist_Column==1);
		peak_loc_mag{peakinfo_row, roi_n}{:, :}.PeakZscore = peak_zscore;
		peak_loc_mag{peakinfo_row, roi_n}{:, :}.PeakNormHP = peak_norm_highpass;
	end
	ROIdata{rn, 5} = peak_loc_mag;

	if nargin >= 2
		% if plot_traces == 1 || 2
		% 	% plot_col_num = ceil(roi_num/5);
		% 	% plot_fig_num = ceil(plot_col_num/2);
		% 	% subplot_multi_factor = 1;
		% 	% close all
		% elseif plot_traces == 3 || 4

		if plot_traces == 1 || plot_traces == 2
			if subplot_roi == 1
				% ROI traces are subplotted in 5x2 size
				colNumPerFig = 2;
				rowNumPerFig = 5;
			elseif subplot_roi == 2
				% ROI traces are subplotted in 2x1 size
				colNumPerFig = 1;
				rowNumPerFig = 2;
			end
				
			plot_col_num = ceil(roi_num/rowNumPerFig); % one column of triggered response plot for each 2-column wide original traces
			plot_fig_num = ceil(plot_col_num/colNumPerFig); % 3 columns for 1 group of data (*5 ROIs)
			% subplot_multi_factor = 3;
			close all
			% end

			% if isempty(ROIdata{rn, 3}) 
			% 	GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
			% else
			% 	GPIO_trace = 1; % show GPIO trace representing stimulation
			% 	stimulation = ROIdata{rn, 3}{1, 1};
			% 	channel = ROIdata{rn, 4}; % GPIO channels
			% 	gpio_signal = cell(1, (length(channel)-2)); % pre-allocate number of stimulation to gpio_signal used to store signal time and value

			% 	gpio_train_patch_x = cell(1, (length(channel)-2)); % pre-allocate gpio_x
			% 	gpio_train_patch_y = cell(1, (length(channel)-2)); % pre-allocate gpio_y
			% 	gpio_x = cell(1, (length(channel)-2)); % pre-allocate gpio_x
			% 	gpio_y = cell(1, (length(channel)-2)); % pre-allocate gpio_y
			% 	for nc = 1:(length(channel)-2) % number of GPIOs used for stimulation
			% 		gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
			% 		gpio_signal{nc}(:, 1) = channel(nc+2).time_value(:, 1); % time value of GPIO signal
			% 		gpio_signal{nc}(:, 2) = channel(nc+2).time_value(:, 2); % voltage value of GPIO signal
			% 		gpio_rise_loc = find(gpio_signal{nc}(:, 2)); % locations of GPIO voltage not 0, ie stimuli start
			% 		gpio_rise_num = length(gpio_rise_loc); % number of GPIO voltage rise

			% 		% Looking for stimulation groups. Many stimuli are train signal. Ditinguish trains by finding rise time interval >=5s
			% 		% Next line calculate time interval between to gpio_rise. (Second:End stimuli_time)-(first:Second_last stimuli_time)
			% 		gpio_rise_interval{nc} = gpio_signal{nc}(gpio_rise_loc(2:end), 1)-gpio_signal{nc}(gpio_rise_loc(1:(end-1)), 1);
			% 		train_interval_loc{nc} = find(gpio_rise_interval{1, nc} >= 5); % If time interval >=5s, this is between end of a train and start of another train
			% 		train_end_loc{nc} = [gpio_rise_loc(train_interval_loc{nc}); gpio_rise_loc(end)]; % time of the train_end rises start
			% 		train_start_loc{nc} = [gpio_rise_loc(1); gpio_rise_loc(train_interval_loc{nc}+1)]; % time of the train_start rises start

			% 		gpio_train_start_time{nc} = gpio_signal{nc}(train_start_loc{nc}, 1); % time points when GPIO trains start
			% 		gpio_train_end_time{nc} = gpio_signal{nc}(train_end_loc{nc}+1, 1); % time points when GPIO trains end

			% 		ROIdata{rn, 4}(4).stim_range(:, 1) = gpio_train_start_time{nc}; % save stimulation signal start time info
			% 		ROIdata{rn, 4}(4).stim_range(:, 2) = gpio_train_end_time{nc}; % save stimulation signal end time info

			% 		% for peak_n = 1:size(peak_loc_mag{peakinfo_row, roi_n}{:, :}, 1) % number of peaks in this roi
			% 		% 	for stim_n = 1:length(gpio_train_start_time{nc}) % number of stimulation

			% 		% 	end
			% 		% end

			% 		for ngt = 1:length(gpio_train_start_time{nc})
			% 			gpio_train_patch_x{nc}(1+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 1);
			% 			gpio_train_patch_x{nc}(2+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 1);
			% 			gpio_train_patch_x{nc}(3+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 1);
			% 			gpio_train_patch_x{nc}(4+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 1);

			% 			gpio_train_patch_y{nc}(1+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt)+1, 2);
			% 			gpio_train_patch_y{nc}(2+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 2);
			% 			gpio_train_patch_y{nc}(3+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt), 2);
			% 			gpio_train_patch_y{nc}(4+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 2);
			% 		end
			% 		gpio_train_lim_loc{nc, 1} = find(gpio_train_patch_y{nc}(:, 1) == 0); % location of gpio voltage ==0 in gpio_train_lim_loc
			% 		gpio_train_lim_loc{nc, 2} = find(gpio_train_patch_y{nc}(:, 1)); % location of gpio voltage ~=0 in gpio_train_lim_loc

			% 		% gpio_x = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_x used to plot GPIO with "patch" function
			% 		% gpio_y = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_y used to plot GPIO with "patch" function
			% 		for ng = 1:gpio_rise_num % number of GPIO voltage rise, ie stimuli
			% 			gpio_x{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
			% 			gpio_x{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
			% 			gpio_x{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);
			% 			gpio_x{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);

			% 			gpio_y{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
			% 			gpio_y{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
			% 			gpio_y{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
			% 			gpio_y{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
			% 		end
			% 		gpio_lim_loc{nc, 1} = find(gpio_y{nc}(:, 1) == 0); % location of gpio voltage ==0 in gpio_y
			% 		gpio_lim_loc{nc, 2} = find(gpio_y{nc}(:, 1)); % location of gpio voltage ~=0 in gpio_y
			% 	end
			% end
				
			for p = 1:plot_fig_num % figure number
				peak_plot_handle(p) = figure (p);
				set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]

				for q = 1:colNumPerFig % column group num for ROI. When plot_traces=1||2, subplot column = q, when 3||4 subplot column == q*4
					if (plot_col_num-(p-1)*colNumPerFig-q) > 0
						last_row = rowNumPerFig;
					else
						last_row = roi_num-(p-1)*colNumPerFig*rowNumPerFig-(q-1)*rowNumPerFig;
					end
					for m = 1:last_row
						roi_plot = (p-1)*colNumPerFig*rowNumPerFig+(q-1)*rowNumPerFig+m; % the number of roi to be plot
						roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_plot}; % roi name ('C0, C1...')
						roi_col_loc_data = find(strcmp(roi_name, recording_data.Properties.VariableNames)); % the column number of this roi in recording_data (ROI_table)
						roi_col_loc_cal = find(strcmp(roi_name, peak_loc_mag.Properties.VariableNames)); % the column number of this roi in peak data (ROI_table)

						roi_col_data = recording_data{:, roi_col_loc_data}; % roi data 
						peak_time_loc = peak_loc_mag{1, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
						peak_value = peak_loc_mag{1, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

						roi_col_data_lowpassed = recording_lowpassed{:, roi_col_loc_data}; % roi data 
						peak_time_loc_lowpassed = peak_loc_mag{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
						peak_value_lowpassed = peak_loc_mag{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

						if ~cnmfe_process
							roi_col_data_select = roi_col_data_lowpassed;
							roi_data_trigplot = recording_rawdata{:, roi_col_loc_data};
							peak_time_loc_select = peak_time_loc_lowpassed;
							peak_value_select = peak_value_lowpassed;
						else
							roi_col_data_select = roi_col_data;
							roi_data_trigplot = recording_lowpassed{:, roi_col_loc_data};
							roi_rawdata = recording_rawdata{:, roi_col_loc_data};
							peak_time_loc_select = peak_time_loc;
							peak_value_select = peak_value;
							peak_rise_turning_time_lowpassed = peak_loc_mag{3, roi_col_loc_cal}{:, :}.('Rise_start_s_');
							peak_rise_turning_value_lowpassed = roi_col_data_lowpassed(peak_loc_mag{3, roi_col_loc_cal}{:, :}.('Rise_start'));
						end
								
 
						peak_rise_turning_loc = peak_loc_mag{peakinfo_row_plot, (roi_col_loc_cal)}{:, :}.('Rise_start_s_');
						peak_rise_turning_value = roi_col_data_select(peak_loc_mag{peakinfo_row_plot, (roi_col_loc_cal)}{:, :}.('Rise_start'));
						peak_decay_turning_loc = peak_loc_mag{peakinfo_row_plot, (roi_col_loc_cal)}{:, :}.('Decay_stop_s_');
						peak_decay_turning_value = roi_col_data_select(peak_loc_mag{peakinfo_row_plot, (roi_col_loc_cal)}{:, :}.('Decay_stop'));

						roi_col_data_highpassed = recording_highpassed{:, roi_col_loc_data}; % roi data 
						thresh_data = recording_thresh{:, roi_col_loc_data};

						% sub_handle(roi_plot) = subplot(6, 2, q+(m-1)*2);
						sub_handle(roi_plot) = subplot((rowNumPerFig+1), colNumPerFig*4, [(q*4-3)+(m-1)*(colNumPerFig*4), (q*4-3)+(m-1)*(colNumPerFig*4)+1]);
						plot(timeinfo, roi_col_data, 'k') % plot original data
						hold on
						plot(timeinfo, roi_col_data_lowpassed, 'Color', '#0072BD', 'linewidth', 1); % plot lowpass filtered data

						% plot detected peaks and their starting and ending points
						plot(peak_time_loc_select, peak_value_select, 'o', 'Color', '#000000', 'linewidth', 1) %plot lowpassed data peak marks
						plot(peak_rise_turning_loc, peak_rise_turning_value, '>', peak_decay_turning_loc, peak_decay_turning_value, '<', 'Color', '#000000', 'linewidth', 1) % plot start and end of transient, turning point

						if cnmfe_process
							plot(timeinfo, roi_rawdata, 'Color', '#7E2F8E')
							plot(peak_time_loc_lowpassed, peak_value_lowpassed, 'o', 'Color', '#D95319', 'linewidth', 1) % plot peak marks of lowpassed data
							plot(peak_rise_turning_time_lowpassed, peak_rise_turning_value_lowpassed, 'd', 'Color', '#D95319',  'linewidth', 1) % plot start of transient of lowpassed data, turning point
						end
						ylim_gpio = ylim;

						if GPIO_trace == 1
							gpio_color = {'cyan', 'magenta', 'yellow'};
							for ncp = 1:(length(channel)-2) % number of channel plot
								% loc_nonzero = find(gpio_y(:, ncp));
								gpio_y{ncp}(gpio_lim_loc{ncp, 2} , 1) = ylim_gpio(2); % expand gpio_y upper lim to max of y-axis
								% loc_zero = find(gpio_y(:, ncp)==0); % loction of gpio value =0 in gpio_y
								gpio_y{ncp}(gpio_lim_loc{ncp, 1} , 1) = ylim_gpio(1); % expand gpio_y lower lim to min of y-axis
								% patch(gpio_x{ncp}(:, 1), gpio_y{ncp}(:, 1), gpio_color{ncp}, 'EdgeColor', 'none', 'FaceAlpha', 0.7)

								gpio_train_patch_y{ncp}(gpio_train_lim_loc{ncp, 2}, 1) = ylim_gpio(2);
								gpio_train_patch_y{ncp}(gpio_train_lim_loc{ncp, 1}, 1) = ylim_gpio(1);
								patch(gpio_train_patch_x{ncp}(:, 1), gpio_train_patch_y{ncp}(:, 1), gpio_color{ncp}, 'EdgeColor', 'none', 'FaceAlpha', 0.3)
							end
						end
						set(gca,'children',flipud(get(gca,'children')))
						axis([0 timeinfo(end) ylim_gpio(1) ylim_gpio(2)])
						set(get(sub_handle(roi_plot), 'YLabel'), 'String', roi_name);
						hold off

						% Plot stimuli triggered response. No criteria yet
						if GPIO_trace == 1
							subplot((rowNumPerFig+1), colNumPerFig*4, (q*4+(m-1)*(colNumPerFig*4)-1)) % plot stimulation triggered responses. All sweeps
							pre_stimuli_duration = 5; % duration before stimulation onset
							post_stimuli_duration = 10; % duration after stimulation end
							baseline_duration = 3; % time duration before stimulation used to calculate baseline for y-axis aligment 
							pre_stimuli_time = gpio_train_start_time{1}-pre_stimuli_duration; % plot from 'pre_stimuli_duration' before stimuli start. The "first GPIO stimuli"
							post_stimuli_time = gpio_train_end_time{1}+post_stimuli_duration; % plot until 'post_stimuli_duration' after stimuli end
							plot_duration = post_stimuli_time-pre_stimuli_time; % duration of plot

							first_gpio_train_start_loc = find(gpio_x{1}(:, 1)==gpio_train_start_time{1}(1), 1); % location of first train starts
							first_gpio_train_end_loc = find(gpio_x{1}(:, 1)==gpio_train_end_time{1}(1), 1, 'last'); % location of first train ends
							gpio_x_trig_plot = gpio_x{1}(first_gpio_train_start_loc:first_gpio_train_end_loc, 1); % gpio_x of the first train
							gpio_x_trig_plot = gpio_x_trig_plot-gpio_x_trig_plot(1, 1); % gpio_x starts from 0
							gpio_y_trig_plot = gpio_y{1}(first_gpio_train_start_loc:first_gpio_train_end_loc); % gpio_y of the first train
							% patch(gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7)

							train_first_gpio_train_start_loc = find(gpio_train_patch_x{1}(:, 1)==gpio_train_start_time{1}(1), 1); % location in gpio_train_patch_x
							train_first_gpio_train_end_loc = find(gpio_train_patch_x{1}(:, 1)==gpio_train_end_time{1}(1), 1, 'last'); % location in gpio_train_patch_x
							gpio_train_patch_x_trig_plot = gpio_train_patch_x{1}(train_first_gpio_train_start_loc:train_first_gpio_train_end_loc, 1);
							gpio_train_patch_x_trig_plot = gpio_train_patch_x_trig_plot-gpio_train_patch_x_trig_plot(1, 1); % gpio_x starts from 0
							gpio_train_patch_y_trig_plot = gpio_train_patch_y{1}(first_gpio_train_start_loc:train_first_gpio_train_end_loc);
							patch(gpio_train_patch_x_trig_plot, gpio_train_patch_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.3)

							hold on
							for tn = 1:length(pre_stimuli_time) % number of stimulation trains
								[val_min, idx_min] = min(abs(timeinfo-pre_stimuli_time(tn))); % value and start point idx for ploting triggered response
								[val_max, idx_max] = min(abs(timeinfo-post_stimuli_time(tn))); % value and end point idx for ploting triggered response
								timeinfo_trig_plot{tn} = timeinfo(idx_min:idx_max)-gpio_train_start_time{1}(tn);

								idx_min_base = idx_min+recording_fr*(pre_stimuli_duration-baseline_duration); % loc of first data point of "baseline_duration" before stimulation
								idx_max_base = find((timeinfo-gpio_train_start_time{1}(tn))<0, 1, 'last'); % loc of last data point of "baseline_duration" before stimulation
								roi_col_data_base = mean(roi_data_trigplot(idx_min_base:idx_max_base)); % baseline before 'tn' stimulation

								roi_col_data_trig_plot{tn} = roi_data_trigplot(idx_min:idx_max)-roi_col_data_base;
								% roi_col_data_lowpassed_trig_plot = roi_col_data_lowpassed(idx_min:idx_max);
								data_point_num(tn) = length(timeinfo_trig_plot{tn}); % data points of each triggered plot

								plot(timeinfo_trig_plot{tn}, roi_col_data_trig_plot{tn}, 'k'); % plot raw data sweeps
								% plot(timeinfo_trig_plot, roi_col_data_lowpassed_trig_plot, 'm'); % plot lowpassed data
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
								std_data_trig_plot = std(datapoint_for_average, 0, 2);
							end
							std_plot_upper_line = average_data_trig_plot+std_data_trig_plot;
							std_plot_lower_line = average_data_trig_plot-std_data_trig_plot;
							std_plot_area_y = [std_plot_upper_line; flip(std_plot_lower_line)];
							% loc_longest_time_trig_plot = find(sort(data_point_num), 1, 'last');
							[longest_time_trig_plot,loc_longest_time_trig_plot] = max(data_point_num, [],'linear');
							average_data_trig_plot_x = timeinfo_trig_plot{loc_longest_time_trig_plot};
							std_plot_area_x = [average_data_trig_plot_x; flip(average_data_trig_plot_x)];
							subplot((rowNumPerFig+1), colNumPerFig*4, (q*4+(m-1)*(colNumPerFig*4))) % plot stimulation triggered responses. Averaged
							% patch(gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7)
							patch(gpio_train_patch_x_trig_plot, gpio_train_patch_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.3)
							hold on
							plot(average_data_trig_plot_x, average_data_trig_plot, 'k');
							patch(std_plot_area_x, std_plot_area_y, 'yellow', 'EdgeColor', 'none', 'FaceAlpha', 0.3) %'#EDB120'
						end

					end
					if GPIO_trace == 1
						subplot((rowNumPerFig+1), colNumPerFig*4, [rowNumPerFig*colNumPerFig*4+(q-1)*4+1,rowNumPerFig*colNumPerFig*4+(q-1)*4+2]);
						for nc = 1:length(channel)-2
							gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
							x = channel(nc+2).time_value(:, 1);
							y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
							stairs(x, y{nc});
							hold on
						end
						axis([0 timeinfo(end) 0 max(y{1})+1])
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
					figfullpath = fullfile(fig_subfolder,figfile);
					savefig(gcf, figfullpath);
					jpgfile_name = [figfile(1:(end-3)), 'jpg'];
					jpgfile_fullpath = fullfile(fig_subfolder, jpgfile_name);
					saveas(gcf, jpgfile_fullpath);
					svgfile_name = [figfile(1:(end-3)), 'svg'];
					svgfile_fullpath = fullfile(fig_subfolder, svgfile_name);
					saveas(gcf, svgfile_fullpath);
				end	
				if pause_step == 1
					disp('Press any key to continue')
					pause;
				end
			end
		end
	end
end
modified_ROIdata = ROIdata;
end

