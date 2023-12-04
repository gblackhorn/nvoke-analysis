function [varargout] = plot_event_info(event_info_struct,varargin)
	% Plot various event properties 
	% Input: 
	%	- structure array including one or more event_info structures {event_info1, event_info2,...}
	% Output:
	%	- event frequency histogram
	%	- event interval variance histogram
	%	- event rise_time bar
	%	- event peak amplitude bar
	%	- event rise_time/peak scatter and correlation
	%	- event peak-slope scatter and correlation
	%	- event slope bar

	% Defaults
	plot_combined_data = false; % applied to histogram plots
	parNames = {'rise_duration','peak_mag_delta','peak_delta_norm_hpstd',...
		'peak_slope','peak_slope_norm_hpstd','baseDiff','baseDiff_stimWin'}; 
		% options: 'rise_duration', 'peak_mag_delta', 'peak_delta_norm_hpstd', 'peak_slope', 'peak_slope_norm_hpstd'
	save_fig = false;
	save_dir = '';
	savepath_nogui = '';
	fname_suffix = '';

	stat = false; % true if want to run anova when plotting bars
	stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

	FontSize = 10;
	FontWeight = 'bold';
	TickAngle = 15; 

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1};
        elseif strcmpi('parNames', varargin{ii})
	        parNames = varargin{ii+1};
        elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('savepath_nogui', varargin{ii})
            savepath_nogui = varargin{ii+1};
        elseif strcmpi('fname_suffix', varargin{ii})
            fname_suffix = varargin{ii+1};
	    elseif strcmpi('stat', varargin{ii})
            stat = varargin{ii+1};
	    elseif strcmpi('stat_fig', varargin{ii})
            stat_fig = varargin{ii+1};
	    elseif strcmpi('FontSize', varargin{ii})
            FontSize = varargin{ii+1};
	    elseif strcmpi('FontWeight', varargin{ii})
            FontWeight = varargin{ii+1};
	    end
	end

	if save_fig 
		if isempty(savepath_nogui)
			save_dir = uigetdir(save_dir,...
				'Choose a folder to save plots');
			varargout{1} = save_dir;
			if save_dir == 0
				disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false')
				varargout{1} = save_dir;
				return
			end
		else
			save_dir = savepath_nogui;
		end
	end

	close all

	% find and delete the empty entries in event_info_struct
	tf_empty = cellfun(@isempty, {event_info_struct.event_info});
	idx_empty = find(tf_empty);
	event_info_struct(idx_empty) = [];

	group_num = numel(event_info_struct);
	par_num = numel(parNames);

	event_info_fieldnames = fieldnames(event_info_struct(1).event_info);
	mean_val_idx = find(contains(event_info_fieldnames, 'mean'));
	if ~isempty(mean_val_idx)
		dataType = 'roi'; % event propertes from each single roi are stored in a single entry in struct. mean values were calculated
		for pn = 1:par_num
			idx_par = find(contains(event_info_fieldnames, parNames{pn})); 
			[C] = intersect(idx_par, mean_val_idx);
			if ~isempty(C)
				parNames{pn} = event_info_fieldnames{C};
			end
		end
		% parNames = cellfun(@(x) [x, '_mean'], parNames, 'UniformOutput',false);
	else
		dataType = 'event'; % 1 entry in a struct only contains 1 event. No mean value
	end

	%% histogram plot
	% par_num = numel(parNames);
	for pn = 1:par_num
		par = parNames{pn};

		[hist_data.(par), hist_setting.(par)] = plot_event_info_hist(event_info_struct,...
			par, 'plot_combined_data', plot_combined_data,'FontSize',FontSize,'FontWeight',FontWeight,...
			'save_fig', save_fig, 'save_dir', save_dir, 'fname_suffix',fname_suffix,'nbins', 200);
	end

	%% histfit plot
	% par_num = numel(parNames);
	for pn = 1:par_num
		par = parNames{pn};

		[histFit_info.(par)] = plot_event_info_histfit(event_info_struct,par,'dist_type','normal',...
			'save_fig', save_fig, 'save_dir', save_dir, 'fname_suffix',fname_suffix,...
			'xRange',[-0.2 2],'nbins', 20,'FontSize',FontSize,'FontWeight',FontWeight); % 'nbins', 20,
	end

	%% bar plot
	f_bar = figure('Name', 'bar plots');
    f_stat = figure('Name', 'bar stat');
    f_box = figure('Name', 'box plots');
    f_violin = figure('Name', 'violin plots');

	if par_num == 1
		fig_position = [0.1 0.1 0.2 0.3]; % left, bottom, width, height
	else
		fig_position = [0.1 0.1 0.8 0.4];
	end
	set(f_bar, 'Units', 'normalized', 'Position', fig_position)
    set(f_stat, 'Units', 'normalized', 'Position', fig_position)
    set(f_box, 'Units', 'normalized', 'Position', fig_position)
    set(f_violin, 'Units', 'normalized', 'Position', fig_position)

	tlo_bar = tiledlayout(f_bar, ceil(par_num/4), 4);
	tlo_barstat = tiledlayout(f_stat, ceil(par_num/4), 4);
	tlo_box = tiledlayout(f_box, ceil(par_num/4), 4);
	tlo_violin = tiledlayout(f_violin, ceil(par_num/4), 4);

	groupNames = {event_info_struct.group};
	% group_num = numel(groupNames);

	for pn = 1:par_num

		% bar plot and statistics
		ax_bar = nexttile(tlo_bar);
		ax_stat = nexttile(tlo_barstat);
		par = parNames{pn};
		if group_num >1
			[bar_data.(par), bar_stat.(par)] = plot_event_info_bar(event_info_struct,par,...
				'plotWhere',ax_bar,'stat',stat,'stat_fig',stat_fig,'FontSize',FontSize,'FontWeight',FontWeight);
			title(replace(par, '_', '-'));

			% Plot multiCompare statistics in a single figure
			uit_pos = get(ax_stat,'Position');
			uit_unit = get(ax_stat,'Units');
			% delete(ax_stat);
			MultCom_stat = bar_stat.(par).c(:,["g1","g2","p","h"]);
			uit = uitable(f_stat,'Data',table2cell(MultCom_stat),...
				'ColumnName',MultCom_stat.Properties.VariableNames,...
				'Units',uit_unit,'Position',uit_pos);
			% title(replace(par, '_', '-'));
			% delete(ax_stat);

			jScroll = findjobj(uit);
			jTable  = jScroll.getViewport.getView;
			jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
			drawnow;
		end

		% box plot
		ax_box = nexttile(tlo_box);
		event_info_cell = cell(1, group_num);
		for gn = 1:group_num
			event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
		end
		[~, box_stat.(par)] = boxPlot_with_scatter(event_info_cell, 'groupNames', groupNames,...
			'plotWhere', ax_box, 'stat', true, 'FontSize', FontSize,'FontWeight',FontWeight);
		title(replace(par, '_', '-'));

		% violin plot
		ax_violin = nexttile(tlo_violin);
		[violinData,violinGroups] = createDataAndGroupNameArray(event_info_cell,groupNames);
		violinplot(violinData,violinGroups);
		set(gca, 'box', 'off');
		set(gca,'TickDir','out');
		set(gca, 'FontSize', FontSize);
		set(gca, 'FontWeight', FontWeight);
		xtickangle(TickAngle);
		title(replace(par, '_', '-'));
	end
	if save_fig
		fname_bar = sprintf('bar_plots-%s',fname_suffix);
		savePlot(f_bar,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_bar);

		fname_stat = sprintf('bar_stat-%s',fname_suffix);
		savePlot(f_stat,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_stat);

		% fname = 'box_plots';
		fname_box = sprintf('box_plots-%s',fname_suffix);
		savePlot(f_box,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_box);

		fname_violin = sprintf('violin_plots-%s',fname_suffix);
		savePlot(f_violin,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname_violin);
	end

	% %% box plot
	% f_box = figure('Name', 'box plots');
	% if par_num == 1
	% 	fig_position = [0.1 0.1 0.2 0.6];
	% else
	% 	fig_position = [0.1 0.1 0.8 0.8];
	% end 
	% set(gcf, 'Units', 'normalized', 'Position', fig_position)
	% tlo = tiledlayout(f_box, ceil(par_num/4), 4);
	% groupNames = {event_info_struct.group};
	% group_num = numel(groupNames);
	% for pn = 1:par_num
	% 	ax = nexttile(tlo);
	% 	par = parNames{pn};
	% 	event_info_cell = cell(1, group_num);
	% 	for gn = 1:group_num
	% 		event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
	% 	end
	% 	[~, box_stat.(par)] = boxPlot_with_scatter(event_info_cell, 'groupNames', groupNames,...
	% 		'plotWhere', ax, 'stat', true, 'FontSize', FontSize,'FontWeight',FontWeight);
	% 	title(replace(par, '_', '-'));
	% end
	% if save_fig
	% 	% fname = 'box_plots';
	% 	fname = sprintf('box_plots-%s',fname_suffix);
	% 	savePlot(f_box,...
	% 		'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
	% end

	% %% violin plot
	% f_violin = figure('Name', 'box plots');
	% if par_num == 1
	% 	fig_position = [0.1 0.1 0.2 0.6];
	% else
	% 	fig_position = [0.1 0.1 0.8 0.8];
	% end 
	% set(gcf, 'Units', 'normalized', 'Position', fig_position)
	% tlo = tiledlayout(f_violin, ceil(par_num/4), 4);
	% groupNames = {event_info_struct.group};
	% group_num = numel(groupNames);
	% for pn = 1:par_num
	% 	ax = nexttile(tlo);
	% 	par = parNames{pn};
	% 	event_info_cell = cell(1, group_num);
	% 	for gn = 1:group_num
	% 		event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
	% 	end
	% 	[~, box_stat.(par)] = boxPlot_with_scatter(event_info_cell, 'groupNames', groupNames,...
	% 		'plotWhere', ax, 'stat', true, 'FontSize', FontSize,'FontWeight',FontWeight);
	% 	title(replace(par, '_', '-'));
	% end
	% if save_fig
	% 	% fname = 'box_plots';
	% 	fname = sprintf('box_plots-%s',fname_suffix);
	% 	savePlot(f_box,...
	% 		'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
	% end


	%% cumulative plot
	f_cd = figure('Name', 'cumulative distribution plots'); 
	if par_num == 1
		fig_position = [0.1 0.1 0.2 0.3];
	else
		fig_position = [0.1 0.1 0.8 0.4];
	end 
	set(gcf, 'Units', 'normalized', 'Position', fig_position)
	tlo = tiledlayout(f_cd, ceil(par_num/4), 4);
	groupNames = {event_info_struct.group};
	group_num = numel(groupNames);
	for pn = 1:par_num
		ax = nexttile(tlo);
		par = parNames{pn};
		event_info_cell = cell(1, group_num);
		for gn = 1:group_num
			event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
		end
		[data_cd, data_cdCombine] = cumulative_distr_plot(event_info_cell, 'groupNames', groupNames,...
			'plotWhere', ax, 'stat', true, 'FontSize', FontSize,'FontWeight',FontWeight);
		title(replace(par, '_', '-'));
	end
	if save_fig
		% fname = 'cd_plots';
		fname = sprintf('cd_plots-%s',fname_suffix);
		savePlot(f_cd,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
	end

	%% scatter plot
	duration_val_idx = find(contains(parNames, 'duration')); % idx of duration pars, such as rise_duration
	mag_val_idx = find(contains(parNames, 'mag_delta')); % idx of mag, such as peak_mag_delta
	mag_norm_val_idx = find(contains(parNames, 'peak_delta_norm_hpstd')); % idx of normalized mag, such as peak_mag_norm_delta
	all_mag_val_idx = [mag_val_idx; mag_norm_val_idx];
	all_slope_val_idx = find(contains(parNames, 'slope')); % idx of all slopes, such as peak_slope and peak_slope_norm_hpstd
	norm_slope_val_idx = find(contains(parNames, 'peak_slope_norm_hpstd')); % idx of slope calculated using norm data, such as peak_slope_norm_hpstd
	slope_val_idx = setdiff(all_slope_val_idx, norm_slope_val_idx); % idx of slope calculated with non-normalized data
	baseDiff_idx = find(contains(parNames, 'baseDiff')); 
	baseDiffRise_idx = find(contains(parNames, 'baseDiffRise')); 
	% baseDiffWin_idx = find(contains(parNames, 'baseDiff_stimWin')); % difference between lowest value during stimulation and baseline 
	val_rise_idx = find(contains(parNames, 'val_rise')); 
	riseDelay_idx = find(contains(parNames, 'rise_delay')); 
	% sponNorm_peak_mag_delta_idx = find(contains(parNames, 'sponNorm_peak_mag_delta')); 

	% mag_num = numel(mag_val_idx);
	% mag_norm_num = numel(mag_norm_val_idx);
	% slope_num = numel(slope_val_idx);
	% slope_norm_num = numel(norm_slope_val_idx);

	%% scatter plot
	% duration vs mag/slope
	if ~isempty(duration_val_idx)
		duration_par_num = numel(duration_val_idx);
		for dn = 1:duration_par_num
			par_duration = parNames{duration_val_idx(dn)};
			if ~isempty(all_mag_val_idx)
				mag_par_num = numel(all_mag_val_idx);
				for mn = 1:mag_par_num
					par_mag = parNames{all_mag_val_idx(mn)};

					[scatter_data.([par_duration, '_vs_' par_mag])] = plot_event_info_scatter(event_info_struct,...
						par_duration, par_mag,'FontSize', FontSize,'FontWeight',FontWeight,...
						'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
				end
			end

			if ~isempty(all_slope_val_idx)
				slope_par_num = numel(all_slope_val_idx);
				for sn = 1:slope_par_num
					par_slope = parNames{all_slope_val_idx(sn)};

					[scatter_data.([par_duration, '_vs_' par_slope])] = plot_event_info_scatter(event_info_struct,...
						par_duration, par_slope,'FontSize', FontSize,'FontWeight',FontWeight,...
						'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
				end
			end
		end

	end

	% mag vs slope
	if ~isempty(mag_val_idx)
		mag_par_num = numel(mag_val_idx);
		for mn = 1:mag_par_num
			par_mag = parNames{mag_val_idx(mn)};
			if ~isempty(slope_val_idx)
				par_slope = numel(slope_val_idx);
				for sn = 1:par_slope
					par_slope = parNames{slope_val_idx(sn)};

					[scatter_data.([par_mag, '_vs_' par_slope])] = plot_event_info_scatter(event_info_struct,...
						par_mag, par_slope,'FontSize', FontSize,'FontWeight',FontWeight,...
						'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
				end
			end
		end
	end

	% mag_norm vs slope_norm
	if ~isempty(mag_norm_val_idx)
		mag_norm_par_num = numel(mag_norm_val_idx);
		for mn = 1:mag_norm_par_num
			par_mag_norm = parNames{mag_norm_val_idx(mn)};
			if ~isempty(norm_slope_val_idx)
				par_slope_norm = numel(norm_slope_val_idx);
				for sn = 1:par_slope_norm
					par_slope_norm = parNames{norm_slope_val_idx(sn)};

					[scatter_data.([par_mag_norm, '_vs_' par_slope_norm])] = plot_event_info_scatter(event_info_struct,...
						par_mag_norm, par_slope_norm,'FontSize', FontSize,'FontWeight',FontWeight,...
						'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
				end
			end
		end
	end

	% baseDiff vs mag
	if ~isempty(baseDiff_idx)
		baseDiff_num = numel(baseDiff_idx);
		for bn = 1:baseDiff_num
			par_baseDiff = parNames{baseDiff_idx(bn)};
			mag_par_num = numel(mag_val_idx);
			for mn = 1:mag_par_num
				par_mag = parNames{mag_val_idx(mn)};
				[scatter_data.([par_baseDiff, '_vs_' par_mag])] = plot_event_info_scatter(event_info_struct,...
					par_baseDiff, par_mag,'FontSize', FontSize,'FontWeight',FontWeight,...
					'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
			end
		end
	end

	% baseDiff vs riseDuration
	if ~isempty(baseDiff_idx)
		baseDiff_num = numel(baseDiff_idx);
		for bn = 1:baseDiff_num
			par_baseDiff = parNames{baseDiff_idx(bn)};
			duration_par_num = numel(duration_val_idx);
			for dn = 1:duration_par_num
				par_duration = parNames{duration_val_idx(dn)};
				[scatter_data.([par_baseDiff, '_vs_' par_duration])] = plot_event_info_scatter(event_info_struct,...
					par_baseDiff, par_duration,'FontSize', FontSize,'FontWeight',FontWeight,...
					'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
			end
		end
	end

	% baseDiffRise vs mag
	if ~isempty(baseDiffRise_idx)
		baseDiffRise_num = numel(baseDiffRise_idx);
		for bn = 1:baseDiffRise_num
			par_baseDiffRise = parNames{baseDiffRise_idx(bn)};
			mag_par_num = numel(mag_val_idx);
			for mn = 1:mag_par_num
				par_mag = parNames{mag_val_idx(mn)};
				[scatter_data.([par_baseDiffRise, '_vs_' par_mag])] = plot_event_info_scatter(event_info_struct,...
					par_baseDiffRise, par_mag,'FontSize', FontSize,'FontWeight',FontWeight,...
					'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
			end
		end
	end

	% rise_delay vs amplitude
	if ~isempty(riseDelay_idx)
		% riseDelay_num = numel(riseDelay_idx);
		par_riseDelay = parNames{riseDelay_idx};

		if ~isempty(duration_val_idx)
			duration_val_num = numel(duration_val_idx);
			% par_mag_norm = numel(norm_slope_val_idx);
			for dvn = 1:duration_val_num
				par_duration_val = parNames{duration_val_idx(dvn)};

				[scatter_data.([par_riseDelay, '_vs_' par_duration_val])] = plot_event_info_scatter(event_info_struct,...
					par_riseDelay, par_duration_val,'FontSize', FontSize,'FontWeight',FontWeight,...
					'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
			end
		end

		if ~isempty(mag_val_idx)
			mag_val_num = numel(mag_val_idx);
			% par_mag_norm = numel(norm_slope_val_idx);
			for mvn = 1:mag_val_num
				par_mag_val = parNames{mag_val_idx(mvn)};

				[scatter_data.([par_riseDelay, '_vs_' par_mag_val])] = plot_event_info_scatter(event_info_struct,...
					par_riseDelay, par_mag_val,'FontSize', FontSize,'FontWeight',FontWeight,...
					'save_fig', save_fig, 'save_dir', save_dir,'fname_suffix',fname_suffix);
			end
		end
	end

	%% plot data and stat
	if exist('hist_data', 'var')
		plot_info.hist_data = hist_data;
		plot_info.hist_setting = hist_setting;
		plot_info.histFit_info = histFit_info;
	end
	if exist('bar_data', 'var')
		plot_info.bar_data = bar_data;
		plot_info.bar_stat= bar_stat;
	end
	if exist('box_stat', 'var')
		plot_info.box_stat= box_stat;
	end
	if exist('scatter_data', 'var')
		plot_info.scatter_data = scatter_data;
	end

	varargout{2} = plot_info;
end
