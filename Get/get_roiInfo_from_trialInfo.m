function [roiInfo,varargout] = get_roiInfo_from_trialInfo(trialData,roiName,varargin)
	% Return the info of a single ROI 
	% trialData: cell array data for a single trial (multiple ROIs). In the recData format
	% roiName: a string var, such as 'neuron3' 
	% roiInfo: a structure var containing trial name, roi name, stim name, 
	%	traceData, stim range and event properties

	% Defaults
	trialName_col = 1;
	trace_col = 2;
	stimName_col = 3;
	stimRange_col = 4;
	eventProp_col = 5;

	traceType = 'lowpass'; % lowpass/raw/decon.This will decide where to get the traceData and the eventProperties
	eventProp_tableRow = 3; % if traceType, such as raw, cannot find evenProp data, use row 3 (lowpass)

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('traceType', varargin{ii})
	        traceType = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('timeInfo', varargin{ii})
	        timeInfo = varargin{ii+1};
	    end
	end	


	%% Content
	roiInfo.trialName = trialData{trialName_col};
	roiInfo.roiName = roiName;
	roiInfo.stimName = trialData{stimName_col};
	roiInfo.stimRange = trialData{stimRange_col}(3:end);

	traceData = trialData{trace_col}.(traceType);
	roiInfo.trace = traceData(:, {'Time', roiName});
	roiInfo.traceType = traceType;

	eventPropAll = trialData{eventProp_col};
	eventProp_typeNames = eventPropAll.Properties.RowNames;
	tf_eventProp = cellfun(@(x) strfind(x, traceType), eventProp_typeNames, 'UniformOutput',false);
	eventProp_row = find(~cellfun(@isempty,tf_eventProp));
	if isempty(eventProp_row)
		eventProp_row = eventProp_tableRow;
		st = dbstack;
		funcName = st.name;
		warning('Warning from func [%s]. \nno eventProp found for "%s", use lowpass events instead',...
			funcName, traceType);
	end
	roiInfo.eventProp = eventPropAll{eventProp_row, roiName};
	if size(roiInfo.eventProp, 2) == 1 % if the eventProp table is in a cell array
		roiInfo.eventProp = roiInfo.eventProp{:};
	end
	roiInfo.eventPropType = eventProp_typeNames{eventProp_row};
end