function [heatmapHandle] = heatMapRoiCorr(corrMatrix,roiNames,varargin)
	% Convert event time points (unit: seconds) from multiple ROIs in one single recording to binary
	% matrix (one column per roi). Calculate the 

	% corrMatrix: roi correlation paires. Can be used to plot heatmap
		% % example: h = heatmap(plotWhere,corrMatrix,'Colormap',jet);
	% roiNames: Names of ROIs. This can be used as xLabels and yLabels when displaying corrMatrix using heatmap
		% example: h = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',jet);

	% Defaults
	heatmapColor = jet; 
	excludeSelfCorrColor = true; % if true, exclude the diagonal values from the heatmap color limit


	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('recName', varargin{ii}) 
            recName = varargin{ii+1}; % name of the recording. a string
	    elseif strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1};
	    elseif strcmpi('heatmapColor', varargin{ii})
            heatmapColor = varargin{ii+1};
	    elseif strcmpi('excludeSelfCorrColor', varargin{ii})
            excludeSelfCorrColor = varargin{ii+1};
	    end
	end

		if ~exist('plotWhere','var')
			f = figure;
			plotWhere = gca;
		end
		xtickLabels = roiNames;
		ytickLabels = roiNames;

		heatmapHandle = heatMapCustomized(corrMatrix,'plotWhere',plotWhere,...
			'xtickLabels',xtickLabels,'ytickLabels',ytickLabels,...
			'heatmapColor',heatmapColor,'excludeSelfCorrColor',excludeSelfCorrColor);
		% heatmapHandle = heatmap(plotWhere,xLabels,yLabels,corrMatrix,'Colormap',heatmapColor);

		% Use recording name as the title
		if ~exist('recName','var')
			recName = 'single recording';
		end
		title(gca,recName);
end