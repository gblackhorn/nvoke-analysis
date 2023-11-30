function [varargout] = plot_reboundEvent_analysis(rbEventInfo,varargin)
	% Analyze the rebound events by finding the relationship among decay tau, calcium level change,
	% event delay after the end of stimulation, etc.

	% Defaults
	fieldName_caDelta = 'caLevelDelta'; % name of the field in rbEventInfo containing the caLevelDelta data
	fieldName_decayTau = 'decayTau'; % name of the field in rbEventInfo containing the decayTau data
	fieldNames_rb_prop = {'rise_duration','sponNorm_rise_duration','FWHM',...
		'peak_mag_delta','sponNorm_peak_mag_delta',...
		'rise_delay'}; % properties of rebound events. 'baseDiff','baseDiff_stimWin','val_rise',

	plot_unit_width = 0.2; % normalized size of a single plot to the display
	plot_unit_height = 0.3; % nomralized size of a single plot to the display
	tileNum = 6; % subplot number in each scatter plot figure
	f_column_lim = 3;
	% fname_suffix = '';
	marker_size = 10;
	marker_face_alpha = 1;
	marker_edge_alpha = 0;
	FontSize = 18;
	FontWeight = 'bold';

	save_fig = false;
	save_dir = '';
	gui_save = 'off'; % Do not use gui to save

