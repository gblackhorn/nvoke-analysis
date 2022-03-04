function [varargout] = plot_trace_yShift(timeInfo,traceInfo,plotWhere,varargin)
	% Plot a trace which y value can be shifted with varargin input

	% timeInfo: vector
	% traceInfo: vector having the same length as timeInfo
	% plotWhere: axe where trace is plotted to

	% Defaults
	yShift = 0; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points

	marker1_frame = []; % location of marker1 in traceInfo
	marker2_frame = []; % location of marker2 in traceInfo
	marker3_frame = []; % location of marker3 in traceInfo

	LineWidth = 1;
	LineColor = '#616887';
	marker1_color = '#8D73BA';
	marker2_color = '#BA9973';
	marker3_color = '#BA9973';
	marker1_shape = 'ro'; % marker shape for scatter plot
	marker2_shape = 'g>';
	marker3_shape = 'c<';

	traceNote = ''; % 'lowpass'/'decon'. string to specify information about traceInfo

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('yShift', varargin{ii})
	        yShift = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker1_frame', varargin{ii})
	        marker1_frame = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker2_frame', varargin{ii})
	        marker2_frame = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker3_frame', varargin{ii})
	        marker3_frame = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('traceNote', varargin{ii})
	        traceNote = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('LineWidth', varargin{ii})
	        LineWidth = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('LineColor', varargin{ii})
	        LineColor = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker1_color', varargin{ii})
	        marker1_color = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker2_color', varargin{ii})
	        marker2_color = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker1_shape', varargin{ii})
	        marker1_shape = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker2_shape', varargin{ii})
	        marker2_shape = varargin{ii+1}; % label style. 'shape'/'text'
	    elseif strcmpi('marker3_shape', varargin{ii})
	        marker3_shape = varargin{ii+1}; % label style. 'shape'/'text'
	    end
	end	

	%% Content
	if ~isempty(plotWhere)
		axes(plotWhere)
    	f = gcf;
    else
    	% f = figure;
    end

    traceInfo_shifted = traceInfo+yShift; % shift trace value on y direction
    plot(timeInfo, traceInfo_shifted, 'LineWidth', LineWidth, 'Color', LineColor); % plot trace
    hold on

    if ~isempty(marker1_frame)
    	scatter(timeInfo(marker1_frame), traceInfo_shifted(marker1_frame),...
    		marker1_shape, 'MarkerEdgeColor', marker1_color, 'LineWidth', LineWidth);
    end
    if ~isempty(marker2_frame)
    	scatter(timeInfo(marker2_frame), traceInfo_shifted(marker2_frame),...
    		marker2_shape, 'MarkerEdgeColor', marker2_color, 'LineWidth', LineWidth);
    end
    if ~isempty(marker3_frame)
    	scatter(timeInfo(marker3_frame), traceInfo_shifted(marker3_frame),...
    		marker3_shape, 'MarkerEdgeColor', marker3_color, 'LineWidth', LineWidth);
    end
end