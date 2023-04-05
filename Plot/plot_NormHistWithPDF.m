function [histHandle,varargout] = plot_NormHistWithPDF(vectorData,binsOrEdges,varargin)
	%Plot histogram and its probability density functions (PDF)  



	% Defaults
	xlabelStr = '';
	ylabelStr = 'Probability Density';
	titleStr = 'Hist with PDF';

	fontSize_tick = 12;
	fontSize_label = 14;
	fontSize_title = 16;

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('plotWhere', varargin{ii}) 
	        plotWhere = varargin{ii+1}; 
	    elseif strcmpi('xlabelStr', varargin{ii})
            xlabelStr = varargin{ii+1};
	    elseif strcmpi('ylabelStr', varargin{ii})
            ylabelStr = varargin{ii+1};
	    elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1};
	    end
	end

	% if plotWhere is not specified, plot to the current axes
	if ~exist('plotWhere','var')
		plotWhere = gca;
	end


	% Plot histogram normalized to probability density functions (PDF)   
	histHandle = histogram(plotWhere,vectorData,binsOrEdges,'Normalization','pdf');
	hold on


	% calculate the PDF
	[f, x] = ksdensity(vectorData);
    plot(x,f);
    hold off


    % Change settings for the plot
    if numel(binsOrEdges) == 1
	    xLimits = [floor(min(vectorData)), ceil(max(vectorData))];
	elseif numel(binsOrEdges) > 1
		xLimits = [binsOrEdges(1), binsOrEdges(end)];
	end
    xlim(xLimits)
    box('off')
    set(gca, 'FontSize', fontSize_tick);
    set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'



    % Add labels and title
    xlabel(xlabelStr,'FontSize', fontSize_label);
    ylabel(ylabelStr,'FontSize', fontSize_label);
    title(titleStr,'FontSize', fontSize_title);
end