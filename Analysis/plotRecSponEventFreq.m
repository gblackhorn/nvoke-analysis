function [varargout] = plotRecSponEventFreq(alignedData,varargin)
	% Plot the spon event frequencies with bar plot with scatters
	% Show the average freq in recordings with bars. Scatters represent the event freq of ROIs

	% Defaults

	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);

	addParameter(p, 'titleSubfix', '', @ischar);
	addParameter(p, 'saveFig', false, @islogical);
	addParameter(p, 'saveDir', '', @ischar);
	addParameter(p, 'guiSave', false, @islogical);
	addParameter(p, 'debugMode', false, @islogical);

	% Parse inputs
	parse(p, alignedData, varargin{:});

	% Retrieve parsed values
	% subNucleiTypes = p.Results.subNucleiTypes;
	% plot_combined_data = p.Results.plot_combined_data;
	% plot_raw_traces = p.Results.plot_raw_traces;
	% shadeType = p.Results.shadeType;
	% tickInt_time = p.Results.tickInt_time;
	% titleSubfix = p.Results.titleSubfix;
	titleSubfix = p.Results.titleSubfix;
	saveFig = p.Results.saveFig;
	saveDir = p.Results.saveDir;
	guiSave = p.Results.guiSave;
	debugMode = p.Results.debugMode;


	% Create a cell to store the data from every recording
	recNum = numel(alignedData);
	recSponFreqCell = cell(recNum, 1);
	% sponFreqFields = {'recName', 'roiName', 'subNuclei', 'sponfq'};

	% Collect spon event freq info and store them in a struct var
	for n = 1:recNum
		% Get the recName
		recName = extractDateTimeFromFileName(alignedData(n).trialName);

		if debugMode
			fprintf('Recording %d/%d: %s\n', n, recNum, recName);
			if n == 21
				pause
			end
		end

		% Get the rec stimName
		recStim = alignedData(n).stim_name;

		% Get the ROI number and names
		roiNum = numel(alignedData(n).traces);

		if roiNum ~= 0
			% Add stimName and the subN of the first ROI to the recName
			firstRoiSubN = alignedData(n).traces(1).subNuclei;
			recName = sprintf('%s %s [%s]', recName, firstRoiSubN, recStim);
			recNameArray = repmat({recName}, roiNum, 1);
			recIDXArray = repmat({n}, roiNum, 1);

			% Store data in a struct 
			% recSponFreqCellStruct = struct('recName',recNameArray, 'roiName', {alignedData(n).traces.roi},...
			% 	'subNuclei', {alignedData(n).traces.subNuclei}, 'sponfq', {alignedData(n).traces.sponfq});
			recSponFreqCellStruct = struct('recName', recNameArray, ...
											'recIDX', recIDXArray,...
			                               'roiName', {alignedData(n).traces.roi}', ...
			                               'subNuclei', {alignedData(n).traces.subNuclei}', ...
			                               'sponfq', {alignedData(n).traces.sponfq}');


			recSponFreqCell{n} = ensureVertical(recSponFreqCellStruct);
		end
	end

	recSponFreqStruct = vertcat(recSponFreqCell{:});

	[uniqueRecNames, ~, ~] = unique({recSponFreqStruct.recName}, 'stable');

	titleStr = sprintf('Spon event freq %s', titleSubfix);
	[f,f_rowNum,f_colNum] = fig_canvas(1,'unit_width',0.9,'unit_height',0.4, 'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);
	ax = nexttile(tlo);

	sponEventFreqData = barPlotOfStructData(recSponFreqStruct, 'sponfq', 'recIDX', 'plotWhere', ax,...
		'xtickLabel', uniqueRecNames, 'TickAngle', 90);


	if saveFig
		if isempty(saveDir)
			guiSave = true;
		end
		saveDir = savePlot(f,'save_dir',saveDir,'guiSave',guiSave,'fname',titleStr);
		% save(fullfile(FolderPathVA.fig, [fname,' data']),'stimEventJitter');
	end


	varargout{1} = sponEventFreqData;
	varargout{2} = saveDir;

end



