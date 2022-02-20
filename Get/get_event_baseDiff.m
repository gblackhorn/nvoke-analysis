function [baseDiff,val_event,varargout] = get_event_baseDiff(eventTime,stimStartTime,timeInfo,roiTrace,varargin)
	% Return the dF/F difference between the event rise and the baseline prior to stimulation
	% The lowest baseDiff during stimWin will be output as varargout{2} if stimEndTime is given

	% eventTime: Use rise_time from event properties.
	% timeInfo: time information for a single trial recording
	% roiTrace: trace data for a single roi. It has the same length as the timeInfo

	% baseDiff: difference between trace value at event time and baseline
	% val_event: trace value at event time

	% Defaults
	base_timeRange = 2; % default 2s. 
	stimEndTime = []; 

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stimEndTime', varargin{ii})
	        stimEndTime = varargin{ii+1};
	    end
	end	

	%% Content
	idx_event = find(timeInfo==eventTime); % location of eventTime in timeInfo
	val_event = roiTrace(idx_event); % df/f value at eventTime

	% idx_stimStart = find(timeInfo==stimStartTime);
	% stimulation time (stimStartTime) has a different frequency other than Ca2+ recording frequency. Find the closest time rather than find the exact val 
	[stimStartTime_in_timeInfo, idx_stimStart] = find_closest_in_array(stimStartTime,timeInfo); 
	idx_baseEnd = idx_stimStart-1;
	baseEndTime = timeInfo(idx_baseEnd);
	baseBeginTime = baseEndTime-base_timeRange;
	[~, idx_baseBegin] = min(abs(timeInfo-baseBeginTime));
	baseBeginTime = timeInfo(idx_baseBegin);
	data_base = roiTrace(idx_baseBegin:idx_baseEnd);
	dataNum_base = numel(data_base);
	val_base = mean(data_base);
	std_base = std(data_base);

	if ~isempty(stimEndTime)
		[stimEndTime_in_timeInfo, idx_stimEnd] = find_closest_in_array(stimEndTime,timeInfo); 
		baseDiff_stimWin = roiTrace(idx_stimStart:idx_stimEnd)-val_base;
		baseDiff_stimWin_low = min(baseDiff_stimWin); % lowest baseDiff during stimulation window
	else
		baseDiff_stimWin_low = [];
	end

	baseDiff = val_event-val_base;
	baseInfo.timeRange = [baseBeginTime baseEndTime];
	baseInfo.data = data_base;
	baseInfo.dataNum = dataNum_base;
	baseInfo.mean = val_base;
	baseInfo.std = std_base;

	varargout{1} = baseInfo;
	varargout{2} = baseDiff_stimWin_low;
end