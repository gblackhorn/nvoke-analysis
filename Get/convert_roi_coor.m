function [roi_coor_matlab,varargout] = convert_roi_coor(roi_coor,varargin)
	% convert roi coordinates from CNMFe format for plotting in matlab
	% CNMFe output coordinates are ['neuronNum', 'row', 'column']
	% Matlab needs [x, y] (from top left of an image) to insert shape/text
	% Delete 'neuronXXX'. Switch 'row' and 'column', and the matrix will be good for matlab

	% roi_coor: a n x 2 or n x 3 matrix

	[rNum_coor, cNum_coor] = size(roi_coor);
	if cNum_coor > 2
		roi_coor(:, 1) = [];
	end

	roi_coor_matlab = NaN(size(roi_coor));
	roi_coor_matlab(:, 1) = roi_coor(:, 2);
	roi_coor_matlab(:, 2) = roi_coor(:, 1);
end