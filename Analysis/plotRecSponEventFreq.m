function [varargout] = plotRecSponEventFreq(alignedData,varargin)
	% Plot the spon event frequencies with bar plot with scatters
	% Show the average freq in recordings with bars. Scatters represent the event freq of ROIs

	% Defaults

	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);

	% Add optional parameters to the input p
	% addParameter(p, 'subNucleiTypes', '', @ischar);
	% addParameter(p, 'plot_combined_data', 'true', @islogical);
	% addParameter(p, 'plot_raw_traces', 'false', @islogical); % 'pre'/'post'. The location of relevent event. Pre or post to the ref event
	% addParameter(p, 'shadeType', 'ste', @ischar); 
	% addParameter(p, 'tickInt_time', 1, @isnumeric);
	% addParameter(p, 'titlePrefix', '', @ischar);
	addParameter(p, 'debugMode', false, @islogical);

	% Parse inputs
	parse(p, alignedData, varargin{:});

	% Retrieve parsed values
	% subNucleiTypes = p.Results.subNucleiTypes;
	% plot_combined_data = p.Results.plot_combined_data;
	% plot_raw_traces = p.Results.plot_raw_traces;
	% shadeType = p.Results.shadeType;
	% tickInt_time = p.Results.tickInt_time;
	% titlePrefix = p.Results.titlePrefix;
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

	titleStr = 'Spon event freq';
	[f,f_rowNum,f_colNum] = fig_canvas(1,'unit_width',0.9,'unit_height',0.4, 'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);
	ax = nexttile(tlo);

	sponEventFreqData = barPlotOfStructData(recSponFreqStruct, 'sponfq', 'recIDX', 'plotWhere', ax,...
		'xtickLabel', uniqueRecNames, 'TickAngle', 90);

end



