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

%%