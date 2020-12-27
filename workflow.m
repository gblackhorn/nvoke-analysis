% set folders for different situation
if ispc
	HDD_folder_invivo = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\'; % to save peak_info_sheet var
	workspace_folder_invivo = 'D:\guoda\Documents\Workspace\Analysis\nVoke\Ventral_approach\processed mat files\'; % to save peak_info_sheet var
	HDD_folder_invitro = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_slice\'; % to save peak_info_sheet var
	workspace_folder_invitro = 'D:\guoda\Documents\Workspace\Analysis\nVoke\Slice\'; % to save peak_info_sheet var
	mat_folder_invivo = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\';
	mat_folder_invitro = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_slice\';
	exported_file_folder_invivo = 'G:\Workspace\Inscopix_Seagate\Projects\IO_GCaMP_IO_ChrimsonR_CN_ventral\ventral_exported_decon_demix'; % contain mat and csv files. used to prepare ROIdata var
elseif isunix
	HDD_folder_invivo = '';
	HDD_folder_invitro = '';
	workspace_folder_invivo = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
	workspace_folder_invitro = '/home/guoda/Documents/Workspace/Analysis/nVoke/Slice/';
	mat_folder_invivo = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
	mat_folder_invitro = '/home/guoda/Documents/Workspace/Analysis/nVoke/Slice/';
    exported_file_folder_invivo = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/ventral_exported_decon_demix_rawdata/';
end

%% ==================== 
% 1. Process nVoke recorded files in recording folder: PP, BP, MC and DFF. Copy these files and GPIO
% info to project folder
nvoke_file_process;

%% ==================== 
%2. Draw ROIs with Inscopix Data Processing Software (IDPS). Or process motion corrected tiff with CNMFe code
% 	- Export ROI info as .csv
% 	- Export GPIO info as .csv if exists
% 	- Check each recording with plot app: 'D:\guoda\Documents\MATLAB\Codes\nvoke-analysis\plot_roi_gpio_App.mlapp'
		plot_roi_gpio_App.mlapp

%% ====================
% 3. Convert ROI info to matlab file (.m). Copy ROI info (csv files) to analysis folder, and run this
% function
% [ROIdata, recording_num, cell_num] = ROIinfo2matlab; % for data without CNMFe process

[ROIdata, recording_num, cell_num] = ROI_matinfo2matlab; % for CNMFe processed data

%% ====================
% Add spatial information of ROIs from *results.mat to ROIdata, ROIdata_peakevent, or modified_ROIdata.
% func roimap.m needs this information to draw ROIs
% [mat_data_file_name, mat_folder_invivo] = uigetfile(mat_folder_invivo,...
% 	'Select a file containing ROIdata, ROIdata_peakevent or modified_ROIdata.');
% mat_data_file = fullfile(mat_folder_invivo, mat_data_file_name);
% display(['Load file: ', mat_data_file_name])
% ROIdata = load(mat_data_file);
ROIdata_backup = ROIdata; % ROIdata, ROIdata_peakevent, modified_ROIdata
num_rec = size(ROIdata, 1);  % number of recordings
exported_file_folder_invivo = uigetdir(exported_file_folder_invivo,...
	'Select a folder containing *results.mat exported by CNMFe code');
