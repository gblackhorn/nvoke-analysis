function [varargout] = plotEventPropMultiGroups(groupedEventProp,props,organizeStruct,varargin)
	% Plot the event properties for multiple pairs of groups

	% groupedEventProp: Struct var output by getAndGroup_eventsProp
	% props: Cell var. Names of event properties. They are the field names of groupedEventProp(n).event_info

	% organizeStruct: Struct var containing fields {'title', 'keepGroups', 'mmFixCat'}. Function
	% 	uses the content in each entry to generate plots for event propterties.
	%	- 'title': Char var. Used for figure and file names
	%	- 'keepGroups': Cell var. If groupedEventProp(n).group contains any of the chars in keepGroups,  
	%		the nth entry will be kept. GLMM analysis is suitable for 2 groups. Try to keep only two entries
	%	- 'mmFixCat': Char var. Category used by GLMM for fixEffect in the model

	% Defaults
	plot_combined_data = false;
	stat = true;
	defaultColorGroup = {'#3FF5E6', '#F55E58', '#F5A427', '#4CA9F5', '#33F577',...
	    '#408F87', '#8F4F7A', '#798F7D', '#8F7832', '#28398F', '#000000'};


	% Input parser
	p = inputParser;

	% Required input
	addRequired(p, 'groupedEventProp', @isstruct);
	addRequired(p, 'props', @iscell); 
	addRequired(p, 'organizeStruct', @isstruct); 

	% Optional parameters with default values
	addParameter(p, 'entryType', 'event', @ischar); % 'event'/'roi'. The type of entries in groupedEventProp(n).event_info
	addParameter(p, 'mmModel', 'GLMM', @ischar); 
	addParameter(p, 'mmDistribution', 'gamma', @ischar); 
	addParameter(p, 'mmLink', 'log', @ischar); 
	addParameter(p, 'mmHierarchicalVars', {'trialName', 'roiName'}, @iscell);
	addParameter(p, 'saveFig', false, @islogical); 
	addParameter(p, 'saveDir', '', @ischar); 
	addParameter(p, 'debugMode', true, @islogical); 

	% Parse inputs
	parse(p, groupedEventProp, props, organizeStruct, varargin{:});

	% Assign parsed values to variables
	groupedEventProp = p.Results.groupedEventProp;
	props = p.Results.props;
	organizeStruct = p.Results.organizeStruct;
	entryType = p.Results.entryType;
	mmModel = p.Results.mmModel;
	mmDistribution = p.Results.mmDistribution;
	mmLink = p.Results.mmLink;
	mmHierarchicalVars = p.Results.mmHierarchicalVars;
	saveFig = p.Results.saveFig;
	saveDir = p.Results.saveDir;
	debugMode = p.Results.debugMode;


	% Get the entry number of 'organizeStruct'
	entryNum = numel(organizeStruct);

	% Loop through 'organizeStruct'. Use the parameters in it to plot and analyze data
	for en = 1:entryNum
		if debugMode
			fprintf('Group %d: %s\n', en, organizeStruct(en).title);
			if en == 12
				pause
			end
		end

		%
		if ~isfield(organizeStruct, 'colorGroup') || isempty(organizeStruct(en).colorGroup)
			colorGroup = defaultColorGroup;
		else
			colorGroup = organizeStruct(en).colorGroup;
		end

		% Filter the entries of 'groupedEventProp' using the information in 'organizeStruct(en).keepGroups'
		[groupedEventPropFiltered] = filter_entries_in_structure(groupedEventProp,'group',...
			'tags_keep',organizeStruct(en).keepGroups);

		organizeStruct(en).data = groupedEventPropFiltered;

		if en == 1
			GUIsave = true; % Choose locations to save figures
		else
			GUIsave = false; % Use the locations chosen before to save figures
		end

		[saveDir, propDataAndStat] = plot_event_info(groupedEventPropFiltered,'entryType',entryType,...
			'plot_combined_data', plot_combined_data, 'parNames', props, 'stat', stat,...
			'mmModel', mmModel, 'mmGroup', organizeStruct(en).mmFixCat,...
			'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
			'colorGroup', colorGroup, 'fname_preffix', organizeStruct(en).title,...
			'save_fig', saveFig, 'save_dir', saveDir, 'GUIsave', GUIsave);

		organizeStruct(en).plotInfo = propDataAndStat;

		% Create a UI table displaying the n numberss
		fNumName = [organizeStruct(en).title,' nNumInfo'];
		[fNum, tabNum] = nNumberTab(groupedEventPropFiltered, entryType, 'figName', fNumName);

		% Save data
		if saveFig
			% Save the fNum
			savePlot(fNum,'guiSave', 'off', 'save_dir', saveDir,...
				'fname', fNumName);

			% Save the fNum tab in latex format
			tabNumName = sprintf('%s nNumInfo.tex', organizeStruct(en).title);
			tableToLatex(tabNum, 'saveToFile',true,'filename',...
			    fullfile(saveDir,tabNumName), 'caption', tabNumName,...
			    'columnAdjust', 'XXXXX');

			% Save the data and statistic info
			propDataName = sprintf('%s propDataAndStat', organizeStruct(en).title);
			save(fullfile(saveDir, propDataName), 'propDataAndStat');
		end
	end

	varargout{1} = saveDir;
	varargout{2} = organizeStruct;
end

