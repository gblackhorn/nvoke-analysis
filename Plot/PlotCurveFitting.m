function [ax_handle,varargout] = PlotCurveFitting(xdata,ydata,yfit,varargin)
	% Plot the data and the fitted curve

	% [ax_handle] = PlotCurveFitting(xdata,ydata,yfit,...
	%			'xlabel_str','Time','ylabel_str','Response Data and Curve',...
	%			'title_str','Curve Fitting',...
	%			'ax',ax)
	% Plot the data with 'o' using xdata and ydata. Plot the fitted curve and intervals using the function
	% in yfit. xlabel, ylabel, plot title and axes can be specified using varargin.


	% Defaults
	xlabel_str = 'Time';
	ylabel_str = 'Response Data and Curve';
	title_str = 'Curve Fitting';
	ax = gca;
	
	% Options
	for ii = 1:2:(nargin-3)
	    if strcmpi('xlabel_str', varargin{ii})
	        xlabel_str = varargin{ii+1};
	    elseif strcmpi('ylabel_str', varargin{ii})
	        ylabel_str = varargin{ii+1};
	    elseif strcmpi('title_str', varargin{ii})
	        title_str = varargin{ii+1};
	    elseif strcmpi('ax', varargin{ii})
	        ax = varargin{ii+1};
	    end
	end


	%% Plot
	plot(ax,xdata,ydata,'o')
	hold on
	plot(yfit,'predobs')
	xlabel(xlabel_str)
	ylabel(ylabel_str)
	title(title_str)
	hold off
end