% cnmfe_result_file_info = dir(exported_file_folder_invivo, '\*results*.mat'); % a struct containing information of *results.mat files
for rn = 1:num_rec
	filename_stem = ROIdata{rn, 1}(1:25);
	% cnmfe_result_file_info = dir([exported_file_folder_invivo, '\', filename_stem, '*results*.mat']);
	cnmfe_result_file_info = dir(fullfile(exported_file_folder_invivo, [filename_stem, '*results*.mat']));
	cnmfe_file = fullfile(cnmfe_result_file_info(1).folder, cnmfe_result_file_info(1).name);
	load(cnmfe_file, 'results');
	ROIdata{rn, 2}.cnmfe_results = organize_extract_CNMFspacialInfo(results);
end


%% ====================
% 3. Convert in vitro calcium imaging info to matlab file (.m). 

sample_frequency = 40;
[ROIdata] = ROI_matinfo2matlab_invitro(sample_frequency); % for in vitro and CNMFe processed data
%%
%====================
% 4. Check data with plot function 
plot_save = 0; % 0-no plot. 1-plot. 2-plot and save
% pause_plot = 1; % pause after plot of one recording
subplot_roi = 1;
pause_plot = 0; % plot without pause
lowpass_fpass = 1; % ventral approach default: 1. slice default: 10
 
[ROIdata_peakevent] = nvoke_event_detection(ROIdata, plot_save, subplot_roi, pause_plot, lowpass_fpass); % plot with pause. (ROIdata, 2, 1) plot and save with pause

prompt_save_ROIdata_peakevent = 'Do you want to save ROIdata_peakevent? y/n [y]: ';
input_str = input(prompt_save_ROIdata_peakevent, 's');

if isempty(input_str)
	input_str = 'y';
end
if input_str == 'y'
	stimulation = input(['Input info including stimulation for the name of the file saving ROIdata_peakevent var [', ROIdata{1, 3}{:}, '] : '], 's');
	experiment = input(['Save the ROIdata_peakevent in "ventral_approach" folder (1) or in "slice" folder (2) [Default-1]: ']);
	if isempty(experiment)
		experiment = 1;
	end
	if experiment == 1
		HDD_folder = HDD_folder_invivo; % to save peak_info_sheet var
		workspace_folder = workspace_folder_invivo; % to save peak_info_sheet var
	elseif experiment == 2
		HDD_folder = HDD_folder_invitro; % to save peak_info_sheet var
		workspace_folder = workspace_folder_invitro; % to save peak_info_sheet var
	end
	
	ROIdata_peakevent_fn = ['ROIdata_peakevent_', datestr(datetime('now'), 'yyyymmdd'), '_', stimulation];
	if ispc
        HDD_path = fullfile(HDD_folder, ROIdata_peakevent_fn);
		save(HDD_path, 'ROIdata_peakevent');
		disp(['var ROIdata_peakevent was saved to file: ', HDD_path])
    end
    workspace_path = fullfile(workspace_folder, ROIdata_peakevent_fn);
	save(workspace_path, 'ROIdata_peakevent');
	disp(['var ROIdata_peakevent was saved to file: ', workspace_path])
end


%%
%====================
% manully delete bad ROIs
nvoke_data = ROIdata; % specify the variable containing all ROI_data
rec_row = 8; % specify recording number
roi_keep = [1]; % ROIs will be kept
ROI_num = width(ROIdata{rec_row, 2}.decon)-1;
disp(nvoke_data{rec_row, 1})
disp(['roi num: ', num2str(ROI_num)])
disp(nvoke_data{rec_row, 2}.decon.Properties.VariableNames)
roi_total = [1:ROI_num];

%
ROIdata_backup = ROIdata;
discard_ind = ismember(roi_total, roi_keep);
roiID = find(discard_ind==0); % specify roi needed to be deleted

% data_decon = nvoke_data{rec_row,2}.decon;
% data_raw = nvoke_data{rec_row,2}.raw;

nvoke_data{rec_row,2}.decon(:, (roiID+1)) = [];
nvoke_data{rec_row,2}.raw(:, (roiID+1)) = [];

ROIdata = nvoke_data;
disp(ROIdata{rec_row, 2}.decon.Properties.VariableNames)

% cd('/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files')
% data_decon(:, (roiID+1)) = [];
% data_raw(:, (roiID+1)) = [];

%%
%====================
% load roidata (ROIdata, ROIdata_peakevent, modified_ROIdata, etc.) from file
experiment = input(['Load mat file from "ventral_approach" folder (1) or in "slice" folder (2) [Default-1]: ']);
if isempty(experiment)
	experiment = 1;
end
if experiment == 1
	mat_folder = mat_folder_invivo;
elseif experiment == 2
	mat_folder = mat_folder_invitro;
end

[mat_fn, mat_folder]=uigetfile([mat_folder, '*.mat'],...
	'Select a mat file with roidata or peak info (generated by event_detection, correct_peakdata or even_cal) in it');
mat_path = fullfile(mat_folder, mat_fn);
if mat_fn~=0
	load(mat_path)
	mat_var_name = who('-file', mat_path);
	if ~exist('mat_loading_log', 'var')
		pslrn = 1; % mat_log_row_num
	else
		pslrn = size(mat_loading_log, 1)+1;
	end
	mat_loading_log{pslrn, 1} = mat_var_name{1};
	mat_loading_log{pslrn, 2} = mat_fn;
	mat_loading_log{pslrn, 3} = datestr(datetime('now'), 'yyyymmdd HH:MM:SS');
	disp([mat_loading_log{pslrn, 3}, ': var ', mat_var_name{1}, ' was loaded from file ', mat_fn])
end


%%
%====================
% 5. Delete bad/usless cells in ROIdata generated by previous steps. Check data with plot function again
plot_save = 2; % 0-no plot. 1-plot. 2-plot and save
% pause_plot = 1; % pause after plot of one recording
subplot_roi = 1;
pause_plot = 0; % plot with (1) or without (0) pause
lowpass_fpass = 1; % ventral approach default: 1. slice default: 10


[modified_ROIdata] = nvoke_correct_peakdata(ROIdata_peakevent,plot_save,subplot_roi,pause_plot,lowpass_fpass); 

prompt_save_modified_ROIdata = 'Do you want to save modified_ROIdata? y/n [y]: ';
input_str = input(prompt_save_modified_ROIdata, 's');
if isempty(input_str)
	input_str = 'y';
end
if input_str == 'y'
	stimulation = input(['Input info including stimulation for the name of the file saving modified_ROIdata var [', modified_ROIdata{1, 3}{:}, '] : '], 's');
	experiment = input(['Save the modified_ROIdata in "ventral_approach" folder (1) or in "slice" folder (2) [Default-1]: ']);
	if isempty(experiment)
		experiment = 1;
	end
	if experiment == 1
		HDD_folder = HDD_folder_invivo; % to save peak_info_sheet var
		workspace_folder = workspace_folder_invivo; % to save peak_info_sheet var
	elseif experiment == 2
		HDD_folder = HDD_folder_invitro; % to save peak_info_sheet var
		workspace_folder = workspace_folder_invitro; % to save peak_info_sheet var
	end
	modified_ROIdata_fn = ['modified_ROIdata_', datestr(datetime('now'), 'yyyymmdd'), '_', stimulation];
	if ispc
        HDD_path = fullfile(HDD_folder, modified_ROIdata_fn);
		save(HDD_path, 'modified_ROIdata');
		disp(['var modified_ROIdata was saved to file: ', HDD_path])
    end
    workspace_path = fullfile(workspace_folder, modified_ROIdata_fn);
	save(workspace_path, 'modified_ROIdata');
	disp(['var modified_ROIdata was saved to file: ', workspace_path])
end

%% ====================
% Manully correct rise and peak position
% correctRisePeak is compatible with modified_ROIdata. Should be good with ROIdata_peakevent as well 
close all
modified_ROIdata_backup = modified_ROIdata;
recNum = size(modified_ROIdata, 1);
for rn = 1:recNum
	recName =  modified_ROIdata{rn, 1};
	roiNum = size(modified_ROIdata{rn, 2}.raw, 2)-1;
	for roin = 1:roiNum
		close all
		roiCol = roin+1;
		roiName = modified_ROIdata{rn, 2}.raw.Properties.VariableNames{roiCol};

		disp([recName, ' - ', roiName]);

		rawTrace = modified_ROIdata{rn, 2}.raw{:, [1 roiCol]};
		deconTrace = modified_ROIdata{rn, 2}.decon{:, [1 roiCol]};
		lowpassTrace = modified_ROIdata{rn, 2}.lowpass{:, [1 roiCol]};
		peakInfo = modified_ROIdata{rn, 5};
		lowpassPeakInfo = peakInfo.(roiName){3};
		[lowpassPeakInfo_correct] = correctRisePeak(rawTrace, deconTrace, lowpassTrace, lowpassPeakInfo);
		modified_ROIdata{rn, 5}.(roiName){3} = lowpassPeakInfo_correct;
	end
end

%% ====================
% 6. Check peaks and their start and end point. Manully correct these numbers and go through step 5 function.
plot_save = 1; % 0-no plot. 1-plot. 2-plot and save
% pause_plot = 1; % pause after plot of one recording
subplot_roi = 1;
pause_plot = 1; % plot without pause
lowpass_fpass = 1; % ventral approach default: 1. slice default: 10

[modified_ROIdata] = nvoke_correct_peakdata(modified_ROIdata,plot_save,subplot_roi,pause_plot, lowpass_fpass); % save plots with pauses 

prompt_save_modified_ROIdata = 'Do you want to save modified_ROIdata? y/n [y]: ';
input_str = input(prompt_save_modified_ROIdata, 's');
if isempty(input_str)
	input_str = 'y';
end
if input_str == 'y'
	stimulation = input(['Input info including stimulation for the name of the file saving modified_ROIdata var [', modified_ROIdata{1, 3}{:}, '] : '], 's');
	experiment = input(['Save the modified_ROIdata in "ventral_approach" folder (1) or in "slice" folder (2) [Default-1]: ']);
	if isempty(experiment)
		experiment = 1;
	end
	if experiment == 1
		HDD_folder = HDD_folder_invivo; % to save peak_info_sheet var
		workspace_folder = workspace_folder_invivo; % to save peak_info_sheet var
	elseif experiment == 2
		HDD_folder = HDD_folder_invitro; % to save peak_info_sheet var
		workspace_folder = workspace_folder_invitro; % to save peak_info_sheet var
	end
	modified_ROIdata_fn = ['modified_ROIdata_', datestr(datetime('now'), 'yyyymmdd'), '_', stimulation];
	if ispc
        HDD_path = fullfile(HDD_folder, modified_ROIdata_fn);
		save(HDD_path, 'modified_ROIdata');
		disp(['var modified_ROIdata was saved to file: ', HDD_path])
    end
    workspace_path = fullfile(workspace_folder, modified_ROIdata_fn);
	save(workspace_path, 'modified_ROIdata');
	disp(['var modified_ROIdata was saved to file: ', workspace_path])
end
%%
%====================
% 7. Rasterplot
[rec, peak_table] = ctraster(ROIdata_peakevent);
[rec, peak_table] = ctraster(ROIdata_peakevent, 5, 0); % ctraster(Input, sort_col, save_plot, stim_duration, pre_stim_duration, post_stim_duration)
													   % sort_col: 5-peakTotal, 6-prePeak, 7-peakDuringStim, 8-postPeak, 
													   % 9-prePeakDpeakTotal, 10-peakDuringStimDpeakTotal, 11-postPeakDpeakTotal


save_plot = 0;
for sortn = 6:15
	close all
    [rec, peaktable]=ctraster(ROIdata_peakevent, sortn, save_plot);
end	

%%
%====================
% 8. Calculate peak amplitude, rise and decay duration. Plot correlations
plot_analysis = 2; % 0-no plot. 1-plot. 2-plot and save

% stimulation = 'ogled10s_fast_peak'; % to save peak_info_sheet var
stimulation = input(['Input info including stimulation for the name of the file saving modified_ROIdata var [', modified_ROIdata{1, 3}{:}, '] : '], 's');
experiment = input(['Save the peak_info_sheet in "ventral_approach" folder (1) or in "slice" folder (2) [Default-1]: ']);
if isempty(experiment)
		experiment = 1;
end
if experiment == 1
	HDD_folder = HDD_folder_invivo; % to save peak_info_sheet var
	workspace_folder = workspace_folder_invivo; % to save peak_info_sheet var
elseif experiment == 2
	HDD_folder = HDD_folder_invitro; % to save peak_info_sheet var
	workspace_folder = workspace_folder_invitro; % to save peak_info_sheet var
end

% C = cellfun(@(x) strfind(x, 'OG'), stimstr)
if strfind(modified_ROIdata{1, 3}{1}, 'noStim') % isempty(modified_ROIdata{1, 3}) 
	triggeredPeak_filter_max = 0;
else
	triggeredPeak_filter_max = 5;
end

for triggeredPeak_filter = 0:triggeredPeak_filter_max
	% triggeredPeak_filter;
	switch triggeredPeak_filter
	case 0
		disp(['trigger filter: ', num2str(triggeredPeak_filter), ': all peaks used'])
	case 1
		disp(['trigger filter: ', num2str(triggeredPeak_filter), ': noStim peaks used. peaks in noStim groups'])
	case 2
		disp(['trigger filter: ', num2str(triggeredPeak_filter), ': non-excited peaks used. peaks with rise point outside of stimulation'])
	case 3
		disp(['trigger filter: ', num2str(triggeredPeak_filter), ': excited peaks used. immediate peaks since stimulation'])
	case 4
		disp(['trigger filter: ', num2str(triggeredPeak_filter), ': delayed excited peaks used. peaks start to rise after a seconds duration of stimulation'])
	case 5
		disp(['trigger filter: ', num2str(triggeredPeak_filter), ': rebound peaks used. peaks start to rise shortly after stimulation'])
	end
	[peak_info_sheet, peak_fq_sheet, total_cell_num, total_peak_num] = nvoke_event_calc(modified_ROIdata, plot_analysis, triggeredPeak_filter);

	peak_sheet_fn = ['peak_info_sheet_', datestr(datetime('now'), 'yyyymmdd'), '_', stimulation, '_trig', num2str(triggeredPeak_filter)];
	peakfq_sheet_fn = ['peakfq_info_sheet_', datestr(datetime('now'), 'yyyymmdd'), '_', stimulation, '_trig', num2str(triggeredPeak_filter)];

	prompt_save_ROIdata_peakevent = 'Do you want to save peak_info_sheet and peak_fq_sheet? y/n [y]: ';
	input_str = input(prompt_save_ROIdata_peakevent, 's');
	if isempty(input_str)
		input_str = 'y';
	end
	if input_str == 'y'
		if ispc
	        HDD_path = fullfile(HDD_folder, peak_sheet_fn);
	        HDD_path_pfq = fullfile(HDD_folder, peakfq_sheet_fn);
			save(HDD_path, 'peak_info_sheet');
			if triggeredPeak_filter == 0
				save(HDD_path_pfq, 'peak_fq_sheet');
			end
	    end
	    workspace_path = fullfile(workspace_folder, peak_sheet_fn);
	    workspace_path_pfq = fullfile(workspace_folder, peakfq_sheet_fn);
		save(workspace_path, 'peak_info_sheet');
		if triggeredPeak_filter == 0
			save(workspace_path_pfq, 'peak_fq_sheet');
		end
	end
end

%% ====================
% organize riseTimeRelative2Stim and histogram bar plot
% close peakRise_histo
stimDuration = 5;
riseDurationLim = [2.5 3]; % use this to filter peaks
% [0 0.55] [0.55 1] [1 1.5] [1.5 2] [2 2.5] [2.5 3]
titleStr = ['ogled5s-stimpos-manualCorrect', '(>', num2str(riseDurationLim(1)), 's <', num2str(riseDurationLim(2)), 's)'];
% 'ogled10s-stimpos-riseTime', 'airpuffIpsi nVoke1-stimpos nVoke2-handpick'

riseTime2stimStart = peak_info_sheet.riseTime2stimStart;
riseDuration = peak_info_sheet.riseDuration;
nanidx = find(isnan(riseTime2stimStart));
% riseTime2stimStart(nanidx) = [];
shortRiseIdx = find(riseDuration<=riseDurationLim(1));
longRiseIdx = find(riseDuration>=riseDurationLim(2));
discardIdx = [nanidx; shortRiseIdx; longRiseIdx];
riseTime2stimStart(discardIdx) = [];

peakRise_histo = figure;
histogram(riseTime2stimStart, 'BinWidth', 1);
xlim([-10 15]) % specify the start and end time of histogram plot
hold on
Yrange = ylim;
stimPatchX = [0 0 stimDuration stimDuration];
stimPatchY = [Yrange(1) Yrange(2) Yrange(2) Yrange(1)];
patch(stimPatchX, stimPatchY, 'red', 'EdgeColor', 'none', 'FaceAlpha', 0.3)

%Returns handles to the patch and line objects
chi=get(gca, 'Children');
%Reverse the stacking order so that the patch overlays the line
set(gca, 'Children',flipud(chi))
title(titleStr)

%% ====================
% Nomalize peakNormHP in peak_info_sheet with max value
peak_info_sheet_plus = peak_info_sheet; % peak_info_sheet_plus will have a new column for peakNorm_maxNorm
peakNormHP = peak_info_sheet_plus.peakNormHP;
riseDuration = peak_info_sheet_plus.riseDuration;
max_peakNorm = max(peakNormHP);
peakNorm_maxNorm = peakNormHP/max_peakNorm;
peakSlope_maxNorm = peakNorm_maxNorm./riseDuration;

peak_info_sheet_plus.peakNorm_maxNorm = peakNorm_maxNorm;
peak_info_sheet_plus.peakSlope_maxNorm = peakSlope_maxNorm;

[peakNorm_maxNorm, idx] = rmoutliers(peakNorm_maxNorm); % remove outliers. an outlier is a value that is more than three scaled median absolute deviations (MAD) 
outlier_row = find(idx == 0);
peak_info_sheet_plus(idx, :) = [];

%% ====================
% add multiple peak_info_sheet_plus generated in previous section to a structure
if ~exist('pispStru', 'var') % peak_info_sheet_plus-Structure (pispStru)
	idx = 1;
else
	idx = size(pispStru, 2)+1;
end
peakCat = input('Input a string to specify the peak_info_sheet_plus about to added to pispStru: ', 's');
pispStru(idx).Category = peakCat;
pispStru(idx).peakInfo = peak_info_sheet_plus;


%% ====================
% assign peak_info_sheet var to a single structure var with filename and datetime info
if ~exist('peak_sheet_folder', 'var')
	if ispc
		peak_sheet_folder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\';
	elseif isunix
		peak_sheet_folder = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
	end
end
[peak_sheet_fn, peak_sheet_folder]=uigetfile([peak_sheet_folder, '*peak_info_sheet*.mat'], 'Select a file with peak_info_sheet variable in it');
peak_sheet_path = fullfile(peak_sheet_folder, peak_sheet_fn);
if peak_sheet_fn~=0
	peak_sheet_fn_stem = peak_sheet_fn(1:(end-5)); % name without trig number and .mat part
	peak_sheet_path_wild = [fullfile(peak_sheet_folder, peak_sheet_fn(1:(end-5))), '*.mat']; 
	peak_sheet_fdir = dir(peak_sheet_path_wild); % all peak_info_sheet files with same stimuli generated on the same day
	for psn = 1:length(peak_sheet_fdir)
		peak_sheet_path_single = fullfile(peak_sheet_fdir(psn).folder, peak_sheet_fdir(psn).name);
		load(peak_sheet_path_single)
		% new_peak_sheet_var_name = input('Input a new name for loaded variable - peak_sheet_info: ', 's');
		% new_peak_sheet_var_name = matlab.lang.makeValidName(new_peak_sheet_var_name); % make sure var name is valid
		% new_peak_sheet_var_name = matlab.lang.makeUniqueStrings(new_peak_sheet_var_name); % make sure var name is unique
		% eval([new_peak_sheet_var_name, '=peak_sheet_info']);

		if ~exist('peak_sheet_multi', 'var')
			psmn = 1; % peak_sheet_multi_num: number of peak sheets
		else
			psmn = size(peak_sheet_multi, 2)+1;
		end
		peak_sheet_multi(psmn).filename = peak_sheet_fdir(psn).name;
		% peak_sheet_multi(psmn).value = array2table(peak_info_sheet,...
		% 	'VariableNames', {'recNo', 'roiNo', 'peakStart', 'peakEnd', 'riseDuration', 'decayDuration', 'wholeDuration', 'peakAmp', 'peakSlope', 'peakZscore', 'peakNormHP', 'peakTriggered'});
		peak_sheet_multi(psmn).value = peak_info_sheet;
		peak_sheet_multi(psmn).loadedT = datestr(datetime('now'), 'yyyymmdd');
		disp(['file [', peak_sheet_fdir(psn).name, '] loaded into peak_sheet_multi. peak_sheet_multi size: ', num2str(size(peak_sheet_multi, 2))])

		% if ~exist(peak_sheet_loading_log)
		% 	pslrn = 1; % peak_sheet_log_row_num
		% else
		% 	pslrn = size(peak_sheet_loading_log, 1)+1;
		% end
		% peak_sheet_loading_log{pslrn, 1} = new_peak_sheet_var_name;
		% peak_sheet_loading_log{pslrn, 2} = peak_sheet_fn;
		% peak_sheet_loading_log{pslrn, 3} = datestr(datetime('now'));
	end
end



%%
%==================== Save peak_sheet_multi generated in last section
if ispc
	peak_sheet_folder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\';
elseif isunix
	peak_sheet_folder = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
end
psm_fn = ['peak_sheet_multi_', datestr(datetime('now'), 'yyyymmdd'), '.mat'];
cd(peak_sheet_folder);
% psm_path = fullfile(peak_sheet_folder, psm_fn)
[psm_fn, psm_folder] = uiputfile(psm_fn,...
	'Save peak_sheet_multi var in a mat file');
psm_path = fullfile(psm_folder, psm_fn);
if psm_fn==0 
	disp('No file selected. peak_sheet_multi not saved')
else
	if exist('peak_sheet_multi')
		save(psm_path, 'peak_sheet_multi')
		disp(['peak_sheet_multi saved to: ', psm_path])
	end
end





%%
%==================== load peak_sheet_multi var and group values from multiple stimulation and filters into a single table
if ispc
	peak_sheet_folder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\';
elseif isunix
	peak_sheet_folder = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
end
[psm_fn, psm_folder] = uigetfile([peak_sheet_folder, '*peak_sheet_multi*.mat'],...
	'Select a file with variable peak_sheet_multi');
if psm_fn~=0
	psm_path = fullfile(psm_folder, psm_fn);
	load(psm_path)
	stimuli_filter_num = size(peak_sheet_multi, 2); % number of groups (seperated by various stimuli and filters)
	column_name = cell(1, stimuli_filter_num); % pre-allocate. strings of different stimuli-filter groups
	for sfn = 1:stimuli_filter_num
		peakNum(sfn)=size(peak_sheet_multi(sfn).value, 1); % number of peaks in each stimuli-filter group
		column_name{sfn} = input(['rename group [', peak_sheet_multi(sfn).filename, ']: '], 's');
	end

	peak_info_rowsize = max(peakNum); % row number of peak_info varibales 
	peak_info_rise = NaN(peak_info_rowsize, stimuli_filter_num); % pre-allocate
	peak_info_amp = NaN(peak_info_rowsize, stimuli_filter_num); % pre-allocate
	peak_info_slope = NaN(peak_info_rowsize, stimuli_filter_num); % pre-allocate
	peak_info_zscore = NaN(peak_info_rowsize, stimuli_filter_num); % pre-allocate
	peak_info_normhp = NaN(peak_info_rowsize, stimuli_filter_num); % pre-allocate
    peak_info_riseRelative2Stim = NaN(peak_info_rowsize, stimuli_filter_num); % pre-allocate
	for sfn = 1:stimuli_filter_num
		% varible strings can be found above. search: peak_sheet_multi
		% 'recNo', 'roiNo', 'peakStart', 'peakEnd', 'riseDuration', 'decayDuration',... 
		% 'wholeDuration', 'peakAmp', 'peakSlope', 'peakZscore', 'peakNormHP', 'peakTriggered'
		peak_info_rise(1:peakNum(sfn), sfn) = peak_sheet_multi(sfn).value{:, 'riseDuration'};
		peak_info_amp(1:peakNum(sfn), sfn) = peak_sheet_multi(sfn).value{:, 'peakAmp'};
		peak_info_slope(1:peakNum(sfn), sfn) = peak_sheet_multi(sfn).value{:, 'peakSlope'};
		peak_info_zscore(1:peakNum(sfn), sfn) = peak_sheet_multi(sfn).value{:, 'peakZscore'};
		peak_info_normhp(1:peakNum(sfn), sfn) = peak_sheet_multi(sfn).value{:, 'peakNormHP'};
		peak_info_riseRelative2Stim(1:peakNum(sfn), sfn) = peak_sheet_multi(sfn).value{:, 'riseTimeRelative2Stim'};
	end
	peak_info_rise = array2table(peak_info_rise, 'VariableNames', column_name);
	peak_info_amp = array2table(peak_info_amp, 'VariableNames', column_name);
	peak_info_slope = array2table(peak_info_slope, 'VariableNames', column_name);
	peak_info_zscore = array2table(peak_info_zscore, 'VariableNames', column_name);
	peak_info_normhp = array2table(peak_info_normhp, 'VariableNames', column_name);
	peak_info_riseRelative2Stim = array2table(peak_info_riseRelative2Stim, 'VariableNames', column_name);
end

cd(psm_folder) 
psmo_fn = ['peak_sheet_multi_organized_', datestr(datetime('now'), 'yyyymmdd'), '.mat']; % peak_sheet_multi_organized
[psmo_fn, psmo_folder] = uiputfile(psmo_fn,...
	'Save organized peak_info (multiple vars for statistics and plots) in a single file');
psmo_path = fullfile(psmo_folder, psmo_fn);
if psmo_fn==0 
	disp('No file selected. Organized peak info not saved')
else
	if exist('peak_info_rise')
		save(psmo_path, 'peak_info_rise', 'peak_info_amp', 'peak_info_slope', 'peak_info_zscore', 'peak_info_normhp', 'peak_info_riseRelative2Stim')
		disp(['Vars ', 'peak_info_rise ', 'peak_info_amp ', 'peak_info_slope ', 'peak_info_zscore ', 'peak_info_normhp ', 'peak_info_riseRelative2Stim ', 'were saved to: ', psm_path])

		prompt_save_modified_ROIdata = 'Do you want to save these tables to csv files? y/n [y]: ';
		input_str = input(prompt_save_modified_ROIdata, 's');
		if isempty(input_str)
			input_str = 'y';
		end
		if input_str == 'y'
			if ispc
				csvfolder = ['G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\statcsv\', datestr(datetime('now'), 'yyyymmdd'), '\'];
			elseif isunix
				csvfolder = ['/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/statCsv/', datestr(datetime('now'), 'yyyymmdd'), '/'];
			end
			input_csv_str = input('Please input a string to make csv files unique: ', 's');
			peak_info_rise_fn = ['peak_info_rise_', datestr(datetime('now'), 'yyyymmdd'), '_',input_csv_str];
			peak_info_amp_fn = ['peak_info_amp_', datestr(datetime('now'), 'yyyymmdd'), '_',input_csv_str];
			peak_info_slope_fn = ['peak_info_slope_', datestr(datetime('now'), 'yyyymmdd'), '_',input_csv_str];
			peak_info_zscore_fn = ['peak_info_zscore_', datestr(datetime('now'), 'yyyymmdd'), '_',input_csv_str];
			peak_info_normhp_fn = ['peak_info_normhp_', datestr(datetime('now'), 'yyyymmdd'), '_',input_csv_str];
			peak_info_riseRelative2Stim_fn = ['peak_info_riseRelative2Stim_', datestr(datetime('now'), 'yyyymmdd'), '_',input_csv_str]; % rise relative to stim

			peak_info_rise_path = fullfile(csvfolder, peak_info_rise_fn);
			peak_info_amp_path = fullfile(csvfolder, peak_info_amp_fn);
			peak_info_slope_path = fullfile(csvfolder, peak_info_slope_fn);
			peak_info_zscore_path = fullfile(csvfolder, peak_info_zscore_fn);
			peak_info_normhp_path = fullfile(csvfolder, peak_info_normhp_fn);
			peak_info_riseRelative2Stim_path = fullfile(csvfolder, peak_info_riseRelative2Stim_fn);

			tmp_peak_info_rise = table2cell(peak_info_rise);
			tmp_peak_info_rise(isnan(peak_info_rise.Variables)) = {[]};
			peak_info_rise = array2table(tmp_peak_info_rise, 'VariableNames', peak_info_rise.Properties.VariableNames);
			writetable(peak_info_rise,[peak_info_rise_path, '.csv']);

			tmp_peak_info_amp = table2cell(peak_info_amp);
			tmp_peak_info_amp(isnan(peak_info_amp.Variables)) = {[]};
			peak_info_amp = array2table(tmp_peak_info_amp, 'VariableNames', peak_info_amp.Properties.VariableNames);
			writetable(peak_info_amp,[peak_info_amp_path, '.csv']);

			tmp_peak_info_slope = table2cell(peak_info_slope);
			tmp_peak_info_slope(isnan(peak_info_slope.Variables)) = {[]};
			peak_info_slope = array2table(tmp_peak_info_slope, 'VariableNames', peak_info_slope.Properties.VariableNames);
			writetable(peak_info_slope,[peak_info_slope_path, '.csv']);

			tmp_peak_info_zscore = table2cell(peak_info_zscore);
			tmp_peak_info_zscore(isnan(peak_info_zscore.Variables)) = {[]};
			peak_info_zscore = array2table(tmp_peak_info_zscore, 'VariableNames', peak_info_zscore.Properties.VariableNames);
			writetable(peak_info_zscore,[peak_info_zscore_path, '.csv']);

			tmp_peak_info_normhp = table2cell(peak_info_normhp);
			tmp_peak_info_normhp(isnan(peak_info_normhp.Variables)) = {[]};
			peak_info_normhp = array2table(tmp_peak_info_normhp, 'VariableNames', peak_info_normhp.Properties.VariableNames);
			writetable(peak_info_normhp,[peak_info_normhp_path, '.csv']);

			tmp_peak_info_riseRelative2Stim = table2cell(peak_info_riseRelative2Stim);
			tmp_peak_info_riseRelative2Stim(isnan(peak_info_riseRelative2Stim.Variables)) = {[]};
			peak_info_riseRelative2Stim = array2table(tmp_peak_info_riseRelative2Stim, 'VariableNames', peak_info_riseRelative2Stim.Properties.VariableNames);
			writetable(peak_info_riseRelative2Stim,[peak_info_riseRelative2Stim_path, '.csv']);
		end
	end
end

%% ====================
% load peak_info_sheet(s) into peak_info_compilation
    if ispc
    	peak_info_sheet_folder = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\';
    elseif isunix
    	peak_info_sheet_folder = '/home/guoda/Documents/Workspace/Analysis/nVoke/Ventral_approach/processed mat files/';
    end
    peak_info_compilation_folder = peak_info_sheet_folder;

    peakInfoSheet_count = 1;
    load_peakInfoSheet_mat = 1;

    prompt_load_pis = 'Load peak_info_sheet. 1-one by one manually. 2-all peaks in same stimuli group. 3-same peak category from all stimuli.  ? 1/2/3 [1]: ';
    input_num = input(prompt_load_pis);
    if isempty(input_num)
    	input_num = 1;
    end
    % [peak_info_sheet_fn, peak_info_sheet_folder]=uigetfile([peak_info_sheet_folder, '*.mat'],...
    % 	'Select a file with peak_info_sheet (generated by nvoke_event_cal) in it');
    % if peak_info_sheet_fn==0
    % 	return
    % end
    clear peak_info_compilation
    switch input_num
    case 1
	    while load_peakInfoSheet_mat == 1
	    	disp('load all peak_info_sheet manually')
	    	[peak_info_sheet_fn, peak_info_sheet_folder]=uigetfile([peak_info_sheet_folder, '*.mat'],...
	    		'Select a file with peak_info_sheet (generated by nvoke_event_cal) in it');
	    	if peak_info_sheet_fn==0
	    		return
	    	end
	    	% [peak_info_sheet_fn, peak_info_sheet_folder]=uigetfile([peak_info_sheet_folder, '*.mat'],...
	    	% 	'Select a file with peak_info_sheet (generated by nvoke_event_cal) in it');
	        if peak_info_sheet_fn == 0
	            load_peakInfoSheet_mat = 0;
	        end
	    	peak_info_sheet_path = fullfile(peak_info_sheet_folder, peak_info_sheet_fn);
	    	if peak_info_sheet_fn~=0
	    		load(peak_info_sheet_path)
	    		if peakInfoSheet_count == 1
	    			peak_info_compilation = peak_info_sheet;
	    		else
	    			peak_info_compilation = [peak_info_compilation; peak_info_sheet];
	    		end

	    		peak_info_sheet_var_name = who('-file', peak_info_sheet_path);
	    		if ~exist('peak_info_sheet_loading_log', 'var')
	    			pslrn = 1; % peak_sheet_log_row_num
	    		else
	    			pslrn = size(peak_info_sheet_loading_log, 1)+1;
	    		end
	    		peak_info_sheet_loading_log{pslrn, 1} = peak_info_sheet_var_name{1};
	    		peak_info_sheet_loading_log{pslrn, 2} = peak_info_sheet_fn;
	    		peak_info_sheet_loading_log{pslrn, 3} = datestr(datetime('now'), 'yyyymmdd HH:MM:SS');
	    		disp([peak_info_sheet_loading_log{pslrn, 3}, ': var ', peak_info_sheet_var_name{1}, ' was loaded from file ', peak_info_sheet_fn])

	    		prompt_load_option = 'Do you want to load more peak_info_sheet? y/n [y]: ';
		    	input_str = input(prompt_load_option, 's');
		    	if isempty(input_str)
		    		input_str = 'y';
		    	end
		    	if input_str == 'y'
		    		load_peakInfoSheet_mat = 1;
		    		peakInfoSheet_count = peakInfoSheet_count+1;
		    	else
		    		load_peakInfoSheet_mat = 0;
		    	end

	    	end
	    end
	    peak_num_sum = size(peak_info_compilation, 1);
	    peakStim_num = size(unique(peak_info_compilation.peakStim), 1);
	    peakCategory_num = size(unique(peak_info_compilation.peakStim), 1);
	    disp([num2str(peak_num_sum), ' peaks from', num2str(pslrn), ' files were load into variable peak_info_compilation'])
	    disp(['Stimuli (', num2str(peakStim_num), '): '])
	    disp(unique(peak_info_compilation.peakStim))
	    disp(['Peak Category (', num2str(peakCategory_num), '): '])
	    disp(unique(peak_info_compilation.peakCategory))
	    peak_sheet_fn_stem_trig = 'Input a string to identify all peak_info_sheet files with same date and trig number in file name (between "stimuli_" and ".mat"): ';
    	trig_str = input(peak_sheet_fn_stem_trig, 's'); % example: "stimpos_trig5" from 'peak_info_sheet_20200621_opto5s_stimpos_trig5.mat'
    	if isempty(trig_str)
    		disp('peak_info_compilation is not saved')
    		return
    	end
    	postfix_str_save_compilation = trig_str;
	case 2
		disp('Select 1 file. All files with same date info and stimuli will be loaded')
		[peak_info_sheet_fn, peak_info_sheet_folder]=uigetfile([peak_info_sheet_folder, '*.mat'],...
			'Select a file with peak_info_sheet (generated by nvoke_event_cal) in it');
		if peak_info_sheet_fn==0
			return
		end
		% peak_sheet_fn_stem_trig = 'Input a string to identify all peak_info_sheet files with same date and stim in file name (between "date" and ".mat"): ';
  %   	trig_str = input(peak_sheet_fn_stem_trig, 's'); % example: "stimpos_trig5" from 'peak_info_sheet_20200621_opto5s_stimpos_trig5.mat'
  %   	if isempty(trig_str)
  %   		return
  %   	end
  		disp(peak_info_sheet_fn)
		peak_sheet_fn_stem = peak_info_sheet_fn(1:(end-5)); % name without trig number and .mat part. 'peak_info_sheet_20200621_opto5s_stimpos_trig5.mat'
		peak_sheet_path_wild = [fullfile(peak_info_sheet_folder, peak_sheet_fn_stem), '*.mat']; 
		peak_sheet_fdir = dir(peak_sheet_path_wild); % all peak_info_sheet files with same stimuli generated on the same day
		postfix_str_save_compilation = peak_info_sheet_fn(26:(end-10)); % 'opto5s_stimpos' from 'peak_info_sheet_20200621_opto5s_stimpos_trig5.mat'
		for psn = 2:length(peak_sheet_fdir)
			peak_info_sheet_path = fullfile(peak_sheet_fdir(psn).folder, peak_sheet_fdir(psn).name);
			load(peak_info_sheet_path)
			if peakInfoSheet_count == 1
				peak_info_compilation = peak_info_sheet;
			else
				peak_info_compilation = [peak_info_compilation; peak_info_sheet];
			end
			peak_info_sheet_var_name = who('-file', peak_info_sheet_path);
			if ~exist('peak_info_sheet_loading_log', 'var')
				pslrn = 1; % peak_sheet_log_row_num
			else
				pslrn = size(peak_info_sheet_loading_log, 1)+1;
			end
			peak_info_sheet_loading_log{pslrn, 1} = peak_info_sheet_var_name{1};
			peak_info_sheet_loading_log{pslrn, 2} = peak_info_sheet_fn;
			peak_info_sheet_loading_log{pslrn, 3} = datestr(datetime('now'), 'yyyymmdd HH:MM:SS');
			disp([peak_info_sheet_loading_log{pslrn, 3}, ': var ', peak_info_sheet_var_name{1}, ' was loaded from file ', peak_sheet_fdir(psn).name])
			if psn < length(peak_sheet_fdir)
				peakInfoSheet_count = peakInfoSheet_count+1;
			end
		end
	case 3
		disp('Select 1 file. All files with same date info and same peak category (trig0-4) will be loaded')
		[peak_info_sheet_fn, peak_info_sheet_folder]=uigetfile([peak_info_sheet_folder, '*.mat'],...
			'Select a file with peak_info_sheet (generated by nvoke_event_cal) in it');
		if peak_info_sheet_fn==0
			return
		end
		disp(peak_info_sheet_fn)
		peak_sheet_fn_stem_trig = 'Input a string to identify all peak_info_sheet files with same date and trig number in file name (between "stimuli_" and ".mat"): ';
    	trig_str = input(peak_sheet_fn_stem_trig, 's'); % example: "stimpos_trig5" from 'peak_info_sheet_20200621_opto5s_stimpos_trig5.mat'
    	if isempty(trig_str)
    		return
    	end
		peak_sheet_fn_stem_date = peak_info_sheet_fn(1:24); % example: "peak_info_sheet_20200621" from 'peak_info_sheet_20200621_opto5s_stimpos_trig5.mat'
		peak_sheet_fn_stem = [peak_sheet_fn_stem_date, '*', trig_str, '*.mat'];
		peak_sheet_path_wild = fullfile(peak_info_sheet_folder, peak_sheet_fn_stem); 
		peak_sheet_fdir = dir(peak_sheet_path_wild); % all peak_info_sheet files with same stimuli generated on the same day
		postfix_str_save_compilation = trig_str;
		for psn = 1:length(peak_sheet_fdir)
			peak_info_sheet_path = fullfile(peak_sheet_fdir(psn).folder, peak_sheet_fdir(psn).name);
			load(peak_info_sheet_path)
			if peakInfoSheet_count == 1
				peak_info_compilation = peak_info_sheet;
			else
				peak_info_compilation = [peak_info_compilation; peak_info_sheet];
			end
			peak_info_sheet_var_name = who('-file', peak_info_sheet_path);
			if ~exist('peak_info_sheet_loading_log', 'var')
				pslrn = 1; % peak_sheet_log_row_num
			else
				pslrn = size(peak_info_sheet_loading_log, 1)+1;
			end
			peak_info_sheet_loading_log{pslrn, 1} = peak_info_sheet_var_name{1};
			peak_info_sheet_loading_log{pslrn, 2} = peak_info_sheet_fn;
			peak_info_sheet_loading_log{pslrn, 3} = datestr(datetime('now'), 'yyyymmdd HH:MM:SS');
			disp([peak_info_sheet_loading_log{pslrn, 3}, ': var ', peak_info_sheet_var_name{1}, ' was loaded from file ', peak_sheet_fdir(psn).name])
			if psn < length(peak_sheet_fdir)
				peakInfoSheet_count = peakInfoSheet_count+1;
			end
		end
	end

    % Save peak_info_compilation
    prompt_save_compilation = 'Do you want to save peak_info_compilation to a mat file? y/n [y]: ';
	input_str = input(prompt_save_compilation, 's');
	if isempty(input_str)
		input_str = 'y';
	end
	if input_str == 'y'

		cd(peak_info_sheet_folder) 
		peak_info_compilation_fn = ['peak_info_compilation_', datestr(datetime('now'), 'yyyymmdd'), '_', postfix_str_save_compilation, '.mat']; % peak_sheet_multi_organized
		[peak_info_compilation_fn, peak_info_compilation_folder] = uiputfile(peak_info_compilation_fn,...
			'Save peak_info_compilation into a file');
		% psmo_path = fullfile(psmo_folder, psmo_fn);
		peak_info_compilation_path = fullfile(peak_info_compilation_folder, peak_info_compilation_fn);
		save(peak_info_compilation_path, 'peak_info_compilation')
		disp(['peak_info_compilation saved to: ', peak_info_compilation_path])
	else
	end

%% ====================
% plot peak_info_compilation
plotsave = 2; % 0-no plot. 1-plot. 2-plot and save
groupType = 1;
% groupType: 0-peaks are not grouped. 1-peaks are grouped according to category. 
% 			   2-peaks are grouped according to stimuli
%			   3-peaks are grouped according to both category and stimuli

nvoke_peak_plot(peak_info_compilation, plotsave, groupType);

%% ====================
% Filter peaks by setting range of various parameter
riseDuration_min = []; % s
riseDuration_max = [0.8]; % s
peakSlope_min = [10];
peakSlope_max = [];
peakNormHP_min = [5];
peakNormHP_max = [];

peak_info_compilation_backup = peak_info_compilation; % just in case

discard_peaks = [];
if ~isempty(riseDuration_min)
	discard_peaks = find(peak_info_compilation.riseDuration < riseDuration_min); 
	peak_info_compilation(discard_peaks, :) = [];
end
if ~isempty(riseDuration_max)
	discard_peaks = find(peak_info_compilation.riseDuration > riseDuration_max); 
	peak_info_compilation(discard_peaks, :) = [];
end

if ~isempty(peakSlope_min)
	discard_peaks = find(peak_info_compilation.peakSlope < peakSlope_min); 
	peak_info_compilation(discard_peaks, :) = [];
end
if ~isempty(peakSlope_max)
	discard_peaks = find(peak_info_compilation.peakSlope > peakSlope_max); 
	peak_info_compilation(discard_peaks, :) = [];
end

if ~isempty(peakNormHP_min)
	discard_peaks = find(peak_info_compilation.peakNormHP < peakNormHP_min); 
	peak_info_compilation(discard_peaks, :) = [];
end

if ~isempty(peakNormHP_max)
	discard_peaks = find(peak_info_compilation.peakNormHP > peakNormHP_max); 
	peak_info_compilation(discard_peaks, :) = [];
end

%% ====================
% Filter peaks according to peakCategories
% discard_peakCat_str = {'noStim', 'outside', 'triggered_delay', 'noStim-OG_LED-10s', 'noStim-OG_LED-1s', 'noStim-OG_LED-5s'};
discard_peakCat_str = {'outside', 'noStim-GPIO1-1s', 'noStim-OG_LED-10s', 'noStim-OG_LED-1s', 'noStim-OG_LED-5s'}; % noStim, noStim-OG_LED-1s, rebound, triggered, triggered_delay
discard_peakStim_str = {'GPIO1-1s', 'OG_LED-1s', 'OG_LED-10s'}; % noStim, GPIO1-1s, OG_LED-1s, OG_LED-5s, OG_LED-10s
peak_info_compilation_backup = peak_info_compilation; % just in case

dis_row = [];
if ~isempty(discard_peakCat_str)
	for dpsn = 1:length(discard_peakCat_str)
		dis_ind = cellfun(@(x) strcmp(discard_peakCat_str{dpsn}, x), peak_info_compilation.peakCategory);
		dis_row = find(dis_ind);
		peak_info_compilation(dis_row, :) = [];
	end
	kept_peakCat = unique(peak_info_compilation.peakCategory);
	disp(kept_peakCat)
end
if ~isempty(discard_peakStim_str)
	for dpsn = 1:length(discard_peakStim_str)
		dis_ind = cellfun(@(x) strcmp(discard_peakStim_str{dpsn}, x), peak_info_compilation.peakStim);
		dis_row = find(dis_ind);
		peak_info_compilation(dis_row, :) = [];
	end
	kept_peakStim = unique(peak_info_compilation.peakStim);
	disp(kept_peakStim)
end

prompt_save_compilation = 'Do you want to save peak_info_compilation to a mat file? y/n [y]: ';
input_str = input(prompt_save_compilation, 's');
if isempty(input_str)
	input_str = 'y';
end
if input_str == 'y'

	cd(peak_info_sheet_folder) 
	peak_info_compilation_fn = ['peak_info_compilation_', datestr(datetime('now'), 'yyyymmdd'), '_', postfix_str_save_compilation, '.mat']; % peak_sheet_multi_organized
	[peak_info_compilation_fn, peak_info_compilation_folder] = uiputfile(peak_info_compilation_fn,...
		'Save peak_info_compilation into a file');
	% psmo_path = fullfile(psmo_folder, psmo_fn);
	peak_info_compilation_path = fullfile(peak_info_compilation_folder, peak_info_compilation_fn);
	save(peak_info_compilation_path, 'peak_info_compilation')
	disp(['peak_info_compilation saved to: ', peak_info_compilation_path])
else
end

%% ====================
% delete specific stim-catelog combination
dis_stim_str = {'OG_LED'};
dis_cat_str = {'noStim-extra'};

dis_stim_idx = strfind(peak_info_compilation.peakStim, dis_stim_str{:});
dis_cat_idx = strfind(peak_info_compilation.peakCategory, dis_cat_str{:});

empty_idx_stim = cellfun(@isempty, dis_stim_idx);
empty_idx_cat = cellfun(@isempty, dis_cat_idx);

dis_stim_row = find(empty_idx_stim==0);
dis_cat_row = find(empty_idx_cat==0);
dis_intersect_row = intersect(dis_stim_row, dis_cat_row);

peak_info_compilation(dis_intersect_row, :) = [];
% peak_info_compilation(dis_cat_row, :) = [];

%% ====================
% evaluate cluster numbers
% peak_info_array = peak_info_sheet(:, [5 8 9]); % N x P matrix. N peaks, P variables
peak_info_array = peak_info_compilation{:, {'riseDuration', 'peakSlope', 'peakNormHP'}};
% 5-rise duration
% 8-peak amplitude
% 9-peak slope
% 10-peak zscore
% 11-peak normhp

% estimate cluster numbers 
peak_clucster_func = @(X, K)(kmeans(X, K, 'emptyaction', 'singleton', 'replicate', 5));
eva = evalclusters(peak_info_array, peak_clucster_func, 'CalinskiHarabasz', 'klist', [1:20])
eva.OptimalK;

%% ==================== 
% kmeans cluster
[idx, c, sumd, D] = kmeans(peak_info_array, eva.OptimalK, 'emptyaction', 'singleton', 'replicate', 5);
peak_info_compilation.cluster=idx;

%% ==================== 
% plot clusters: version2

% change noStim-'stimulation' peakCategroy to noStim-extra
nostimexog_ind = strfind(peak_info_compilation.peakCategory, 'noStim-OG');
nostimexgp_ind = strfind(peak_info_compilation.peakCategory, 'noStim-GP');
empty_idx_og = cellfun(@isempty,nostimexog_ind);
empty_idx_gp = cellfun(@isempty,nostimexgp_ind);
nostimexog_row = find(empty_idx_og~=1);
nostimexgp_row = find(empty_idx_gp~=1);
nostimex_row = [nostimexog_row; nostimexgp_row];
if ~isempty(nostimex_row)
	for nr = 1:length(nostimex_row)
		peak_info_compilation.peakCategory{nostimex_row(nr)} = 'noStim-extra';
	end
end

% seperate opto trig and trig-delay peaks from airpuff
change_stim_idx = strfind(peak_info_compilation.peakStim, 'OG_LED');
change_cat_idx = strfind(peak_info_compilation.peakCategory, 'triggered');
empty_idx_stim = cellfun(@isempty, change_stim_idx);
empty_idx_cat = cellfun(@isempty, change_cat_idx);
change_stim_row = find(empty_idx_stim==0);
change_cat_row = find(empty_idx_cat==0);
change_intersect_row = intersect(change_stim_row, change_cat_row);
if ~isempty(change_intersect_row)
	for cir = 1:length(change_intersect_row)
		peak_info_compilation.peakCategory{change_intersect_row(cir)} = 'triggered-opto';
	end
end
change_stim_idx = strfind(peak_info_compilation.peakStim, 'OG_LED');
change_cat_idx = strfind(peak_info_compilation.peakCategory, 'rebound');
empty_idx_stim = cellfun(@isempty, change_stim_idx);
empty_idx_cat = cellfun(@isempty, change_cat_idx);
change_stim_row = find(empty_idx_stim==0);
change_cat_row = find(empty_idx_cat==0);
change_intersect_row = intersect(change_stim_row, change_cat_row);
if ~isempty(change_intersect_row)
	for cir = 1:length(change_intersect_row)
		peak_info_compilation.peakCategory{change_intersect_row(cir)} = 'rebound-opto';
	end
end


peakStim_str = unique(peak_info_compilation.peakStim);
peakCategory_str = unique(peak_info_compilation.peakCategory);
peakStim_num = size(peakStim_str, 1);
peakCategory_num = size(peakCategory_str, 1);

% calculate center of each peak category. Ignore cluster
for catn = 1:peakCategory_num
	cat_row = find(strcmp(peakCategory_str{catn}, peak_info_compilation.peakCategory));
	peak_info_cate = peak_info_compilation(cat_row, :);
	mean_riseDuration_cat(catn) = mean(peak_info_cate.riseDuration); 
	mean_peakNormHP_cat(catn) = mean(peak_info_cate.peakNormHP);
	mean_peakSlope_cat(catn) = mean(peak_info_cate.peakSlope);
end

clear peak_info_compilation_plot
clear peaknum_table
clear peak_percent
for cn = 1:eva.OptimalK
	cluster_row = find(peak_info_compilation.cluster==cn);
	peak_info_compilation_cluster(cn).value = peak_info_compilation(cluster_row, :);
	peak_info_compilation_cluster(cn).group = ['cluster-', num2str(cn)];
	cluster_str{cn} = ['cluster', num2str(cn)];

	for catn = 1:peakCategory_num
		gn = (cn-1)*peakCategory_num+catn; % peak group number
		cat_row = find(strcmp(peakCategory_str{catn}, peak_info_compilation_cluster(cn).value.peakCategory));
		peak_info_compilation_plot(gn).value = peak_info_compilation_cluster(cn).value(cat_row, :);
		peak_info_compilation_plot(gn).group = [peak_info_compilation_cluster(cn).group, '-', peakCategory_str{catn}];
		peak_info_compilation_plot(gn).clus = cn; % for cluster markertype later
		peak_info_compilation_plot(gn).cate = catn; % for cluster markertype later
		peak_num_group = size(peak_info_compilation_plot(gn).value, 1);
		peaknum_table(catn, cn) = peak_num_group;
	end
end
for catn = 1:size(peaknum_table, 1)
	for cn = 1:size(peaknum_table, 2)
        catn
        cn
		peak_percent(catn, cn) = peaknum_table(catn, cn)/sum(peaknum_table(catn, :));
	end
end
pn_table = table(peaknum_table, 'VariableNames', {'peakNum'}, 'RowNames', peakCategory_str)
pp_table = table(peak_percent*100, 'VariableNames', {'peakPercent'}, 'RowNames', peakCategory_str)

close all
peakGroup_num = size(peak_info_compilation_plot, 2);
cluster_markertype = {'.', '+', 'x', 'o', 'square', 'diamond', 'pentagram', 'hexagram'};
% cluster_markertype = {'o', 'square', 'diamond', 'pentagram', 'hexagram'};
cat_markercolor = {'#6D6D6D', '#0072BD', '#D95319', '#EDB120', '#7E2F8E', '#77AC30', '#4DBEEE', '#A2142F'}; % 'MarkerFaceColor'
clear legendstr
scluster = figure;
for gn = 1:peakGroup_num
	peak_info_sheet = peak_info_compilation_plot(gn).value;
	peak_num = size(peak_info_sheet, 1);
	if peak_num>0 % if there are peaks in this group
		if gn == 1
			legendstr = {[peak_info_compilation_plot(gn).group, ' (n=', num2str(peak_num), ')']};
		else
			if exist('legendstr', 'var')
				legendstr = [legendstr {[peak_info_compilation_plot(gn).group, ' (n=', num2str(peak_num), ')']}];
			else
				legendstr = {[peak_info_compilation_plot(gn).group, ' (n=', num2str(peak_num), ')']};
			end
		end

		% mean value of specific category peaks in single cluster
		mean_riseDuration(gn) = mean(peak_info_sheet.riseDuration); 
		mean_peakNormHP(gn) = mean(peak_info_sheet.peakNormHP);
		mean_peakSlope(gn) = mean(peak_info_sheet.peakSlope);
		
		max_riseT = max(peak_info_sheet.riseDuration);
		max_PeakAmpNormHp = max(peak_info_sheet.peakNormHP);
		max_peakSlope = max(peak_info_sheet.peakSlope);
		markerT = cluster_markertype{peak_info_compilation_plot(gn).cate}; % marker type
		markerC = cat_markercolor{peak_info_compilation_plot(gn).clus};
		total_peak_num = size(peak_info_sheet, 1);

		if peak_info_compilation_plot(gn).cate <= 3
			markersize = 2;
		elseif peak_info_compilation_plot(gn).cate == 4 || peak_info_compilation_plot(gn).cate == 7
			markersize = 5;
		else
			markersize = 60;
		end

		
		scatter3(peak_info_sheet.riseDuration, peak_info_sheet.peakNormHP, peak_info_sheet.peakSlope,...
			markerT, 'MarkerFaceColor', markerC, 'MarkerEdgeColor', markerC, 'SizeData', markersize)
		hold on
		
		% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
		xlim([0 (max_riseT+0.5)])
		ylim([0 60]) % ylim([0 (max_PeakAmpNormHp+5)])
		zlim([0 60]) % zlim([0 (max_peakSlope+5)])
		xlabel('RiseT', 'FontSize', 16)
		ylabel('PeakAmpNormHp', 'FontSize', 16)
		zlabel('Slope', 'FontSize', 16)
		% if gn == peakGroup_num
		% 	legend(gca, legendstr);
		% end
		legend(gca, legendstr);
		title(['Kmeans cluster' ], 'FontSize', 16)
	end
end

% draw center of every group
for gn = 1:peakGroup_num
	if mean_riseDuration(gn)~=0
		legendstr = [legendstr {[peak_info_compilation_plot(gn).group, ' mean']}];
		markerT = cluster_markertype{peak_info_compilation_plot(gn).cate}; % marker type
		markerC = cat_markercolor{peak_info_compilation_plot(gn).clus};
		scatter3(mean_riseDuration(gn), mean_peakNormHP(gn), mean_peakSlope(gn),...
			markerT, 'MarkerEdgeColor', markerC, 'SizeData', 100)
		legend(gca, legendstr);
	end
end

% draw center of every peak category
for catn = 1:peakCategory_num
	legendstr = [legendstr {[peakCategory_str{catn}, '-all center']}];
	markerT = cluster_markertype{catn}; % marker type
	scatter3(mean_riseDuration_cat(catn), mean_peakNormHP_cat(catn), mean_peakSlope_cat(catn),...
		cluster_markertype{catn}, 'MarkerEdgeColor', 'magenta', 'SizeData', 100)
	legend(gca, legendstr);
end

% draw centroids of clusters on 3D scatter
% for cn = 1:size(c, 1)
% 	scatter3(c(cn, 1), c(cn, 3), c(cn, 2), 'o', 'MarkerEdgeColor', cat_markercolor{cn}, 'SizeData', 400)
% end
% legend(gca, legendstr);




%% ==================== 
% 1st version cluster code
scluster = figure;
for cn = 1:eva.OptimalK
	scatter3(peak_info_array(idx==cn, 1), peak_info_array(idx==cn, 2), peak_info_array(idx==cn, 3), 'filled')
	% set(gca, 'XLim', [0 150], 'YLim', [0 30], 'ZLim' [0 40])
	hold on

end
xlim([0 (max(peak_info_array(:, 1))+0.5)])
ylim([0 (max(peak_info_array(:, 2))+0.1)])
zlim([0 (max(peak_info_array(:, 3))+0.05)])
xlabel('RiseT', 'FontSize', 16)
ylabel('Slope', 'FontSize', 16)
zlabel('peakNormHP', 'FontSize', 16)

%%
klist=2:6;%the number of clusters you want to try
myfunc = @(X,K)(kmeans(X, K));
eva = evalclusters(net.IW{1},myfunc,'CalinskiHarabasz','klist',klist)
classes=kmeans(net.IW{1},eva.OptimalK);