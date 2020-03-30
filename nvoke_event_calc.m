function [peak_info_sheet, varargout] = nvoke_event_calc(ROIdata, plot_analysis)
% Analyse calcium transient events: amplitude, rise and decay duration, whole event duration
%   Detailed explanation goes here
% varargout{1} = total_cell_num;
% varargout{2} = total_peak_num;
%
% [peak_info_sheet, total_cell_num, total_peak_num] = nvoke_event_calc(ROIdata, 1)

if plot_analysis == 2
	figfolder = uigetdir('G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\peaks',...
		'Select a folder to save figures');
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
for rn = 1:recording_num
	roi_num = size(ROIdata{rn, 5}, 2);
	for roi_n = 1:roi_num
		peak_num = size(ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}, 1); % number of peaks in 1 roi in 1 recording
		total_peak_num = total_peak_num+peak_num;
	end
end

peak_info_sheet = zeros(total_peak_num, 7);
sheet_fill_count = 1;
cell_num_count = 0;
for rn = 1:recording_num
	recording_name = ROIdata{rn, 1};
	recording_code = rn;
	roi_num = size(ROIdata{rn, 5}, 2);
	for roi_n = 1:roi_num
		roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_n};
		roi_code = roi_n-1;
		peak_start = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}{:, 6}; % time points of peak start
		peak_end = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}{:, 7};
		rise_duration = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}{:, 8};
		decay_duration = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}{:, 9};
		peak_amp = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}{:, 10}; % relative one
		peak_slope = ROIdata{rn,5}{peakinfo_row_name, roi_n}{1, 1}{:, 17}; % peak slope
		transient_duration = rise_duration+decay_duration;

		recording_code_sheet = ones(size(peak_start))*recording_code;
		roi_code_sheet = ones(size(peak_start))*roi_code;
		sheet_start = sheet_fill_count;
		sheet_end = sheet_fill_count+length(peak_start)-1;

		peak_info_sheet(sheet_start:sheet_end, 1) = recording_code_sheet;
		peak_info_sheet(sheet_start:sheet_end, 2) = roi_code_sheet;
		peak_info_sheet(sheet_start:sheet_end, 3) = peak_start;
		peak_info_sheet(sheet_start:sheet_end, 4) = peak_end;
		peak_info_sheet(sheet_start:sheet_end, 5) = rise_duration;
		peak_info_sheet(sheet_start:sheet_end, 6) = decay_duration;
		peak_info_sheet(sheet_start:sheet_end, 7) = transient_duration;
		peak_info_sheet(sheet_start:sheet_end, 8) = peak_amp;
		peak_info_sheet(sheet_start:sheet_end, 9) = peak_slope;


		sheet_fill_count = sheet_fill_count+length(peak_start);
	end
	cell_num_count = cell_num_count+roi_num;
end

total_cell_num = cell_num_count;
total_peak_num = sheet_fill_count-1;

if nargin == 2
	if plot_analysis == 1 || 2 
		% calculate proper bin number according to The Freedman-Diaconis rule
		% h=2×IQR×n^(−1/3), bin+number = (max−min)/h
		iqr_rise = iqr(peak_info_sheet(:, 5));
		bin_width_rise = 2*iqr_rise*total_peak_num^(1/3);
		bin_num_rise = (max(peak_info_sheet(:, 5))-min(peak_info_sheet(:, 5)))/bin_width_rise;
		bin_num_rise = ceil(bin_num_rise);

		iqr_decay = iqr(peak_info_sheet(:, 6));
		bin_width_decay = 2*iqr_decay*total_peak_num^(1/3);
		bin_num_decay = (max(peak_info_sheet(:, 6))-min(peak_info_sheet(:, 6)))/bin_width_decay;
		bin_num_decay = ceil(bin_num_decay);

		iqr_transient = iqr(peak_info_sheet(:, 7));
		bin_width_transient = 2*iqr_transient*total_peak_num^(1/3);
		bin_num_transient = (max(peak_info_sheet(:, 7))-min(peak_info_sheet(:, 7)))/bin_width_transient;
		bin_num_transient = ceil(bin_num_transient);

		iqr_peakmag = iqr(peak_info_sheet(:, 8));
		bin_width_peakmag = 2*iqr_peakmag*total_peak_num^(1/3);
		bin_num_peakmag = (max(peak_info_sheet(:, 8))-min(peak_info_sheet(:, 8)))/bin_width_peakmag;
		bin_num_peakmag = ceil(bin_num_peakmag);

		iqr_peakslope = iqr(peak_info_sheet(:, 9));
		bin_width_peakslope = 2*iqr_peakslope*total_peak_num^(1/3);
		bin_num_peakslope = (max(peak_info_sheet(:, 9))-min(peak_info_sheet(:, 9)))/bin_width_peakslope;
		bin_num_peakslope = ceil(bin_num_peakslope);

		% use the self-decided bin number
		bin_num_rise = 40;
		bin_num_decay = 40;
		bin_num_transient = 40;
		bin_num_peakmag = 40;
		bin_num_peakslope = 200;


		close all
		h = figure(1);
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
		subplot(2, 3, 1);
		
		histogram(peak_info_sheet(:, 5), bin_num_rise); % plot rise duration
		title('peak rise duration');
		subplot(2, 3, 2);

		histogram(peak_info_sheet(:, 6), bin_num_decay); % plot decay duration
		title('Peak decay duration');
		subplot(2, 3, 3);
		histogram(peak_info_sheet(:, 7), bin_num_transient); % plot transient duration
		title('Calcium transient duration'); 
		subplot(2, 3, 4);
		histogram(peak_info_sheet(:, 8), bin_num_peakmag); % peak_mag
		title('Peak amp');
		subplot(2, 3, 5);
		histogram(peak_info_sheet(:, 9), bin_num_peakslope); % peak_slope
		title('Peak slope');
		sgtitle('nVoke event analysis - Histograms ', 'Interpreter', 'none');

		s = figure(2);
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
		subplot(2, 3, 1);
		corrplot(peak_info_sheet(:, [5, 8]), 'varNames', {'RiseT', 'PeakM'});
		subplot(2, 3, 2);
		corrplot(peak_info_sheet(:, [6, 8]), 'varNames', {'DecayT', 'PeakM'});
		subplot(2, 3, 3);
		corrplot(peak_info_sheet(:, [7, 8]), 'varNames', {'WholeT', 'PeakM'});
		subplot(2, 3, 4);
		corrplot(peak_info_sheet(:, [8, 9]), 'varNames', {'PeakM', 'Slope'});
		subplot(2, 3, 5);
		corrplot(peak_info_sheet(:, [6, 9]), 'varNames', {'DecayT', 'Slope'});
		subplot(2, 3, 6);
		scatter3(peak_info_sheet(:, 6), peak_info_sheet(:, 8), peak_info_sheet(:, 9))
		xlabel('DecayT')
		ylabel('PeakM')
		zlabel('Slope')
		sgtitle('nVoke event analysis - corralations ', 'Interpreter', 'none');


		if plot_analysis == 2 && ~isempty(figfolder)
			figfile_histo = ['nVoke event analysis - Histograms'];
			figfile_corr = ['nVoke event analysis - corralations'];
			figfullpath_histo = fullfile(figfolder,figfile_histo);
			figfullpath_corr = fullfile(figfolder,figfile_corr);

			savefig(h, figfullpath_histo);
			savefig(s, figfullpath_corr);

			saveas(h, figfullpath_histo,'jpg');
			saveas(s, figfullpath_corr,'jpg');
		end

	end
end

varargout{1} = total_cell_num;
varargout{2} = total_peak_num;

end


