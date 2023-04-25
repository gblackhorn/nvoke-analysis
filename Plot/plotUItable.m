function [varargout] = plotUItable(plotWhereFig,plotWhereAxes,tableData,varargin)
	% Plot a table on an axes

	uit_pos = get(plotWhereAxes,'Position');
	uit_unit = get(plotWhereAxes,'Units');
	% delete(axStat);
	% MultCom_stat = barStat(stn).anovaCombineBase.c(:,["g1","g2","p","h"]);
	uit = uitable(plotWhereFig,'Data',table2cell(tableData),...
		'ColumnName',tableData.Properties.VariableNames,...
		'Units',uit_unit,'Position',uit_pos);
	% title(replace(par, '_', '-'));
	% delete(axStat);

	jScroll = findjobj(uit);
	jTable  = jScroll.getViewport.getView;
	jTable.setAutoResizeMode(jTable.AUTO_RESIZE_SUBSEQUENT_COLUMNS);
	drawnow;
end

