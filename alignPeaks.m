function [alignedTraceData] = alignPeaks(traceData, peakInfo, expType)
% Align peaks with their rising point and prepare data for overlpTraces.m 
% With given traceData, peakInfo, and experiment type, alignPeaks outputs peak-traces 
% data with rising point at time zero
% traceData: table of trace data. 
%				2 columns: 1-col is timeInfo. 2-col is trace value
%				3 columns: 1-col is timeInfo. 2-col and 3-col are trace value. 
%						   For Ca imaging data, 2-col is decon and 3-col is raw
% peakInfo: Table inculding peak related information. It's either ePhy or imaging info depends on expType value
% expType: 1 is ePhy 
% 		   2 is Ca imaging with 2 col
%	 	   3 is Ca imaging with 3 col

	switch expType
		case 1
			expStr = 'ePhy';
			timeCol = 1; % column number of time in the table
			valCol = 2; % column number of data value in the table
			alignLocStr = 'peak_locs'; % variable name of align location in peakInfo table
			alignTimeStr = 'peak_time'; % variable name of align time in peakInfo table
			rLocStr = 'thresh_loc';
			rTimeStr = 'thresh_time';
			preT_dur = 0.05; % default for ePhy: 50ms. time duration kept before the rise start
			postT_dur = 0.15; % default for ePhy: 100ms. time duration kept after the rise start
		case 2
			expStr = 'caImg_2col';
			timeCol = 1; % column number of time in the table
			valCol = 2; % column number of data value in the table
			alignLocStr = 'Peak_loc'; % variable name of align location in peakInfo table
			alignTimeStr = 'Peak_loc_s_'; % variable name of align time in peakInfo table
			rLocStr = 'Rise_start';
			rTimeStr = 'Rise_start_s_';
			preT_dur = 2; % default for caImg: 2s. time duration kept before the rise start
			postT_dur = 5; % default for caImg: 5s. time duration kept after the rise start
		case 3
			expStr = 'caImg_3col';
			timeCol = 1; % column number of time in the table
			valCol = 3; % column number of data value in the table
			alignLocStr = 'Peak_loc'; % variable name of align location in peakInfo table
			alignTimeStr = 'Peak_loc_s_'; % variable name of align time in peakInfo table
			rLocStr = 'Rise_start';
			rTimeStr = 'Rise_start_s_';
			preT_dur = 2; % default for caImg: 2s. time duration kept before the rise start
			postT_dur = 5; % default for caImg: 5s. time duration kept after the rise start
		otherwise
			disp('Experiment type not exist.')
			return
	end

	timeInfo = traceData{:, timeCol};
	traceVal = traceData{:, valCol};
	alignLoc = peakInfo{:, alignLocStr}; % loc of point used to align data
	alignTime = peakInfo{:, alignTimeStr}; % time used to align data
	rLoc = peakInfo{:, rLocStr}; % time used to align data
	peakNum = size(peakInfo, 1);
	alignedTraceData = cell(peakNum, 2);

	for pn = 1: peakNum
		% find the location of start and end points of aligned trace 
		preT = alignTime(pn)-preT_dur;
		preT_loc = find(timeInfo<=preT, 1, 'last');
		preThalf = alignTime(pn)-preT_dur*0.5;
		preThalf_loc = find(timeInfo<=preThalf, 1, 'last');
		if isempty(preT_loc)
			preT_loc = 1; % when rising point is too close to the start of recording
			preThalf_loc = 1;
		end
		postT = alignTime(pn)+postT_dur;
		postT_loc = find(timeInfo>=postT, 1);
		if isempty(postT_loc)
			postT_loc = length(timeInfo); % when rising point is too close to the start of recording
		end

		% align data, and store aligned trace in output cell
		alignVal = mean(traceVal(preThalf_loc:rLoc(pn)));
		alignedTraceTime = timeInfo(preT_loc:postT_loc)-alignTime(pn);
		alignedTraceVal = traceVal(preT_loc:postT_loc)-alignVal;
		alignedTraceData{pn, 1}(:, 1) = alignedTraceTime;
		alignedTraceData{pn, 1}(:, 2) = alignedTraceVal;
		alignedTraceData{pn, 2} = peakInfo(pn, :); % time and loc are original value in traceData. Not converted to alignedTrace
	end
	alignedTraceData = cell2table(alignedTraceData, 'VariableNames',{'alignedTrace' 'PeakInfo'});
end

