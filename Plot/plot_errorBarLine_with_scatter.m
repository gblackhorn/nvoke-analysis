function [h,varargout] = plot_errorBarLine_with_scatter(xData,Data,varargin)
	% Plot data using errorbar function and add scatters to each error bar

	% xData is vector, Data is a cell array
	% xData and DAta have the same size 

	% Use varargin to input error values to plot error bars

	% Example:
	%		

	% Defaults

	% figure parameters
	unit_width = 0.4; % normalized to display
	unit_height = 0.4; % normalized to display
	column_lim = 1; % number of axes column

	errorBarColor = '#4D4D4D';
	scatterSize = 5;
	scatterAlpha = 0.5;

	errorBarName = 'error bar';

	showScatter = true;


	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('unit_width', varargin{ii})
            unit_width = varargin{ii+1};
	    elseif strcmpi('unit_height', varargin{ii})
            unit_height = varargin{ii+1};
	    elseif strcmpi('errorBarColor', varargin{ii})
	    	errorBarColor = varargin{ii+1};
	    elseif strcmpi('scatterSize', varargin{ii})
	    	scatterSize = varargin{ii+1};
	    elseif strcmpi('scatterAlpha', varargin{ii})
	    	scatterAlpha = varargin{ii+1};
	    elseif strcmpi('errorBarName', varargin{ii})
	    	errorBarName = varargin{ii+1};
	    elseif strcmpi('showScatter', varargin{ii})
	    	showScatter = varargin{ii+1};
	    elseif strcmpi('plotWhere', varargin{ii})
	    	plotWhere = varargin{ii+1};
	    end
	end


	% validate the xData and Data
	if ~isvector(xData)
		error('xData must be a vector')
	end
	if ~iscell(Data)
		error('Data must be a cell array')
	end
	if numel(xData) ~= numel(Data)
		error('the length of xData and Data must be the same')
	end


	% Calculate the means and standard errors for plotting
	meanVal = cellfun(@mean,Data);
	steVal = cellfun(@ste,Data);


	% Set up the figure
	if ~exist('plotWhere','var')
		f = fig_canvas(1,'unit_width',unit_width,'unit_height',unit_height,'column_lim',column_lim);
	else
		plotWhere;
	end


	% Line plots with errorbar
	% ax = nexttile(tlo);
	hold on

	% Plot the means and error bars for each group at each time point
	h = errorbar(xData, meanVal, steVal, 'o-', 'LineWidth', 1.5, 'CapSize', 10,'Color',errorBarColor,...
		'MarkerSize', 8,'MarkerFaceColor',errorBarColor,'MarkerEdgeColor',errorBarColor,...
		'DisplayName', errorBarName);

	% Plot scatters using Data
	if showScatter
		for n = 1:numel(Data)
			scatterY = Data{n};
			scatterX = xData(n) + 0.1*randn(1,length(scatterY));
		
			% scatterX = xData(n)*ones(size(scatterY)) + (rand(size(scatterY))-0.5)*0.1; % add random noise to x-coordinates
			scatterColor = sscanf(errorBarColor(2:end), '%2x%2x%2x', [1, 3])/255;
			scatter(scatterX, scatterY, scatterSize, scatterColor, 'filled', 'MarkerFaceAlpha', scatterAlpha,...
				'HandleVisibility', 'off');
		end
	end

	varargout{1} = meanVal;
	varargout{2} = steVal;
end
