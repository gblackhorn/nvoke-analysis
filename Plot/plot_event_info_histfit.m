function [histFit_info,varargout] = plot_event_info_histfit(event_info_struct,par_name,varargin)
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
	nbins = [];
	% plot_combined_data = false;
	save_fig = false;
	save_dir = '';
	fname_suffix = '';

	sp_colNum = 3; % subplot column number
	FontSize = 18;
	show_legend = false;
	dist_type = 'normal'; % 'beta', 'gamma'. read description about func histfit.

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('nbins', varargin{ii})
	        nbins = varargin{ii+1};
	    elseif strcmpi('dist_type', varargin{ii})
	        dist_type = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    elseif strcmpi('fname_suffix', varargin{ii})
	        fname_suffix = varargin{ii+1};
	    elseif strcmpi('xRange', varargin{ii})
	        xRange = varargin{ii+1}; % a 2-element vector to set the xlim of plot
	    end
	end

	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end

	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);
	histFit_info = struct('group', struct_length_size,'data',struct_length_size,'pd',struct_length_size);

	% all data
	data_cell = cell(1, group_num);
	for n = 1:group_num
		data_cell{n} = [event_info_struct(n).event_info.(par_name)];
	end
	data_all = [data_cell{:}];
	histFit_info(1).group = 'all';
	histFit_info(1).data = data_all(:);

	if histFit_info(1).data>1 % fitdist only works when data number is bigger than 1
		histFit_info(1).pd = fitdist(histFit_info(1).data,'Normal');


		% Plot
		% legendstr ={event_info_struct.group}';

		% title_str = ['HistFit: ', par_name]; 
		title_str = sprintf('HistFit-%s-%s', par_name,fname_suffix); 
		title_str = replace(title_str, '_', '-');
		figure('Name', title_str);
	    set(gcf,'units','Normalized','position',[0.1, 0.1, 0.8, 0.8])

		% if group_num == 1
		% 	plot_combined_data = true;
		% end

		%% ====================
		% subplot
		sp_rowNum = ceil((group_num+1)/sp_colNum);
		subplot(sp_rowNum, sp_colNum, 1)

		if ~isempty(nbins)
			histfit(histFit_info(1).data,nbins);
		else
			histfit(histFit_info(1).data);
		end
		
		legend(histFit_info(1).group)
		if exist('xRange','var')
			xlim([xRange])
		end
		set(gca,'box','off')
		set(gca, 'FontSize', FontSize)
		xRange = xlim(gca);
		yRange = ylim(gca);

		if group_num > 1
			for n = 1:group_num
				group_data = data_cell{n};
				histFit_info(n+1).group = event_info_struct(n).group;
				if ~isempty(group_data(:)) && numel(group_data(:))>1
					histFit_info(n+1).data = group_data(:);
					histFit_info(n+1).pd = fitdist(histFit_info(n+1).data,dist_type);

		            subplot(sp_rowNum, sp_colNum, n+1)	
		            histfit(histFit_info(n+1).data,nbins,dist_type);		
		   %          if ~isempty(nbins)
					% 	histfit(histFit_info(n+1).data,nbins,dist_type);
					% else
					% 	histfit(histFit_info(n+1).data);
					% end

					% [histFit_info(n+1).N, histFit_info(n+1).edges] = histcounts(group_data, edges);

					% if plot_combined_data
					% 	histogram('BinEdges',histFit_info(1).edges,'BinCounts',histFit_info(1).N,...
					% 		'Normalization', 'probability', 'FaceAlpha',0.1);
					% 	hold on
					% end

					% h(n+1) = histogram('BinEdges',histFit_info(n+1).edges,'BinCounts',histFit_info(n+1).N);
					% h(n+1).Normalization = 'probability';
					
					if show_legend
						legend(histFit_info(n+1).group)
						legend('boxoff')
					end
					title(histFit_info(n+1).group)
					xlim(xRange)
					% ylim(yRange)
					set(gca,'box','off')
					set(gca, 'FontSize', FontSize)
				end
			end
		end

		if save_fig
			title_str = replace(title_str, ':', '-');
			fig_path = fullfile(save_dir, title_str);
			savefig(gcf, [fig_path, '.fig']);
			saveas(gcf, [fig_path, '.jpg']);
			saveas(gcf, [fig_path, '.svg']);
		end

		% setting.BinWidth = BinWidth;
		% setting.nbins = nbins;
		% varargout{1} = setting;
	end
end