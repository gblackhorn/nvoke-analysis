function [varargout] = displayRecSyncPerc(plotWhere,alignedDataRec,binSize,varargin)
	% Display the synchronicity of ROIs in a recording using percentage

	% alignedDataRec: alignedData for one recording. Get this using the function 'get_event_trace_allTrials' 
	% binSize: unit: second

	% Example:
	%		

	% Defaults
	eventTimeType = 'peak_time'; % rise_time/peak_time
	patchColor = {'#F05BBD','#4DBEEE','#ED8564'};

	% dispCorr = false;
	% filters = {[nan 1 nan nan], [1 nan nan nan], [nan nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: excitatory AP during OG
		% filter number must be equal to stim_names

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('eventTimeType', varargin{ii}) 
	        eventTimeType = varargin{ii+1}; 
	    % elseif strcmpi('plotWhere', varargin{ii})
        %     plotWhere = varargin{ii+1};
	    % elseif strcmpi('dispCorr', varargin{ii})
        %     dispCorr = varargin{ii+1};
	    end
	end

	% Get the stimulation patch info for plotting the shades to indicate stimulation
	[patchCoor,stimTypes,stimTypeNum] = get_TrialStimPatchCoor_from_alignedData(alignedDataRec);
	% combinedStimRange = alignedData_trial.stimInfo.UnifiedStimDuration.range;
	stimInfo = alignedDataRec.stimInfo;

	% Get the beginning and the end time of the recording
	timeStart = alignedDataRec.fullTime(1);
	timeEnd = alignedDataRec.fullTime(2);

	% Get a vector storing the percentage of synchronicity at each time bin
	[syncPercArray,recDateTime] = syncRoiPerc(alignedDataRec,binSize,'eventTimeType',eventTimeType);
	syncPercArrayXpos = [0:length(syncPercArray)-1].*binSize+binSize/2+timeStart;

	% Display the percentage of synchronicity using bar plot

	% Create a bar graph
	hBar = bar(syncPercArrayXpos,syncPercArray, 1); % Bar width set to 1 to remove gaps

	% Set bars to a milder color, e.g., a soft blue
	hBar.FaceColor = [0.6 0.8 1]; % Soft blue color
	hBar.EdgeColor = 'none'; % Remove edges of the bars

	% Add labels and title with increased font size
	xlabel('time (s)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);
	ylabel('Percentage of synchronous ROIs', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);
	title('Percentage of synchronous ROIs', 'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);

	% Customizing axes properties
	ax = gca; % Current axes
	ax.FontSize = 10; % Font size of tick labels
	ax.Box = 'off'; % Enclose the plot in a box
	ax.LineWidth = 1.5; % Thicker axes lines
	ax.TickDir = 'out'; % Make ticks face outward
	ax.XColor = [0.3 0.3 0.3]; % Greyish black for X axis
	ax.YColor = [0.3 0.3 0.3]; % Greyish black for Y axis

	% Add grid lines for better readability
	grid on;
	ax.GridLineStyle = '--'; % Dashed grid lines
	ax.GridColor = [0.5 0.5 0.5]; % Grey for grid lines
	ax.GridAlpha = 0.7; % Transparency of grid lines


	% Display the stimulation using color shade
	if ~isempty(patchCoor)
	    patchTypeNum = numel(patchCoor);
	    for stn = 1:patchTypeNum
	        draw_WindowShade(gca,patchCoor{stn},'shadeColor',patchColor{stn});
	    end
	end
	set(gca,'children',flipud(get(gca,'children')))
end