% workflow for developing
recSN = 3; % recording serial number in the result table
trace_col = 2; % column of trace data in the table
stat_col = 5; % column of statistics in the table
rowinStat = 3; % row in the stat table
resultTable = modified_ROIdata;
lowpassedData = resultTable{recSN, trace_col}.lowpass; 
timeinfo = lowpassedData.Time;
traces = lowpassedData{:, 2:end};
roiNames = lowpassedData.Properties.VariableNames(2:end); 
statInfo = resultTable{recSN, stat_col}{rowinStat, :};
statInfo = cellfun(@(x) x{:, {'Rise_start', 'Peak_loc'}}, statInfo, 'UniformOutput', false); % only keep rise and peak index info

%% plot_trace_peak_rise
timeinfo = time_info;
traceinfo = [roi_col_data roi_col_data_lowpassed roi_col_data_raw];


peakinfo{1} = [peak_loc_mag{1, roi_plot}(:, 5) peak_loc_mag{1, roi_plot}(:, 2)];
peakinfo{2} = [peak_loc_mag{3, roi_plot}(:, 5) peak_loc_mag{3, roi_plot}(:, 2)];

riseinfo{1} = [peak_loc_mag{peak_table_row, roi_plot}(:, 6) roi_col_data_select(peak_loc_mag{peak_table_row, roi_plot}(:, 3))];
riseinfo{2} = [peak_loc_mag{3, roi_plot}(:, 6) roi_col_data_lowpassed(peak_loc_mag{3, roi_plot}(:, 3))];

plot_trace_peak_rise(timeinfo,traceinfo,peakinfo,riseinfo)