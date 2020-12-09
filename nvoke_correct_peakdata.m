function [modified_ROIdata] = nvoke_correct_peakdata(ROIdata, varargin)
% After manually discarding ROIs and correcting peak rise and fall point.
% Correct the rise_loc, decay_loc, etc.
% nvoke_correct_peakdata(ROIdata,plot_traces,subplot_roi,pause_step, lowpass_fpass)
% Input:
%		- 1. ROIdata
% 		- 2. plot_traces: 1-plot, 2-plot and save, 3-plot original traces and stimuli triggered response, 4-plot 3 and save
%		- 3. subplot_roi: 1-5x2 rois in 1 figure, 2-2x1 rois in 1 figure
% 		- 4. pause_step: 1-pause after ploting every figure, 0-no pause
%		- 5. lowpass_fpass: lowpassfilter default passband is 1 (ventral approach). 10 for slice
% 
% 
% 
%   Detailed explanation goes here
%
%[modified_ROIdata] = nvoke_correct_peakdata(ROIdata,plot_traces,pause_step)


lowpass_fpass = 10; % lowpassfilter default passband is 1 (ventral approach). 10 for slice
highpass_fpass = 4;
peakinfo_row_name = 'Peak_lowpassed';

criteria_riseT = [0 8]; % unit: second. filter to keep peaks with rise time in the range of [min max]
criteria_slope = [3 80]; % default: slice-[50 2000]
							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
							% ventral approach default: [3 80]
							% slice default: [50 2000]
criteria_mag = 3; % default: 3. peak_mag_normhp
criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
criteria_excitated = 2; % If a peak starts to rise in 2 sec since stimuli, it's a excitated peak
criteria_rebound = 1; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end
stimTime_corr = 0.3; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
use_criteria = true; % true or false. choose to use criteria or not for picking peaks

% use follwing parameters to select a window for aligned stimulation analysis.
stimPreTime = 10; % time (s) before stimuli start
stimPostTime = 10; % time (s) after stimuli end

% parameters for makeing a new row for peak frequencies
peakFq_size = [1 14];
peakFq_varTypes = {'string', 'double', 'double', 'double', 'double',...
'double', 'double', 'double', 'double', 'double',...
'double', 'double', 'double', 'double'};
peakFq_varNames = {'stim', 'recTime', 'stimTime', 'stimNum', 'stimTsum',...
'nostimTsum', 'peakNumTrig', 'peakNumTrigDelay', 'peakNumRebound', 'peakNumOther',...
'timeTrig', 'timeTrigDelay', 'timeRebound', 'timeOther'}; 

if nargin == 1 % ROIdata
	plot_traces = 0;
	pause_step = 0;
elseif nargin == 2 % ROIdata, plot_traces
	plot_traces = varargin{1};
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
elseif nargin == 3 % ROIdata, plot_traces, subplot_roi
	plot_traces = varargin{1};
	subplot_roi = varargin{2};
	% if plot_traces ~= 0
	% 	pause_step = 1;
	% else
	% 	pause_step = 0;
	% end
	if plot_traces == 3 || 4
		stimuli_triggered_response = 1;
	elseif plot_traces == 1 || 2
		pause_step = 1;
	else
		stimuli_triggered_response = 0;
		pause_step = 0;
	end
elseif nargin >= 4 && nargin <= 5 % ROIdata, plot_traces, subplot_roi, pause_step, (lowpass_fpass)
	plot_traces = varargin{1};
	subplot_roi = varargin{2};
	pause_step = varargin{3};
	if nargin == 5
		lowpass_fpass = varargin{4};
	end
elseif nargin > 5
	error('Too many input. Maximum 5. Read document of function "nvoke_correct_peakdata"')
end

if plot_traces == 2
	if ispc
		figfolder = uigetdir('G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks',...
			'Select a folder to save figures');
	elseif isunix
		figfolder = uigetdir('/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/peaks',...
			'Select a folder to save figures');
	end
end

