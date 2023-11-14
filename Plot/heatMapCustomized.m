function [heatmapHandle] = heatMapCustomized(matData,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi). Calculate the 

	% matData: a matrix

	% Defaults
	heatmapColor = jet; 
	excludeSelfCorrColor = false; % if true, exclude the diagonal values from the heatmap color limit
	showColorbar = true;
	xtickDegree = 90;
	labelFontSize = 10;

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('plotWhere', varargin{ii}) 
            plotWhere = varargin{ii+1}; % name of the recording. a string
	    elseif strcmpi('xtickLabels', varargin{ii})
            xtickLabels = varargin{ii+1};
	    elseif strcmpi('ytickLabels', varargin{ii})
            ytickLabels = varargin{ii+1};
	    elseif strcmpi('heatmapColor', varargin{ii})
            heatmapColor = varargin{ii+1};
	    elseif strcmpi('excludeSelfCorrColor', varargin{ii})
            excludeSelfCorrColor = varargin{ii+1};
	    elseif strcmpi('showColorbar', varargin{ii})
            showColorbar = varargin{ii+1};
	    end
	end

	if ~exist('plotWhere','var')
		f = figure;
		plotWhere = gca;
	end


	% Plot heatmap using imagesc
	heatmapHandle = imagesc(plotWhere, matData);

	% exclude diagonal (self-correlation) from the color range
	if excludeSelfCorrColor
		% Find the range of values excluding the diagonal (self-correlation)
		nonDiagonalValues = matData(~eye(size(matData)));
		minValue = min(nonDiagonalValues(:));
		maxValue = max(nonDiagonalValues(:));

		% Adjust the color axis limits
		if maxValue > minValue
			caxis([minValue, maxValue]);
		end
	end

	colormap(gca, heatmapColor);  % Optional: Specify colormap

	% Add a color bar
	if showColorbar
		colorbar;
	end

	% Remove the box
	box(plotWhere, 'off');

	% Add x and y tick labels
	xticks(plotWhere, 1:length(xtickLabels));
	yticks(plotWhere, 1:length(ytickLabels));
	% Adjust font size of tick labels
	ax = gca; % Get handle to current axes
	ax.FontSize = labelFontSize; % Set the font size as desired

	% Optionally set specific properties for XTickLabels and YTickLabels
	% ax.XAxis.FontSize = 12;
	% ax.YAxis.FontSize = 12;
	xticklabels(plotWhere, xtickLabels);
	yticklabels(plotWhere, ytickLabels);

	% Remove the ticks
	plotWhere.TickLength = [0 0];

	% Rotate x tick labels 90 degrees
	xtickangle(plotWhere, 90);
end