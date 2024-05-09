%% ====================
% Sync ROIs across trials in the same series (same FOV, same ROI set) 
sd.ref_stim = 'GPIO-1-1s'; % ROIs are synced to the trial applied with this stimulation
sd.ref_SpikeCat = {'spon','trig'}; % spike/peak/event categories kept during the syncing in ref trials
sd.nonref_SpikeCat = {'spon','rebound'}; % spike/peak/event categories kept during the syncing in non-ref trials
[seriesData_sync] = sync_rois_multiseries(alignedData_allTrials,...
	'ref_stim',sd.ref_stim,'ref_SpikeCat',sd.ref_SpikeCat,'nonref_SpikeCat',sd.nonref_SpikeCat);

%% ====================
% Group series data using ROI. Each ROI group contains events from trials using various stimulation
ngd.ref_stim = 'ap'; % reference stimulation
ngd.ref_SpikeCat = 'trig'; % reference spike/peak/event category 
ngd.other_SpikeCat = 'rebound'; % spike/peak/event category in other trial will be plot
ngd.debug_mode = false;

series_num = numel(seriesData_sync);
for sn = 1:series_num
	alignedData_series = seriesData_sync(sn).SeriesData;
	[seriesData_sync(sn).NeuronGroup_data] = group_aligned_trace_series_ROIpaired(alignedData_series,...
		'ref_stim',ngd.ref_stim,'ref_SpikeCat',ngd.ref_SpikeCat,'other_SpikeCat',ngd.other_SpikeCat,...
		'debug_mode', ngd.debug_mode);
end

%% ====================
% Plot spikes of each ROI recorded in trials received various stimulation
close all
psnt.plot_raw = true; % true/false.
psnt.plot_norm = true; % true/false. plot the ref_trial normalized data
psnt.plot_mean = true; % true/false. plot a mean trace on top of raw traces
psnt.plot_std = true; % true/false. plot the std as a shade on top of raw traces. If this is true, "plot_mean" will be turn on automatically
psnt.y_range = [-10 10];
psnt.tickInt_time = 1; % interval of tick for timeInfo (x axis)
psnt.fig_row_num = 3; % number of rows (ROIs) in each figure
psnt.save_fig = false; % true/false
psnt.fig_position = [0.1 0.1 0.85 0.85]; % [left bottom width height]

if psnt.save_fig
	psnt.save_path = uigetdir(FolderPathVA.fig,'Choose a folder to save spikes from series trials');
	if psnt.save_path~=0
		FolderPathVA.fig = psnt.save_path;
	end 
else
	psnt.save_path = '';
end

series_num = numel(seriesData_sync);
for sn = 1:series_num
	series_name = seriesData_sync(sn).seriesName;
	% NeuronGroup_data = seriesData_sync(sn).NeuronGroup_data;
	plot_series_neuron_paired_trace(seriesData_sync(sn).NeuronGroup_data,'plot_raw',psnt.plot_raw,'plot_norm',psnt.plot_norm,...
		'plot_mean',psnt.plot_mean,'plot_std',psnt.plot_std,'y_range',psnt.y_range,'tickInt_time',psnt.tickInt_time,...
		'fig_row_num',psnt.fig_row_num,'fig_position',psnt.fig_position,'save_fig',psnt.save_path);
end


%% ====================
% Collect all events from series and plot their REFnorm data
[all_series_eventProp] = collect_AllEventProp_from_seriesData(seriesData_sync);
[grouped_all_series_eventProp, varargout] = group_event_info_multi_category(all_series_eventProp,...
	'category_names', {'group'});

close all
pgase.plot_combined_data = true;
pgase.parNames = {'rise_duration_refNorm','peak_mag_delta_refNorm'}; % entry: event
pgase.save_fig = false; % true/false
pgase.save_dir = FolderPathVA.fig;
pgase.stat = true; % true if want to run anova when plotting bars
pgase.stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

% grouped_event_info = grouped_event_info_bk;
[pgase.save_dir, pgase.plot_info] = plot_event_info(grouped_all_series_eventProp,...
	'plot_combined_data', pgase.plot_combined_data, 'parNames', pgase.parNames, 'stat', pgase.stat,...
	'save_fig', pgase.save_fig, 'save_dir', pgase.save_dir);
if pgase.save_dir~=0
	FolderPathVA.fig = pgase.save_dir;
end

% if pgase.save_fig
% 	% plot_stat_info.grouped_event_info_option = grouped_event_info_option;
% 	plot_stat_info.grouped_event_info_filtered = grouped_all_series_eventProp;
% 	plot_stat_info.plot_info = plot_info;
% 	dt = datestr(now, 'yyyymmdd');
% 	save(fullfile(save_dir, [dt, '_plot_stat_info']), 'plot_stat_info');
% end



%% ====================
% Choose a trial_roi_list and compare the rois in it with the ones in alignedData_allTrials to find difference
roilist = trial_roi_list_rb_all;
alignedData = alignedData_allTrials;

neg_roi_num = 0;
for tn = 1:numel(roilist)
	trial_idx = find(strcmp({alignedData_allTrials.trialName},roilist(tn).trialName));
	alignedData_rois = {alignedData(trial_idx).traces.roi};

	roilist_trial_roi = roilist(tn).roi_list;
	roilist(tn).neg_roi_list = setdiff(alignedData_rois,roilist_trial_roi);
	roilist(tn).neg_roi_num = numel(roilist(tn).neg_roi_list);

	neg_roi_num = neg_roi_num+roilist(tn).neg_roi_num;
end


