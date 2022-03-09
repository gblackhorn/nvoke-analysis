%% ====================
% Plot alignedData. Group traces according to stimulation
% event_type of alignedData is stimWin
plot_combined_data = true;
plot_stim_shade = true;
y_range = [-20 30];

alignedData = alignedData_allTrials;
[C, ia, ic] = unique({alignedData.stim_name});
num_C = numel(C);

f_trace_win = figure;
fig_position = [0.1 0.1 0.8 0.4];
set(gcf, 'Units', 'normalized', 'Position', fig_position)
tlo = tiledlayout(f_trace_win, 1, 3);

for n = 1:num_C
	ax = nexttile(tlo);

	stimName = C{n};
	IDX_trial = find(ic == n);
	timeInfo = alignedData(IDX_trial(1)).time;
	stim_range = {alignedData(IDX_trial(1)).stimInfo.time_range};
	num_stimTrial = numel(IDX_trial); % number of trials applied with the same stim
	traceData_cell_trials = cell(1, num_stimTrial); 
	for nst = 1:num_stimTrial
		traceInfo_trial = alignedData(IDX_trial(nst)).traces;
		num_roi = numel(traceInfo_trial);
		traceData_cell_rois = cell(1, num_roi);
		for nr = 1:num_roi
			traceData_cell_rois{nr} = traceInfo_trial(nr).value;
		end
		traceData_cell_trials{nst} = [traceData_cell_rois{:}];
	end
	traceData_trials = [traceData_cell_trials{:}];
	traceData_trials_mean = mean(traceData_trials, 2, 'omitnan');
	traceData_trials_shade = std(traceData_trials, 0, 2, 'omitnan');

	plot_trace(timeInfo, traceData_trials, 'plotWhere', ax,...
		'plot_combined_data', plot_combined_data,...
		'mean_trace', traceData_trials_mean, 'mean_trace_shade', traceData_trials_shade,...
		'plot_stim_shade', plot_stim_shade, 'stim_range', stim_range,...
        'y_range', y_range); % 'y_range', y_range

	title(stimName)
end

%% ====================
% Plot alignedData. Group traces according to stimulation
% event_type of alignedData is detected_events
close all
catNames = {'spon','trig', 'trig-AP', 'rebound'};
plot_combined_data = true;
plot_stim_shade = true;
y_range = [-20 30];

alignedData = alignedData_filtered;
timeInfo = alignedData(1).time;
stimNames = {alignedData.stim_name};

idx_ap = find(strcmp('GPIO-1-1s', stimNames));
idx_op = find(strcmp('OG-LED-5s', stimNames));
idx_op_ap = find(strcmp('OG-LED-5s GPIO-1-1s', stimNames));
alignedData_ap = alignedData(idx_ap);
alignedData_opAll = alignedData([idx_op idx_op_ap]);
alignedData_op_ap = alignedData(idx_op_ap);

alignedTraces = struct('peakCat', cell(1, 5), 'traces', cell(1, 5),...
	'traceMean', cell(1, 5), 'traceStd', cell(1, 5));

num_cat = numel(catNames);
for nc = 1:num_cat
	cat_name = catNames{nc};
	switch cat_name
		case 'spon'
			alignedTraces(1).peakCat = 'spon';
			[alignedTraces(1).traces,~,alignedTraces(1).traceMean,alignedTraces(1).traceStd] = collect_aligned_trace(alignedData,cat_name);
		case 'trig'
			alignedTraces(2).peakCat = 'trig [AP-1s]';
			alignedTraces(3).peakCat = 'trig [OPTO-5s]';
			[alignedTraces(2).traces,~,alignedTraces(2).traceMean,alignedTraces(2).traceStd] = collect_aligned_trace(alignedData_ap,cat_name);
			[alignedTraces(3).traces,~,alignedTraces(3).traceMean,alignedTraces(3).traceStd] = collect_aligned_trace(alignedData_opAll,cat_name);
		case 'rebound'
			alignedTraces(4).peakCat = 'rebound [OPTO-5s]';
			[alignedTraces(4).traces,~,alignedTraces(4).traceMean,alignedTraces(4).traceStd] = collect_aligned_trace(alignedData_opAll,cat_name);
		case 'trig-AP'
			alignedTraces(5).peakCat = 'trig-AP [OPTO-5s AP-1S]';
			[alignedTraces(5).traces,~,alignedTraces(5).traceMean,alignedTraces(5).traceStd] = collect_aligned_trace(alignedData_op_ap,cat_name);
		otherwise
	end
end

f_trace_event = figure;
fig_position = [0.1 0.1 0.8 0.7];
set(gcf, 'Units', 'normalized', 'Position', fig_position)
tlo = tiledlayout(f_trace_event, 2, 3);

for n = 1:numel(alignedTraces)
	ax = nexttile(tlo);
	plot_trace(timeInfo, alignedTraces(n).traces, 'plotWhere', ax,...
			'plot_combined_data', plot_combined_data,...
			'mean_trace', alignedTraces(n).traceMean, 'mean_trace_shade', alignedTraces(n).traceStd,...
			'y_range', y_range); % 'y_range', y_range
	title(alignedTraces(n).peakCat)
