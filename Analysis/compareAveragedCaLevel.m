function [varargout] = compareAveragedCaLevel(alignedData,groupA,groupB,binWidth,varargin)
	% Collect the calcium level from recordings applied with 'stimName' and plot the averaged trace

	% groupA/groupB: Struct vars containing fields 'stimName' and 'subNucleiType'


	% Defaults
	plotUnitWidth = 0.3;
	plotUnitHeight = 0.1;
	columnLim = 3;
	yRangeMargin = 0.5;

	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);
	addRequired(p, 'groupA', @isstruct);
	addRequired(p, 'groupB', @isstruct);
	addRequired(p, 'binWidth', @isnumeric);

	% Add optional parameters to the input p
	addParameter(p, 'plotCombinedData', true, @islogical);
	addParameter(p, 'plotRawTraces', false, @islogical); % 'pre'/'post'. The location of relevent event. Pre or post to the ref event
	addParameter(p, 'shadeType', 'ste', @ischar); 
	addParameter(p, 'tickInt_time', 1, @isnumeric);
	addParameter(p, 'titlePrefix', '', @ischar);
	addParameter(p, 'debugMode', false, @islogical);

	% Parse inputs
	parse(p, alignedData, groupA, groupB, binWidth, varargin{:});

	% Retrieve parsed values
	plotCombinedData = p.Results.plotCombinedData;
	plotRawTraces = p.Results.plotRawTraces;
	shadeType = p.Results.shadeType;
	tickInt_time = p.Results.tickInt_time;
	titlePrefix = p.Results.titlePrefix;
	debugMode = p.Results.debugMode;


	% Get the data using the settings in groupA and groupB
	[CaLevelDataA,CaLevelDataNnumA,binX,binDataCellA] = getAveragedCaLevel(alignedData,...
		groupA.stimName,groupA.subNucleiType,binWidth);
	[CaLevelDataB,CaLevelDataNnumB,binX,binDataCellB] = getAveragedCaLevel(alignedData,...
		groupB.stimName,groupB.subNucleiType,binWidth);


	% Create a figure with tiles
	groupAstr = sprintf('%s [%s]', groupA.stimName, groupA.subNucleiType);
	groupBstr = sprintf('%s [%s]', groupB.stimName, groupB.subNucleiType);
	titleStr = sprintf('%s %s vs %s', titlePrefix, groupAstr, groupBstr);
	[f, fRowNum, fColNum] = fig_canvas(2, 'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'row_lim',2,'column_lim',1,'fig_name',titleStr);
	tlo = tiledlayout(f,fRowNum,fColNum);


	% Combine all the data to extract max and min value for setting the yRange
	CaLevelDataAverageCombine = [mean(CaLevelDataA.data,2); mean(CaLevelDataB.data,2)];
	yMax = max(CaLevelDataAverageCombine);
	yMin = min(CaLevelDataAverageCombine);
	yDiff = yMax - yMin;
	yRange = [yMin - yDiff * yRangeMargin, yMax + yDiff * yRangeMargin];

	% Plot the traces
	axTrace = nexttile(1);
	[~, ~] = plotAlignedTracesAverage(axTrace, CaLevelDataA.data, CaLevelDataA.time,...
		'shadeType', shadeType, 'plot_combined_data', plotCombinedData,'plot_raw_traces', plotRawTraces,...
		'y_range', yRange, 'tickInt_time', tickInt_time);
	hold on
	[~, ~] = plotAlignedTracesAverage(axTrace, CaLevelDataB.data, CaLevelDataB.time,...
		'shadeType', shadeType, 'plot_combined_data', plotCombinedData,'plot_raw_traces', plotRawTraces,...
		'y_range', yRange, 'tickInt_time', tickInt_time);
	legend(groupAstr, '', groupBstr, '');

	title(titleStr)

	% % 






	% [~,CaLevel_box_statInfo] = boxPlot_with_scatter(binDataCell,'groupNames',NumArray2StringCell(xData),...
	% 	'stat',true,'plotScatter',false);
	% titleStr = sprintf('%s CaLevel box', subNucleiTypes{sn});
	% title(titleStr)
	% ylim([-4 4]);

end

%% ==========
% Subfunctions
function [CaLevelData,CaLevelDataNnum,binX,binDataCell,varargout] = getAveragedCaLevel(alignedData,stimName,subNuclei,binWidth)
    % Screen neurons using subNuclei tags if 'subNucleiTypes' is not empty
    if ~isempty(subNuclei)
    	alignedData = screenSubNucleiROIs(alignedData,subNuclei);
    end

    % Filter recordings using 'stimName'
    stimNameAll = {alignedData.stim_name};
    stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
    alignedDataStim = alignedData(stimPosIDX);

    % Get the calcium level trace and time data. 
    % CaLevelData fields: data, time
    % CaLevelData_n_num: trial_list, trial_num, roi_num, stim_num
    [CaLevelData,CaLevelDataNnum] = GetCalLevelInfoFromAlignedData(alignedDataStim,stimName);

    % Calculte the smapling freq
    freq = get_frame_rate(CaLevelData.time);
    binDataPointNum = binWidth*freq; % Data point number in a singla box 

    % Calculate the number of boxes using the time duration and binWidth
    binNum = floor(max(CaLevelData.time)-min(CaLevelData.time))/binWidth;

    % Calculate the middle location for every bin
    binX = [CaLevelData.time(1):binWidth:(CaLevelData.time(1)+binWidth*(binNum-1))]+binWidth/2; % the x-axis location of data in the plot 

    % Pre-allocate RAM
    binDataCell = cell(binNum,1);
    % data_groupName = cell(binNum,1);

    % Loop through the bins and collect calcium level data 
    for bn = 1:binNum
    	startLoc = (bn-1)*binDataPointNum+1;
    	endLoc = bn*binDataPointNum;
    	binData = mean(CaLevelData.data(startLoc:endLoc,:));
    	binDataCell{bn} = binData(:);
    end

    varargout{1} = binNum;
end
