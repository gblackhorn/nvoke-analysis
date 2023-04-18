function [varargout] = violinplot_CellArray(CellArrayData,groupNames,varargin)
	% use the function violinplot to plot data stored in cell array


	% Defaults
	% plotWhere = gca;
	FontSize = 14; % Set a normalized font size value
	FontWeight = 'bold';

	% Optionals
	for ii = 1:2:(nargin-2)
	    % if strcmpi('plotWhere', varargin{ii})
	    %     plotWhere = varargin{ii+1};
	    if strcmpi('FontSize', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        FontSize = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    elseif strcmpi('FontWeight', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        FontWeight = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    % elseif strcmpi('guiSave', varargin{ii})
        %     guiSave = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end

	% prepare data and the categories. 
	% violinData is a double vector. violinDataCategories is a cell array having the same size as violinData
	[violinData,violinDataCategories] = createDataAndGroupNameArray(event_info_cell,groupNames);

	% Plot violin
	violinplot(violinData,violinDataCategories);
	set(gca, 'box', 'off');
	set(gca,'TickDir','out');
	set(gca, 'FontSize', FontSize);
	set(gca, 'FontWeight', FontWeight);
	xtickangle(TickAngle);
	title(replace(par, '_', '-'));
end