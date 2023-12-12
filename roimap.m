function [roi_map,roi_center] = roimap(A,imgRowSize,imgColSize,varargin)
    % Read results mat file exported by CNMFe code and output ROI spatial info 
    % creat a a matrix of ROI contour (roi_array) and extract the locations of ROI centers (roi_center)
    % varargin{1} is an array to specific which roi centers should be output

    % A: spatial components of neurons
    % Cn: correlation image

    filter_output = false;
    if nargin == 2
        neuron_idx = varargin{1}; % an array
        filter_output = true;
    end

    roiNum = size(A, 2); % number of ROIs
    % imgRowNum = size(Cn, 1); % number of vertical pixels of recorded video
    % imgColNum = size(Cn, 2); % number of horizontal pixels of recorded video

    roi_center = NaN(roiNum, 3); % allocate memory for roi_center
    roi_mat_cell = cell(roiNum, 1); % allocate memory for cell array containing sparse matrix of roi
    roi_mat_cell_nonzero = cell(roiNum, 1); % allocate memory for cell array containing non-zero pixels
    roi_array = zeros(imgRowSize*imgColSize, 1);

    for rn = 1:roiNum
    	roi_mat_cell{rn} = reshape(A(:, rn), imgRowSize, imgColSize);
    	[roi_mat_cell_nonzero{rn}(:, 1) roi_mat_cell_nonzero{rn}(:, 2)] = find(roi_mat_cell{rn});
    	roi_center(rn, 1) = rn; % The number of roi
    	roi_center(rn, 2) = median(roi_mat_cell_nonzero{rn}(:, 1)); % median of row
    	roi_center(rn, 3) = median(roi_mat_cell_nonzero{rn}(:, 2)); % median of col

    	roi_array = roi_array+A(:, rn);
    end

    if filter_output
        roi_center = roi_center(neuron_idx, :);
    end


    roi_map = full(reshape(roi_array, imgRowSize, imgColSize));
end