%% ====================
% Draw roi manually and extract calcium data using FIJI. Replace cnmfe data with this and plot traces
folder = 'G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff\IO_ventral_approach\2021-03-29_dff_crop';
file = '2021-03-29-14-19-43_video_sched_0-PP-BP-MC_crop.csv';
% recdata_manual_new = recdata_manual;
% Get the tbl data
csvpath = fullfile(folder,file);
opts = detectImportOptions(csvpath);
tbl = readtable(csvpath,opts);
%% ====================
% Process the tbl to replace the existing cnmfe data
[new_tbl] = ConvertFijiTbl(tbl);

% Replace cnmfe data
trial_loc = 1;
DataStruct = recdata_manual{trial_loc,2};
[DataStruct_new] = Replace_decon_raw_data(DataStruct,new_tbl);
recdata_manual_new{trial_loc,2} = DataStruct_new;


%% ====================
% 9.2.0.3 Plot traces, aligned traces and roi map
close all
save_fig = true; % true/false
pause_after_trial = false;
markers_name = {}; % of which will be labled in trace plot: 'peak_loc', 'rise_loc'

if save_fig
	save_dir = uigetdir(FolderPathVA.fig,'Choose a folder to save plots');
	if save_dir~=0
		FolderPathVA.fig = save_dir;
	end 
end
trial_num = numel(alignedData_allTrials);
tn = 1;
while tn <= trial_num
	close all
	alignedData = alignedData_allTrials(tn);
	plot_trace_roiCoor(alignedData,'markers_name',markers_name,...
		'save_fig',save_fig,'save_dir',save_dir);
	fprintf('- %d/%d: %s\n', tn, trial_num, alignedData.trialName);

	if pause_after_trial
		direct_input = input(sprintf('\n(c)continue  (b)back to previous or input the trial number [default-c]:'), 's');
		if isempty(direct_input)
			direct_input = 'c';
		end
		if strcmpi(direct_input, 'c')
			tn = tn+1; 
		elseif strcmpi(direct_input, 'b')
			tn = tn-1; 
		else
			tn = str2num(direct_input);
		end
	else
		tn = tn+1;
	end
end


%% ====================
% fit the data to exponential curve
% [curvefit,gof,output] = fit(tdata',ydata','exp1');

alignedData = alignedData_allTrials(7);
[TimeInfo,FluroData] = get_TrialTraces_from_alignedData(alignedData,...
		'norm_FluorData',false); 
fVal = FluroData(:,1);
TimeRanges = alignedData_allTrials(7).stimInfo.StimDuration.range  ;
EventTime = [alignedData_allTrials(7).traces(1).eventProp.rise_time];
[curvefit,tauInfo] = GetDecayFittingInfo_neuron(TimeInfo,fVal,TimeRanges,EventTime);
PlotCurveFitting_neuron(curvefit);

%% ==================== 
FitStimIDX = [alignedData_allTrials(7).traces(13).StimCurveFit.SN];
stimTime = alignedData_allTrials(7).stimInfo.StimDuration.range(:,2);
ROIeventProp = alignedData_allTrials(7).traces(13).eventProp;
eventCat = 'rebound';

[stimNum,decayNum,eventIDX,eventFitNum,eventNoFitNum] = get_StimEvents_CloseToFit_roi(FitStimIDX,stimTime,ROIeventProp,eventCat)

%% ==================== 

[List_curveFitNum_eventNum] = get_StimEvents_CloseToFit_trials(alignedData_allTrials,'rebound',2);

%% ====================
% Generate some sample data
x = 1:10;
y = 2*x + 3 + randn(size(x));

% Fit a line to the data using polyfit
coeffs = polyfit(x, y, 1);
yfit = polyval(coeffs, x);

% Calculate R^2
yresid = y - yfit;
SSresid = sum(yresid.^2);
SStotal = (length(y)-1) * var(y);
rsq = 1 - SSresid/SStotal;
fprintf('R^2 = %f\n', rsq);

% Calculate RMSE
rmse = sqrt(mean(yresid.^2));
fprintf('RMSE = %f\n', rmse);

% Plot the data and the fitted line
plot(x, y, 'o', x, yfit, '-')
legend('Data', 'Fitted line')

% %% ==================== 
% To perform frequency power analysis on calcium imaging data in MATLAB, you can follow these steps: 

% 1. Load the data into MATLAB. The data should be in a matrix format, with time on one axis and the
% fluorescence intensity of each neuron on the other axis. 

% 2. Select the time intervals corresponding to the optogenetic stimulations. You can do this by
% creating a vector of logical values that is true during the time intervals when the stimulation
% was delivered. 

% 3. Separate the data into two groups based on whether the stimulation was delivered or not. You
% can do this using the logical vector created in step 2.
    
% 4. Perform frequency power analysis on each group separately. You can use the fft function to
% compute the Fourier transform of the data, and then calculate the power spectrum as the square of
% the absolute value of the Fourier coefficients. 

% 5. Compare the power between the two groups. You can use a statistical test, such as a t-test or
% Wilcoxon rank-sum test, to determine if there is a significant difference in power between the
% stimulated and non-stimulated groups. 

% Here is some example code that demonstrates these steps:

% Load the data
data = load('calcium_data.mat');

% Set the stimulation interval
stim_interval = [1000:2000, 3000:4000, 5000:6000];

% Separate the data into two groups based on the stimulation interval
stim_data = data(:, stim_interval);
nonstim_data = data(:, ~ismember(1:size(data, 2), stim_interval));

% Perform frequency power analysis on each group
stim_power = abs(fft(stim_data)).^2;
nonstim_power = abs(fft(nonstim_data)).^2;

% Calculate the mean power across neurons for each group
stim_mean_power = mean(stim_power, 2);
nonstim_mean_power = mean(nonstim_power, 2);

