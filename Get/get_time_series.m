function [timeseries_for_crossCorr,varargout] = get_time_series(alignedData_trial,varargin)
% get time series for every ROI in the given alignedData_trial data
% alignedData_trial is a single trial entry in alignedData_allTrials (output by get_event_trace_allTrials)
	% time_info: n x 2 matrix. stimulation windows, alignedData_trial.stimInfo.time_range_notAlign, can be used for this

	time_info = []; % when empty, get the whole trace
	time_preComp = 0; % pre time info compensation. time_info(:,1)-time_preComp
	time_postComp = 0; % pre time info compensation. time_info(:,2)+time_postComp
	% distSort = []; % when roi_coordination are given, sort the cross-correlation with the distance. if empty, no sort

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('time_info', varargin{ii})
	        time_info = varargin{ii+1}; 
	    % elseif strcmpi('distSort', varargin{ii})
	    %     distSort = varargin{ii+1}; 
	    elseif strcmpi('time_preComp', varargin{ii})
	        time_preComp = varargin{ii+1}; 
	    elseif strcmpi('time_postComp', varargin{ii})
	        time_postComp = varargin{ii+1}; 
	    end
	end

	if ~isempty(time_info)
		time_info(:,1) = time_info(:,1)-time_preComp;
		time_info(:,2) = time_info(:,2)+time_postComp;

		fullTime_trace = alignedData_trial.fullTime;
		freq = round(1/(fullTime_trace(10)-fullTime_trace(9)));
		time_info_loc = NaN(size(time_info));
		[time_info(:,1), time_info_loc(:,1)] = find_closest_in_array(time_info(:,1), fullTime_trace);
		[time_info(:,2), time_info_loc(:,2)] = find_closest_in_array(time_info(:,2), fullTime_trace);
	end

	traceInfo = alignedData_trial.traces;
	roi_num = numel(traceInfo);
	timeseries_for_crossCorr = struct('roi', cell(1, roi_num), 'roi_coor', cell(1, roi_num),...
		'repeats', cell(1, roi_num), 'traceData', cell(01, roi_num));

	[timeseries_for_crossCorr.roi] = deal(traceInfo.roi);
	[timeseries_for_crossCorr.roi_coor] = deal(traceInfo.roi_coor);
	% timeseries_for_crossCorr.roi_coor = traceInfo.roi_coor;
	if ~isempty(time_info)
		timeSec_num = size(time_info_loc, 1);

		traceData = cell(1, timeSec_num);
		for rn = 1:roi_num
			for tn = 1:timeSec_num
				traceData{1, tn} = traceInfo(rn).fullTrace(time_info_loc(tn, 1):time_info_loc(tn, 2));
			end
			timeseries_for_crossCorr(rn).traceData = traceData;
		end
	else
		timeSec_num = 1;
		timeseries_for_crossCorr.traceData = deal(traceInfo.fullTrace);
	end
	[timeseries_for_crossCorr.repeats] = deal(timeSec_num);

	varargout{1} = freq;
end