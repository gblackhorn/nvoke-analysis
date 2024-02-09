function [varargout] = plotRoiCoor2(roi_map,coor,varargin)
	% Plot roi map output from CNMFe and mark rois 

	% roi_map: a matrix output from CNMFe summarizing the spatial information
	% coor: n x 2 matrix. coordinats of rois. Each row contains x and y for a coordinate

	% Defaults
	colorScheme = 'gray'; % 'viridis'

	% label = 'shape'; % 'shape'/'text'. lables of rois.
	% shape_style = 'FilledCircle';
	% shape_size = 10; % radius of 'Circle'

	% text_lable = false;
	labelFontSize = 10; % size of text label
	% anchorpoint = 'Center'; % anchor point for text labels
	textCell = {}; % a column cell containing neuron lables
	text_prefix = 'neuron'; % this will be used to find the neuron numbers
	dis_prefix = true; % true/false

	% shapeColor = 'magenta'; % 'Color' for [insertShape]. 'BoxColor' for [insertText]
	% opacity  = 0.8; % 'Opacity' for [insertShape]. 'BoxOpacity' for [insertText]
	textColor = 'm'; % 'y'
	textWeight = 'normal';

	% contrast_scale = 0.7; % used to decrease the contrast of roi_map for better visulization

	showMap = true;

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1}; % label style. 'shape'/'text'
	    % elseif strcmpi('label', varargin{ii})
	    %     label = varargin{ii+1}; % label style. 'shape'/'text'
        elseif strcmpi('textCell', varargin{ii})
	        textCell = varargin{ii+1}; % a column cell containing neuron lables
        % elseif strcmpi('shape_style', varargin{ii})
	    %     shape_style = varargin{ii+1}; 
        elseif strcmpi('labelFontSize', varargin{ii})
	        labelFontSize = varargin{ii+1}; 
        % elseif strcmpi('shape_size', varargin{ii})
	    %     shape_size = varargin{ii+1}; 
        elseif strcmpi('text_prefix', varargin{ii})
	        text_prefix = varargin{ii+1}; 
        elseif strcmpi('dis_prefix', varargin{ii})
	        dis_prefix = varargin{ii+1}; 
        % elseif strcmpi('shapeColor', varargin{ii})
	    %     shapeColor = varargin{ii+1}; 
        % elseif strcmpi('opacity', varargin{ii})
	    %     opacity = varargin{ii+1}; 
        elseif strcmpi('textColor', varargin{ii})
	        textColor = varargin{ii+1}; 
        elseif strcmpi('showMap', varargin{ii})
	        showMap = varargin{ii+1}; 
	    end
	end	


	if ~exist('plotWhere','var') || isempty(plotWhere) 
    	f = figure;
    else
    	axes(plotWhere)
    	f = gcf;
    end
    
    if showMap
		roi_map_marked = imagesc(roi_map); % Display the ROI map
		colormap(gca,colorScheme); % Optional: Choose a colormap that suits your data
		axis equal; % Keep the aspect ratio of the map
		axis off; % Turn off the axis box and labels
		hold on; % Keep the map displayed while plotting the labels



		for i = 1:length(textCell)
		    % Extract the coordinates for the current ROI
		    x = coor(i, 1);
		    y = coor(i, 2);

		    % Modify the label text
		    if dis_prefix
		    	text_str{i} = strrep(textCell{i},text_prefix,'');
		    	% prefix_length = numel(text_prefix);
		    	% k = strfind(textCell{n}, text_prefix);
		    	% text_str{n} = textCell{n}((k+prefix_length):end);
		    else
		    	text_str{i} = textCell{i};
		    end


		    % Place the text label on the map with specified color and font weight
		    text(x, y, text_str{i},'Color',textColor,'FontSize',labelFontSize,'FontWeight',textWeight,...
		    	'HorizontalAlignment', 'center');	
		end

    end


    varargout{1} = roi_map_marked;
end