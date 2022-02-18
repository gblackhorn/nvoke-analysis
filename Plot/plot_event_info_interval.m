function [hist_info,varargout] = plot_event_info_interval(event_info_struct,varargin)
	% Plot event interval histogram  
	% Input: 
	%	- structure array(s) with field "group" and "event_info"  
	% Output:
	%	- histogram info inclusing counts in each bins and the bin edges
	%	- event interval histogram
	%	- histogram bin width, nbins

	% Defaults
	BinWidth = [];
	nbins = [];

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('BinWidth', varargin{ii})
	        BinWidth = varargin{ii+1};
	    elseif strcmpi('nbins', varargin{ii})
	        nbins = varargin{ii+1};
	    end
	end



	group_num = numel(event_info_struct);
	struct_length_size = cell(group_num+1, 1);
	hist_info = struct('group', struct_length_size,...
		'N', struct_length_size, 'edges', struct_length_size);

	% all data
	interval_cell = cell(1, group_num);
	for n = 1:group_num
		interval_cell{n} = [event_info_struct(n).event_info.events_interval_time_mean];
	end
	interval_all = [interval_cell{:}];
	if ~isempty(nbins)
		[N, edges] = histcounts(interval_all, nbins);
	else
		[N, edges] = histcounts(interval_all);
	end
	hist_info(1).group = 'all';
	hist_info(1).N = N;
	hist_info(1).edges = edges;
	if isempty(BinWidth)
		BinWidth = edges(2)-edges(1);
	end



	% Plot
	% legendstr ={event_info_struct.group}';

	figure('Name', 'event interval histogram');
	hold on

	h(1) = histogram('BinEdges',hist_info(1).edges,'BinCounts',hist_info(1).N);
	h(1).Normalization = 'probability';
	alpha(0.2)
	
	if group_num > 1
		for n = 1:group_num
			interval_data = interval_cell{n};
			hist_info(n+1).group = event_info_struct(n).group;
			[hist_info(n+1).N, hist_info(n+1).edges] = histcounts(interval_data, edges);

			h(n+1) = histogram('BinEdges',hist_info(n+1).edges,'BinCounts',hist_info(n+1).N);
			h(n+1).Normalization = 'probability';
			alpha(0.5)
		end
	end

	legendstr = {hist_info.group}';
	legend(h(1:group_num+1), legendstr);
	hold off


	setting.BinWidth = BinWidth;
	setting.nbins = nbins;
	varargout{1} = setting;
end