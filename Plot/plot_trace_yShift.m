function [varargout] = plot_trace_yShift(timeInfo,traceInfo,plotWhere,varargin)
	% Plot a trace which y value can be shifted with varargin input

	% timeInfo: vector
	% traceInfo: vector having the same length as timeInfo
	% plotWhere: axe where trace is plotted to

	% Defaults
	yShift = 0; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points

	markers_frame = {}; % location of marker1 in traceInfo

	mean_trace = []; % used to plot shade 
	std_trace = []; % used to plot shade 

	LineWidth = 1;
	LineColor = '#98A3D4'; % '#98A3D4' '#616887'
	markers_color = {'#8D73BA', '#BA9973', '#BA9973'};
	markers_shape = {'ro', 'g>', 'c<'}; % marker shape for scatter plot
	FontSize = 12;

	traceNote = ''; % 'lowpass'/'decon'. string to specify information about traceInfo

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('yShift', varargin{ii})
	        yShift = varargin{ii+1}; 
	    elseif strcmpi('markers_frame', varargin{ii})
	        markers_frame = varargin{ii+1}; 
	    elseif strcmpi('mean_trace', varargin{ii})
	        mean_trace = varargin{ii+1}; 
	    elseif strcmpi('std_trace', varargin{ii})
	        std_trace = varargin{ii+1}; 
	    elseif strcmpi('traceNote', varargin{ii})
	        traceNote = varargin{ii+1}; 
	    elseif strcmpi('LineWidth', varargin{ii})
	        LineWidth = varargin{ii+1}; 
	    elseif strcmpi('LineColor', varargin{ii})
	        LineColor = varargin{ii+1}; 
	    elseif strcmpi('FontSize', varargin{ii})
	        FontSize = varargin{ii+1}; 
	    elseif strcmpi('markers_color', varargin{ii})
	        markers_color = varargin{ii+1}; 
	    elseif strcmpi('markers_shape', varargin{ii})
	        markers_shape = varargin{ii+1}; 
	    end
	end	

	%% Content
	if ~isempty(plotWhere)
		axes(plotWhere)
		ax = gca;
    	f = gcf;
    else
    	% f = figure;
    end
    hold on

    traceInfo_shifted = traceInfo+yShift; % shift trace value on y direction
    plot(timeInfo, traceInfo_shifted,...
    'LineWidth', LineWidth, 'Color', LineColor); % plot trace
    

    if ~isempty(markers_frame)
    	for n = 1:numel(markers_frame)
    		frame = markers_frame{n};
    		scatter(timeInfo(frame), traceInfo_shifted(frame),...
    		markers_shape{n}, 'MarkerEdgeColor', markers_color{n}, 'LineWidth', LineWidth);
    	end
    end

    if ~isempty(mean_trace) && ~isempty(std_trace)
    	mean_trace_shifted = mean_trace+yShift;
    	plot_trace_with_rangeShade(timeInfo,mean_trace_shifted,std_trace,ax);
    end

    set(gca, 'FontSize', FontSize)
end