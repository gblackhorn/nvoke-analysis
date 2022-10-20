function [newTBLorSTRUCT,varargout] = SortVariedStimDuration(StimRange,varargin)
	%Tag calcium events and stimulation window with stimulation durations

	% In some recordings, varied stimulation duration are applied. For example, airpuff with 0.05s,
	% 0.1s, 0.25s, etc. duration may be applied in a single recording. This function will extract
	% the durations of stimulations. The output can be used to tag stimulations. If event rise time
	% is given, this function will also return tags used to label the stimulation related events.

end
