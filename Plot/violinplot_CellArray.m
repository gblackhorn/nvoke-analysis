function [varargout] = violinplot_CellArray(CellArrayData,groupNames,varargin)
	% use the function violinplot to plot data stored in cell array


	% Defaults
	plotWhere = gca;
	FontSize = 14; % Set a normalized font size value

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('plotWhere', varargin{ii})
	        plotWhere = varargin{ii+1};
	    elseif strcmpi('FontSize', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        FontSize = varargin{ii+1}; % output of stim_effect_compare_trace_mean_alltrial
	    % elseif strcmpi('guiSave', varargin{ii})
        %     guiSave = varargin{ii+1};
	    % elseif strcmpi('fname', varargin{ii})
        %     fname = varargin{ii+1};
	    end
	end


	% Check if groupNames contain '_'. '_' will make convert the letter before it to subscript
	fieldNames = cellfun(@(x) strrep(x,'_',''),groupNames,'UniformOutput',false); 


	% Convert the cell array to a structure
	violinPlotData = cell2struct(CellArrayData,fieldNames,2);


	% Plot
	plotWhere;
	violinplot(violinPlotData,fieldNames,'GroupOrder',fieldNames);
	set(gca,'TickDir','out'); % Make tick direction to be out.The only other option is 'in'
	set(gca, 'box', 'off');
	set(gca, 'FontSize', FontSize) % Set the font size of the current axes
end