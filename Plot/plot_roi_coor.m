function [varargout] = plot_roi_coor(roi_map,coor,plotWhere,varargin)
	% Plot roi map output from CNMFe and mark rois 

	% roi_map: a matrix output from CNMFe summarizing the spatial information
	% coor: n x 2 matrix. coordinats of rois. Each row contains x and y for a coordinate

	% Defaults
	label = 'shape'; % 'shape'/'text'. lables of rois.
	shape_style = 'FilledCircle';
	shape_size = 10; % radius of 'Circle'

	text_lable = false;
	fontSize = 10; % size of text label
	anchorpoint = 'Center'; % anchor point for text labels
	textCell = {};
	text_prefix = 'neuron'; % this will be used to find the neuron numbers
	dis_prefix = true; % true/false

	shapeColor = 'magenta'; % 'Color' for [insertShape]. 'BoxColor' for [insertText]
	opacity  = 0.8; % 'Opacity' for [insertShape]. 'BoxOpacity' for [insertText]
	textColor = 'black';

	contrast_scale = 0.5; % used to decrease the contrast of roi_map for better visulization

	showMap = true;

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('label', varargin{ii})
	        label = varargin{ii+1}; % label style. 'shape'/'text'
        elseif strcmpi('textCell', varargin{ii})
	        textCell = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('shape_style', varargin{ii})
	        shape_style = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('shape_size', varargin{ii})
	        shape_size = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('text_prefix', varargin{ii})
	        text_prefix = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('dis_prefix', varargin{ii})
	        dis_prefix = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('shapeColor', varargin{ii})
	        shapeColor = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('opacity', varargin{ii})
	        opacity = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('textColor', varargin{ii})
	        textColor = varargin{ii+1}; % a column cell containing neuron lables
        elseif strcmpi('showMap', varargin{ii})
	        showMap = varargin{ii+1}; % a column cell containing neuron lables
	    end
	end	


	%% Content
	coor_num = size(coor, 1);

	if strcmpi(label, 'text') && ~isempty(textCell)
		if numel(textCell) ~= coor_num
			error('Error in func [plot_roi_coor]: \n number of text str are differenct from coor');
		else
			text_str = cell(coor_num, 1);
			prefix_length = numel(text_prefix);
			text_lable = true;
		end
	else
		text_lable = false;
	end


	roi_map = roi_map*contrast_scale;
	for n = 1:coor_num
		if text_lable
			if dis_prefix
				k = strfind(textCell{n}, text_prefix);
				text_str{n} = textCell{n}((k+prefix_length):end);
			else
				text_str{n} = textCell{n};
			end
		else
			roi_map_marked = insertShape(roi_map, shape_style, [coor(n, :) shape_size],...
				'Color', shapeColor,'Opacity',opacity);
		end
	end
	if text_lable
		roi_map_marked = insertText(roi_map, coor, text_str,'FontSize',fontSize,...
			'BoxOpacity',opacity,'AnchorPoint',anchorpoint,'TextColor',textColor,'BoxColor',shapeColor);
	end

	if isempty(plotWhere)
    	% f = figure;
    else
    	axes(plotWhere)
    	f = gcf;
    end
    
    if showMap
    	imshow(roi_map_marked)
    else

    varargout{1} = roi_map_marked;
end