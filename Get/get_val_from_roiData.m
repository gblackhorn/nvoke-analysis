function [locDataVal,varargout] = get_val_from_roiData(roiData,locInfo,varargin)
	% Given roiData and locInfo (location of data point(s). 1 point or a shrot range),
	% returns the value of trace at locInfo (1 point or mean of the short range)
	% locInfo: canbe either the location in roiData or the timeStamp for roiData. 
	%	timeInfo along the roiData is needed if locInfo is the latter one.

	% Defaults
	loc_type = 'index'; % index/time. (1) the index number in roiData. (2) time stamp 

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('loc_type', varargin{ii})
	        loc_type = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('timeInfo', varargin{ii})
	        timeInfo = varargin{ii+1};
	    end
	end	


	%% Content
	% Convert locInfo from time to index if needed, and assign the index to locIdx
	switch loc_type
		case 'index'
			locIdx = locInfo;
		case 'time'
			tf_timeInfo = exist('timeInfo', 'var');
			if tf_timeInfo
				[~, locIdx] = intersect(timeInfo, locInfo);
			else
				st = dbstack;
				funcName = st.name;
				error('Error in func [%s]. \nvarargin [timeInfo] is needed', 'funcName');
			end
	end

	locDataVal_raw = roiData(locIdx);
	num_locDataVal = numel(locDataVal_raw); % number of points in locDataVal_raw
	if num_locDataVal=1
		locDataVal = locDataVal_raw;
	elseif num_locDataVal>1
		locDataVal = mean(locDataVal_raw); % assign the average of locDataVal_raw to locDataVal
	end

	varargout{1} = locDataVal_raw;
	varargout{2} = num_locDataVal;
end