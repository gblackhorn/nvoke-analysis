function [varargout] = plot_roi_coor_alignedData(alignedData,plotWhere,varargin)
	% Plot roi map with marker. Stim effect of ROI can be shown using different color

	% alignedData: alignedData structure of a single trial

	% Defaults
	stimEffect = true; % true/false. give different color to ROIs according to stim effect
	label = 'shape'; % 'shape'/'text'. lables of rois.
	plotWhere = [];

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('stimEffect', varargin{ii})
	        stimEffect = varargin{ii+1}; % label style. 'shape'/'text'
        elseif strcmpi('label', varargin{ii})
	        label = varargin{ii+1}; % a column cell containing neuron lables
        % elseif strcmpi('shapeColor', varargin{ii})
	       %  shapeColor = varargin{ii+1}; % a column cell containing neuron lables
        % elseif strcmpi('opacity', varargin{ii})
	       %  opacity = varargin{ii+1}; % a column cell containing neuron lables
	    end
	end	

	%% Content
	roi_map = alignedData.roi_map;
	roiNames = {alignedData.traces.roi}';
	roiCoor = {alignedData.traces.roi_coor}';
	roiCoor = cell2mat(roiCoor);
	roiCoor = convert_roi_coor(roiCoor);
	
	idx_all = 1:numel(alignedData.traces);
	[idx_ex,num_ex] = get_struct_entry_idx(alignedData.traces,'stimEffect','excitation','req',true);
	[idx_in,num_in] = get_struct_entry_idx(alignedData.traces,'stimEffect','inhibition','req',true);
	idx_other = setdiff(idx_all, [idx_ex idx_in]);

	coor_ex = roiCoor(idx_ex, :);
	coor_in = roiCoor(idx_in, :);
	coor_other = roiCoor(idx_other, :);
	roiNames_ex = roiNames(idx_ex);
	roiNames_in = roiNames(idx_in);
	roiNames_other = roiNames(idx_other);

	if isempty(plotWhere)
		title_str = sprintf('roi-map: %s', alignedData.trialName(1:15));
    	f = figure('Name', title_str);
    else
    	axes(plotWhere)
    	f = gcf;
    end

    if stimEffect
    	if ~isempty(coor_ex)
    		[roi_map] = plot_roi_coor(roi_map,coor_ex,[],...
    			'label',label,'textCell',roiNames_ex,'shapeColor','magenta','showMap',false); % plotWhere is [] to supress plot
    	end
    	if ~isempty(coor_in)
    		[roi_map] = plot_roi_coor(roi_map,coor_in,[],...
    			'label',label,'textCell',roiNames_in,'shapeColor','cyan','showMap',false); % plotWhere is [] to supress plot
    	end
    	if ~isempty(coor_other)
    		[roi_map] = plot_roi_coor(roi_map,coor_other,[],...
    			'label',label,'textCell',roiNames_other,'shapeColor','yellow','showMap',false); % plotWhere is [] to supress plot
    	end
    	imshow(roi_map)
    else
    	[roi_map] = plot_roi_coor(roi_map,roiCoor,[],...
    			'label',label,'textCell',roiNames,'shapeColor','black','showMap',true); % plotWhere is [] to supress plot
    end
end