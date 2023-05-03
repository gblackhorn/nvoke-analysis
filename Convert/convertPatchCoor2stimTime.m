function [stimTime,varargout] = convertPatchCoor2stimTime(patchCoor,varargin)
	% convert a patchCoor used to plot stimulation shade to stimulation time

	% patchCoor: a 2-col number array. 1st col contains time. 2nd col contains binary values (0 when
	% stimulaation is on, 1 when stimulation is off)

	% stimTime: a 2-col number array. 1st col contains the starting time of stimulation, 2nd col
	% contains the ends of stimulation

	stimStatusPattern = [0 1 1 0];



	% Get the stimulation on and off binary and ensure that is a row vector
	stimStatus = patchCoor(:,2);
	stimStatus = stimStatus(:); % make sure it a col vector
	stimStatus = stimStatus'; % convert it to a row vector

	% Find the same pattern as stimStatusPattern in stimStatus (the second col of patchCoor) to find the stimulation repeats
	stimRepeats = strfind(stimStatus, stimStatusPattern)

	% Get the [1 1] parts in stimStatus and use it as [start end] for stimulation
	stimTime = NaN(numel(stimRepeats),2);
	% Loop through the stimRepeats and fill the [start end] to each row of stimTime
	for n = 1:numel(stimRepeats)
		stimTime(n,1) = patchCoor(stimRepeats(n)+1,1);
		stimTime(n,2) = patchCoor(stimRepeats(n)+2,1);
	end
end