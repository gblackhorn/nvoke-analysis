function [varargout] = plot_aligned_event_trace(grouped_alignedTrace_all,varargin)
	% plot aligned event traces

	% grouped_alignedTrace_all: structure var containing fields "stimGroup" and "eventTrace". 
	% 	- field "eventTrace" is also a structure var containing fields "group", "alignedTrace", and "normalization"

	% Defaults
	fig_position = [0.1 0.1 0.6 0.7];
	tile_col_num = 4;
	plot_combined_data = true; % whether to plot the mean and the std as shade
	y_range = [-15 10]; % limits of y axis

	% pc_norm = 'spon'; % alignedTrace will be normalized to the average value of this event category
	% normData = true; % whether normalize alignedTrace with average value of pc_norm data

	% Optionals
	% for ii = 1:2:(nargin-1)
	%     if strcmpi('pc_norm', varargin{ii})
	%         pc_norm = varargin{ii+1}; 
	%     elseif strcmpi('normData', varargin{ii})
	%         normData = varargin{ii+1};
	%     end
	% end	

	%% Content
	num_stimGroup = numel(grouped_alignedTrace_all);

	for sn = 1:num_stimGroup
		stimName = grouped_alignedTrace_all(sn).stimGroup;
		traceInfo = grouped_alignedTrace_all(sn).eventTrace;
		num_eventType = numel(traceInfo);
        
        figureName = sprintf('Aligned Event Traces (stimulation: %s)', stimName);

		f(sn) = figure('Name', figureName);
		set(gcf, 'Units', 'normalized', 'Position', fig_position)
		tile_row_num = ceil(num_eventType/tile_col_num);
		tlo = tiledlayout(f(sn), tile_row_num, tile_col_num);
		
		for en = 1:num_eventType
			eventType = traceInfo(en).group;
			timeInfo = traceInfo(en).timeInfo;
			traceData = traceInfo(en).alignedTrace;

			traceData_mean = mean(traceData, 2, 'omitnan');
			traceData_median = median(traceData, 2, 'omitnan');
			meanTraceData = traceData_median;
			traceData_shade = std(traceData, 0, 2, 'omitnan');

			ax = nexttile(tlo);
			plot_trace(timeInfo, traceData, 'plotWhere', ax,...
				'plot_combined_data', plot_combined_data,...
				'mean_trace', meanTraceData, 'mean_trace_shade', traceData_shade,...
		        'y_range', y_range); % 'y_range', y_range
			% tileTitleName = sprintf('%s: %s-negative ', stimName, stimEffectType);
			title(eventType)
        end
        
        
		title(tlo, figureName)
	end
end