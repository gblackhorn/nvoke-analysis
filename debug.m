% peak detection
% Defaults
lowpass_fpass = 1;
highpass_fpass = 4;   
smooth_method = 'loess';
smooth_span = 0.1;
prominence_factor = 4; % prominence_factor doesn't influence peak finding in decon data
existing_peak_duration_extension_time_pre  = 0; % duration in second, before existing peak rise 
existing_peak_duration_extension_time_post = 1; % duration in second, after decay
criteria_rise_time = [0 0.8]; % unit: second. filter to keep peaks with rise time in the range of [min max]
criteria_slope = [3 80]; % default: slice-[50 2000]
							% calcium(a.u.)/rise_time(s). filter to keep peaks with rise time in the range of [min max]
							% ventral approach default: [3 80]
							% slice default: [50 2000]
% criteria_mag = 3; % default: 3. peak_mag_normhp
criteria_pnr = 3; % default: 3. peak-noise-ration (PNR): relative-peak-signal/std. std is calculated from highpassed data.
criteria_excitated = 2; % If a peak starts to rise in 2 sec since stimuli, it's a excitated peak
criteria_rebound = 1; % a peak is concidered as rebound if it starts to rise within 2s after stimulation end
stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
% use_criteria = true; % true or false. choose to use criteria or not for picking peaks
stim_pre_time = 10; % time (s) before stimuli start
stim_post_time = 10; % time (s) after stimuli end
merge_peaks = true;
merge_time_interval = 1; % default: 0.5s. peak to peak interval.
discard_noisy_roi = false;
std_fold = 10; % used as criteria to discard noisy_rois

%% ==================== 
% use ogled5s data
TrialRow = 7; % 20180919-154330 neuron 1, 2, 3
roi_idx = 9;
TrialData = recdata_organized(TrialRow, :); 
roi_trace = TrialData{1, 2}.raw{:,(roi_idx+1)};
filter_chosen = 'lowpass';
time_info = TrialData{1, 2}.raw.Time;
existing_peakInfo = TrialData{1, 5}{1, roi_idx}{:};

[peak_par, processed_data_and_info] = find_peaks_with_existing_peakinfo(roi_trace,existing_peakInfo,...
	'filter', filter_chosen, 'time_info', time_info);

%% ==================== 
% in Func "find_peaks_in_windows"
win_trace = roi_trace_window(:, wn);
plot(win_trace)


%% ==================== 
% Test Yoe's plotting stim-aligned traces code
trialData = recdata_organized(15, :); %  20200303-125953-PP-BP-MC-ROI.csv
PREwin = 100;
POSTwin = 100;

meanTraceSegments = plotOGsegmentsInTrial (trialData, PREwin, POSTwin, gca);

%% ==================== 
% Test Yoe's plotting stim-aligned traces code
IOnVokeData = recdata_organized; %  20200303-125953-PP-BP-MC-ROI.csv
PREwin = 100;
POSTwin = 100;
plotOGsegmentsInGroup (IOnVokeData, PREwin, POSTwin);


%% ==================== 
% debugging filtering trials and rois
recdata = recdata_organized;
event_info_table = event_info_high_freq_rois;

recdata_trial_names = recdata(:, 1);

unique_trial_rois = unique(event_info_table(:, {'recording_name', 'roi_name'}));
unique_trials = unique(unique_trial_rois.recording_name);
unique_trials_num = length(unique_trials);

trial_keep_idx = ones(unique_trials_num, 1);


% Discard trials
for tn = 1:unique_trials_num
%     tn
%     if tn == 7
%         pause
%     end
    trial_keep_idx(tn) = find(strcmp(unique_trials{tn}, recdata_trial_names));
end
recdata_selected = recdata(trial_keep_idx, :);
recdata_selected_trial_names = recdata_selected(:, 1);



% Discard ROIs
trials_num = size(recdata_selected, 1);
for tn = 1:trials_num
    tn
%     if tn == 8
%         pause
%     end
    unique_rois_idx = find(strcmp(recdata_selected_trial_names{tn}, unique_trial_rois.recording_name));
    roi_keep_names = unique_trial_rois{unique_rois_idx, 'roi_name'};
    recdata_selected{tn, 2}.lowpass = recdata_selected{tn, 2}.lowpass(:, ['Time', roi_keep_names']);
    recdata_selected{tn, 2}.smoothed = recdata_selected{tn, 2}.smoothed(:, ['Time', roi_keep_names']);
    recdata_selected{tn, 2}.highpass = recdata_selected{tn, 2}.highpass(:, ['Time', roi_keep_names']);

    recdata_selected{tn, 5} = recdata_selected{tn, 5}(:, roi_keep_names);
end


%% ==================== 
trialData = recdata_selected(9, :);
plotROItracesFromTrial (trialData);


%% ==================== 
% ca level analysis
BinWidth = 1; % varargin: Use bin number instead of BinWidth: 'nbins', 40
min_spont_freq = 0.05;
pre_stim_duration = 10; % second
post_stim_duration = 10; % second
SavePlot = false; % true or false
% SaveVars = true;

[ca_level_bin,setting,ca_level_high_freq] = ca_level_analysis_histogram(recdata_organized,...
	'BinWidth', BinWidth, 'min_spont_freq', min_spont_freq,...
	'pre_stim_duration', pre_stim_duration, 'post_stim_duration', post_stim_duration,...
	'SavePlot', SavePlot);