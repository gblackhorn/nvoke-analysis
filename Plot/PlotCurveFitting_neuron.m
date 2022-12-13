function [f_handle,varargout] = PlotCurveFitting_neuron(CurveFitInfo,varargin)
	% Plot the data and the fitted curve in a single neuron

	% [f_handle] = PlotCurveFitting(CurveFitInfo): Plot multiple CurveFitting stored in the
	% structure variable CurveFitInfo 


	% Defaults
	xlabel_str = 'Time';
	ylabel_str = 'Response Data and Curve';
	% title_str = 'Curve Fitting';
	ax = gca;
	
	% Options
	for ii = 1:2:(nargin-3)
	    if strcmpi('xlabel_str', varargin{ii})
	        xlabel_str = varargin{ii+1};
	    elseif strcmpi('ylabel_str', varargin{ii})
	        ylabel_str = varargin{ii+1};
	    % elseif strcmpi('title_str', varargin{ii})
	    %     title_str = varargin{ii+1};
	    end
	end


	%% Plot
	plot_num = numel(CurveFitInfo);
	[f_handle] = fig_canvas(plot_num,'column_lim',4,'row_lim',2,...
			'fig_name','data and fitting');
	tlo = tiledlayout(f_handle, ceil(plot_num/4), 4);

	for pn = 1:plot_num
		f_title = sprintf('stimulation %d',CurveFitInfo(pn).SN);
		ax = nexttile(tlo);

		PlotCurveFitting(CurveFitInfo(pn).tdata,CurveFitInfo(pn).ydata,CurveFitInfo(pn).fitinfo_curvefit,...
			'xlabel_str',xlabel_str,'ylabel_str',ylabel_str,...
			'title_str',f_title,...
			'ax',ax)
	end
end