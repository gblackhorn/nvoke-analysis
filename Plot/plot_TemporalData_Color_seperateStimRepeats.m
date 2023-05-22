function [f,varargout] = plot_TemporalData_Color_seperateStimRepeats(plotWhere,fluroData,timeData,stimInfo,varargin)
	% Plot a color plot. Every ROI trace is cut to several sections using stimulation repeat. One
	% row contains the start of stim to the start of the next stim. Each ROI contains the stim
	% repeat number of rows

	% Use function [get_TrialTraces_from_alignedData] to get the timeData and fluroData from alignedData
		% [timeData,fluroData] = get_TrialTraces_from_alignedData(alignedData_trials,...
		% 'norm_FluorData',norm_FluorData); 


	% Defaults
	preTime = 0; % include time before stimulation starts for plotting
	postTime = []; % include time after stimulation ends for plotting. []: until the next stimulation starts
	eventsTime = -1; % -1: do not filter stimRanges with eventsTime. Use all of them

	shadeData = {};
	shadeColor = {'#F05BBD','#4DBEEE','#ED8564'};
    colorLUT = 'turbo'; % default look up table (LUT)/colormap. Other sets are: 'parula','hot','jet', etc.
    show_colorbar = true; % true/false. Show color next to the plot if true.
    xtickInt = 1; % interval between x ticks

	% Optionals
	for ii = 1:2:(nargin-4)
        if strcmpi('rowNames', varargin{ii})
            rowNames = varargin{ii+1}; % cell array containing strings used to label y_ticks
        elseif strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1}; 
        elseif strcmpi('postTime', varargin{ii})
            postTime = varargin{ii+1}; 
        elseif strcmpi('eventsTime', varargin{ii})
            eventsTime = varargin{ii+1}; 
        % elseif strcmpi('x_window', varargin{ii})
        %     x_window = varargin{ii+1}; % [a b] numerical array. Used to display time
        elseif strcmpi('xtickInt', varargin{ii})
            xtickInt = varargin{ii+1}; % a single number to set the interval between x ticks
        elseif strcmpi('colorLUT', varargin{ii})
            colorLUT = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        end
	end	


	% Create rowNames if it doesn't exist 
    if exist('rowNames')==0 || isempty(rowNames)
        rowNames = NumArray2StringCell(size(fluroData,2));
    end

    % Get necessary information from stimInfo 
    stimRanges = stimInfo.UnifiedStimDuration.range;


    % Get the time range for plotting
    stimPlusRange = NaN(size(stimRanges));
    stimPlusRange(:,1) = stimRanges(:,1)-preTime;
    if ~isempty(postTime)
    	stimPlusRange(:,2) = stimRanges(:,2)+postTime;
    end

    % Filter stimRanges with events
    if exist(eventsTime,'var') && eventsTime ~= 1
    	[stimPlusRange,posRangeIDX] = getRangeIDXwithEvents(eventsTime,stimPlusRange);
    end


    if ~isempty(stimPlusRange)
	    % Get the closest recording time for stimulation repeats
	    stimNum = size(stimRanges,1);
	    stimPlusRangeIDX = NaN(size(stimRanges));
	    [stimPlusRange(:,1),stimPlusRangeIDX(:,1)] = find_closest_in_array(stimPlusRange(:,1),timeData);
	    if ~isempty(postTime)
		    [stimPlusRange(:,2),stimPlusRangeIDX(:,2)] = find_closest_in_array(stimPlusRange(:,2),timeData);
		end


	    % Get the number of data points for the first stim start to the second stim start. And use this
	    % number for all the following stimulations
	    plotRangeIDX = NaN(size(stimRanges));
	    plotRangeIDX(1,1) = stimPlusRange(1,1); % start from the 1st stimulation 
	    if isempty(postTime)
	    	plotRangeIDX(1,2) = stimPlusRange(2,1)-1; % end just before the 2nd stimulation
	    else
	    	plotRangeIDX(1,2) = stimPlusRange(1,2);
	    end
	    datapointNum = plotRangeIDX(1,2)-plotRangeIDX(1,1)+1;
	    timeRange = timeData(plotRangeIDX(1,2))-timeData(plotRangeIDX(1,1));
	    for sn = 2:stimNum
	    	plotRangeIDX(sn,1) = stimPlusRangeIDX(sn,1);
	    	plotRangeIDX(sn,2) = stimPlusRangeIDX(sn,1)+datapointNum-1;
	    end


	    % Create a new fluroData called fdSection contains roiNum * stimNum of traces for plotting
	    roiNum = size(fluroData,2);
	    fdSection = NaN(roiNum*stimNum,datapointNum);
	    rowNamesSection = cell(roiNum*stimNum,1);
	    for rn = 1:roiNum
	    	for sn = 1:stimNum
	    		rowIDX = (rn-1)*stimNum+sn;
	    		rowNamesSection{rowIDX} = sprintf('%s-s%g',rowNames{rn},sn);
	    		sTrace = fluroData((plotRangeIDX(sn,1):plotRangeIDX(sn,2)),rn); % Get a section trace from one ROI from fluroData
	    		sTraceRow = reshape(sTrace,[1,numel(sTrace)]); % ensure that sTraceRow is a row vector
	    		fdSection(rowIDX,:) = sTraceRow;
	    	end
	    end

	    % plot the heatmap using function [plot_TemporalData_Color]
	    % Creat a figure to plot raster (first ax) and histogram (second ax)
	    f = fig_canvas(2,'unit_width',0.4,'unit_height',0.4,'column_lim',1,...
	    	'fig_name',titleStr); % create a figure
	    tlo = tiledlayout(f, 11, 1); % setup tiles
	    ax = nexttile(tlo,[10 1]); % activate the ax for color plot
	    plot_TemporalData_Color(gca,fdSection,...
				'rowNames',rowNamesSection,'x_window',[0 timeRange],'xtickInt',xtickInt,...
				'show_colorbar',show_colorbar);
	    xlabel('time (s)')

	    	% add a shade plot to display the stimulation range
	    ax = nexttile(tlo);
	    xlim([0 timeRange]);
	    ylim([0 1]);
	    if ~isempty(stimInfo)
		    stimTypeNum = numel(stimInfo.StimDuration);
		    shadeDataAligned = cell(stimTypeNum,1);
		    shadeNames = cell(stimTypeNum,1);
		    for  stn= 1:stimTypeNum
			    shadeDataAligned{stn} = stimInfo.StimDuration(stn).patch_coor(1:4,1:2); % Get the first 4 rows for the first repeat of stimulation
			    shadeDataAligned{stn}(1:2,1) = stimInfo.StimDuration(stn).range_aligned(1); % Replace the first 2 x values (stimu gpio rising) with the 1st element from range_aligned
			   	shadeDataAligned{stn}(3:4,1) = stimInfo.StimDuration(stn).range_aligned(2); % Replace the last 2 x values (stimu gpio falling) with the 2nd element from range_aligned
			   	shadeNames{stn} = stimInfo.StimDuration(stn).type;

			   	draw_WindowShade(gca,shadeDataAligned{stn},'shadeColor',shadeColor{stn});
			end
	        legend(shadeNames,'Location', 'Best') % 'northeastoutside'
	        set(gca,'XTickLabel',[]); % remove the x-axis labels
	        set(gca,'YTickLabel',[]); % remove the y-axis labels
	        box off; % remove the box around the plot
	        title('stimulation(s)')
	    end




	    sgtitle(titleStr)

	    varargout{1} = fdSection; % fluorescence data
	    varargout{2} = rowNamesSection; % names for each row of fluorescence data
	    varargout{3} = [0 timeRange]; % xdata
	else
		varargout{1} = []; % fluorescence data
		varargout{2} = []; % names for each row of fluorescence data
		varargout{3} = []; % xdata
	end
end

