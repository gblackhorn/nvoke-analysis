function [hist_info,varargout] = plot_event_info_hist(event_info_struct,par_name,varargin)
	% Plot histogram of specified parameter by "par_name"  
	% Input: 
	%	- structure array(s) with field "group" and "event_info"  
	%	- "par_name" is one of the fieldnames of "event_info" 
	%		- freq
	%		- events_interval_time_mean
	%		- peak_slope
	%		- peak_mag_norm
	%		- peak_mag_norm_mean
	% Output:
	%	- histogram info including counts in each bins and the bin edges
	%	- event histogram
	%	- histogram bin width, nbins

	% Defaults
	BinWidth = [];
	nbins = [];
	plot_combined_data = false;
	save_fig = false;
	save_dir = '';

	sp_colNum = 3; % subplot column number

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('BinWidth', varargin{ii})
	        BinWidth = varargin{ii+1};
	    elseif strcmpi('nbins', varargin{ii})
	        nbins = varargin{ii+1};
	    elseif strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    end
	end

	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end

	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);
	hist_info = struct('group', struct_length_size,...
		'N', struct_length_size, 'edges', struct_length_size);

	% all data
	data_cell = cell(1, group_num);
	for n = 1:group_num
		data_cell{n} = [event_info_struct(n).event_info.(par_name)];
	end
	data_all = [data_cell{:}];
	if ~isempty(nbins)
		[N, edges] = histcounts(data_all, nbins);
	else
		[N, edges] = histcounts(data_all);
	end
	hist_info(1).group = 'all';
	hist_info(1).N = N;
	hist_info(1).edges = edges;
	if isempty(BinWidth)
		BinWidth = edges(2)-edges(1);
	end



	% Plot
	% legendstr ={event_info_struct.group}';

	title_str = ['Histogram: ', par_name]; 
	title_str = replace(title_str, '_', '-');
	figure('Name', title_str);
    set(gcf,'units','Normalized','position',[0.1, 0.1, 0.8, 0.8])

	if group_num == 1
		plot_combined_data = true;
	end

	%% ====================
	% subplot
	sp_rowNum = ceil((group_num+1)/sp_colNum);
	subplot(sp_rowNum, sp_colNum, 1)
	
	h(1) = histogram('BinEdges',hist_info(1).edges,'BinCounts',hist_info(1).N);
	h(1).Normalization = 'probability';
	legend(hist_info(1).group)
	xRange = xlim(gca);
	yRange = ylim(gca);

	if group_num > 1
		for n = 1:group_num
			group_data = data_cell{n};
			hist_info(n+1).group = event_info_struct(n).group;
			[hist_info(n+1).N, hist_info(n+1).edges] = histcounts(group_data, edges);

			subplot(sp_rowNum, sp_colNum, n+1)

			if plot_combined_data
				histogram('BinEdges',hist_info(1).edges,'BinCounts',hist_info(1).N,...
					'Normalization', 'probability', 'FaceAlpha',0.1);
				hold on
			end

			h(n+1) = histogram('BinEdges',hist_info(n+1).edges,'BinCounts',hist_info(n+1).N);
			h(n+1).Normalization = 'probability';
			legend(h(n+1), hist_info(n+1).group)
			xlim(xRange)
			ylim(yRange)
		end
	end

	if save_fig
		title_str = replace(title_str, ':', '-');
		fig_path = fullfile(save_dir, title_str);
		savefig(gcf, [fig_path, '.fig']);
		saveas(gcf, [fig_path, '.jpg']);
		saveas(gcf, [fig_path, '.svg']);
	end

	setting.BinWidth = BinWidth;
	setting.nbins = nbins;
	varargout{1} = setting;
end