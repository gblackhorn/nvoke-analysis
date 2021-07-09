function [hist_info,varargout] = plot_trace(time_info,trace_data,varargin)
	% Plot traces 
	% Input: 
	%	- structure array(s) with field "group" and "event_info"  
	%	- "par_name" is one of the fieldnames of "event_info" 
	%		- freq
	%		- events_interval_time_mean
	%		- peak_slope
	%		- peak_mag_norm
	%		- peak_mag_norm_mean
	%		- traces: a structure including "time" and value
	% Output:
	%	- histogram info including counts in each bins and the bin edges
	%	- event histogram
	%	- histogram bin width, nbins

	% Defaults
	plot_combined_data = true; % mean trace for each single group. std value as shade
	save_fig = false;
	save_dir = '';
	mean_trace = [];
	mean_trace_shade = [];

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('plot_combined_data', varargin{ii})
	        plot_combined_data = varargin{ii+1};
	    elseif strcmpi('mean_trace', varargin{ii})
	        mean_trace = varargin{ii+1};
	    elseif strcmpi('mean_trace_shade', varargin{ii})
	        mean_trace_shade = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
	        save_fig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
	        save_dir = varargin{ii+1};
	    end
	end

	if save_fig && isempty(save_dir)
		save_dir = uigetdir;
	end

	f = figure;
	hold on
	if isa(trace_data, 'double')
		h = plot(time_info, trace_data);
	elseif isa(trace_data, 'cell')
		group_num = numel(trace_data);
		for n = 1:group_num
			h(n) = plot(time_info, trace_data{n});
		end
	end

	if plot_combined_data
		h_m = plot(time_info, mean_trace);


		shade_x = [time_info; flip(time_info)];

		shade_upperline = mean_trace+mean_trace_shade;
		shade_lowerline = mean_trace-mean_trace_shade;
		shade_y = [shade_upperline; flip(shade_lowerline)];
		h_s = patch(shade_x, shade_y);
	end


end