function [varargout] = plot_trace_roiCoor(alignedData,varargin)
	% Plot traces and roi map side by side

	% alignedData: alignedData structure of a single trial

	% Defaults
	yShiftInt = -20; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points
	traceNum_perFig = 10; 
	marker1_name = 'peak_loc';
	marker2_name = 'rise_loc';
	% marker3_name = 'decay_loc'; % alignedData does not have decay loc yet

	LineWidth = 1;
	LineColor = '#616887';

	stimEffect = true; % true/false. give different color to ROIs according to stim effect
	label = 'shape'; % 'shape'/'text'. lables of rois.

	fig_position = [0.1 0.1 0.7 0.7];

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('yShift', varargin{ii})
	        yShift = varargin{ii+1}; 
	    elseif strcmpi('traceNum_perFig', varargin{ii})
	        traceNum_perFig = varargin{ii+1}; 
	    elseif strcmpi('LineWidth', varargin{ii})
	        LineWidth = varargin{ii+1}; 
	    elseif strcmpi('LineColor', varargin{ii})
	        LineColor = varargin{ii+1}; 
	    elseif strcmpi('stimEffect', varargin{ii})
	        stimEffect = varargin{ii+1}; 
	    elseif strcmpi('label', varargin{ii})
	        label = varargin{ii+1}; 
	    end
	end	

	%% Content
	num_roi = numel(alignedData.traces);
	num_fig = ceil(num_roi/traceNum_perFig);
	timeInfo = alignedData.fullTime;
	stimRange = {alignedData.stimInfo.time_range_notAlign};

	marker1_frame = cell(1, num_roi);
	for rn = 1:num_roi
		marker1_frame{rn} = alignedData.traces(rn).eventProp.(marker1_name)};
		marker2_frame{rn} = alignedData.traces(rn).eventProp.(marker2_name)};
		% marker3_frame{rn} = alignedData.traces(rn).eventProp.(marker3_name)};
	end

	for fn = 1:num_fig
		fig_title = sprintf('%s (%d)', alignedData.trialName{1:15}, fn);
		f(fn) = figure('Name', fig_title);
		set(gcf, 'Units', 'normalized', 'Position', fig_position)
		tlo = tiledlayout(f(fn), 1, 2);

		idx_start_roi = (fn-1)*traceNum_perFig+1;
		if fn < num_fig
			idx_end_roi = fn*traceNum_perFig;
		else
			idx_end_roi = num_roi;
		end
		roiData = alignedData.traces(idx_end_roi:idx_end_roi);
		tracesInfo = {roiData.fullTrace};

		% plot traces
		ax = nexttile(tlo);
		plot_trace_yShift_multiple(timeInfo,tracesInfo,ax,...
			'marker1_frame', marker1_frame, 'marker2_frame', marker2_frame,...
			'yShift',yShiftInt,'traceNum_perFig',traceNum_perFig,'label',label);

		% plot roi map
		ax = nexttile(tlo);
		plot_roi_coor_alignedData(alignedData,[],'label',label);
	end
end