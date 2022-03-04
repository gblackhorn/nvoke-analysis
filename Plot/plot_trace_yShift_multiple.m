function [varargout] = plot_trace_yShift_multiple(timeInfo,tracesInfo,plotWhere,varargin)
	% Plot multiple traces

	% timeInfo: vector
	% tracesInfo: a cell containing multiple traces
	% plotWhere: axe where trace is plotted to

	% Defaults
	yShiftInt = -20; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points
	yLabelName = []; % used to change the y tick lable to more meaning for text

	marker1_frame = {}; % location of marker1 in traceInfo
	marker2_frame = {}; % location of marker2 in traceInfo
	marker3_frame = {}; % location of marker3 in traceInfo
	stimRange = {};

	LineWidth = 1;
	LineColor = '#616887';
	marker1_color = '#8D73BA';
	marker2_color = '#BA9973';
	marker3_color = '#BA9973';
	marker1_shape = 'ro'; % marker shape for scatter plot
	marker2_shape = 'g>';
	marker3_shape = 'c<';
	stim_shade_color = {'#ED8564', '#5872ED', '#EDBF34', '#40EDC3', '#5872ED'};

	traceNote = ''; % 'lowpass'/'decon'. string to specify information about traceInfo

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('yShiftInt', varargin{ii})
	        yShiftInt = varargin{ii+1}; 
	    elseif strcmpi('yLabelName', varargin{ii})
	        yLabelName = varargin{ii+1}; 
	    elseif strcmpi('marker1_frame', varargin{ii})
	        marker1_frame = varargin{ii+1}; 
	    elseif strcmpi('marker2_frame', varargin{ii})
	        marker2_frame = varargin{ii+1}; 
	    elseif strcmpi('marker3_frame', varargin{ii})
	        marker3_frame = varargin{ii+1}; 
	    elseif strcmpi('stimRange', varargin{ii})
	        stimRange = varargin{ii+1}; % cell array. in each cell, there can be n repeats of stim (row number)
	    elseif strcmpi('traceNote', varargin{ii})
	        traceNote = varargin{ii+1}; 
	    elseif strcmpi('LineWidth', varargin{ii})
	        LineWidth = varargin{ii+1}; 
	    elseif strcmpi('LineColor', varargin{ii})
	        LineColor = varargin{ii+1}; 
	    elseif strcmpi('marker1_color', varargin{ii})
	        marker1_color = varargin{ii+1}; 
	    elseif strcmpi('marker2_color', varargin{ii})
	        marker2_color = varargin{ii+1}; 
	    elseif strcmpi('marker1_shape', varargin{ii})
	        marker1_shape = varargin{ii+1}; 
	    elseif strcmpi('marker2_shape', varargin{ii})
	        marker2_shape = varargin{ii+1}; 
	    elseif strcmpi('marker3_shape', varargin{ii})
	        marker3_shape = varargin{ii+1}; 
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
    	plot_trace_yShift(timeInfo,singleTrace,plotWhere,'yShift',shift_val,...
    		'marker1_frame', marker1_frame, 'marker2_frame', marker2_frame, 'marker3_frame', marker3_frame);
    end
    yticks(flip(yticks_pos));
    yticklabels(flip(yLabelName));

    if ~isempty(stimRange)
    	stimTypeNum = numel(stimRange); % number of stimulation types
    	for stn = 1:stimTypeNum
    		stimShadeRange = stim_range{stn};
    		draw_shade(stimShadeRange, gca, 'shadeColor', stim_shade_color{stn});
    	end
    end
    chi=get(gca, 'Children');
	set(gca, 'Children',flipud(chi));
	set(gca,'Xtick',[time_info(1):1:time_info(end)])
end