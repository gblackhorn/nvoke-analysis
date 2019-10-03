function [peak_info_sheet, varargout] = nvoke_event_calc(ROIdata, plot_analysis)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
% varargout{1} = total_cell_num;
% varargout{2} = total_peak_num;
%
% [peak_info_sheet, total_cell_num, total_peak_num] = nvoke_event_calc(ROIdata, 1)

if plot_analysis == 2
	figfolder = uigetdir('G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data\peaks',...
		'Select a folder to save figures');
end

recording_num = size(ROIdata, 1);
total_peak_num = 0;
for rn = 1:recording_num
	roi_num = size(ROIdata{rn, 3}, 2);
	for roi_n = 1:roi_num
		peak_num = length(ROIdata{rn,3}{3, roi_n}{1, 1}{:, 1}); % number of peaks in 1 roi in 1 recording
		total_peak_num = total_peak_num+peak_num;
	end
end

peak_info_sheet = zeros(total_peak_num, 7);
sheet_fill_count = 1;
cell_num_count = 0;
for rn = 1:recording_num
	recording_name = ROIdata{rn, 1};
	recording_code = rn;
	roi_num = size(ROIdata{rn, 3}, 2);
	for roi_n = 1:roi_num
		roi_name = ROIdata{rn,3}.Properties.VariableNames{roi_n};
		roi_code = roi_n-1;
		peak_start = ROIdata{rn,3}{3, roi_n}{1, 1}{:, 6}; % time points of peak start
		peak_end = ROIdata{rn,3}{3, roi_n}{1, 1}{:, 7};
		rise_duration = ROIdata{rn,3}{3, roi_n}{1, 1}{:, 8};
		decay_duration = ROIdata{rn,3}{3, roi_n}{1, 1}{:, 9};
		peak_amp = ROIdata{rn,3}{3, roi_n}{1, 1}{:, 10}; % relative one
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


		sheet_fill_count = sheet_fill_count+length(peak_start);
	end
	cell_num_count = cell_num_count+roi_num;
end

total_cell_num = cell_num_count;
total_peak_num = sheet_fill_count-1;

if nargin == 2
	if plot_analysis == 1 || 2 
		iqr_rise = iqr(peak_info_sheet(:, 5));
		bin_width_rise = 2*iqr_rise*total_peak_num^(1/3);
		bin_num_rise = (max(peak_info_sheet(:, 5))-min(peak_info_sheet(:, 5)))/bin_width_rise;
		bin_num_rise = ceil(bin_num_rise);

		iqr_decay = iqr(peak_info_sheet(:, 6));
		bin_width_decay = 2*iqr_decay*total_peak_num^(1/3);
		bin_num_decay = (max(peak_info_sheet(:, 6))-min(peak_info_sheet(:, 6)))/bin_width_decay;
		bin_num_decay = ceil(bin_num_decay);

		iqr_peakmag = iqr(peak_info_sheet(:, 8));
		bin_width_peakmag = 2*iqr_peakmag*total_peak_num^(1/3);
		bin_num_peakmag = (max(peak_info_sheet(:, 8))-min(peak_info_sheet(:, 8)))/bin_width_peakmag;
		bin_num_peakmag = ceil(bin_num_peakmag);


		close all
		h = figure(1);
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
		subplot(2, 2, 1);
		
		histogram(peak_info_sheet(:, 5), 80); % plot rise duration
		title('peak rise duration');
		subplot(2, 2, 2);

		histogram(peak_info_sheet(:, 6), 80); % plot decary duration
		title('Peak decay duration');
		subplot(2, 2, 3);
		histogram(peak_info_sheet(:, 7), 80); % plot transient duration
		title('Calcium transient duration'); 
		subplot(2, 2, 4);
		histogram(peak_info_sheet(:, 8), 80); % peak_mag
		title('Peak amp');
		sgtitle('nVoke event analysis - Histograms ', 'Interpreter', 'none');

		s = figure(2);
		set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
		subplot(2, 2, 1);
		corrplot(peak_info_sheet(:, [5, 8]), 'varNames', {'RiseT', 'PeakM'});
		subplot(2, 2, 2);
		corrplot(peak_info_sheet(:, [6, 8]), 'varNames', {'DecayT', 'PeakM'});
		subplot(2, 2, 3);
		corrplot(peak_info_sheet(:, [7, 8]), 'varNames', {'WholeT', 'PeakM'});
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


