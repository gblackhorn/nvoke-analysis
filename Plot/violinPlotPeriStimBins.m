function ax = violinPlotPeriStimBins(barStatStruct, binNames, ax, varargin)
    % Plot specific bins of peri-stim data

    % Use the output (e.g. barStat.PO) of function 'periStimEventFreqAnalysisSubnucleiVIIO' for
    % barStatStruct

    % If barStatStruct contains multiple entries, the function will only plot the first one

    % Initialize input parser
    p = inputParser;

    % Add required inputs with validation functions
    addRequired(p, 'barStatStruct', @isstruct); % e.g. barStat.PO output by function 'periStimEventFreqAnalysisSubnucleiVIIO'
    addRequired(p, 'binNames', @iscell); % {'baseline', 'lateFirstStim1', 'lateFirstStim2', 'postFirstStim'} 
    
    % Add optional axis handle parameter
    addOptional(p, 'ax', [], @(x) isempty(x) || isa(x, 'matlab.graphics.axis.Axes'));

    % Add parameters to the parser with default values and comments
    addParameter(p, 'plotUnitWidth', 0.4, @isnumeric); % normalized size of ax
    addParameter(p, 'plotUnitHeight', 0.3, @isnumeric); % normalized size of ax
    addParameter(p, 'columnLim', 2, @isnumeric); % max number of columns in a figure
    addParameter(p, 'titleStr', 'Peri-stim eventFreq violin plot', @ischar); % max number of columns in a figure
    addParameter(p, 'titlePrefix', '', @ischar); % max number of columns in a figure

    % Parse the inputs
    parse(p, barStatStruct, binNames, ax, varargin{:});

    % Assign parsed values to variables
    barStatStruct = p.Results.barStatStruct;
    binNames = p.Results.binNames;
    ax = p.Results.ax;
    plotUnitWidth = p.Results.plotUnitWidth;
    plotUnitHeight = p.Results.plotUnitHeight;
    columnLim = p.Results.columnLim;
    titleStr = p.Results.titleStr;
    titlePrefix = p.Results.titlePrefix;

    % Validate structure fields
    if ~validateStructureFields(barStatStruct)
        error('The input structure does not contain all necessary fields: stim, data, binNames.');
    end


    % Create the plot in the specified axis or a new figure
    titleStr = sprintf('%s %s', titlePrefix, titleStr);
    if isempty(ax)
        [f,f_rowNum,f_colNum] = fig_canvas(1,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
        	'column_lim',columnLim,'fig_name',titleStr); % create a figure 
        ax = axes;
    else
    	ax;
    end
    % axNum = numel(barStatStruct);
    % titleStr = sprintf('%s %s', titlePrefix, titleStr);
    % [f,f_rowNum,f_colNum] = fig_canvas(axNum,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
    % 	'column_lim',columnLim,'fig_name',titleStr); % create a figure        
    % tlo = tiledlayout(f,f_rowNum,f_colNum);



    % Get the data and bin names from the barStatStruct
    stimName = barStatStruct(1).stim;
	FreqDataAll = barStatStruct(1).data;
	FreqBinNamesAll = barStatStruct(1).binNames;

	% Get the idx of bin names
	[binNameTF, binNameIDX] = ismember(binNames, FreqBinNamesAll);
	if any(binNameTF == 0)
		error('Some binNames not found in the data')
	end

	% Get the data using the bin IDX
	freqData = FreqDataAll(binNameIDX);

	% Create a structure used for violin plot
	disIDX = []; % Used to mark the discarded bin if there is not enough data point
	for n = 1:numel(freqData) 
		nNum = freqData(n).nNum;

		if nNum >= 3 
			violinDataStruct.(binNames{n}) = freqData(n).groupData; 
		else
			disIDX = [disIDX n];
		end
	end

	% Discard the names of bin without enough n number
	binNames(disIDX) = [];

	% Create violin plot
	if ~isempty(binNames)
		violins = violinplot(violinDataStruct, binNames, 'GroupOrder', binNames);
		titleStr = sprintf('%s %s', stimName, titleStr);
		title(titleStr)
		% xlabel(ax, 'Bin Index');
		ylabel(ax, 'eventFreq normToBase');
	end



    % % Loop through all the entries 
    % for n = 1:numel(barStatStruct)
    % 	% Get the data and bin names from the barStatStruct
    % 	FreqData = barStatStruct(n).data;
    % 	FreqBinNames = barStatStruct(n).binNames;


    % 	ax = nexttile;

    % end

end

function isValid = validateStructureFields(structVar)
    % List of required fields
    requiredFields = {'stim', 'data', 'binNames'};
    
    % Check if all required fields are present in the structure
    isValid = all(isfield(structVar, requiredFields));
end