% Compare the power between the two groups using a t-test
[h, p] = ttest2(stim_mean_power, nonstim_mean_power);
disp(['p-value: ' num2str(p)]);


%% ==================== 
sponTimeRanges(:,1) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1)-15;   
sponTimeRanges(:,2) = alignedData_allTrials(7).stimInfo.UnifiedStimDuration.range(:,1);   
EventsTime = [alignedData_allTrials(7).traces(1).eventProp.rise_time];  
stimIDX_curvefit = [alignedData_allTrials(7).traces(1).StimCurveFit.SN];
[sponFreqList] = get_sponFreq_everyStim_roi(EventsTime,sponTimeRanges,'stimIDX_curvefit',stimIDX_curvefit);


%% ==================== 
tags = {grouped_event_info_filtered.tag};
pos_OG5sRB = find(strcmpi('rebound [og-5s]', tags));

stimNum = [List_decayFitNum_rbNum.stimNum];
fitNum = [List_decayFitNum_rbNum.fitNum];
eventFitNum = [List_decayFitNum_rbNum.eventFitNum];

% Calculate the curve_fit/stimulation_number 
PercFit = fitNum./stimNum; 
meanPercFit = mean(PercFit);
stePercFit = ste(PercFit);

% Calculate the events_with_curveFit/curve_fit
PercEventFit = eventFitNum./fitNum;
meanPercEventFit = mean(PercEventFit);
stePercEventFit = ste(PercEventFit);

% Calculate the events_with_curveFit/stimulation_number
PercEventFitToStimNum = eventFitNum./stimNum;
meanEventFitToStimNum = mean(EventFitToStimNum);
steEventFitToStimNum = ste(EventFitToStimNum);






%% ==================== 
% auto-correlogram

close all
% generate a sample signal
fs = 100; % sampling rate
t = 0:1/fs:10; % time vector
x = sin(2*pi*50*t) + sin(2*pi*150*t); % signal with 50Hz and 150Hz components

% calculate and plot the auto-correlogram
[acor, lag] = xcorr(x, 'coeff');
plot(lag, acor);
xlabel('Lag (samples)');
ylabel('Correlation coefficient');


% % assume you have n recordings, each with spike times in a cell array
% spike_times = {[10, 20, 30, 50, 70, 80, 90, 100, 120, 140, 150], ...
%                [15, 25, 40, 60, 75, 85, 105, 125, 130, 135, 145], ...
%                [20, 40, 55, 65, 70, 85, 95, 110, 125, 140, 155]};

% spike_times_all = cat(1, spike_times{:}); % concatenate all spike times
% max_lag = 10; % set the maximum lag to compute the autocorrelogram
% [autocorr, lags] = xcorr(spike_times_all, max_lag);
% plot(lags, autocorr);

%% ==================== 
% % the probability density function (PDF)
close all
% % Generate random calcium data
% ca_data = sort(randn(1000,1)*5+50); % 1000 samples of random calcium data
% 
% % Calculate PDF using ksdensity
% [f, xi] = ksdensity(ca_data); 
% 
% % Plot PDF
% plot(xi, f);
% xlabel('Calcium Value');
% ylabel('Probability Density');
% title('Calcium Recording PDF');

% Generate some random data
t = 0:0.01:100; % time vector
firing_rate = 5*sin(t); % firing rate (in Hz)
spike_times = poissrnd(firing_rate/1000); % simulate spike times (in ms)
calcium_signal = conv(spike_times, exp(-t/1)); % convolve with exponential decay kernel
calcium_signal = calcium_signal(1:length(t)); % remove extra points


% Estimate the PDF of the calcium signal
[f, x] = ksdensity(calcium_signal);


% Plot the PDF of the calcium signal
figure
plot(x, f)
xlabel('Fluorescence intensity')
ylabel('Probability density')


%%
% close all
% Generate sample data for three ROIs
num_ROIs = 3;
event_times = cell(num_ROIs, 1);
for roi = 1:num_ROIs
    % Generate random number of events between 50 and 100
    num_events = randi([50 100]);
    % Generate random event times between 0 and 300 seconds
    event_times{roi} = sort(rand(num_events, 1)*300);
end

% Calculate inter-event times for each ROI
ieis = cell(num_ROIs, 1);
for roi = 1:num_ROIs
    ieis{roi} = diff(event_times{roi});
end

% Plot histograms of inter-event times for each ROI
figure;
for roi = 1:num_ROIs
    subplot(num_ROIs, 1, roi);
    hold on
    histogram(ieis{roi}, 20, 'Normalization', 'pdf');

    pd = fitdist(ieis{roi}, 'Kernel', 'Kernel', 'normal');
    x_values = linspace(min(ieis{roi}), max(ieis{roi}), 1000);
    y_values = pdf(pd, x_values);
    plot(x_values, y_values);

    % [f, x] = ksdensity(ieis{roi});
    % plot(x,f);

    xlabel('Inter-Event Time (s)');
    ylabel('Probability Density');
    title(sprintf('ROI %d', roi));
    hold off
end

% % Plot probability density functions (PDF) of inter-event times for each ROI
% figure;
% for roi = 1:num_ROIs
%     subplot(num_ROIs, 1, roi);
%     pd = fitdist(ieis{roi}, 'Kernel', 'Kernel', 'normal');
%     x_values = linspace(min(ieis{roi}), max(ieis{roi}), 1000);
%     y_values = pdf(pd, x_values);
%     plot(x_values, y_values);
%     xlabel('Inter-Event Time (s)');
%     ylabel('Probability Density');
%     title(sprintf('ROI %d', roi));
% end

