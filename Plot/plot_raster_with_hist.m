function [f,varargout] = plot_raster_with_hist(rasterData,x_window,varargin)
	% Plot event raster plot using function 'plot_TemporalRaster' and show the sum up of raster points in
	% histogram time bin

	% [f] = plot_raster_with_hist(rasterData,x_window)

	% Defaults
	rowNames = [];
	shadeData = {};
	shadeColor = {'#F05BBD','#4DBEEE','#ED8564'};
	% xtickInt = [];
	yInterval = 5; % offset on y axis to seperate data from various ROIs
	sz = 20; % marker area
	hist_binsize = 5; % the size of the bin, used to calculate the edges of the bins
	xtickInt_scale = 5; % xtickInt = hist_binsize * xtickInt_scale

	titleStr = 'Raster and hist plot';

	% Optionals
    for ii = 1:2:(nargin-2)
    	if strcmpi('rowNames', varargin{ii})
    		rowNames = varargin{ii+1}; % cell array containing strings used to label y_ticks
        elseif strcmpi('x_window', varargin{ii})
            x_window = varargin{ii+1}; % [a b] numerical array. Used to set the limitation of x axis
        elseif strcmpi('shadeData', varargin{ii})
            shadeData = varargin{ii+1}; % [a b] numerical array. Used to set the limitation of x axis
        % elseif strcmpi('xtickInt', varargin{ii})
        %     xtickInt = varargin{ii+1}; % [a b] numerical array. Used to set the limitation of x axis
        elseif strcmpi('yInterval', varargin{ii})
            yInterval = varargin{ii+1}; % interval between rows in the plot
        elseif strcmpi('sz', varargin{ii})
            sz = varargin{ii+1}; % size of the markers in the raster plot
        elseif strcmpi('hist_binsize', varargin{ii})
            hist_binsize = varargin{ii+1};
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % size of the markers in the raster plot
        end
    end

	% ====================
	% Main contents

	% Create rowNames if it does not exist or is empty
	if exist('rowNames')==0 || isempty(rowNames)
	    rowNames = [1:numel(rasterData)]; % Create a numerical array 
	    rowNames = arrayfun(@num2str,rowNames,'UniformOutput',0); % The NUM2STR function converts a number 
	    % to the string representation of that number. This function is applied to each cell in the A array/matrix 
	    % using ARRAYFUN. The 'UniformOutput' parameter is set to 0 to instruct CELLFUN to encapsulate the outputs into a cell array.
	end

	% Creat a figure to plot raster (first ax) and histogram (second ax)
	f = fig_canvas(2,'unit_width',0.4,'unit_height',0.4,'column_lim',1,...
		'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f, 3, 1); % setup tiles
	xtickInt = hist_binsize*xtickInt_scale;

	% Create raster plot in the first ax
	ax = nexttile(tlo,[2,1]);
	plotWhere = gca;
	plot_TemporalRaster(plotWhere,rasterData,...
		'rowNames',rowNames,'x_window',x_window,'xtickInt',xtickInt,...
		'yInterval',yInterval,'sz',sz); % Plot raster
	scatter_xlim = xlim;


	% Plot histogram to show the sum up of raster points in time bins
	ax = nexttile(tlo);
	hist_binedge = [x_window(1):hist_binsize:x_window(2)]; % Get the bin edges for histogram
	if x_window(2) > hist_binedge(end) % if the end of x_window is bigger than the last hist_binedge
	    hist_binedge = [hist_binedge x_window(end)]; % add the end of x_window to the binedge
	end
	raster_all = cell2mat(rasterData); % collect rasterData in every cell and make a number array
	raster_all(isnan(raster_all)) = []; % discard nan values
	histogram(raster_all,hist_binedge,'LineStyle','none');
	xlim(scatter_xlim);

	if ~isempty(shadeData)
	    shade_type_num = numel(shadeData);
	    for stn = 1:shade_type_num
	        draw_WindowShade(gca,shadeData{stn},'shadeColor',shadeColor{stn});
	    end
	end
	set(gca,'children',flipud(get(gca,'children')))

	x_ticks = [scatter_xlim(1):xtickInt:scatter_xlim(2)];
	set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
	xticks(x_ticks);
	xlabel('time (s)')
	set(gca,'box','off')
end 
