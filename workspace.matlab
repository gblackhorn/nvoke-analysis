% check all recordings in ROIdata variable, plot and save as .fig
recording_num = size(ROIdata, 1);
for m = 1:recording_num

	single_recording = ROIdata{m,2};
	[peak_loc_mag_table] = nvoke_event_detection(single_recording,1);
	gcf;
	sgtitle(ROIdata{m, 1}, 'Interpreter', 'none');
	ROIdata{m,3} = peak_loc_mag_table;
	% disp('Press any key to continue')
	% pause;

	figfile = [ROIdata{m,1}(1:(end-3)), 'fig'];
	figfolder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data\peaks';
	figfullpath = fullfile(figfolder,figfile);
	savefig(gcf, figfullpath);
end

%%
single_recording = ROIdata{m,2};
	peak_loc_mag = nvoke_event_detection(single_recording,1);
	gcf;
	sgtitle(ROIdata{m, 1}, 'Interpreter', 'none');
	ROIdata{m,3} = peak_loc_mag;

m = m+1;

%=======================================
% save all .fig file as .jpg
close all
figfiles = dir('G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data\peaks\*.fig');
for n = 1:numel(figfiles)
	figfile_fullpath = fullfile(figfiles(n).folder, figfiles(n).name);
	figfile = openfig(figfile_fullpath);
	jpgfile_name = [figfiles(n).name(1:(end-3)), 'jpg'];
	jpgfile_fullpath = fullfile(figfiles(n).folder, jpgfile_name);
	saveas(figfile, jpgfile_fullpath);
	close all
end


time_info = table2array(single_recording(:, 1));
data_points = table2array(single_recording(1:10, 2));
time_duration = time_info(10) - time_info(1);


%==========
close all
figure
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]);
subplot(2, 2, 1);
corrplot(peak_info_sheet(:, [5, 8]))
subplot(2, 2, 2);
corrplot(peak_info_sheet(:, [6, 8]))
subplot(2, 2, 3);
corrplot(peak_info_sheet(:, [7, 8]))


%==================
find(strcmp('C07', ROIdata{6, 3}.Properties.VariableNames))


recording_rawdata = ROIdata{2,2};
roi_name = ROIdata{2,3}.Properties.VariableNames{2};
roi_rawdata = recording_rawdata(find(strcmp(roi_name, recording_rawdata.Properties.VariableNames)));


find(recording_timeinfo == 5.8)
[min closestIndex] = min(abs(recording_timeinfo-5.8))

rn = 2; peakinfo_row = 3; roi_n =2; pn = 1

peak_loc_time = ROIdata{rn, 3}{peakinfo_row, roi_n}{:, :}.('Rise_start_s_')

[modified_ROIdata] = nvoke_correct_peakdata(ROIdata,1,1)



% ==============================
% detect event and plot with pause
nvoke_event_detection(ROIdata,1, 1)
% detect event and plot with pause, save figures
nvoke_event_detection(ROIdata,1, 2)


%============================
close all
% h1 = figure(1);
poster_folder = 'D:\guoda\Documents\Workspace\Script\Poster\2019_Gordon\figures\nvoke';

h1 = histogram(peak_info_sheet_ventral(:, 5), 10);
hold
h2 = histogram(peak_info_sheet_dorsal(:, 5), 10);
title('rise')
h1.Normalization = 'probability';
h1.BinWidth = 0.25;
h2.Normalization = 'probability';
h2.BinWidth = 0.25;

rise_name = 'histo_rise_ventral_dorsal';
rise_fig = fullfile(poster_folder,rise_name);
saveas(gcf, rise_fig, 'fig');
saveas(gcf, rise_fig, 'jpg');
saveas(gcf, rise_fig, 'svg');

% h2 = figure(2);
close all
h1 = histogram(peak_info_sheet_ventral(:, 6), 10);
hold
h2 = histogram(peak_info_sheet_dorsal(:, 6), 10);
title('decay')
h1.Normalization = 'probability';
h1.BinWidth = 0.25;
h2.Normalization = 'probability';
h2.BinWidth = 0.25;

decay_name = 'histo_decay_ventral_dorsal';
decay_fig = fullfile(poster_folder,decay_name);
saveas(gcf, decay_fig, 'fig');
saveas(gcf, decay_fig, 'jpg');
saveas(gcf, decay_fig, 'svg');

% h3 = figure(3);
close all
h1= histogram(peak_info_sheet_ventral(:, 7), 10);
hold
h2= histogram(peak_info_sheet_dorsal(:, 7), 10);
title('whole')
h1.Normalization = 'probability';
h1.BinWidth = 0.25;
h2.Normalization = 'probability';
h2.BinWidth = 0.25;

whole_name = 'histo_whole_ventral_dorsal';
whole_fig = fullfile(poster_folder,whole_name);
saveas(gcf, whole_fig, 'fig');
saveas(gcf, whole_fig, 'jpg');
saveas(gcf, whole_fig, 'svg');

% h4 = figure(4);
close all
h1 = histogram(peak_info_sheet_ventral(:, 8), 10);
hold
h2 = histogram(peak_info_sheet_dorsal(:, 8), 10);
title('peak')
h1.Normalization = 'probability';
h1.BinWidth = 0.25;
h2.Normalization = 'probability';
h2.BinWidth = 0.25;

peak_name = 'histo_peak_ventral_dorsal';
peak_fig = fullfile(poster_folder,peak_name);
saveas(gcf, peak_fig, 'fig');
saveas(gcf, peak_fig, 'jpg');
saveas(gcf, peak_fig, 'svg');




h1.Normalization = 'probability';
h1.BinWidth = 0.25;
h2.Normalization = 'probability';
h2.BinWidth = 0.25;
h3.Normalization = 'probability';
h3.BinWidth = 0.25;
h4.Normalization = 'probability';
h4.BinWidth = 0.25;




