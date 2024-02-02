function [figHandle,varargout] = PlotCrossCorrResult(crossCorrResult,varargin)
	% Plot the crossCorrResult output by function 'roiCorrTrace'
	% Cross-correlation for each ROI pair will be shown in a subplot
	% All the subplots will be arranged in the upper triangle

	% crossCorrResult: Cell var. Each cell contains the cross-correlation info of a ROI pair

	% Example:
	%		

	% Defaults
	recName = 'recording xxx';

	fontSize = 6;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('recName', varargin{ii}) 
	        recName = varargin{ii+1}; 
	    end
	end

	% Get the number of ROIs
	roiNum = size(crossCorrResult,1); % the cell row number = column number = roi number

	% Create a name for the figure
	figName = sprintf('Cross-Correlation of recording %s',recName);

	% Create a figure with customized size
	f = fig_canvas(1,'unit_width',0.9,'unit_height',0.9,'fig_name',figName);
	fTile = tiledlayout(f,roiNum-1,roiNum-1); % create tiles 
	% t.TileSpacing = 'compact';
	% t.Padding = 'compact';

	% plotNum = 0;
	for i = 1:roiNum
	    for j = i+1:roiNum
	    	% % Calculte the index of the current subplot
	    	% pairIDX = ((i - 1) * (roiNum - i/2)) + (j - i);

	    	% Calculate the subplot location
	    	plotPos = (i-1)*(roiNum-1)+j-1;

	    	% Create a subplot for the cross-correlation of a pair of ROIs
	    	% subplot(roiNum, roiNum, pairIDX);
	    	nexttile(plotPos)
	    	plot(crossCorrResult{i, j}.lags, crossCorrResult{i, j}.correlation);
	    	% title(sprintf('%s vs %s',crossCorrResult{i,j}.roiA,crossCorrResult{i,j}.roiB));

	    	% Customizing axes properties
	    	ax = gca; % Current axes
	    	ax.FontSize = fontSize; % Font size of tick labels
	    	ax.Box = 'off'; % Enclose the plot in a box
	    	% ax.LineWidth = 1.5; % Thicker axes lines
	    	ax.TickDir = 'out'; % Make ticks face outward
	    	ax.XColor = [0.3 0.3 0.3]; % Greyish black for X axis
	    	ax.YColor = [0.3 0.3 0.3]; % Greyish black for Y axis


	    	% Add x and y label to the first subplot
	    	if i == 1 && j == 2
	    		xlabel('Lags');
	    		ylabel('Cross-Correlation');
	    	end


	        % if j > i
	        %     plotNum = plotNum + 1;
	        %     subplot(roiNum, roiNum, (i - 1) * roiNum + j);
	        %     % Compute cross-correlation (example: using xcorr with 'coeff')
	        %     [cc, lags] = xcorr(calciumData(:, i), calciumData(:, j), 'coeff');
	        %     % Plot cross-correlation
	        %     plot(lags, cc);
	        %     title(['Cells ' num2str(i) ' & ' num2str(j)]);
	        % end
	    end
	end

	% Add a title to the figure
	sgtilte(figHandle);
end