%%
% Example data
recording1 = [0.1, 0.3, 0.8, 1.2, 2.5, 3.0, 3.5];
recording2 = [0.2, 0.5, 0.7, 1.5, 2.0, 2.5, 3.2];
recording3 = [0.4, 0.6, 1.0, 1.8, 2.2, 2.8, 3.3];
all_recordings = {recording1, recording2, recording3};

% Combine all inter-event times
all_inter_event_times = [];
for i = 1:length(all_recordings)
    inter_event_times = diff(all_recordings{i});
    all_inter_event_times = [all_inter_event_times, inter_event_times];
end

% Plot histogram of inter-event times
figure;
histogram(all_inter_event_times, 'Normalization', 'probability');
xlabel('Inter-event time (s)');
ylabel('Probability');
title('Histogram of inter-event times');

% Calculate and plot PDF of inter-event times
[f, x] = ksdensity(all_inter_event_times);
figure;
plot(x, f);
xlabel('Inter-event time (s)');
ylabel('Probability density');
title('PDF of inter-event times');

%%
close all
% create a binary vector for stimulus presentation
stim = [0 0 1 0 0 1 0 1 0 0];

% generate some random calcium event times
event_times = sort(rand(1, 50)*10);

% find closest stimulus presentation times for each event time
stim_times_before = interp1(find(stim), find(stim), event_times, 'previous');
stim_times_after = interp1(find(stim), find(stim), event_times, 'next');

% calculate time differences between event times and closest stimulus presentation times
delta_t_before = event_times - stim_times_before;
delta_t_after = stim_times_after - event_times;
delta_t = [delta_t_before delta_t_after];

% calculate auto-correlogram of delta_t
max_lag = 10; % maximum lag time
acf = xcorr(delta_t, max_lag, 'normalized');

% plot auto-correlogram
stem(-max_lag:max_lag, acf);
xlabel('Lag (s)');
ylabel('Normalized Auto-correlation');


[eventIntAll] = get_eventTimeInt(alignedData_allTrials,'peak_time',...
	'filter_roi_tf',true,'stim_names','ap-0.1s','filters',{[nan 1 nan], [1 nan nan], [nan nan nan]});

[histHandle] = plot_NormHistWithPDF(eventIntAll,[0:0.5:20],...
	'xlabelStr','time (s)','titleStr','Inter-event time [ap-0.1s ex]');




filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan 1 nan], [1 nan nan], [nan nan nan]}; % [ex in rb]
eventType = 'peak_time';
binsOrEdges = [0:0.5:20];
plot_eventTimeInt_alignedData_allTrials(alignedData_allTrials,eventType,binsOrEdges,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters);


%%
close all
eventType = 'peak_time';

trialNum = numel(alignedData_og);
eventTimeTrials = cell(1,trialNum);

for tn = 1:trialNum
	% get the events time (rise or peak) from all ROIs in a single trial
	eventsTime = get_TrialEvents_from_alignedData(alignedData_og(tn),eventType);
	
	% concatenate ROIs' event intervals 
	eventTimeTrials{tn} = eventsTime;
end
eventTimeAll = [eventTimeTrials{:}];

% Assuming you have extracted calcium events from multiple neurons and stored them in a cell array called "events"
% events{1} contains the events from neuron 1, events{2} contains the events from neuron 2, and so on.

num_neurons = length(eventTimeAll);
corr_all = []; % initialize a matrix to store the cross-correlations

for i = 1:num_neurons
    for j = i+1:num_neurons % only calculate the cross-correlation for distinct pairs of neurons
        [corr, lags] = xcorr(eventTimeAll{i}, eventTimeAll{j}, 'none'); % calculate the cross-correlation and lags
        corr_all = [corr_all; corr]; % store the correlation coefficients in a matrix
    end
end

% Plot the average cross-correlation across all pairs of neurons
figure;
mean_corr = mean(corr_all, 1); % calculate the mean correlation across all pairs of neurons
plot(lags, mean_corr);
xlabel('Lags');
ylabel('Cross-correlation coefficient');
title('Average cross-correlation across multiple neurons');

acf = cell(1,5);
lags = cell(1,5);
bounds = cell(1,5);
for n = 1:5
	[acf{n},lags{n},bounds{n}] = autocorr(eventTimeAll{n},'NumLags',10);
end
et = eventTimeAll(1:5);


figure
hold on
for m = 1:5
	plot(acf{m})
end
hold off


%%
% Example data
event_times = {[1, 5, 10, 15, 20], [2, 6, 11, 16, 21], [3, 7, 12, 17, 22], [4, 8, 13, 18, 23], [9, 14, 19, 24]};
lags = 0:0.5:5; % specify lag bins

% Initialize histogram counts
hist_counts = zeros(length(lags)-1, 1);

% Calculate histogram counts
for i = 1:length(event_times)
    acor = xcorr(event_times{i}-mean(event_times{i}), lags, 'none');
    hist_counts = hist_counts + histcounts(acor, lags);
end

% Plot histogram
histogram(hist_counts,lags(1:end-1));
xlabel('Lags (s)');
ylabel('Counts');
title('Autocorrelation Histogram');


%% 
QTM_mat_path = 'G:\Workspace\Mocap\Mos1a_2023_03_31_matfiles_for_naming\MOS1a_S19_M5_MCL2_T2_TRE_2023_03_31.mat';
QTM_mat = matfile(QTM_mat_path);




[f,p] = uigetfile;
isxdfile = fullfile(p,f);

isdxMovie = isx.Movie.read(isxdfile);
sampling_frequency = 1/isdxMovie.timing.period.secs_float;
datetime = isdxMovie.timing.start.datetime;
frameNum = isdxMovie.timing.num_samples;

