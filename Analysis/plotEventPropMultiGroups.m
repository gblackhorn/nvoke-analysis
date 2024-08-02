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
	addParameter(p, 'debugMode', false, @islogical); 

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
			if en == 3
				pause
			end
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

		[saveDir, organizeStruct(en).plotInfo] = plot_event_info(groupedEventPropFiltered,'entryType',entryType,...
			'plot_combined_data', plot_combined_data, 'parNames', props, 'stat', stat,...
			'mmModel', mmModel, 'mmGroup', organizeStruct(en).mmFixCat,...
			'mmHierarchicalVars', mmHierarchicalVars, 'mmDistribution', mmDistribution, 'mmLink', mmLink,...
			'fname_preffix', organizeStruct(en).title,...
			'save_fig', saveFig, 'save_dir', saveDir, 'GUIsave', GUIsave);

		% Create a UI table displaying the n numberss
		fNum = nNumberTab(groupedEventPropFiltered, entryType);

		% Save data
		if saveFig
			% Save the fNum
			savePlot(fNum,'guiSave', 'off', 'save_dir', saveDir,...
				'fname', [organizeStruct(en).title,' nNumInfo']);

		end
	end

	% Save the 'organizeStruct' including the data and stat stored in the new fields
	if saveFig
		% Save the statistics info
		save(fullfile(saveDir, 'propDataAndStat'), 'organizeStruct');
	end

	varargout{1} = saveDir;
	varargout{2} = organizeStruct;
end

