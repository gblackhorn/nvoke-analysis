function [stimNum,decayNum,FiteventIDX,eventFitNum,eventNoFitNum,varargout] = get_StimEvents_CloseToFit_roi(FitStimIDX,stimTime,ROIeventProp,eventCat,varargin)
	% This function use the eventProp data and StimCurveFit data to find the stimulation related
	% events for each curve fit

	% This can be used for:
	% Some optogenetics stimulation of nucleo-olivary cerebellar nuclei terminals cause a
	% exponential decay. And rebound events can be found after the stimulations

	% Note: ROIeventProp is a structure var. Fields 'rise_time' and 'peak_category' are used in this
	% function. eventCat is a character var (such as 'rebound'). StimTime is a vector (the ends of stimulation for
	% rebound events). FitStimIDX and is a vector.

	% Example:
	% FitStimIDX = [alignedData_allTrials(7).traces(13).StimCurveFit.SN];
	% stimTime = alignedData_allTrials(7).stimInfo.StimDuration.range(:,2);
	% ROIeventProp = alignedData_allTrials(7).traces(13).eventProp;
	% eventCat = 'rebound';

	% [stimNum,decayNum,eventIDX,eventFitNum,eventNoFitNum] = get_StimEvents_CloseToFit_roi(FitStimIDX,stimTime,ROIeventProp,eventCat)



	% Defaults


	% Get the number number of stimulations
	stimNum = numel(stimTime);

	% Get the number of decay
	decayNum = numel(FitStimIDX);

	% Get the number of rebound events
	tf_idx_events = strcmpi({ROIeventProp.peak_category},eventCat);
	eventIDX = find(tf_idx_events); 
	eventNum = numel(eventIDX);

	% Find the closest stimulation (1st, 2nd, 3rd....?) for each screened events in the last step
	[~,FiteventIDX] = find_closest_in_array([ROIeventProp(eventIDX).rise_time],stimTime); % get a n_th stimulation for each event time


	% Get the stimIDX where both curveFit and stimulation related event exsit
	if ~isempty(FiteventIDX)
		idxStim_fit_and_event = intersect(FitStimIDX,FiteventIDX);
		eventFitNum = numel(idxStim_fit_and_event);
		eventNoFitNum = eventNum-eventFitNum;
	else
		eventFitNum = 0;
		eventNoFitNum = 0;
	end
end