% 1. Process nVoke recorded files in recording folder: PP, BP, MC and DFF. Copy these files and GPIO
% info to project folder
nvoke_file_process;

% 2. Draw ROIs with Inscopix Data Processing Software (IDPS)
% 	- Export ROI info as .csv
% 	- Export GPIO info as .csv if exists
% 	- Check each recording with plot app: 'D:\guoda\Documents\MATLAB\Codes\nvoke-analysis\plot_roi_gpio_App.mlapp'
		plot_roi_gpio_App.mlapp

% 3. Convert ROI info to matlab file (.m). Copy ROI info (csv files) to analysis folder, and run this
% function
[ROIdata, recording_num, cell_num] = ROIinfo2matlab;
[ROIdata, recording_num, cell_num] = ROI_matinfo2matlab

%%
% 4. Check data with plot function 
plot_save = 1; % 0-no plot. 1-plot. 2-plot and save
% pause_plot = 1; % pause after plot of one recording
pause_plot = 0; % plot without pause

[ROIdata_peakevent] = nvoke_event_detection(ROIdata,plot_save, pause_plot); % plot with pause. (ROIdata, 2, 1) plot and save with pause

%%
% 5. Delete bad/usless cells in ROIdata generated by previous steps. Check data with plot function again
plot_save = 1; % 0-no plot. 1-plot. 2-plot and save
% pause_plot = 1; % pause after plot of one recording
pause_plot = 0; % plot without pause


[modified_ROIdata] = nvoke_correct_peakdata(ROIdata_peakevent,plot_save,pause_plot); 

%%
% 6. Check peaks and their start and end point. Manully correct these numbers and go through step 5 function.
plot_save = 2; % 0-no plot. 1-plot. 2-plot and save
% pause_plot = 1; % pause after plot of one recording
pause_plot = 1; % plot without pause
[modified_ROIdata] = nvoke_correct_peakdata(modified_ROIdata,plot_save,pause_plot); % save plots with pauses 

%%
% 7. Rasterplot
[rec, peak_table] = ctraster(ROIdata_peakevent);
[rec, peak_table] = ctraster(ROIdata_peakevent, 5, 1); % ctraster(Input, sort_col, save_plot, stim_duration, pre_stim_duration, post_stim_duration)
													   % sort_col: 5-peakTotal, 6-prePeak, 7-peakDuringStim, 8-postPeak, 
													   % 9-prePeakDpeakTotal, 10-peakDuringStimDpeakTotal, 11-postPeakDpeakTotal
for sortn = 6:15
	close all
    [rec, peaktable]=ctraster(ROIdata_peakevent, sortn, 1);
end	

%%
% 8. Calculate peak amplitude, rise and decay duration. Plot correlations
plot_analysis = 2; % 0-no plot. 1-plot. 2-plot and save
[peak_info_sheet, total_cell_num, total_peak_num] = nvoke_event_calc(modified_ROIdata, plot_analysis);