recording_num = size(ROIdata, 1);
for rn = 1:recording_num
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
		stim_str = 'noStim';
	elseif strfind(ROIdata{rn, 3}{:}, 'noStim')
		GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
		stim_str = 'noStim';
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
			if strfind(channel(nc+2).name{1}, 'GPIO-1')
				gpio_thresh = 30000; % 30000 for nvoke2
			elseif strfind(channel(nc+2).name{1}, 'OG-LED')
				gpio_thresh = 0.15;
			else
				gpio_thresh = 0.5;
			end


			gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
			gpio_signal{nc}(:, 1) = channel(nc+2).time_value(:, 1); % time value of GPIO signal
			gpio_signal{nc}(:, 2) = channel(nc+2).time_value(:, 2); % voltage value of GPIO signal
			gpio_rise_loc = find(gpio_signal{nc}(:, 2)>gpio_thresh); % locations of GPIO voltage not 0, ie stimuli start
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

				% gpio_train_patch_y{nc}(1+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt)+1, 2);
				% gpio_train_patch_y{nc}(2+(ngt-1)*4, 1) = gpio_signal{nc}(train_start_loc{nc}(ngt), 2);
				% gpio_train_patch_y{nc}(3+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt), 2);
				% gpio_train_patch_y{nc}(4+(ngt-1)*4, 1) = gpio_signal{nc}(train_end_loc{nc}(ngt)+1, 2);

				gpio_train_patch_y{nc}(1+(ngt-1)*4, 1) = 0;
				gpio_train_patch_y{nc}(2+(ngt-1)*4, 1) = 1;
				gpio_train_patch_y{nc}(3+(ngt-1)*4, 1) = 1;
				gpio_train_patch_y{nc}(4+(ngt-1)*4, 1) = 0;
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
		stim_duration = round(ROIdata{rn, 4}(3).stim_range(1, 2) - ROIdata{rn, 4}(3).stim_range(1, 1)); % duration of stimulation
		stim_str = [ROIdata{rn, 4}(3).name{1}, '-', num2str(stim_duration), 's']; % OG_LED-5s, OG_LED-10s, GPIO1-1s, etc.
	end
	ROIdata{rn, 3}{1} = stim_str;


	peak_loc_mag = ROIdata{rn, 5};
	if size(peak_loc_mag, 1)<4 % if there is no row for peak frquency
		neuron_n = size(peak_loc_mag, 2); % number of rois
		peakFqrow = cell2table(cell(1, neuron_n)); % new peakFqrow 
		peakFqrow.Properties.VariableNames = peak_loc_mag.Properties.VariableNames; % give new row var names
		peakFqrow.Properties.RowNames{1} = 'Peak_Fq';
		peak_loc_mag = [peak_loc_mag; peakFqrow]; % add new row to table
	end

	peakinfo_row = find(strcmp(peakinfo_row_name, peak_loc_mag.Properties.RowNames));
	peakinfo_row_plot = find(strcmp(peakinfo_row_name_plot, peak_loc_mag.Properties.RowNames));
	[recording_rawdata, recording_time, roi_num_all] = ROI_calc_plot(recording_rawdata);
	timeinfo = recording_rawdata{:, 1}; % array not table
	recording_fr = 1/(timeinfo(10)-timeinfo(9));
    recording_code = rn;
	roi_num = size(peak_loc_mag, 2); % total roi numbers after handpick

	recording_highpassed = recording_rawdata; % allocate ram
    recording_thresh = recording_rawdata; % allocate ram
	recording_lowpassed = recording_rawdata; % allocate ram

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
			thresh = mean(roi_highpassed)+4*std(roi_highpassed);
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

			[peakmag_lowpassed_25per_diff peakloc_lowpassed_25per(pn, 1)] = min(abs(roi_data_peak_calc(closestIndex_rise:closestIndex_peak)-peakmag_25per_cal)); % 25% loc in (rising:peak) range
			peakloc_lowpassed_25per(pn, 1) = closestIndex_rise-1+peakloc_lowpassed_25per(pn, 1); % location of 25% peak value in data

			[peakmag_lowpassed_75per_diff peakloc_lowpassed_75per(pn, 1)] = min(abs(roi_data_peak_calc(closestIndex_rise:closestIndex_peak)-peakmag_75per_cal)); % 75% loc in (rising:peak) range
			peakloc_lowpassed_75per(pn, 1) = closestIndex_rise-1+peakloc_lowpassed_75per(pn, 1); % location of 75% peak value in data

			peakmag_lowpassed_25per(pn, 1) = roi_data_peak_calc(peakloc_lowpassed_25per(pn, 1));
			peaktime_lowpassed_25per(pn, 1) = timeinfo(peakloc_lowpassed_25per(pn, 1)); % time stamp of 25% peak value in data
			peakmag_lowpassed_75per(pn, 1) = roi_data_peak_calc(peakloc_lowpassed_75per(pn, 1));
			peaktime_lowpassed_75per(pn, 1) = timeinfo(peakloc_lowpassed_75per(pn, 1)); % time stamp of 75% peak value in data

			peakmag_normhp_25per(pn, 1) = norm_roi_data_peak_calc(peakloc_lowpassed_25per(pn, 1));
			peakmag_normhp_75per(pn, 1) = norm_roi_data_peak_calc(peakloc_lowpassed_75per(pn, 1));

			peakslope = (peakmag_lowpassed_75per(pn, 1)-peakmag_lowpassed_25per(pn, 1))/(peaktime_lowpassed_75per(pn, 1)-peaktime_lowpassed_25per(pn, 1));
			peakslope_normhp = (peakmag_normhp_75per(pn, 1)-peakmag_normhp_25per(pn, 1))/(peaktime_lowpassed_75per(pn, 1)-peaktime_lowpassed_25per(pn, 1));

			% rn
			% roi_n
			% pn
			% if rn==7 && roi_n==1 && pn==1
			% 	pause
			% end

			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakLoc25percent')(pn) = peakloc_lowpassed_25per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakLoc75percent')(pn) = peakloc_lowpassed_75per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakMag25percent')(pn) = peakmag_lowpassed_25per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakMag75percent')(pn) = peakmag_lowpassed_75per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakMag25percent_normhp')(pn) = peakmag_normhp_25per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakMag75percent_normhp')(pn) = peakmag_normhp_75per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakTime25percent')(pn) = peaktime_lowpassed_25per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakTime75percent')(pn) = peaktime_lowpassed_75per(pn, 1);
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakSlope')(pn) = peakslope;
			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('PeakSlope_normhp')(pn) = peakslope_normhp;

			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('stim')(pn) = {stim_str};

			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime2stimStart')(pn) = NaN;
			% check whether peak start to rise during stimulation
			if isempty(strfind(ROIdata{rn, 3}{1}, 'noStim')) % ~isempty(ROIdata{rn, 3})
				for stim_n = 1:length(gpio_train_start_time{nc}) % number of stimulation
					peak_rise_start_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_start_s_');
					peak_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_loc_s_');
					% if stim_n == 1
					% 	if peak_rise_start_time(pn) < (gpio_train_start_time{nc}(stim_n)-stimTime_corr) % stimTime_corr is defiened in the beginning of the code
					% 		if peak_time < (gpio_train_start_time{nc}(stim_n)-stimTime_corr)
					% 			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = {'noStim'}; % peaks not related to stimulation at all
					% 		elseif peak_time >= (gpio_train_start_time{nc}(stim_n)-stimTime_corr)
					% 			peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = {['noStim-', stim_str]};
					% 		end
					% 		peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime_stimRelative')(pn) = NaN;
					% 	elseif peak_rise_start_time(pn) >= (gpio_train_start_time{nc}(stim_n)-stimTime_corr) && peak_rise_start_time(pn) < gpio_train_start_time{nc}(stim_n+1)
					% 		riseTime_stimRelative = peak_rise_start_time(pn)-gpio_train_start_time{nc}(stim_n);
					% 		if riseTime_stimRelative < 0 
					% 			riseTime_stimRelative = 0;
					% 		end
					% 		peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime_stimRelative')(pn) = riseTime_stimRelative;
					% 	end
					% else
						% if peak_rise_start_time(pn) >= (gpio_train_start_time{nc}(stim_n)-stimTime_corr) && peak_rise_start_time(pn) <= gpio_train_end_time{nc}(stim_n)
						% 	peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'triggered'};
						% elseif peak_rise_start_time(pn) > gpio_train_end_time{nc}(stim_n) && peak_rise_start_time(pn) <= (gpio_train_end_time{nc}(stim_n)+criteria_rebound)
						% 	peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'rebound'};
						% else
						% 	peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'not_triggered'};
						% end
						if stim_n < length(gpio_train_start_time{nc})
							period_end = gpio_train_start_time{nc}(stim_n+1);
						elseif stim_n == length(gpio_train_start_time{nc})
							period_end = recording_data.Time(end);
						end

						preTimeEdge = gpio_train_start_time{nc}(stim_n)-stimPreTime;
						postTimeEdge = gpio_train_end_time{nc}(stim_n)+stimPostTime;
						if peak_rise_start_time(pn) >= preTimeEdge && peak_rise_start_time(pn) <= postTimeEdge
							riseTime2stimStart = peak_rise_start_time(pn)-gpio_train_start_time{nc}(stim_n);
							peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime2stimStart')(pn) = riseTime2stimStart;
						end

						if peak_rise_start_time(pn) >= (gpio_train_start_time{nc}(stim_n)-stimTime_corr) && peak_rise_start_time(pn) < period_end
							riseTime_stimRelative = peak_rise_start_time(pn)-gpio_train_start_time{nc}(stim_n); % riseTime_stimRelative is used to decide peak category. It's always positive
							if riseTime_stimRelative < 0 % if rise time fall into the stimTime_corr range
								riseTime_stimRelative = 0;
							end
							peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime_stimRelative')(pn) = riseTime_stimRelative;
							% peak start to rise in 2sec since stimuli start
							if stim_duration >= 2
								if peak_rise_start_time(pn) <= (gpio_train_start_time{nc}(stim_n)+criteria_excitated)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'triggered'}; % immediat peak triggered by stim
									
								elseif peak_rise_start_time(pn) < (gpio_train_end_time{nc}(stim_n)-stimTime_corr)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'triggered_delay'}; % delay triggered peak. Still during stim
								elseif peak_rise_start_time(pn) >= (gpio_train_end_time{nc}(stim_n)-stimTime_corr) && peak_rise_start_time(pn) <= (gpio_train_end_time{nc}(stim_n)+criteria_rebound)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'rebound'}; % rebound peak after inhibition
								else
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'interval'}; % peaks not during stimuli, and not happen immediatly after stimuli
								end
							else
								if peak_rise_start_time(pn) < (gpio_train_end_time{nc}(stim_n)-stimTime_corr)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'triggered'}; % immediat peak triggered by stim
								elseif peak_rise_start_time(pn) >= (gpio_train_end_time{nc}(stim_n)-stimTime_corr) && peak_rise_start_time(pn) <= (gpio_train_end_time{nc}(stim_n)+criteria_rebound)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'rebound'}; % rebound peak after inhibition
								else
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = { 'interval'}; % 
								end
							end
						elseif peak_rise_start_time(pn) < (gpio_train_start_time{nc}(stim_n)-stimTime_corr)
							if stim_n == 1
								if peak_time(pn) < (gpio_train_start_time{nc}(stim_n)-stimTime_corr)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = {'noStim'}; % peaks not related to stimulation at all
								elseif peak_time(pn) >= (gpio_train_start_time{nc}(stim_n)-stimTime_corr)
									peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = {['noStim-', stim_str]};
								end
								peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime_stimRelative')(pn) = NaN;
								peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime2stimStart')(pn) = NaN;
							end
						end
					% end
				end
			else
				peak_loc_mag{peakinfo_row, roi_n}{:, :}.('peakCategory')(pn) = {'noStim'};
				peak_loc_mag{peakinfo_row, roi_n}{:, :}.('riseTime_stimRelative')(pn) = NaN;
			end
			

			% check whether to discard this peak
			peak_rise_time = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Rise_duration_s_')(pn);
			peak_slope = peakslope;
			peak_mag_normhp = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_relative_NormHP')(pn);
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
			if peak_mag_normhp <= criteria_mag
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

		% calculate peak frequency
		% peakFq_size = [1 14];
		% peakFq_varTypes = {'string', 'double', 'double', 'double', 'double',...
		% 'double', 'double', 'double', 'double', 'double',...
		% 'double', 'double', 'double', 'double'};
		% peakFq_varNames = {'stim', 'recTime', 'stimTime', 'stimNum', 'stimTsum',...
		% 'nostimTsum', 'peakNumTrig', 'peakNumTrigDelay', 'peakNumRebound', 'peakNumOther',...
		% 'timeTrig', 'timeTrigDelay', 'timeRebound', 'timeOther'}; 
		% criteria_excitated = 2; % If a peak starts to rise in 2 sec since stimuli, it's a excitated peak
		% criteria_rebound = 1; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end

		peakFq_T = table('Size', peakFq_size, 'VariableTypes', peakFq_varTypes, 'VariableNames', peakFq_varNames);
		peakFq_T.stim = stim_str;
		peakFq_T.recTime = recording_data.Time(end)-recording_data.Time(1); % recording time
		if ~isempty(peak_loc_mag{peakinfo_row, roi_n}{:, :})
			if isempty(strfind(ROIdata{rn, 3}{1}, 'noStim')) % if there are stimuli
				peakFq_T.stimTime = stim_duration; % time duration of a single stimulation
				peakFq_T.stimNum = size(ROIdata{rn, 4}(3).stim_range, 1); % number of stimuli
				peakFq_T.stimTsum = peakFq_T.stimTime*peakFq_T.stimNum; % whole time duration of stimuli
				peakFq_T.nostimTsum = peakFq_T.recTime-peakFq_T.stimTsum; % time duration of no stimuli
				peak_num_roi = size(peak_loc_mag{peakinfo_row, roi_n}{:, :}, 1); % number of peak in this roi

				% peakTrig_strfind = strfind(peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory, 'triggered'); % find strings triggered peaks
				% peakFq_T.peakNumTrig = length(find(cellfun(@(x) ~isempty(x), peakTrig_strfind))); % number of triggered peaks

				% peakTrigDelay_strfind = strfind(peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory, 'triggered_delay'); % find strings triggered peaks
				% peakFq_T.peakNumTrigDelay = length(find(cellfun(@(x) ~isempty(x), peakTrigDelay_strfind))); % number of triggered peaks

				% peakRebound_strfind = strfind(peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory, 'triggered'); % find strings triggered peaks
				% peakFq_T.peakNumRebound = length(find(cellfun(@(x) ~isempty(x), peakRebound_strfind))); % number of triggered peaks

				% peakFq_T.peakNumOther = peak_num_roi-peakFq_T.peakNumTrig-peakFq_T.peakNumTrigDelay-peakFq_T.peakNumRebound; % number of other peaks. interval of stimuli

				peakTrig_strfind = strcmp('triggered', peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory);
				peakFq_T.peakNumTrig = length(find(peakTrig_strfind)); % number of triggered peaks
				peakTrigDelay_strfind = strcmp('triggered_delay', peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory);
				peakFq_T.peakNumTrigDelay = length(find(peakTrigDelay_strfind)); % number of triggered peaks
				peakRebound_strfind = strcmp('rebound', peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory);
				peakFq_T.peakNumRebound = length(find(peakRebound_strfind)); % number of triggered peaks
				peakInterval_strfind = strcmp('interval', peak_loc_mag{peakinfo_row, roi_n}{:, :}.peakCategory);
				peakFq_T.peakNumInterval = length(find(peakInterval_strfind)); % number of triggered peaks
				peakFq_T.peakNumNostim = peak_num_roi-peakFq_T.peakNumTrig-peakFq_T.peakNumTrigDelay-peakFq_T.peakNumRebound-peakFq_T.peakNumInterval; % number of other peaks. Interval of stimuli
				peakFq_T.peakNumOther = peakFq_T.peakNumInterval+peakFq_T.peakNumOther; % number of other peaks. Interval of stimuli

				if peakFq_T.stimTime > criteria_excitated
					peakFq_T.timeTrig = criteria_excitated*peakFq_T.stimNum; % summation of time windows used for picking trig peaks
				else
					peakFq_T.timeTrig = peakFq_T.stimTime*peakFq_T.stimNum;
				end
				if peakFq_T.stimTime > criteria_excitated
					peakFq_T.timeTrigDelay = (peakFq_T.stimTime-criteria_excitated)*peakFq_T.stimNum; % summation of time windows used for picking trig_delay peaks
				else
					peakFq_T.timeTrigDelay = 0;
				end
				peakFq_T.timeRebound = criteria_rebound*peakFq_T.stimNum; % summation of time windows used for picking rebound peaks
				peakFq_T.timeInterval = peakFq_T.recTime-peakFq_T.stimTsum-peakFq_T.timeRebound-ROIdata{rn, 4}(3).stim_range(1,1); % % summation of time windows used for picking other peaks
				peakFq_T.timeNostim = ROIdata{rn, 4}(3).stim_range(1,1); % % summation of time windows used for picking other peaks
				peakFq_T.timeOther = peakFq_T.recTime-peakFq_T.stimTsum-peakFq_T.timeRebound; % % summation of time windows used for picking other peaks

			else % when no stimuli
				peakFq_T.stimTime = 0; % time duration of a single stimulation
				peakFq_T.stimNum = 0; % number of stimuli
				peakFq_T.stimTsum = 0; % whole time duration of stimuli
				peakFq_T.nostimTsum = peakFq_T.recTime; % time duration of no stimuli

				peak_num_roi = size(peak_loc_mag{peakinfo_row, roi_n}{:, :}, 1); % number of peak in this roi
				peakFq_T.peakNumTrig = 0; % number of triggered peaks
				peakFq_T.peakNumTrigDelay = 0; % number of triggered peaks
				peakFq_T.peakNumRebound = 0; % number of triggered peaks
				peakFq_T.peakNumInterval = 0;
				peakFq_T.peakNumNostim = peak_num_roi;
				peakFq_T.peakNumOther = peak_num_roi; % number of other peaks. outside of stimul
				peakFq_T.timeTrig = 0;
				peakFq_T.timeTrigDelay = 0;
				peakFq_T.timeRebound = 0;
				peakFq_T.timeInterval = 0;
				peakFq_T.timeNostim = peakFq_T.recTime;
				peakFq_T.timeOther = peakFq_T.recTime;
			end
		end
		peak_loc_mag{'Peak_Fq', roi_n}{:} = peakFq_T; % fill peakFq_T into peak_loc_mag table

		roi_peakloc = peak_loc_mag{peakinfo_row, roi_n}{:, :}.('Peak_loc'); % accquire peak locations in roi_n
		peak_zscore = z_score_roi_data_peak_calc(roi_peakloc); % z-score value of peaks
		peak_norm_highpass = norm_roi_data_peak_calc(roi_peakloc); % peaks normalized by std of highpassed data
		Exist_Column = strcmp('PeakZscore',peak_loc_mag{peakinfo_row, roi_n}{:, :}.Properties.VariableNames);
		val = Exist_Column(Exist_Column==1);
		peak_loc_mag{peakinfo_row, roi_n}{:, :}.PeakZscore = peak_zscore;
		peak_loc_mag{peakinfo_row, roi_n}{:, :}.PeakNormHP = peak_norm_highpass;
	end
	ROIdata{rn,2}.lowpass = recording_lowpassed;
	ROIdata{rn,2}.highpass = recording_highpassed;
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
							plot(peak_time_loc_lowpassed, peak_value_lowpassed, 'o', 'Color', '#D95319', 'linewidth', 2) % plot peak marks of lowpassed data
							plot(peak_rise_turning_time_lowpassed, peak_rise_turning_value_lowpassed, 'd', 'Color', '#D95319',  'linewidth', 2) % plot start of transient of lowpassed data, turning point
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