end


%% ====================
% test color
x = [1:10];
y = ones(1, numel(x));
colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F'};
sf = figure;
hold on
for n = 1:numel(x)
	scatter(x(n), y(n), 100, 'filled', 'MarkerFaceColor', colorGroup{n},...
		'MarkerFaceAlpha',1,'MarkerEdgeAlpha',0)
end
hold off



%% ====================
alignedData = alignedData_allTrials(17);
roiMap = alignedData.roi_map;
roiNames = alignedData.traces.roi;
roiCoor = {alignedData.traces.roi_coor}';
roiCoor = cell2mat(roiCoor);
roiCoor = convert_roi_coor(roiCoor);
plot_roi_coor(roiMap,roiCoor,[]);



%% ====================
% get the stimEffect and related info for checking the parameter
num_trial = numel(alignedData_allTrials);

in_info_cell = cell(1, num_trial);
for tn = 1:num_trial
	trialData = alignedData_allTrials(tn);
	trialName = trialData.trialName;
	timeInfo = trialData.fullTime;
	stimName = trialData.stim_name;
	stimTimeInfo = trialData.stimInfo(1).time_range_notAlign;  

	% fprintf('trial %d/%d: %s\n', tn, num_trial, trialName)

	if contains(stimName, 'OG-LED', 'IgnoreCase',true)
		num_roi = numel(trialData.traces);
		in_info_struct =  struct('trial', cell(1, num_roi), 'roi', cell(1, num_roi),...
			'inhibition', cell(1, num_roi), 'excitation',...
			cell(1, num_roi),'rebound', cell(1, num_roi), 'ex_in', cell(1, num_roi),...
			'meanIn_average', cell(1, num_roi), 'sponStim_logRatio', cell(1, num_roi));

		for rn = 1:num_roi
			roiData = trialData.traces(rn);
			roiName = roiData.roi;
			traceData = roiData.fullTrace;
			eventCats = roiData.eventProp;
			sponfq = roiData.sponfq;
			stimfq = roiData.stimfq;
			freq_spon_stim = [sponfq stimfq];

			% fprintf(' - roi %d/%d: %s\n', rn, num_roi, roiName)

			[stimEffect,in_info] = get_stimEffect(timeInfo,traceData,stimTimeInfo,eventCats,...
				'freq_spon_stim', freq_spon_stim);
			if roiData.stimEffect.excitation && roiData.stimEffect.inhibition
				ex_in = true;
			else
				ex_in = false;
			end

			in_info_struct(rn).trial = trialName;
			in_info_struct(rn).roi = roiName;
			in_info_struct(rn).inhibition = roiData.stimEffect.inhibition;
			in_info_struct(rn).excitation = roiData.stimEffect.excitation;
			in_info_struct(rn).rebound = roiData.stimEffect.rebound;
			in_info_struct(rn).ex_in = ex_in;
			in_info_struct(rn).meanIn_average = in_info.meanIn_average;
			in_info_struct(rn).sponStim_logRatio = in_info.sponStim_logRatio;
		end
		in_info_cell{tn} = in_info_struct;
	end
end
in_info_all = [in_info_cell{:}];

% plot
close all
colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};
tf_inhibition = [in_info_all.inhibition];
tf_excitation = [in_info_all.excitation];
tf_rebound = [in_info_all.rebound];
tf_ExIn = [in_info_all.ex_in];

idx_inhibition = find(tf_inhibition);
idx_excitation = find(tf_excitation);
idx_rebound = find(tf_rebound);
idx_ExIn = find(tf_ExIn);

meanTrace_stim.inhibition = [in_info_all(idx_inhibition).meanIn_average];
meanTrace_stim.excitation = [in_info_all(idx_excitation).meanIn_average];
meanTrace_stim.rebound = [in_info_all(idx_rebound).meanIn_average];
meanTrace_stim.ExIn = [in_info_all(idx_ExIn).meanIn_average];

logRatio_SponStim.inhibition = [in_info_all(idx_inhibition).sponStim_logRatio];
logRatio_SponStim.excitation = [in_info_all(idx_excitation).sponStim_logRatio];
logRatio_SponStim.rebound = [in_info_all(idx_rebound).sponStim_logRatio];
logRatio_SponStim.ExIn = [in_info_all(idx_ExIn).sponStim_logRatio];

groups = {'inhibition', 'excitation', 'rebound', 'ExIn'}; % 'rebound'
num_groups = numel(groups);
figure
hold on
for gn = 1:num_groups
	if contains(groups{gn}, 'rebound')
		mSize = 30;
	else
		mSize = 80;
	end
	h(gn) = scatter(meanTrace_stim.(groups{gn}), logRatio_SponStim.(groups{gn}),...
		mSize, 'filled', 'MarkerFaceColor', colorGroup{gn},...
		'MarkerFaceAlpha', 1, 'MarkerEdgeAlpha', 0);
end
legend(h(1:num_groups), groups, 'Location', 'northeastoutside', 'FontSize', 16);
xlabel('meanTraceDiff during stimulation', 'FontSize', 16)
ylabel('log(freqSpon/freqStim)', 'FontSize', 16)
hold off



