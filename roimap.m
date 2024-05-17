function [roiMap,roiCenter,varargout] = roimap(A,imgRowSize,imgColSize,varargin)
    % Read results mat file exported by CNMFe code and output ROI spatial info 
    % creat a a matrix of ROI contour (roiArray) and extract the locations of ROI centers (roiCenter)
    % varargin{1} is an array to specific which roi centers should be output

    % A: spatial components of neurons
    % Cn: correlation image

    filter_output = false;
    if nargin == 2
        neuron_idx = varargin{1}; % an array
        filter_output = true;
    end

    % Cound the number of ROIs
    roiNum = size(A, 2); % number of ROIs
    % imgRowNum = size(Cn, 1); % number of vertical pixels of recorded video
    % imgColNum = size(Cn, 2); % number of horizontal pixels of recorded video

    % Pre-allocate memory
    roiCenter = NaN(roiNum, 3); % allocate memory for roiCenter
    roiMatCell = cell(roiNum, 1); % allocate memory for cell array containing sparse matrix of roi
    roiMatCellNonzero = cell(roiNum, 1); % allocate memory for cell array containing non-zero pixels
    roiEdge = cell(roiNum, 1); % allocate memory for cell array containing non-zero pixels
    roiArray = zeros(imgRowSize*imgColSize, 1);

    % Loop through ROIs, and get the roiCenter coordination and roiEdge matrix
    for rn = 1:roiNum
        % Convert the ROI spatial info from vector back to matrix
    	roiMatCell{rn} = reshape(A(:, rn), imgRowSize, imgColSize);

        % Get the pixel coordination of the ROI
    	[roiMatCellNonzero{rn}(:, 1) roiMatCellNonzero{rn}(:, 2)] = find(roiMatCell{rn});

        % Store the ROI index and median of row and col in roiCenter
    	roiCenter(rn, 1) = rn; % The number of roi
    	roiCenter(rn, 2) = median(roiMatCellNonzero{rn}(:, 1)); % median of row
    	roiCenter(rn, 3) = median(roiMatCellNonzero{rn}(:, 2)); % median of col

        % Add ROI pixels to roiMap vector
    	roiArray = roiArray+A(:, rn);

        % Identify the ROI (non-zero regions)
        roiBinarySparse = roiMatCell{rn} > 0;

        % Convert the sparse binary matrix to a full matrix
        roiBinary = full(roiBinarySparse);

        % Find the edges of the ROI
        % roiEdges{rn} = edge(roiBinary, 'Canny');
         b = bwboundaries(roiBinary);
         roiEdges{rn} = b{1}; % bwboundaries returns cell array output. This line is for proper assignment
    end

    if filter_output
        roiCenter = roiCenter(neuron_idx, :);
    end


    roiMap = full(reshape(roiArray, imgRowSize, imgColSize));


    varargout{1} = roiEdges;
end

