function [varargout] = plot_trace_yShift_multiple(timeInfo,tracesInfo,plotWhere,varargin)
	% Plot multiple traces

	% timeInfo: vector
	% tracesInfo: a cell containing multiple traces
	% plotWhere: axe where trace is plotted to

	% Defaults
	yShiftInt = -20; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points
	yLabelName = {}; % used to change the y tick lable to more meaning for text

	markers_frame_cell = {}; % location of markers in traceInfo
	stimRange = {};

	mean_tracesInfo = {};
	std_tracesInfo = {};

	LineWidth = 1;
	LineColor = '#616887';
	FontSize = 12;
	markers_color = {'#8D73BA','#BA9973','#BA9973'};
	markers_shape = {'ro','g>','c<'}; % marker shape for scatter plot
	stim_shade_color = {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'};

	traceNote = ''; % 'lowpass'/'decon'. string to specify information about traceInfo

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('yShiftInt', varargin{ii})
	        yShiftInt = varargin{ii+1}; 
	    elseif strcmpi('yLabelName', varargin{ii})
	        yLabelName = varargin{ii+1}; 
	    elseif strcmpi('markers_frame', varargin{ii})
	        markers_frame_cell = varargin{ii+1}; 
	    elseif strcmpi('stimRange', varargin{ii})
	        stimRange = varargin{ii+1}; % cell array. in each cell, there can be n repeats of stim (row number)
	    elseif strcmpi('mean_tracesInfo', varargin{ii})
	        mean_tracesInfo = varargin{ii+1}; % cell array. in each cell, there can be n repeats of stim (row number)
	    elseif strcmpi('std_tracesInfo', varargin{ii})
	        std_tracesInfo = varargin{ii+1}; % cell array. in each cell, there can be n repeats of stim (row number)
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
    	f = gcf;
    else
    	f = figure;
    end
    hold on

    num_trace = numel(tracesInfo);
    yticks_pos = [yShiftInt:yShiftInt:(num_trace*yShiftInt)];
    for n = 1:num_trace
    	singleTrace = tracesInfo{n};
    	shift_val = n*yShiftInt;
    	if ~isempty(markers_frame_cell)
    		markers_frame = markers_frame_cell{n};
    	else
    		markers_frame = {};
    	end

    	if ~isempty(mean_tracesInfo) && ~isempty(std_tracesInfo)
    		singleMeanTrace = mean_tracesInfo{n};
    		singleStdTrace = std_tracesInfo{n};
    	else
    		singleMeanTrace = [];
    		singleStdTrace = [];
    	end

    	plot_trace_yShift(timeInfo,singleTrace,plotWhere,'yShift',shift_val,...
    		'markers_frame', markers_frame, 'mean_trace', singleMeanTrace, 'std_trace', singleStdTrace,...
    		'markers_color', markers_color, 'markers_shape', markers_shape, 'FontSize', FontSize);
    end
    yticks(flip(yticks_pos));
    yticklabels(flip(yLabelName));

    if ~isempty(stimRange)
    	stimTypeNum = numel(stimRange); % number of stimulation types
    	for stn = 1:stimTypeNum
    		stimShadeRange = stimRange{stn};
    		draw_shade(stimShadeRange, gca, 'shadeColor', stim_shade_color{stn});
    	end
    end
    chi=get(gca, 'Children');
	set(gca, 'Children',flipud(chi));
	set(gca,'Xtick',[timeInfo(1):10:timeInfo(end)])

	varargout{1} = ylim;
end