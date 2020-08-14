function [peak_info_sheet, peak_fq_sheet, varargout] = nvoke_event_calc(ROIdata, plot_analysis, triggeredPeak_filter)
% Analyse calcium transient events: amplitude, rise and decay duration, whole event duration
%   Detailed explanation goes here
% varargout{1} = total_cell_num;
% varargout{2} = total_peak_num;
%
% [peak_info_sheet, total_cell_num, total_peak_num] = nvoke_event_calc(ROIdata, 1)

% triggeredPeak_filter = 2; % 0- no fileter, all peaks. 1- noStim. 2- not_triggered. 3- triggered. 4- rebound

% criterias used in nvoke_correct_peakdata to category peaks
criteria_excitated = 2; % If a peak starts to rise in 2 sec since stimuli, it's a excitated peak
criteria_rebound = 1; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end
stimTime_corr = 0.3; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
% ====================

if plot_analysis == 2
	global figfolder
	if figfolder~=0
	else
		if ispc
			figfolder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks\';
		elseif isunix
			figfolder = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/peaks/';
		end
		
	end
	figfolder = uigetdir(figfolder,...
				['Select a folder to save figures. Trigger_filter-', num2str(triggeredPeak_filter)]);
end

if isstruct(ROIdata{1, 2})
	% recording_rawdata = ROIdata{rn,2}.decon;
	% peak_info = table2array(ROIdata{rn,5}(1, :)); 
	cnmf = 1;
	lowpass_for_peak = false; % use lowpassed data for peak detaction off
	% peakinfo_row = 1; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 1st row (peak row)
	peakinfo_row_name = 'Peak_lowpassed';
else
	% recording_rawdata = ROIdata{1,2};
	% peak_info = table2array(ROIdata{rn,5}(3, :));
	cnmf = 0;
	lowpass_for_peak = true; % use lowpassed data for peak detaction on
	% peakinfo_row = 3; % more detailed peak info for plot and further calculation will be stored in roidata_gpio{x, 5} 3rd row (peak row)
	peakinfo_row_name = 'Peak_lowpassed';
end

recording_num = size(ROIdata, 1);
total_peak_num = 0;
triggered_Pn = 0;
not_triggered_Pn = 0;
for rn = 1:recording_num
	roi_num = size(ROIdata{rn, 5}, 2);
	for roi_n = 1:roi_num
		peak_num = size(ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}, 1); % number of peaks in 1 roi in 1 recording
		total_peak_num = total_peak_num+peak_num;
	end
end

