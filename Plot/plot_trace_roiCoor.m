function [varargout] = plot_trace_roiCoor(alignedData,varargin)
	% Plot traces and roi map side by side

	% alignedData: alignedData structure of a single trial

	% Defaults
	yShiftInt = -20; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points
	traceNum_perFig = 10; 
	markers_name = {'peak_loc', 'rise_loc'}; % of which will be labled in trace plot
	% marker3_name = 'decay_loc'; % alignedData does not have decay loc yet

	LineWidth = 1;
	LineColor = '#616887';

	stimEffect = true; % true/false. give different color to ROIs according to stim effect
	label = 'text'; % 'shape'/'text'. lables of rois. Default color: ex-magenta, in-cyan, other-yellow

	fig_position = [0.1 0.1 0.85 0.8];

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('yShift', varargin{ii})
	        yShift = varargin{ii+1}; 
	    elseif strcmpi('markers_name', varargin{ii})
	        markers_name = varargin{ii+1}; 
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
	aligned_timeInfo = alignedData.time;
	stimRange = {alignedData.stimInfo.time_range_notAlign};
	aligned_stimRange = {alignedData.stimInfo.time_range};

	marker1_frame = cell(1, num_roi);
	for rn = 1:num_roi
		for mn = 1:numel(markers_name)
			markers_frame_all{rn}{mn} = [alignedData.traces(rn).eventProp.(markers_name{mn})];
			% marker2_frame{rn} = {alignedData.traces(rn).eventProp.(marker2_name)};
			% marker3_frame{rn} = alignedData.traces(rn).eventProp.(marker3_name)};
		end
	end

	for fn = 1:num_fig
		fig_title = sprintf('%s (%d)', alignedData.trialName(1:15), fn);
		f(fn) = figure('Name', fig_title);
		set(gcf, 'Units', 'normalized', 'Position', fig_position)
		tlo = tiledlayout(f(fn), 1, 9);
		tlo.Title.String = ['trial: ', fig_title];


		idx_start_roi = (fn-1)*traceNum_perFig+1;
		if fn < num_fig
			idx_end_roi = fn*traceNum_perFig;
		else
			idx_end_roi = num_roi;
		end
		roiData = alignedData.traces(idx_start_roi:idx_end_roi);
		tracesInfo = {roiData.fullTrace};
		yLabelName = {roiData.roi};
		markers_frame = markers_frame_all(idx_start_roi:idx_end_roi);
		aligned_tracesInfo = {roiData.value};
		aligned_tracesMean = {roiData.mean_val};
		aligned_tracesStd = {roiData.std_val};


		% plot traces
		ax = nexttile(tlo, [1 4]);
		yl = plot_trace_yShift_multiple(timeInfo,tracesInfo,ax,...
			'yLabelName', yLabelName, 'markers_frame', markers_frame, 'stimRange', stimRange,...
			'yShift',yShiftInt);
		title('traces')

		% plot aligned traces 
		ax = nexttile(tlo, [1 1]);
		ylim(yl)
		plot_trace_yShift_multiple(aligned_timeInfo,aligned_tracesInfo,ax,...
			'yLabelName', yLabelName, 'stimRange', aligned_stimRange,...
			'yShift', yShiftInt, 'mean_tracesInfo', aligned_tracesMean,'std_tracesInfo', aligned_tracesStd);
		title('stim-aligned traces')

		% plot roi map
		ax = nexttile(tlo, [1 4]);
		plot_roi_coor_alignedData(alignedData,ax,'label',label);
		title('roi map')
	end
end