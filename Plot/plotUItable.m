function [varargout] = plotUItable(plotWhereFig,plotWhereAxes,tableData,varargin)
	% Plot a table on an axes

	fontSize = 12;


	uit_pos = get(plotWhereAxes,'Position');
	uit_unit = get(plotWhereAxes,'Units');
	% delete(axStat);
	% MultCom_stat = barStat(stn).anovaCombineBase.c(:,["g1","g2","p","h"]);

	if ~isempty(tableData.Properties.RowNames)
		uit = uitable(plotWhereFig,'Data',table2cell(tableData),...
			'ColumnName',tableData.Properties.VariableNames,...
			'RowName',tableData.Properties.RowNames,...
			'Units',uit_unit,'Position',uit_pos);
	else
		uit = uitable(plotWhereFig,'Data',table2cell(tableData),...
		'ColumnName',tableData.Properties.VariableNames,...
		'Units',uit_unit,'Position',uit_pos);
	end


	uit.FontSize = fontSize;

	% Get the handle to the current axes
	ax = gca;

	% Hide all the ticks and labels
	ax.XTick = [];
	ax.YTick = [];
	ax.XTickLabel = '';
	ax.YTickLabel = '';

	% Hide the frame
	% uit.BorderType = 'none';
	% uit.CellEditCallback = @noEdit;

	% Remove x-labels and y-labels (column and row headers)
	% uit.ColumnName = {};
	% uit.RowName = {};
	% title(replace(par, '_', '-'));
	% delete(axStat);

	jScroll = findjobj(uit);
	jTable  = jScroll.getViewport.getView;
	jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
	drawnow;
end

