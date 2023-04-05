function [varargout] = plot_eventTimeInt_alignedData_allTrials(alignedData,eventType,binsOrEdges,varargin)
	%Get the event time and calculate their intervals 

	% intervals are calculated in each ROI, and the data from all ROIs from all trials are concatenated

	% eventType: 'rise_time', 'peak_time'



	% Defaults
	filter_roi_tf = false; % do not filter ROIs by default
	stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = {[nan 1 nan], [1 nan nan], [nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound

	plot_unit_width = 0.45; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display

	% fontSize_tick = 12;
	% fontSize_label = 14;
	% fontSize_title = 16;
	fontSize_sgTitle = 16;

	xlabelStr = 'time (s)';
	ylabelStr = 'Probability Density';
	% titleStr = 'Hist with PDF';

	% Optionals
	for ii = 1:2:(nargin-3)
		if strcmpi('filter_roi_tf', varargin{ii})
		    filter_roi_tf = varargin{ii+1}; % number array. An index of ROI traces will be collected 
		elseif strcmpi('stim_names', varargin{ii})
		    stim_names = varargin{ii+1}; % number array. An index of ROI traces will be collected 
		elseif strcmpi('filters', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
		    filters = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    % elseif strcmpi('xlabelStr', varargin{ii})
        %     xlabelStr = varargin{ii+1};
	    % elseif strcmpi('ylabelStr', varargin{ii})
        %     ylabelStr = varargin{ii+1};
	    % elseif strcmpi('titleStr', varargin{ii})
        %     titleStr = varargin{ii+1};
	    end
	end

	% loop through stimulation types
    if numel(binsOrEdges) == 1
	    binWidth = binsOrEdges;
	elseif numel(binsOrEdges) > 1
		binWidths = diff(binsOrEdges);
		binWidth = binWidths(1);
	end
	titleStr = sprintf('Inter-event time in %g s bins [%s]',binWidth,eventType);
	titleStr = strrep(titleStr,'_',' ');

	stim_type_num = numel(stim_names); % Get the number of stimulation types
	[fPDF,fPDF_rowNum,fPDF_colNum] = fig_canvas(stim_type_num,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tloPDF = tiledlayout(fPDF,fPDF_rowNum,fPDF_colNum);

	[fACF,fACF_rowNum,fACF_colNum] = fig_canvas(stim_type_num,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tloACF = tiledlayout(fACF,fACF_rowNum,fACF_colNum);
	for stn = 1:stim_type_num
		% Get all the inter-event time from 
		[eventIntAll] = get_eventTimeInt(alignedData,eventType,...
			'filter_roi_tf',filter_roi_tf,'stim_names',stim_names{stn},...
			'filters',filters);

		% Plot the PDF for inter-event time
		ax = nexttile(tloPDF);
		filterStr = NumArray2StringCell(filters{stn});
		sub_titleStr = sprintf('%s: ex-%s in-%s rb-%s',stim_names{stn},filterStr{1},filterStr{2},filterStr{3}); % string for the subtitle

		[histHandle] = plot_NormHistWithPDF(eventIntAll,binsOrEdges,...
			'xlabelStr',xlabelStr,'ylabelStr',ylabelStr,...
			'titleStr',sub_titleStr);

		% Plot the auto-correlogram for inter-event time
		ax = nexttile(tloACF);
		[acf_values,lag_values] = autocorr(eventIntAll,'NumLags',200);
		stem(lag_values,acf_values);
		xlabel('lag (bins)')
		ylabel('auto-correlation')
		title(sub_titleStr)
	end
	sgtitle(fPDF,['PDF ',titleStr],'FontSize', fontSize_sgTitle)
    sgtitle(fACF,['ACF ',titleStr],'FontSize', fontSize_sgTitle)
end