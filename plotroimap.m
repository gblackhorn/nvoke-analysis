function plotroimap(roi_map,roi_center,varargin)
    % Plot roi map of calcium imaging
    %   use roi_map and roi_center from function roimap.m
    % 	label: 0-no lable
    %		   1-label	

    if nargin < 2
    	error('Not enough input. Minimum 2: roi_map, roi_center')
    elseif nargin == 2
    	label_roi = 0;
    elseif nargin == 3
    	label_roi = varargin{1};
    elseif nargin > 3
    	error('Too many input. Maximum 3: roi_map, roi_center, label_roi')
    end

    position_x = roi_center(:, 3);
    position_y = roi_center(:, 2);
    position = [position_x position_y];
    value = roi_center(:, 1); % roi number code
    if label_roi == 1
    	roi_map = insertText(roi_map, position, value,...
    		'FontSize', 20, 'BoxColor', 'yellow', 'TextColor', 'yellow', 'BoxOpacity', 0);
    end

    % rm = figure;
    imshow(roi_map);
end