% peak_info_sheet = zeros(total_peak_num, 7);
sheet_fill_count = 1;
Sheet_fill_count_pfq = 1; % for peak frequency info
cell_num_count = 0;
triggered_Pn = 0;
not_triggered_Pn = 0;
stim_time = 0;
no_stim_time = 0;
stim_name = ROIdata{rn, 3}{:}; % name of stim
nostim = false;
for rn = 1:recording_num
	recording_name = ROIdata{rn, 1};
	recording_code = rn;
	roi_num = size(ROIdata{rn, 5}, 2);
	if strcmp('noStim', ROIdata{rn, 3}{:})
		nostim = true;
	end

	for roi_n = 1:roi_num
		if ~isempty(ROIdata{rn,5}{peakinfo_row_name, roi_n}{:})
			roi_imported = 1;
			roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_n};
			roi_code = roi_n;

			roi_peaksize = size(ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('Rise_start_s_')); % number of peaks in one roi

			recording_code_sheet = ones(roi_peaksize)*recording_code;
			roi_code_sheet = ones(roi_peaksize)*roi_code;
			sheet_start = sheet_fill_count;
			sheet_end = sheet_fill_count+roi_peaksize(1)-1;

			str_cells = cell(roi_peaksize);
			peak_rec_name = cellfun(@(x) recording_name, str_cells, 'UniformOutput', false);
			peak_roi_name = cellfun(@(x) roi_name, str_cells, 'UniformOutput', false);

			peak_start = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('Rise_start_s_'); % time points of peak start
			peak_end = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('Decay_stop_s_');
			rise_duration = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('Rise_duration_s_');
			decay_duration = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('decay_duration_s_');
			peak_amp = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('Peak_mag_relative'); % relative one
			peak_slope = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('PeakSlope'); % peak slope
			peakslope_normhp = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('PeakSlope_normhp'); % peak slope
			peak_zscore = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('PeakZscore'); % z-score
			peak_norm_hp = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('PeakNormHP'); % peak normalized to std of highpassed data
			peak_relative_norm_hp = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('Peak_relative_NormHP'); % peak normalized to std of highpassed data
			riseTime_stimStart = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('riseTime2stimStart');

			Exist_Column_peakCategory = strcmp('peakCategory',ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.Properties.VariableNames);
			Exist_Column_stim = strcmp('stim',ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.Properties.VariableNames);
			val_peakCategory_exist = Exist_Column_peakCategory(Exist_Column_peakCategory==1);
			val_stim_exist = Exist_Column_stim(Exist_Column_stim==1);

			if val_stim_exist == 1
				peak_stim = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('stim'); % strings: [stim_str, '-triggered'] or not-triggered, rebound, etc.
			else
				peak_stim = cellfun(@(x) 'unknown', str_cells, 'UniformOutput', false);
				% triggeredPeak_filter = 0;
			end

			if val_peakCategory_exist == 1
				peak_category = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('peakCategory'); % strings: [stim_str, '-triggered'] or not-triggered, rebound, etc.
				riseTime_Relative2Stim = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('riseTime_stimRelative'); % strings: [stim_str, '-triggered'] or not-triggered, rebound, etc.
			else
				peak_category = cellfun(@(x) 'unknown', str_cells, 'UniformOutput', false);;
				riseTime_Relative2Stim = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}.('riseTime_stimRelative'); % strings: [stim_str, '-triggered'] or not-triggered, rebound, etc.
				% triggeredPeak_filter = 0;
			end

			transient_duration = rise_duration+decay_duration;

	% {'recNo', 'roiNo', 'peakStart', 'peakEnd', 'riseDuration', 'decayDuration',...
	% 'wholeDuration', 'peakAmp', 'peakSlope', 'peakZscore', 'peakNormHP', 'peakCategory'}
			recNo(sheet_start:sheet_end, 1) = recording_code_sheet;
			roiNo(sheet_start:sheet_end, 1) = roi_code_sheet;
			recName(sheet_start:sheet_end, 1) = peak_rec_name;
			roiName(sheet_start:sheet_end, 1) = peak_roi_name;
			peakStart(sheet_start:sheet_end, 1) = peak_start;
			peakEnd(sheet_start:sheet_end, 1) = peak_end;
			riseDuration(sheet_start:sheet_end, 1) = rise_duration;
			decayDuration(sheet_start:sheet_end, 1) = decay_duration;
			wholeDuration(sheet_start:sheet_end, 1) = transient_duration;
			peakAmp(sheet_start:sheet_end, 1) = peak_amp;
			peakSlope(sheet_start:sheet_end, 1) = peak_slope;
			peakSlope_normhp(sheet_start:sheet_end, 1) = peakslope_normhp;
			peakZscore(sheet_start:sheet_end, 1) = peak_zscore;
			peakNormHP(sheet_start:sheet_end, 1) = peak_relative_norm_hp;
			peakCategory(sheet_start:sheet_end, 1) = peak_category;
			peakStim(sheet_start:sheet_end, 1) = peak_stim;
			riseTimeRelative2Stim(sheet_start:sheet_end, 1) = riseTime_Relative2Stim;
			riseTime2stimStart(sheet_start:sheet_end, 1) = riseTime_stimStart;

			sheet_fill_count = sheet_fill_count+length(peak_start);

			if Sheet_fill_count_pfq == 1
				peak_fq_sheet = ROIdata{rn,5}{'Peak_Fq', roi_n}{:};
			else
				peak_fq_sheet = [peak_fq_sheet; ROIdata{rn,5}{'Peak_Fq', roi_n}{:}];
			end
			Sheet_fill_count_pfq = Sheet_fill_count_pfq+1;

		else
			roi_imported = 0;
		end

	end
	if roi_imported == 1
		cell_num_count = cell_num_count+roi_num;
	end
