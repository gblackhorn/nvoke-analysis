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

	stat = false; % true if want to run anova when plotting bars
	stat_fig = 'off'; % options: 'on', 'off'. display anova test figure or not

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
	    elseif strcmpi('stat', varargin{ii})
            stat = varargin{ii+1};
	    elseif strcmpi('stat_fig', varargin{ii})
            stat_fig = varargin{ii+1};
	    end
	end

	if save_fig 
		save_dir = uigetdir(save_dir,...
			'Choose a folder to save plots');
		varargout{1} = save_dir;
		if save_dir == 0
			disp('Folder for saving plots not chosen. Choose one or set "save_fig" to false')
			varargout{1} = save_dir;
			return
		end
	end

	close all

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
			par, 'plot_combined_data', plot_combined_data,...
			'save_fig', save_fig, 'save_dir', save_dir, 'nbins', 200);
	end

	%% histfit plot
	% par_num = numel(parNames);
	for pn = 1:par_num
		par = parNames{pn};

		[histFit_info.(par)] = plot_event_info_histfit(event_info_struct,par,...
			'dist_type','beta','save_fig', save_fig, 'save_dir', save_dir, 'xRange',[-0.2 2],'nbins', 10); % 'nbins', 20,
	end

	%% bar plot
	f_bar = figure('Name', 'bar plots');
	if par_num == 1
		fig_position = [0.1 0.1 0.2 0.6];
	else
		fig_position = [0.1 0.1 0.8 0.6];
	end
	set(gcf, 'Units', 'normalized', 'Position', fig_position)
	tlo = tiledlayout(f_bar, ceil(par_num/4), 4);
	for pn = 1:par_num
		ax = nexttile(tlo);
		par = parNames{pn};
		if group_num >1
			[bar_data.(par), bar_stat.(par)] = plot_event_info_bar(event_info_struct,par,...
				'plotWhere', ax, 'stat', stat, 'stat_fig', stat_fig);
			% 'save_fig', save_fig, 'save_dir', save_dir,
			% title_str = ['Bar-plot: ', par_name]; 
			% title_str = replace(title_str, '_', '-');
			title(replace(par, '_', '-'));
		end
	end
	if save_fig
		fname = 'bar_plots';
		savePlot(f_bar,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
	end

	%% box plot
	f_box = figure('Name', 'box plots');
	if par_num == 1
		fig_position = [0.1 0.1 0.2 0.6];
	else
		fig_position = [0.1 0.1 0.8 0.6];
	end 
	set(gcf, 'Units', 'normalized', 'Position', fig_position)
	tlo = tiledlayout(f_box, ceil(par_num/4), 4);
	groupNames = {event_info_struct.group};
	group_num = numel(groupNames);
	for pn = 1:par_num
		ax = nexttile(tlo);
		par = parNames{pn};
		event_info_cell = cell(1, group_num);
		for gn = 1:group_num
			event_info_cell{gn} = [event_info_struct(gn).event_info.(par)]';
		end
		[~, box_stat.(par)] = boxPlot_with_scatter(event_info_cell, 'groupNames', groupNames,...
			'plotWhere', ax, 'stat', true);
		title(replace(par, '_', '-'));
	end
	if save_fig
		fname = 'box_plots';
		savePlot(f_box,...
			'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
	end

	%% cumulative plot
	f_cd = figure('Name', 'cumulative distribution plots'); 
	if par_num == 1
		fig_position = [0.1 0.1 0.2 0.6];
	else
		fig_position = [0.1 0.1 0.8 0.6];
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
			'plotWhere', ax, 'stat', true);
		title(replace(par, '_', '-'));
	end
	if save_fig
		fname = 'cd_plots';
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
	val_rise_idx = find(contains(parNames, 'val_rise')); 
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
						par_duration, par_mag,...
						'save_fig', save_fig, 'save_dir', save_dir);
				end
			end

			if ~isempty(all_slope_val_idx)
				slope_par_num = numel(all_slope_val_idx);
				for sn = 1:slope_par_num
					par_slope = parNames{all_slope_val_idx(sn)};

					[scatter_data.([par_duration, '_vs_' par_slope])] = plot_event_info_scatter(event_info_struct,...
						par_duration, par_slope,...
						'save_fig', save_fig, 'save_dir', save_dir);
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
						par_mag, par_slope,...
						'save_fig', save_fig, 'save_dir', save_dir);
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
						par_mag_norm, par_slope_norm,...
						'save_fig', save_fig, 'save_dir', save_dir);
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
					par_baseDiff, par_mag,...
					'save_fig', save_fig, 'save_dir', save_dir);
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
					par_baseDiff, par_duration,...
					'save_fig', save_fig, 'save_dir', save_dir);
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