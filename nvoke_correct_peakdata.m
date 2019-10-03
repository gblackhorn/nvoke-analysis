function [modified_ROIdata] = nvoke_correct_peakdata(ROIdata,plot_traces,pause_step)
% After manually discarding ROIs and correcting peak rise and fall point.
% Correct the rise_loc, decay_loc, etc.
% Input:
% 		- plot_traces: 1-plot, 2-plot and save
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
elseif nargin == 2
	if plot_traces == 1 || 2
		pause_step = 1;
	else
		pause_step = 0;
	end
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
	peakinfo_row = find(strcmp(peakinfo_row_name, ROIdata{rn, 3}.Properties.RowNames));
	recording_rawdata = ROIdata{rn,2};
	recording_timeinfo = recording_rawdata{:, 1}; % array not table
	recording_fr = 1/(recording_timeinfo(2)-recording_timeinfo(1));
    recording_code = rn;
	roi_num = size(ROIdata{rn, 3}, 2); % total roi numbers after handpick

	recording_highpassed = ROIdata{rn,2};
    recording_thresh = ROIdata{rn,2};
	recording_lowpassed = ROIdata{rn,2};

	for roi_n = 1:roi_num
		roi_name = ROIdata{rn,3}.Properties.VariableNames{roi_n};
		roi_rawdata_loc = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames));

		roi_rawdata = recording_rawdata{:, roi_rawdata_loc};
		roi_lowpasseddata = lowpass(roi_rawdata, lowpass_fpass, recording_fr);
		roi_highpassed = highpass(roi_rawdata, highpass_fpass, recording_fr);

		recording_highpassed{:, roi_rawdata_loc} = roi_highpassed;
		recording_lowpassed{:, roi_rawdata_loc} = roi_lowpasseddata;

		thresh = mean(roi_highpassed)+5*std(roi_highpassed);
		recording_thresh{:, roi_rawdata_loc} = ones(size(recording_timeinfo))*thresh;;

		peak_loc_time = ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Peak_loc_s_'); % peaks' time
		rise_start_time = ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Rise_start_s_');
		decay_stop_time = ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Decay_stop_s_');

		peak_num = length(peak_loc_time);
		for pn = 1:peak_num
			[min_peak closestIndex_peak] = min(abs(recording_timeinfo-peak_loc_time(pn)));
			[min_rise closestIndex_rise] = min(abs(recording_timeinfo-rise_start_time(pn)));
			[min_decay closestIndex_decay] = min(abs(recording_timeinfo-decay_stop_time(pn)));

			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Peak_loc')(pn) = closestIndex_peak;
			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Rise_start')(pn) = closestIndex_rise;
			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Decay_stop')(pn) = closestIndex_decay;

			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Peak_mag')(pn) = roi_lowpasseddata(closestIndex_peak);
			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Rise_duration_s_')(pn) = peak_loc_time(pn)-rise_start_time(pn);
			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('decay_duration_s_')(pn) = decay_stop_time(pn)-peak_loc_time(pn);

			peakmag_relative_rise = roi_lowpasseddata(closestIndex_peak)-roi_lowpasseddata(closestIndex_rise);
			peakmag_relative_decay = roi_lowpasseddata(closestIndex_peak)-roi_lowpasseddata(closestIndex_decay);
			ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Peak_mag_relative')(pn) = max(peakmag_relative_rise, peakmag_relative_decay);
		end
	end

	if nargin >= 2
		if plot_traces == 1 || 2
			plot_col_num = ceil(roi_num/5);
			plot_fig_num = ceil(plot_col_num/2);
			close all
			
			for p = 1:plot_fig_num % figure number
				peak_plot_handle(p) = figure (p);
				set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]

				for q = 1:2 % column num
					if (plot_col_num-(p-1)*2-q) > 0
							last_row = 5;
					else
							last_row = roi_num-(p-1)*10-(q-1)*5;
					end
					for m = 1:last_row
						roi_plot = (p-1)*10+(q-1)*5+m; % the number of roi to be plot
						roi_name = ROIdata{rn,3}.Properties.VariableNames{roi_plot}; % roi name ('C0, C1...')
						roi_col_loc_data = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames)); % the column number of this roi in recording_rawdata (ROI_table)
						roi_col_loc_cal = find(strcmp(roi_name, ROIdata{rn, 3}.Properties.VariableNames)); % the column number of this roi in recording_rawdata (ROI_table)

						roi_col_data = recording_rawdata{:, roi_col_loc_data}; % roi data 
						peak_time_loc = ROIdata{rn, 3}{1, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
						peak_value = ROIdata{rn, 3}{1, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

						roi_col_data_lowpassed = recording_lowpassed{:, roi_col_loc_data}; % roi data 
						peak_time_loc_lowpassed = ROIdata{rn, 3}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
						peak_value_lowpassed = ROIdata{rn, 3}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

						peak_rise_turning_loc = ROIdata{rn, 3}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Rise_start_s_');
						peak_rise_turning_value = roi_col_data_lowpassed(ROIdata{rn, 3}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Rise_start'));
						peak_decay_turning_loc = ROIdata{rn, 3}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Decay_stop_s_');
						peak_decay_turning_value = roi_col_data_lowpassed(ROIdata{rn, 3}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Decay_stop'));

						roi_col_data_highpassed = recording_highpassed{:, roi_col_loc_data}; % roi data 
						thresh_data = recording_thresh{:, roi_col_loc_data};

						sub_handle(roi_plot) = subplot(5, 2, q+(m-1)*2);
						plot(recording_timeinfo, roi_col_data, 'k') % plot original data
						hold on
						% plot(peak_time_loc, peak_value, 'ro', 'linewidth', 2) % plot peak marks
						% plot(recording_timeinfo, roi_col_data_highpassed, 'b') % plot highpass filtered data
						plot(recording_timeinfo, thresh_data, '--k'); % plot thresh hold line
						plot(recording_timeinfo, roi_col_data_lowpassed, 'm'); % plot lowpass filtered data
						plot(peak_time_loc_lowpassed, peak_value_lowpassed, 'yo', 'linewidth', 2) %plot lowpassed data peak marks
						plot(peak_rise_turning_loc, peak_rise_turning_value, '>b', peak_decay_turning_loc, peak_decay_turning_value, '<b', 'linewidth', 2) % plot start and end of transient, turning point
						set(get(sub_handle(roi_plot), 'YLabel'), 'String', roi_name);
						hold off

					end
				end
				sgtitle(ROIdata{rn, 1}, 'Interpreter', 'none');
				if plot_traces == 2 && ~isempty(figfolder)
					figfile = [ROIdata{rn,1}(1:(end-4)), '-handpick-', num2str(p), '.fig'];
					figfullpath = fullfile(figfolder,figfile);
					savefig(gcf, figfullpath);
					jpgfile_name = [figfile(1:(end-3)), 'jpg'];
					jpgfile_fullpath = fullfile(figfolder, jpgfile_name);
					saveas(gcf, jpgfile_fullpath);
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