opts.downsampleFactor = 1;
opts.newFilename = fullfile(p,'2023-03-30-18-26-47_video_trig_0.hdf5');
ciapkg.inscopix.convertInscopixIsxdToHdf5(isxdfile,'options',opts)



% Define the input timestamp
timestamp = "2023-03-31, 13:04:41.533	5449.33313310";

% Extract the date and time components from the timestamp
dt = datetime(timestamp, 'InputFormat', 'yyyy-MM-dd, HH:mm:ss.SSS', 'TimeZone', 'local');

% Convert the datetime object to a string in the desired format
formatted_date = datestr(dt, 'yyyy-mm-dd-hh-MM-ss');

% Display the formatted date
disp(formatted_date);

isxd_recStartTime = cellfun(@(x) x(1:19),names,'UniformOutput',false);
isxd_dt = cellfun(@(x) datetime(x,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local'),...
	isxd_recStartTime,'UniformOutput',false);
mocap1_time = datetime(x(1).recStartTime,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local')


QTMmatFolderPath = 'G:\Workspace\Mocap\Mos1a_2023_03_31_matfiles_for_naming';
nVokeRawDataFolder = 'S:\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\Moscope\Moscope_CaImg\Raw_recordings\MOS1A_2023-03-31';
nVokeRenameDataFolder = 'S:\PROCESSED_DATA_BACKUPS\nRIM_MEMBERS\Moscope\Moscope_CaImg\Raw_recordings_renamed';
[nVoke_oldNew_filenames,debriefing] = batchMod_nVoke2_filenames('QTMmatFolderPath',QTMmatFolderPath,...
	'nVokeRawDataFolder',nVokeRawDataFolder,'nVokeRenameDataFolder',nVokeRenameDataFolder);


[bin_Events] = plot_autoCorrelogramEvents(alignedData_allTrials,...
			'timeType','rise_time','stimName','ap-0.1s','stimEventCat','trig',...
			'remove_centerEvents',true,'binWidth',0.25,'normData',true,'saveFig',true);


%%
offStimData = grouped_event_info_filtered(2).event_info;
followData = grouped_event_info_filtered(1).event_info;
[pairedStat.rise_duration.h,pairedStat.rise_duration.p] = ttest([followData.rise_duration],[offStimData.rise_duration]);
[pairedStat.FWHM.h,pairedStat.FWHM.p] = ttest([followData.FWHM],[offStimData.FWHM]);
[pairedStat.peak_mag_delta.h,pairedStat.peak_mag_delta.p] = ttest([followData.peak_mag_delta],[offStimData.peak_mag_delta]);
[pairedStat.sponnorm_peak_mag_delta.h,pairedStat.sponnorm_peak_mag_delta.p] = ttest([followData.sponnorm_peak_mag_delta],[offStimData.sponnorm_peak_mag_delta]);

%% Delete the recordings with names in the trialNamesDiscard
trialNamesDiscard = {'20210326-150725_video_sched_0-PP-BP-MC-ROI.csv',...
'20210326-151454_video_sched_0-PP-BP-MC-ROI.csv','20210326-152008_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-135544_video_sched_0-PP-BP-MC-ROI.csv','20210329-140143_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-141943_video_sched_0-PP-BP-MC-ROI.csv','20210329-142437_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-142928_video_sched_0-PP-BP-MC-ROI.csv','20210405-134049_video_sched_0-PP-BP-MC-ROI.csv',...
'20210409-130356_video_sched_0-PP-BP-MC-ROI.csv'};
trialNames = recdata_organized_old_part(:,1);
trialNamesDiscardIDX = cellfun(@(x) find(strcmpi(x,trialNames)),trialNamesDiscard);
recdata_organized_old_part(trialNamesDiscardIDX,:) = [];


%% Copy the stimulation name and the gpio info from the old recdata
trialNamesDiscard = {'20210326-150725_video_sched_0-PP-BP-MC-ROI.csv',...
'20210326-151454_video_sched_0-PP-BP-MC-ROI.csv','20210326-152008_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-135544_video_sched_0-PP-BP-MC-ROI.csv','20210329-140143_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-141943_video_sched_0-PP-BP-MC-ROI.csv','20210329-142437_video_sched_0-PP-BP-MC-ROI.csv',...
'20210329-142928_video_sched_0-PP-BP-MC-ROI.csv','20210405-134049_video_sched_0-PP-BP-MC-ROI.csv',...
'20210409-130356_video_sched_0-PP-BP-MC-ROI.csv'};
trialNames = recdata_organized_old_part(:,1);
trialNamesDiscardIDX = cellfun(@(x) find(strcmpi(x,trialNames)),trialNamesDiscard);
for n = 1:numel(trialNamesDiscard)
	recdata{n,3} = recdata_organized_old{trialNamesDiscardIDX(n),3};
	recdata{n,4} = recdata_organized_old{trialNamesDiscardIDX(n),4};
end

%%
recdata_organized = [recdata_organized_old_part;recdata_organized];

% Original cell array of strings
trialNamesDiscard = {
    '20210326-150725_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210326-151454_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210326-152008_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-135544_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-140143_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-141943_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-142437_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210329-142928_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210405-134049_video_sched_0-PP-BP-MC-ROI.csv', ...
    '20210409-130356_video_sched_0-PP-BP-MC-ROI.csv'
};

% Extract date and time portions and convert to datetime format
datesAndTimes = cellfun(@(str) datetime(str(1:15), 'InputFormat', 'yyyyMMdd-HHmmss'), trialNamesDiscard);

% Sort the strings based on date and time
[sortedDatesAndTimes, sortedIndices] = sort(datesAndTimes);

% Sort the original cell array using the sorted indices
sortedTrialNamesDiscard = trialNamesDiscard(sortedIndices);


%% ====================
close all
save_fig = false; % true/false
gui_save = 'on';

filter_roi_tf = true; % true/false. If true, screen ROIs
stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
filters = {[nan nan nan nan], [nan nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

propName = 'peak_time'; % 'rise_time'/'peak_time'. Choose one to find the loactions of events
binWidth = 1; % the width of histogram bin. the default value is 1 s.
stimIDX = []; % []/vector. specify stimulation repeats around which the events will be gathered. If [], use all repeats 
preStim_duration = 5; % unit: second. include events happened before the onset of stimulations
postStim_duration = 15; % unit: second. include events happened after the end of stimulations

stimEventsPos = false; % true/false. If true, only use the peri-stim ranges with stimulation related events
stimEvents(1).stimName = 'og-5s';
stimEvents(1).eventCat = 'rebound';
stimEvents(1).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(2).stimName = 'ap-0.1s';
stimEvents(2).eventCat = 'trig';
stimEvents(2).eventCatFollow = 'spon'; % The category of first event following the eventCat one
stimEvents(3).stimName = 'og-5s ap-0.1s';
stimEvents(3).eventCat = 'rebound';
stimEvents(3).eventCatFollow = 'spon'; % The category of first event following the eventCat one

normToBase = true; % true/false. normalize the data to baseline (data before baseBinEdge)
baseBinEdgestart = -preStim_duration; % where to start to use the bin for calculating the baseline. -1
baseBinEdgeEnd = -2; % 0

debug_mode = false; % true/false

[violinData,statInfo] = violinplotPeriStimFreq(alignedData_allTrials);


timeData = alignedData_allTrials(1).fullTime;
stimInfo = alignedData_allTrials(1).stimInfo;
[timeRanges,timeRangesIDX,stimRanges,stimRangesIDX,timeDuration,datapointNum] = createTimeRangesUsingStimInfo(timeData,stimInfo)
eventsTime = [alignedData_allTrials(1).traces(1).eventProp.peak_time];
[posTimeRanges,posRangeIDX,negRangeIDX,rangEventsTime,rangEventsIDX] = getRangeIDXwithEvents(eventsTime,timeRanges)


alignedData = alignedData_allTrials(7);
fluroData = alignedData.traces(1).fullTrace;
timeData = alignedData.fullTime;
% eventsTime = [alignedData.traces(1).eventProp.peak_time];
roiNum = numel(alignedData.traces);
fluroData = cell(1,roiNum);
eventsTime = cell(roiNum,1);
eventCat = cell(roiNum,1);
for rn = 1:roiNum
	fluroData{rn} = alignedData.traces(rn).fullTrace;
	eventsTime{rn} = [alignedData.traces(rn).eventProp.peak_time];
	eventCat{rn} = {alignedData.traces(rn).eventProp.peak_category};
end
fluroData = horzcat(fluroData{:});
stimInfo = alignedData_allTrials(1).stimInfo;
preTime = 5;
postTime = 10;
% eventCat = {alignedData_allTrials(1).traces(1).eventProp.peak_category};
stimEventCat = 'rebound';
followEventCat = 'spon';
stimRefType = 'end';
debugMode = false;
[sortedIDX,sortedFdSection,sortedEventMarker,sortedRowNames,sortedEventNumIDX] = sortPeriStimTraces(fluroData,timeData,...
		eventsTime,stimInfo,'preTime',preTime,'postTime',postTime,...
		'eventCat',eventCat,'stimEventCat',stimEventCat,'followEventCat',followEventCat,...
		'stimRefType',stimRefType,'debugMode',debugMode);


%% ====================
timeInfo = alignedData_allTrials(2).fullTime;
stimInfo = alignedData_allTrials(2).stimInfo;

[periStimSections] = setPeriStimSectionForEventFreqCalc(timeInfo,stimInfo);

x = periStimSections(sn,:)
[y,closestIndex] = find_closest_in_array(x,timeInfo)


[stimFollowEventsPair] = getStimEventFollowEventROI(alignedData(1),'trig','spon')

[sponEventsInt,osr,osrNum] = getSponEventsInt(alignedData(1))


[intData] = stimEventSponEventIntAnalysis(alignedData,'ap-0.1s','trig')


%% ====================
figure
plot(timeInfo,traceData);

hold on

preCloseHMTime = timeInfo(HMstartLoc);
preCloseHMData = traceData(HMstartLoc);

postCloseHMTime = timeInfo(HMendLoc);
postCloseHMData = traceData(HMendLoc);

nanIDX = find(isnan(HMendLoc));
halfMax(nanIDX) = [];
preCloseHMTime(nanIDX) = [];
preCloseHMData(nanIDX) = [];
postCloseHMTime(nanIDX) = [];
postCloseHMData(nanIDX) = [];

plot(preCloseHMTime,preCloseHMData,'ko');
plot(postCloseHMTime,postCloseHMData,'k*');

plot(timeAtHM(:,1),halfMax,'ro');
plot(timeAtHM(:,2),halfMax,'r*');



%% ====================
% Sample data for two groups, each group has 5 time-points
% group1_data = {data for time1, data for time2, data for time3, data for time4, data for time5};
% group2_data = {data for time1, data for time2, data for time3, data for time4, data for time5};
% 
% Combine the data into a single matrix
dataMatrix = [cell2mat(group1_data); cell2mat(group2_data)];

% Create grouping variables for the two independent variables
groupVar = [repmat({'Group1'}, 1, 5), repmat({'Group2'}, 1, 5)];
timeVar = ['Time1', 'Time2', 'Time3', 'Time4', 'Time5'];

% Perform two-way ANOVA
[p, tbl, stats] = anovan(dataMatrix, {groupVar, timeVar}, 'varnames', {'Group', 'Time'});

% 'p' contains the p-values for main effects and interaction
% 'tbl' is the ANOVA table
% 'stats' contains additional information about the ANOVA

% Display the results
disp(tbl);

idx = [1 3];
xDataCells = {diffStat(idx).xB};
yDataCells = {diffStat(idx).dataBnorm};
legStr = {diffStat(idx).groupB};
stimShadeData = {diffStat(idx).shadeB};
plot_errorBarLines_with_scatter_stimShade(xDataCells,yDataCells,'legStr',legStr,'stimShadeData',stimShadeData)

diffStat(dpn).shadeB.shadeData


%% ====================
ogData = PSEF_Data(1).binData;
ogMeans = cellfun(@mean,ogData);
ogapData = PSEF_Data(3).binData;
ogapDataNorm = cell(size(ogapData));

for n = 1:numel(ogapData)
	ogapDataNorm{n} = ogapData{n}/ogMeans(n);
end
ogapDataNormMeans = cellfun(@mean,ogapDataNorm)



 
%% ====================
% 2023-07-31
% event freq comparison: OG vs OGAP in AP bin
save_fig = false;
titleStr = 'eventFreq OG vs OGAP in AP bin';
OGvsOGAPdata = {violinData.eventFreq};
groupNames = {violinData.stim};
[violinInfo1,FolderPathVA.fig] = violinplotWithStat(OGvsOGAPdata,...
	'groupNames',groupNames,...
	'titleStr',titleStr,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','on');


% event freq comparison: baseline of AP vs AP
titleStr = 'eventFreq baseline vs AP';
BASEvsAP = {barStat(2).data(1).group_data barStat(2).data(3).group_data};
groupNames = {'baseline', 'AP'};
[violinInfo2,FolderPathVA.fig] = violinplotWithStat(BASEvsAP,...
	'groupNames',groupNames,...
	'titleStr',titleStr,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save','off');


% bar plot of the fold-change of event frequency in violinInfo1 and violinInfo2
title_str = 'foldChange of eventFreq caused by AP with and without OG';
[f,f_rowNum,f_colNum] = fig_canvas(1,'unit_width',0.4,'unit_height',0.4,...
	'column_lim',1,...
    'fig_name',titleStr); % create a figure
foldDataOGAP = violinInfo1.data.ogap/mean(violinInfo1.data.og);  
foldDataAP = violinInfo2.data.AP/mean(violinInfo2.data.baseline);
[barInfo] = barplot_with_stat({foldDataAP,foldDataOGAP},'plotWhere',gca,...
	'group_names',{'without OG','with OG'},'ylabelStr','eventFreq fold-change',...
	'title_str',title_str,'save_fig',save_fig,'save_dir',FolderPathVA.fig,'gui_save',false);

%% ====================
filter_roi_tf = true;
stim_names = {'og-5s'};
filters = {[0 nan nan nan]};
alignedData = alignedData_allTrials;
saveFig = true;
save_dir = '';
guiSave = true; % Options: 'on'/'off'. whether use the gui to choose the save_dir

[analysisResult] = stimCurveFitAnalysis(alignedData,...
	'filter_roi_tf',filter_roi_tf,'stim_names',stim_names,'filters',filters,...
	'saveFig',saveFig,'save_dir',save_dir,'guiSave',guiSave);

%% ====================
pieData = [analysisResult.roiNumFit analysisResult.roiNumNotFit];
sliceNames = {'ROIs with decay curves', 'ROIs without decay curves'};

stylishPieChart(pieData,'sliceNames',sliceNames)

%% ====================
barData{1,1} = analysisResult.preEventFreqFit;
barData{1,2} = analysisResult.preEventFreqNotFit;
[barInfo] = barplot_with_errBar(barData)

barNames = {'a','bb','ccc','dddd','eeeee'};


%% ====================
eventTimeType = 'peak_time'; % rise_time/peak_time
binSize = 1; % unit: second
visualizeData = true;
saveFig = false;
alignedDataRec = alignedData_allTrials(1);
% [corrMatrix,corrFlat,distMatrix,distFlat,roiNames,recName] = roiCorrAndDistSingleRec(alignedDataRec,binSize,'eventTimeType',eventTimeType);
% [heatmapHandle] = heatMapRoiCorr(corrMatrix,roiNames,'recName',recName);

% [corrMatrix,corrFlat,distMatrix,distFlat] = roiCorrAndDistSingleRec(alignedDataRec,binSize,'visualizeData',true);

[corrAndDist,corrFlatAll,distFlatAll] = roiCorrAndDistMultiRec(alignedData_allTrials,binSize,...
	'visualizeData',visualizeData,'eventTimeType',eventTimeType,'dbMode',false); 


%% ==========
videoFileIsxd = '';
videoFileTiff = '';
imuFileIsxd = '';
imuFileTiff = '';

isx.export_movie_to_tiff(videoFileIsxd,videoFileTiff);
isx.export_movie_to_tiff(videoFileIsxd,videoFileTiff);



%% ==========
saveFig = false;
dbMode = true; % debug mode
[timeLagCorr] = roiCorrAndtimeLagCorr(alignedData_allTrials,0.05,[1:3],...
	'visualizeData',true,'saveFig',saveFig,'dbMode',true);



%% ==========
matrixData = [alignedData_allTrials(1).traces(:).fullTrace];

%% ==========
roi_map = alignedData_allTrials(4).roi_map;
roiCoor = {alignedData_allTrials(4).traces.roi_coor}';
roiCoor = cell2mat(roiCoor);
roiCoor = convert_roi_coor(roiCoor);
roiNames = {alignedData_allTrials(4).traces(:).roi};

figure;
imagesc(roi_map); % Display the ROI map
colormap('jet'); % Optional: Choose a colormap that suits your data
axis equal; % Keep the aspect ratio of the map
hold on; % Keep the map displayed while plotting the labels


for i = 1:length(roiNames)
    % Extract the coordinates for the current ROI
    x = roiCoor(i, 1);
    y = roiCoor(i, 2);

    % Place the text label on the map
    text(x, y, roiNames{i}, 'Color', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center');
end



%% ==========
close all
[riseVals,peakVals,eventTypesAll] = getRisePeakValFromRecordings(alignedData_allTrials,'normWithSponEvent',true);
stylishScatter(riseVals,peakVals);
[Rrvpv, pValuervpv,RL1,RU1] = corrcoef(riseVals, peakVals);
correlationCoefficientRVPV = Rrvpv(1,2);


peakAmps = peakVals-riseVals;
stylishScatter(riseVals,peakAmps);
[Rrvpa, pValuervpa,RL2,RU2] = corrcoef(riseVals, peakAmps);
correlationCoefficientRVPA = Rrvpa(1,2);

%% ==========
close all
[riseVals,peakVals,eventTypesAll] = getRisePeakValFromRecordings(alignedData_allTrials,'normWithSponEvent',true);
peakAmps = peakVals-riseVals;
sepGroups = {'AP-trig','OGAP-trig-ap','OG-rebound','OGAP-rebound'}; % plot these in different color. All the rest group in another color

sepGroupsStruct = empty_content_struct({'labels','riseVals','peakVals','peakAmps'},numel(sepGroups)+1);
for i = 1:numel(sepGroups)
	sepGroupsStruct(i).labels = sepGroups{i};
	tf = strcmpi(sepGroupsStruct(i).labels,eventTypesAll);
	IDX = find(tf);
	sepGroupsStruct(i).riseVals = riseVals(IDX);
	sepGroupsStruct(i).peakVals = peakVals(IDX);
	sepGroupsStruct(i).peakAmps = peakAmps(IDX);

	eventTypesAll(IDX) = [];
	riseVals(IDX) = [];
	peakVals(IDX) = [];
	peakAmps(IDX) = [];
end

sepGroupsStruct(end).labels = 'other';
sepGroupsStruct(end).riseVals = riseVals;
sepGroupsStruct(end).peakVals = peakVals;
sepGroupsStruct(end).peakAmps = peakAmps;

figure
gca
colors = {'#3A8E9E','#873A9E','#9E683A','#7B9E3A','#AFAFAF'};
% colors = {'#1267B3','#00615B','#61461B','#66645B','#AFAFAF'};
for j = 1:numel(sepGroupsStruct)-1
	hold on
	stylishScatter(sepGroupsStruct(j).riseVals,sepGroupsStruct(j).peakVals,...
		'plotWhere',gca,'MarkerFaceColor',colors{j},'MarkerSize',20,...
		'xlabelStr','riseVals','ylabelStr','peakVals');
end
legend({sepGroupsStruct.labels})
hold off
set(gca,'children',flipud(get(gca,'children')))



figure
gca
colors = {'#3A8E9E','#873A9E','#9E683A','#7B9E3A','#AFAFAF'};
% colors = {'#1267B3','#00615B','#61461B','#66645B','#AFAFAF'};
for j = 1:numel(sepGroupsStruct)-1
	hold on
	stylishScatter(sepGroupsStruct(j).riseVals,sepGroupsStruct(j).peakAmps,...
		'plotWhere',gca,'MarkerFaceColor',colors{j},'MarkerSize',20,...
		'xlabelStr','riseVals','ylabelStr','peakAmps');
end
legend({sepGroupsStruct.labels})
hold off
set(gca,'children',flipud(get(gca,'children')))

%% ==========
recdata{11, 2}.FOV_loc = recdata{10, 2}.FOV_loc;
recdata{11, 2}.mouseID = recdata{10, 2}.mouseID;
recdata{11, 2}.fovID = recdata{10, 2}.fovID;

%% ==========
datafolderpath = 'D:\guoda\Documents\Workspace Large Files\OIST\confocal\20211014_ventralApproach_G137-G141';
makeFolderThumbnails(datafolderpath, 'fileType', 'czi', 'method', 'mean', 'frameIndex', 'all', 'aspectRatio', 'original', 'newHeight', 256, 'imageDescriptor', 'BilateralInjection');


%% ==========
% Plot calcium traces by reading the csv file exported by the IDPS software
close all
saveFig = true; % true/false
showYtickRight = true;
[timeFluorTab,csvFolder,csvName] = readInscopixTraceCsv; % csvName does not contain the file extension
timeFluorTab{:,2:end} = timeFluorTab{:,2:end} .* 100; % Convert the deltaF/F to deltaF/F %
plot_TemporalData_Trace([],timeFluorTab{:,1},timeFluorTab{:,2:end},...
	'ylabels',timeFluorTab.Properties.VariableNames,'showYtickRight',showYtickRight)

if saveFig
	msg = 'Save the ROI traces';
	savePlot(gcf,'save_dir',csvFolder,'guiSave',true,...
		'guiInfo',msg,'fname',csvName);
end


%% ==========
% Copy the roi names to recdata{n,2}.locTag.roiNames

% Loop through the recordings
recNum = size(recdata,1);
for n = 1:recNum
	roiNames = recdata{n,2}.raw.Properties.VariableNames(2:end);
	[recdata{n,2}.locTag.roiNames] = roiNames{:};
end