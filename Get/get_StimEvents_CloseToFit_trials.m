function [List_curveFitNum_eventNum,varargout] = get_StimEvents_CloseToFit_trials(alignedData,eventCat,stimTime_col,varargin)
	% Get the number of curvefit and events related to stimulation time for further analysis

	% Note: alignedData is a structure value acquired with the function
	% [get_event_trace_allTrials]. eventCat is a character var (such as 'rebound'). stimTime_col is
	% a number (1 or 2) to indicate if to use the beginnings (1) or the ends (2) of the stimulation

	% Example:


	% Get the number of recordings (trials)
	recNum = numel(alignedData);

	% Create a cell array to store the list from each recording
	List_cell = cell(1,recNum);


	% Loop through each recording and get the list
	for rn = 1:recNum
		roiNum = numel(alignedData(rn).traces); % number of ROIs in a single recording
		List_rec = empty_content_struct({'recName','roiName','stimNum','fitNum','eventFitNum','eventNoFitNum'},roiNum);

		% Get the necessary information, such as stimulation time, the idx of curvefit in the order of
		% stimulations, etc
		recName = alignedData(rn).trialName;
		roiNames = {alignedData(rn).traces.roi};
		stimTime = alignedData(rn).stimInfo.UnifiedStimDuration.range(:,stimTime_col);

		% loop through every ROIs
		for roin = 1:roiNum
			FitStimIDX = [alignedData(rn).traces(roin).StimCurveFit.SN];
			ROIeventProp = alignedData(rn).traces(roin).eventProp;
			[stimNum,fitNum,FiteventIDX,eventFitNum,eventNoFitNum] = get_StimEvents_CloseToFit_roi(FitStimIDX,...
				stimTime,ROIeventProp,eventCat);
			List_rec(roin).stimNum = stimNum;
			List_rec(roin).fitNum = fitNum;
			List_rec(roin).eventFitNum = eventFitNum;
			List_rec(roin).eventNoFitNum = eventNoFitNum;
		end

		[List_rec(1:end).recName] = deal(recName);
		[List_rec(1:end).roiName] = deal(roiNames{:});
		List_cell{rn} = List_rec;
	end
	List_curveFitNum_eventNum = cat(1,List_cell{:});
end