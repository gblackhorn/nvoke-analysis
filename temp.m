%% ====================
% Plot alignedData. Group traces according to stimulation
% event_type of alignedData is stimWin
plot_combined_data = true;
plot_stim_shade = true;
y_range = [-20 30];

alignedData = alignedData_filtered;
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


