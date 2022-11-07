function [varargout] = PlotTraceFromAlignedDataVar(alignedData,varargin)
	% Plot traces (full or aligned) in a single trial

	% timeInfo: vector
	% tracesInfo: a cell containing multiple traces
	% plotWhere: axe where trace is plotted to

	% Defaults
	TraceType = 'full'; % 'full'/'aligned'. Plot the full trace or stimulation aligned trace
	yShiftInt = -20; % use the (idx_timePoint)th and (idx_timePoint-1)th points to calculate the interval time points
	traceNum_perFig = 10; 
	% yLabelName = {}; % used to change the y tick lable to more meaning for text

	markers_frame_cell = {}; % location of markers in traceInfo
	stimRange = {};

	mean_tracesInfo = {};
	std_tracesInfo = {};

	LineWidth = 1;
	LineColor = '#616887';

	traceNote = ''; % 'lowpass'/'decon'. string to specify information about traceInfo

	
	save_fig = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('yShiftInt', varargin{ii})
	        yShiftInt = varargin{ii+1}; 
	    elseif strcmpi('yLabelName', varargin{ii})
	        yLabelName = varargin{ii+1}; 
	    elseif strcmpi('TraceType', varargin{ii})
	        TraceType = varargin{ii+1}; 
	    elseif strcmpi('markers_name', varargin{ii})
	        markers_name = varargin{ii+1}; 
	    elseif strcmpi('LineWidth', varargin{ii})
	        LineWidth = varargin{ii+1}; 
	    elseif strcmpi('LineColor', varargin{ii})
	        LineColor = varargin{ii+1}; 
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1}; 
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1}; 
	    end
	end	

	%% Content
	num_roi = numel(alignedData.traces);
	num_fig = ceil(num_roi/traceNum_perFig);

	switch TraceType
		case 'full'
			fig_position = [0.1 0.1 0.85 0.8];
			timeInfo = alignedData.fullTime;
			stimRange = {alignedData.stimInfo.StimDuration.range};
			for rn = 1:num_roi
				if numel(markers_name)>0
					for mn = 1:numel(markers_name)
						markers_frame_all{rn}{mn} = [alignedData.traces(rn).eventProp.(markers_name{mn})];
					end
				else
					markers_frame_all = [];
				end
			end
		case 'aligned'
			fig_position = [0.1 0.1 0.1 0.8];
			timeInfo = alignedData.time;
			stimRange = {alignedData.stimInfo.StimDuration.range_aligned};
		% otherwise
		% 	body
	end

	for fn = 1:num_fig
		fig_title = sprintf('%s[%s] %s (%d)', alignedData.trialName(1:15),alignedData.stim_name,TraceType,fn);
		f(fn) = figure('Name', fig_title);
		set(gcf, 'Units', 'normalized', 'Position', fig_position)

		idx_start_roi = (fn-1)*traceNum_perFig+1;
				if fn < num_fig
			idx_end_roi = fn*traceNum_perFig;
		else
			idx_end_roi = num_roi;
		end
		roiData = alignedData.traces(idx_start_roi:idx_end_roi);
		yLabelName = {roiData.roi};


		switch TraceType
			case 'full'
				if ~isempty(markers_frame_all)
					markers_frame = markers_frame_all(idx_start_roi:idx_end_roi);
				else
					markers_frame = [];
				end
				tracesInfo = {roiData.fullTrace};
				plot_trace_yShift_multiple(timeInfo,tracesInfo,gca,...
							'yLabelName', yLabelName, 'markers_frame', markers_frame, 'stimRange', stimRange,...
							'yShift',yShiftInt);

			case 'aligned'
				tracesInfo = {roiData.value};
				aligned_tracesMean = {roiData.mean_val};
				aligned_tracesStd = {roiData.std_val};
				plot_trace_yShift_multiple(timeInfo,tracesInfo,gca,...
					'yLabelName', yLabelName, 'stimRange', stimRange,...
					'yShift', yShiftInt, 'mean_tracesInfo', aligned_tracesMean,'std_tracesInfo', aligned_tracesStd);
		end
		if save_fig
			fname = sprintf('%s_trace_%s_%s_%d',TraceType,alignedData.trialName(1:15),alignedData.stim_name,fn);
			savePlot(f(fn),'save_dir',save_dir,'fname',fname);
		end
	end
end