end

if isempty(riseDuration)
	disp('No peaks found in this category')
	peak_info_sheet = [];
	peak_fq_sheet = [];
else
	trig_row = find(peak_fq_sheet.peakNumTrig);
	trigDelay_row = find(peak_fq_sheet.peakNumTrigDelay);
	rebound_row = find(peak_fq_sheet.peakNumRebound);
	interval_row = find(peak_fq_sheet.peakNumInterval);
	nostim_row = find(peak_fq_sheet.peakNumNostim);
	other_row = find(peak_fq_sheet.peakNumOther);
	trigT_sum = sum(peak_fq_sheet.timeTrig(trig_row));
	trigDelayT_sum = sum(peak_fq_sheet.timeTrigDelay(trigDelay_row));
	reboundT_sum = sum(peak_fq_sheet.timeRebound(rebound_row));
	intervalT_sum = sum(peak_fq_sheet.timeInterval(interval_row));
	nostimT_sum = sum(peak_fq_sheet.timeNostim(nostim_row));
	otherT_sum = sum(peak_fq_sheet.timeOther(other_row));

	peak_fq_numTrig = sum(peak_fq_sheet.peakNumTrig); %number of immediat peaks since stimulation
	peak_fq_numTrigDelay = sum(peak_fq_sheet.peakNumTrigDelay); %number of peaks start to rise with a delay since stimulation
	peak_fq_numRebound = sum(peak_fq_sheet.peakNumRebound); %number of peaks start to rise immediatly after stimulation ends
	peak_fq_numOther = sum(peak_fq_sheet.peakNumOther); %other peaks. peaks far from the last stimulation
	peak_fq_trig = peak_fq_numTrig/trigT_sum; % frequency of In-peak
	peak_fq_trigDelay = peak_fq_numTrigDelay/trigDelayT_sum; % 
	peak_fq_rebound = peak_fq_numRebound/reboundT_sum; % 
	peak_fq_other = peak_fq_numOther/otherT_sum; % 

	peak_info_sheet = table(recNo, roiNo, recName, roiName, peakStart,...
		peakEnd, riseDuration, decayDuration, wholeDuration, peakAmp,...
		peakSlope, peakSlope_normhp, peakZscore, peakNormHP, peakStim, peakCategory,...
		riseTimeRelative2Stim, riseTime2stimStart);

	% peak_category value: noStim, triggered, not_triggered, rebound, and stimulation as prefix, such as OG_LED-10s-triggered

	if triggeredPeak_filter == 1
		% ind_cell = strfind(peakCategory, 'noStim'); % cell index of peakCategory containing 'noStim' string
		% ind_row_discard = find(cellfun(@isempty, ind_cell)); % convert ind_cell to array. Index of peak_category without 'noStim'
		% peak_info_sheet(ind_row_discard, :) = [];

		ind_cell = strcmp('noStim', peakCategory);
		ind_row_discard = find(ind_cell==0);
		peak_info_sheet(ind_row_discard, :) = [];

		% discard_peaks = find(peakCategory==0);
		triggeredPeak_filter_string = 'noStim';
		nostim = true;
		% peak_info_sheet(discard_peaks, :) = [];
	elseif triggeredPeak_filter == 2
		% ind_cell = strfind(peakCategory, 'not_triggered'); % cell index of peakCategory containing 'not_triggered' string
		% ind_row_discard = find(cellfun(@isempty, ind_cell)); % convert ind_cell to array. Index of peak_category without 'not_triggered'
		% peak_info_sheet(ind_row_discard, :) = [];

		ind_cell = strcmp('interval', peakCategory);
		ind_row_discard = find(ind_cell==0);
		peak_info_sheet(ind_row_discard, :) = [];

		% discard_peaks = find(peak_info_sheet(:, 12)==1);
		triggeredPeak_filter_string = 'intervalPeaks';
		% peak_info_sheet(discard_peaks, :) = [];
	elseif triggeredPeak_filter == 3
		% ind_cell = strfind(peakCategory, 'triggered'); % cell index of peakCategory containing '-triggered' string
		% ind_row_discard = find(cellfun(@isempty, ind_cell)); % convert ind_cell to array. Index of peak_category without '-triggered'
		% peak_info_sheet(ind_row_discard, :) = [];

		ind_cell = strcmp('triggered', peakCategory);
		ind_row_discard = find(ind_cell==0);
		peak_info_sheet(ind_row_discard, :) = [];

		% discard_peaks = find(peak_info_sheet(:, 12)==1);
		triggeredPeak_filter_string = 'triggeredPeaks';
		% peak_info_sheet(discard_peaks, :) = [];
	elseif triggeredPeak_filter == 4
		% ind_cell = strfind(peakCategory, 'rebound'); % cell index of peakCategory containing '-rebound' string
		% ind_row_discard = find(cellfun(@isempty, ind_cell)); % convert ind_cell to array. Index of peak_category without '-rebound'
		% peak_info_sheet(ind_row_discard, :) = [];

		ind_cell = strcmp('triggered_delay', peakCategory);
		ind_row_discard = find(ind_cell==0);
		peak_info_sheet(ind_row_discard, :) = [];

		triggeredPeak_filter_string = 'triggeredDelay';
	elseif triggeredPeak_filter == 5
		% ind_cell = strfind(peakCategory, 'rebound'); % cell index of peakCategory containing '-rebound' string
		% ind_row_discard = find(cellfun(@isempty, ind_cell)); % convert ind_cell to array. Index of peak_category without '-rebound'
		% peak_info_sheet(ind_row_discard, :) = [];

		ind_cell = strcmp('rebound', peakCategory);
		ind_row_discard = find(ind_cell==0);
		peak_info_sheet(ind_row_discard, :) = [];
		triggeredPeak_filter_string = 'rebound';
	elseif triggeredPeak_filter == 0
		triggeredPeak_filter_string = 'AllPeaks'; 
	end

	total_cell_num = cell_num_count;
	% total_peak_num = sheet_fill_count-1;
	total_peak_num = size(peak_info_sheet, 1);

	if size(peak_info_sheet.riseDuration, 1) <= 2
		display('Less then 2 peaks found in this category. Not enough for plot')
	else
		
		if nargin >= 2
			if plot_analysis == 1 || plot_analysis == 2 
				% calculate proper bin number according to The Freedman-Diaconis rule
				% h=2×IQR×n^(−1/3), bin+number = (max−min)/h
				iqr_rise = iqr(peak_info_sheet{:, 'riseDuration'});
				bin_width_rise = 2*iqr_rise*total_peak_num^(1/3);
				bin_num_rise = (max(peak_info_sheet{:, 'riseDuration'})-min(peak_info_sheet{:, 'riseDuration'}))/bin_width_rise;
				bin_num_rise = ceil(bin_num_rise);

				iqr_decay = iqr(peak_info_sheet{:, 'decayDuration'});
				bin_width_decay = 2*iqr_decay*total_peak_num^(1/3);
				bin_num_decay = (max(peak_info_sheet{:, 'decayDuration'})-min(peak_info_sheet{:, 'decayDuration'}))/bin_width_decay;
				bin_num_decay = ceil(bin_num_decay);

				iqr_transient = iqr(peak_info_sheet{:, 'wholeDuration'});
				bin_width_transient = 2*iqr_transient*total_peak_num^(1/3);
				bin_num_transient = (max(peak_info_sheet{:, 'wholeDuration'})-min(peak_info_sheet{:, 'wholeDuration'}))/bin_width_transient;
				bin_num_transient = ceil(bin_num_transient);

				iqr_peakmag = iqr(peak_info_sheet{:, 'peakAmp'});
				bin_width_peakmag = 2*iqr_peakmag*total_peak_num^(1/3);
				bin_num_peakmag = (max(peak_info_sheet{:, 'peakAmp'})-min(peak_info_sheet{:, 'peakAmp'}))/bin_width_peakmag;
				bin_num_peakmag = ceil(bin_num_peakmag);

				iqr_peakslope = iqr(peak_info_sheet{:, 'peakSlope'});
				bin_width_peakslope = 2*iqr_peakslope*total_peak_num^(1/3);
				bin_num_peakslope = (max(peak_info_sheet{:, 'peakSlope'})-min(peak_info_sheet{:, 'peakSlope'}))/bin_width_peakslope;
				bin_num_peakslope = ceil(bin_num_peakslope);

				% use the self-decided bin number
				bin_num_rise = 40;
				bin_num_decay = 40;
				bin_num_transient = 40;
				bin_num_peakmag = 40;
				bin_num_peakslope = 200;
				bin_num_peakslope_normhp = 200;
				bin_num_peak_zscore = 40;
				bin_num_peak_norm_hp = 40;
				bin_num_rise_rela2stim = 40;

				str_fn = [peak_stim{1}, '-', triggeredPeak_filter_string];

				close all
				h = figure(1);
				set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
				subplot(2, 3, 1);
				
				histogram(peak_info_sheet{:, 'riseDuration'}, bin_num_rise); % plot rise duration
				title('peak rise duration', 'FontSize', 16);
				subplot(2, 3, 2);
				histogram(peak_info_sheet{:, 'decayDuration'}, bin_num_decay); % plot decay duration
				title('Peak decay duration', 'FontSize', 16);
				% subplot(2, 3, 3);
				% histogram(peak_info_sheet{:, 7}, bin_num_transient); % plot transient duration
				% title('Calcium transient duration', 'FontSize', 16); 
				subplot(2, 3, 3);
				histogram(peak_info_sheet{:, 'peakAmp'}, bin_num_peakmag); % peak_mag
				title('Peak amp', 'FontSize', 16);
				subplot(2, 3, 4);
				histogram(peak_info_sheet{:, 'peakSlope_normhp'}, bin_num_peakslope_normhp); % peak_slope
				title('Peak slope normhp', 'FontSize', 16);
				% subplot(2, 3, 5);
				% histogram(peak_info_sheet{:, 'peakZscore'}, bin_num_peak_zscore); % peak zscore
				% title('Peak zscore', 'FontSize', 16);
				subplot(2, 3, 5);
				histogram(peak_info_sheet{:, 'peakNormHP'}, bin_num_peak_norm_hp); % peak normalized to std of highpassed data
				title('Peak norm HighpassStd', 'FontSize', 16);
				subplot(2, 3, 6);
				histogram(peak_info_sheet{:, 'riseTimeRelative2Stim'}, bin_num_rise_rela2stim); % peak normalized to std of highpassed data
				title('Time diff - stimulation start and rise of peak', 'FontSize', 16);
				sgtitle(['nVoke analysis - Histograms ', str_fn], 'Interpreter', 'none');


				cor = figure(2);
				set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
				subplot(2, 3, 1);
				corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakAmp], 'varNames', {'RiseT', 'PeakM'});
				% subplot(2, 3, 2);
				% corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakZscore], 'varNames', {'RiseT', 'PeakMzscore'});
				subplot(2, 3, 2);
				corrplot([peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP], 'varNames', {'RiseT', 'PMnorm'});
				subplot(2, 3, 3);
				corrplot([peak_info_sheet.peakAmp, peak_info_sheet.peakSlope], 'varNames', {'PeakM', 'Slope'});
				% subplot(2, 3, 5);
				% corrplot([peak_info_sheet.peakZscore, peak_info_sheet.peakSlope], 'varNames', {'PeakMzscore', 'Slope'});
				subplot(2, 3, 4);
				corrplot([peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope], 'varNames', {'PMnorm', 'Slope'});

				if nostim == false % if peak classification is nostim
					if isempty(find(peak_info_sheet.riseTimeRelative2Stim)) % if all transients start to rise just at the stimulation time, skip plots below
					else
						subplot(2, 3, 5);
						corrplot([peak_info_sheet.riseDuration, peak_info_sheet.riseTimeRelative2Stim], 'varNames', {'RiseT', 'RRela2Stim'});
						subplot(2, 3, 6);
						corrplot([peak_info_sheet.riseTimeRelative2Stim, peak_info_sheet.peakSlope], 'varNames', {'RRela2Stim', 'Slope'});
					end
				end
				sgtitle(['nVoke analysis - corralations ', str_fn], 'Interpreter', 'none');

				max_riseT = max(peak_info_sheet.riseDuration);
				max_peakAmp = max(peak_info_sheet.peakAmp);
				max_peakSlope = max(peak_info_sheet.peakSlope);
				max_peakSlope_normhp = max(peak_info_sheet.peakSlope_normhp);
				max_peakAmpzscore = max(peak_info_sheet.peakZscore);
				max_PeakAmpNormHp = max(peak_info_sheet.peakNormHP);

				s = figure(4);
				scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakAmp, peak_info_sheet.peakSlope)
				% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
				xlim([0 (max_riseT+0.5)])
				ylim([0 (max_peakAmp+0.1)])
				zlim([0 (max_peakSlope+0.05)])
				xlabel('RiseT', 'FontSize', 16)
				ylabel('PeakAmp', 'FontSize', 16)
				zlabel('Slope', 'FontSize', 16)
				title(['nVoke analysis - scatter ', str_fn], 'FontSize', 16)

				s2 = figure(5);
				scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakZscore, peak_info_sheet.peakSlope)
				% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
				xlim([0 (max_riseT+0.5)])
				ylim([0 (max_peakAmpzscore+1)])
				zlim([0 (max_peakSlope+0.05)])
				xlabel('RiseT', 'FontSize', 16)
				ylabel('PeakAmpzscore', 'FontSize', 16)
				zlabel('Slope', 'FontSize', 16)
				title(['nVoke analysis - scatter ', str_fn], 'FontSize', 16)

				s3 = figure(6);
				scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope)
				% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
				xlim([0 (max_riseT+0.5)])
				ylim([0 (max_PeakAmpNormHp+5)])
				zlim([0 (max_peakSlope+0.05)])
				xlabel('RiseT', 'FontSize', 16)
				ylabel('PeakAmpNormHp', 'FontSize', 16)
				zlabel('Slope', 'FontSize', 16)
				title(['nVoke analysis - scatter ', str_fn], 'FontSize', 16)

				s4 = figure(7);
				scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope_normhp)
				% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
				xlim([0 (max_riseT+0.5)])
				ylim([0 (max_PeakAmpNormHp+5)])
				zlim([0 (max_peakSlope_normhp+0.05)])
				xlabel('RiseT', 'FontSize', 16)
				ylabel('PeakAmpNormHp', 'FontSize', 16)
				zlabel('SlopeNormhp', 'FontSize', 16)
				title(['nVoke analysis - scatter ', str_fn], 'FontSize', 16)

				if triggeredPeak_filter == 0
					Trig_peak_str = ['Trig-Peak (n=', num2str(peak_fq_numTrig), ')'];
					trigDelay_peak_str = ['TrigDelay-Peak (n=', num2str(peak_fq_numTrigDelay), ')'];
					Rebound_peak_str = ['Rebound-Peak (n=', num2str(peak_fq_numRebound), ')'];
					Other_peak_str = ['Other-Peak (n=', num2str(peak_fq_numOther), ')'];
					peak_cat = categorical({Trig_peak_str, trigDelay_peak_str, Rebound_peak_str, Other_peak_str});
					peak_fq_plot = [peak_fq_trig*100 peak_fq_trigDelay*100 peak_fq_rebound*100 peak_fq_other*100];
					s5 = figure(8);
					bar(peak_cat, peak_fq_plot)
					ylabel('peakFrequency x 100', 'FontSize', 16)
					title(['nVoke peak frequency ', str_fn])
				end


				if plot_analysis == 2 && ~isempty(figfolder)
					% figfile_histo = [triggeredPeak_filter_string, '_nVoke event analysis - Histograms'];
					% figfile_corr = [triggeredPeak_filter_string, '_nVoke event analysis - corralations'];
					% figfile_scatter = [triggeredPeak_filter_string, '_nVoke event analysis - scatter'];
					% % figfile_corr2 = [triggeredPeak_filter_string, '_nVoke event analysis - corralations2'];
					% figfile_scatter2 = [triggeredPeak_filter_string, '_nVoke event analysis - scatter2'];
					% figfile_scatter3 = [triggeredPeak_filter_string, '_nVoke event analysis - scatter3'];
					% figfile_scatter4 = [triggeredPeak_filter_string, '_nVoke event analysis - scatter4'];
					% figfile_fqbar = [triggeredPeak_filter_string, '_nVoke event analysis - peak_fq'];

					figfile_histo = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - Histograms'];
					figfile_corr = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - corralations'];
					figfile_scatter = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - scatter'];
					% figfile_corr2 = [peak_info_group.group, ' nVoke - corralations2'];
					figfile_scatter2 = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - scatter2'];
					figfile_scatter3 = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - scatter3'];
					figfile_scatter4 = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - scatter4'];
					figfile_fqbar = [datestr(datetime('now'), 'yyyymmdd'), ' ',str_fn, ' nVoke - peakFrequency'];


					figfullpath_histo = fullfile(figfolder,figfile_histo);
					figfullpath_corr = fullfile(figfolder,figfile_corr);
					figfullpath_scatter = fullfile(figfolder,figfile_scatter);
					% figfullpath_corr2 = fullfile(figfolder,figfile_corr2);
					figfullpath_scatter2 = fullfile(figfolder,figfile_scatter2);
					figfullpath_scatter3 = fullfile(figfolder,figfile_scatter3);
					figfullpath_scatter4 = fullfile(figfolder,figfile_scatter4);
					figfullpath_fqbar = fullfile(figfolder, figfile_fqbar);

					savefig(h, figfullpath_histo);
					savefig(cor, figfullpath_corr);
					savefig(s, figfullpath_scatter);
					% savefig(cor2, figfullpath_corr2);
					savefig(s2, figfullpath_scatter2);
					savefig(s3, figfullpath_scatter3);
					savefig(s4, figfullpath_scatter4);

					saveas(h, figfullpath_histo,'jpg');
					saveas(cor, figfullpath_corr,'jpg');
					saveas(s, figfullpath_scatter,'jpg');
					% saveas(cor2, figfullpath_corr2,'jpg');
					saveas(s2, figfullpath_scatter2,'jpg');
					saveas(s3, figfullpath_scatter3,'jpg');
					saveas(s4, figfullpath_scatter4,'jpg');

					saveas(h, figfullpath_histo,'svg');
					saveas(cor, figfullpath_corr,'svg');
					saveas(s, figfullpath_scatter,'svg');
					% saveas(cor2, figfullpath_corr2,'svg');
					saveas(s2, figfullpath_scatter2,'svg');
					saveas(s3, figfullpath_scatter3,'svg');
					saveas(s4, figfullpath_scatter4,'svg');

					saveas(h, figfullpath_histo,'fig');
					saveas(cor, figfullpath_corr,'fig');
					saveas(s, figfullpath_scatter,'fig');
					% saveas(cor2, figfullpath_corr2,'fig');
					saveas(s2, figfullpath_scatter2,'fig');
					saveas(s3, figfullpath_scatter3,'fig');
					saveas(s4, figfullpath_scatter4,'fig');

					if triggeredPeak_filter == 0
						savefig(s5, figfullpath_fqbar);
						saveas(s5, figfullpath_fqbar,'jpg');
						saveas(s5, figfullpath_fqbar,'fig');
					end
				end

			end
		end
	end
end

varargout{1} = total_cell_num;
varargout{2} = total_peak_num;

end


