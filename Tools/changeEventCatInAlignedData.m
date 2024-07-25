function [alignedDataNewCat] = changeEventCatInAlignedData(alignedData,stimName,oldCat,newCat)
	% Change the events' category from 'oldCat' to 'newCat' in recordings applied with 'stimName'


	% Example:
	% [alignedDataNewCat] = changeEventCatInAlignedData(alignedData,'ap-0.1s','rebound','spon');

	% Defaults


	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);
	addRequired(p, 'stimName', @ischar);
	addRequired(p, 'oldCat', @ischar);
	addRequired(p, 'newCat', @ischar);


	% Parse inputs
	parse(p, alignedData, stimName, oldCat, newCat);

	% Retrieve parsed values
	alignedData = p.Results.alignedData;
	stimName = p.Results.stimName;
	oldCat = p.Results.oldCat;
	newCat = p.Results.newCat;


	% Filter the alignedData with stimName
	stimNameAll = {alignedData.stim_name};
	stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));



	% Loop through the alignedDataNewCat and update the event cateogry
	alignedDataNewCat = alignedData;
	for n = 1:numel(stimPosIDX)
		% Get the number of ROIs
		roiNum = numel(alignedDataNewCat(stimPosIDX(n)).traces);

		% Loop through the ROIs
		for rn = 1:roiNum
			% Get the eventProp of a ROI
			eventProp = alignedDataNewCat(stimPosIDX(n)).traces(rn).eventProp;

			% Change the 'oldCat' to 'newCat' if there is any
			eventPeakCag = cellfun(@(x) strrep(x, oldCat, newCat), {eventProp.peak_category}, 'UniformOutput', false);
			alignedDataNewCat(stimPosIDX(n)).traces(rn).eventProp = replaceFieldWithArray(eventProp,...
				'peak_category', eventPeakCag);
		end
	end
end