% 	colorGroup = {'#A0DFF0', '#F29665', '#6C80BD', '#BD7C6C', '#27418C',...
% 		'#B1F0C7', '#F276A5', '#79BDB7', '#BD79B5', '#318C85'};
    
    colorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	'#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};

	linearFit = true; % true/false

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('fieldNames_rb_prop', varargin{ii})
	        fieldNames_rb_prop = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('linearFit', varargin{ii})
	        linearFit = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('FontSize', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        FontSize = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('FontWeight', varargin{ii})
            FontWeight = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
	    end
	end


	% Calculate the number of figures for each scatter set
	rb_prop_num = numel(fieldNames_rb_prop);
	scatterData_caDelta_fieldNames = cell(1,rb_prop_num);
	rb_prop_field = fieldNames_rb_prop;
	for rpn = 1:rb_prop_num
		rb_prop_field{rpn} = strrep(fieldNames_rb_prop{rpn}, '_', ' '); % replace underscore with space
		scatterData_caDelta_groups{rpn} = sprintf('%s vs %s',fieldName_caDelta,rb_prop_field{rpn});
		scatterData_decayTau_groups{rpn} = sprintf('%s vs %s',fieldName_decayTau,rb_prop_field{rpn});
	end
	% scatterData_caDelta = empty_content_struct({'groups','data'},rb_prop_num); % empty structure to store the data 
	sf_num = ceil(rb_prop_num/tileNum);
	sf_title = cell(1,sf_num);


	% Scatter Set1: Show the effect of calcium level change on rbevent properties (rise time, peak
	% amplitude, event delay)
	for sfn = 1:sf_num
		sf_title{sfn} = sprintf('%s vs rebound event properties -%g',fieldName_caDelta,sfn);
		sf_ca(sfn) = fig_canvas(tileNum,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',f_column_lim,'fig_name',sf_title{sfn}); % create a figure
		tlo = tiledlayout(sf_ca(sfn),tileNum/f_column_lim,f_column_lim); % setup tiles
		axNum_notPlotted = rb_prop_num-(sfn-1)*tileNum; % number of subplots waiting to be plot
		if axNum_notPlotted >= tileNum
			axNum = tileNum; % number of plots in the current figure
		else
			axNum = axNum_notPlotted;% number of plots in the current figure
		end

		for an = 1:axNum
			ax = nexttile(tlo); % activate the ax for trace plot
			idx_rb_prop = (sfn-1)*tileNum+an;

			scatterPlot_groups({[rbEventInfo.(fieldName_caDelta)]},...
				{[rbEventInfo.(fieldNames_rb_prop{idx_rb_prop})]},...
				'xyLabel',{fieldName_caDelta,rb_prop_field{idx_rb_prop}},...
				'PlotXYlinear',linearFit,'plotwhere',gca,'titleStr',scatterData_caDelta_groups{idx_rb_prop});
		end
	end


	%% ====================
	% Get the idx of events with decayTau values
	decayTau_cell = {rbEventInfo.decayTau}; % get the decayTau and store them in a cell array
	decayTau_empty_idx = find(cellfun(@(x) isempty(x), decayTau_cell)); % Find the non-empty elements
	decayTau_nonempty_idx = find(cellfun(@(x) ~isempty(x), decayTau_cell)); % Find the non-empty elements
	decayTau_nonempty_num = numel(decayTau_nonempty_idx);
	decayTau_empty_num = numel(rbEventInfo)-decayTau_nonempty_num;


	% Pie chart showing the numbers of events with decay tau and without
	pie_values_num = [decayTau_nonempty_num decayTau_empty_num];
	pie_values_perc = [decayTau_nonempty_num/numel(rbEventInfo) decayTau_empty_num/numel(rbEventInfo)];
	label_decay_str = sprintf('exp decay %g (%g %%)',pie_values_num(1),pie_values_perc(1)*100);
	label_nondecay_str = sprintf('exp decay %g (%g %%)',pie_values_num(2),pie_values_perc(2)*100);
	pie_labels = {label_decay_str, label_nondecay_str};
	pf_title = sprintf('pie chart - rebounds events with pre-expDecay');

	pf = fig_canvas(1,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',1,'fig_name',pf_title); % create a figure to plot pie chart
	pie(gca,pie_values_num, pie_labels);
	title(pf_title);


	% Compare the event properties between decayTau positive and decayTau negtive event
	rbEventInfo_decay = rbEventInfo(decayTau_nonempty_idx); % get the rebound events with a pre-exponantial decay during og stimu
	rbEventInfo_nondecay = rbEventInfo(decayTau_empty_idx); % get the rebound events with a pre-exponantial decay during og stimu
	group_names = {'stimDecay','no-stimDecay'};
	barInfo = empty_content_struct({'prop','info'},rb_prop_num);

	for sfn = 1:sf_num
		bf_title{sfn} = sprintf('rebound events decay vs nondecay bar -%g',sfn);
		bf(sfn) = fig_canvas(tileNum,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',f_column_lim,'fig_name',bf_title{sfn}); % create a figure
		tlo = tiledlayout(bf(sfn),tileNum/f_column_lim,f_column_lim); % setup tiles

		vf_title{sfn} = sprintf('rebound events decay vs nondecay violin -%g',sfn);
		vf(sfn) = fig_canvas(tileNum,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',f_column_lim,'fig_name',vf_title{sfn}); % create a figure
		tlo_v = tiledlayout(vf(sfn),tileNum/f_column_lim,f_column_lim); % setup tiles

		stat_title{sfn} = sprintf('rebound events decay vs nondecay stat -%g',sfn);
		sf(sfn) = fig_canvas(tileNum,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',f_column_lim,'fig_name',stat_title{sfn}); % create a figure
		tlo_s = tiledlayout(sf(sfn),tileNum/f_column_lim,f_column_lim); % setup tiles

		axNum_notPlotted = rb_prop_num-(sfn-1)*tileNum; % number of subplots waiting to be plot
		if axNum_notPlotted >= tileNum
			axNum = tileNum; % number of plots in the current figure
		else
			axNum = axNum_notPlotted;% number of plots in the current figure
		end

		for an = 1:axNum
			% bar plot
			ax = nexttile(tlo); % activate the ax for bar plot
			idx_rb_prop = (sfn-1)*tileNum+an;
			prop_name = fieldNames_rb_prop{idx_rb_prop};
			bardata = {[rbEventInfo_decay.(prop_name)],...
				[rbEventInfo_nondecay.(prop_name)]};
			barInfo(idx_rb_prop).prop = rb_prop_field{idx_rb_prop};
			barInfo(idx_rb_prop).info = barplot_with_stat(bardata,'plotWhere',gca,...
				'group_names',group_names,'title_str',rb_prop_field{idx_rb_prop},...
				'TickAngle',45);

			% violin plot
			ax = nexttile(tlo_v); % activate the ax for violin plot
			fieldNames = cellfun(@(x) strrep(x,'-',''),group_names,'UniformOutput',false);
			violinData = cell2struct(bardata,fieldNames,2);
			violinplot(violinData,fieldNames,'GroupOrder',fieldNames);
			set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
			set(gca, 'box', 'off');
			title(rb_prop_field{idx_rb_prop});

			% statistics table
			statMethod = barInfo(idx_rb_prop).info.stat.stat_method; 
			switch statMethod
				case 'anova'
					sTable = barInfo(idx_rb_prop).info.stat.c;
				otherwise
					sStruct.p = barInfo(idx_rb_prop).info.stat.p;
					sStruct.h = barInfo(idx_rb_prop).info.stat.h;
					sTable = struct2table(sStruct);
			end
			ax = nexttile(tlo_s);
			plotUItable(sf(sfn),gca,sTable);
			titleMsg = sprintf('%s [%s]',rb_prop_field{idx_rb_prop},statMethod);
			title(titleMsg);
		end
	end 
	varargout{1} = barInfo; % data and stat for the event property comparisons between decay and no-decay reboud events


	% Scatter set2: Show the relationship of decayTau and rbevent properties (rise time, peak
	% amplitude, event delay)
	for sfn = 1:sf_num
		sf_title{sfn} = sprintf('%s vs rebound event properties -%g',fieldName_decayTau,sfn);
		sf_decay(sfn) = fig_canvas(tileNum,'unit_width',plot_unit_width,'unit_height',plot_unit_height,...
			'column_lim',f_column_lim,'fig_name',sf_title{sfn}); % create a figure
		tlo = tiledlayout(sf_decay(sfn),tileNum/f_column_lim,f_column_lim); % setup tiles
		axNum_notPlotted = rb_prop_num-(sfn-1)*tileNum; % number of subplots waiting to be plot
		if axNum_notPlotted >= tileNum
			axNum = tileNum; % number of plots in the current figure
		else
			axNum = axNum_notPlotted;% number of plots in the current figure
		end

		for an = 1:axNum
			ax = nexttile(tlo); % activate the ax for trace plot
			idx_rb_prop = (sfn-1)*tileNum+an;

			scatterPlot_groups({[rbEventInfo_decay.(fieldName_decayTau)]},...
				{[rbEventInfo_decay.(fieldNames_rb_prop{idx_rb_prop})]},...
				'xyLabel',{fieldName_decayTau,rb_prop_field{idx_rb_prop}},...
				'PlotXYlinear',linearFit,'plotwhere',gca,'titleStr',scatterData_decayTau_groups{idx_rb_prop});
		end
	end


	% Save figures
	if save_fig

		% scatter plot figure for calcium level delta related
		for sfn = 1:sf_num 
			if ~isempty(save_dir)
				gui_save = 'on';
			end

			msg = 'Choose a folder to save analysis plots for rebound events';
			save_dir = savePlot(sf_ca(sfn),'save_dir',save_dir,'guiSave',gui_save,...
				'guiInfo',msg,'fname',sf_title{sfn});

			varargout{2} = save_dir;
		end
		gui_save = 'off';

		% pie chart
		save_dir = savePlot(pf,'save_dir',save_dir,'guiSave',gui_save,...
				'guiInfo',msg,'fname',pf_title);

		% bar plot figure
		for sfn = 1:sf_num 
			savePlot(bf(sfn),'save_dir',save_dir,'guiSave',gui_save,...
				'guiInfo',msg,'fname',bf_title{sfn});
		end
		save(fullfile(save_dir, ['rbEvent_decay_vs_nodecay']),...
		    'barInfo');

		% violin plot figure
		for sfn = 1:sf_num 
			savePlot(vf(sfn),'save_dir',save_dir,'guiSave',gui_save,...
				'guiInfo',msg,'fname',vf_title{sfn});
		end

		% statistics table
		for sfn = 1:sf_num 
			savePlot(sf(sfn),'save_dir',save_dir,'guiSave',gui_save,...
				'guiInfo',msg,'fname',stat_title{sfn});
		end

		% scatter plot figure for decayTau related 
		for sfn = 1:sf_num 
			savePlot(sf_decay(sfn),'save_dir',save_dir,'guiSave',gui_save,...
				'guiInfo',msg,'fname',sf_title{sfn});
		end
	end
end


