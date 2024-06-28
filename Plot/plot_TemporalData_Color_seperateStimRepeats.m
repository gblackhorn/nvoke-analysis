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

	eventsTime = NaN; % -1: do not filter stimRanges with eventsTime. Use all of them
	eventsTimeSort = 'off'; % 'off'/'inROI','all'. sort traces according to eventsTime
	followEventsTime = NaN; % time of the following events
	followDelayType = 'stim'; % stim/stimEvent. Calculate the delay of the following events using the stimulation start or the stim-evoked event time
	stimRefType = 'end';

	eventCat = {}; % -1: do not filter stimRanges with eventsTime. Use all of them
	stimEventCat = '';
	followEventCat = '';

	markEvents = true; % true/false. Mark events in the heatmap if true
	shadeData = {};
	shadeColor = {'#F05BBD','#4DBEEE','#ED8564'};
    colorLUT = 'turbo'; % default look up table (LUT)/colormap. Other sets are: 'parula','hot','jet', etc.
    show_colorbar = true; % true/false. Show color next to the plot if true.
    xtickInt = 1; % interval between x ticks

    unit_width = 0.45; % normalized size of a single plot to the display
    unit_height = 0.4; % nomralized size of a single plot to the display
    column_lim = 1;

    debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-4)
        if strcmpi('rowNames', varargin{ii})
            rowNames = varargin{ii+1}; % cell array containing strings used to label y_ticks
        elseif strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1}; 
        elseif strcmpi('postTime', varargin{ii})
            postTime = varargin{ii+1}; 
        elseif strcmpi('eventCat', varargin{ii})
            eventCat = varargin{ii+1}; 
        elseif strcmpi('eventsTime', varargin{ii})
            eventsTime = varargin{ii+1}; 
        elseif strcmpi('eventsTimeSort', varargin{ii})
            eventsTimeSort = varargin{ii+1}; % 
        elseif strcmpi('followEventCat', varargin{ii})
            followEventCat = varargin{ii+1}; % 
        elseif strcmpi('stimEventCat', varargin{ii})
            stimEventCat = varargin{ii+1}; % 
        elseif strcmpi('stimRefType', varargin{ii})
            stimRefType = varargin{ii+1}; % 
        elseif strcmpi('roiNames', varargin{ii})
            roiNames = varargin{ii+1}; % 
        elseif strcmpi('followEventsTime', varargin{ii})
            followEventsTime = varargin{ii+1}; % 
        elseif strcmpi('followDelayType', varargin{ii})
            followDelayType = varargin{ii+1}; % 
        elseif strcmpi('markEvents', varargin{ii})
            markEvents = varargin{ii+1}; % a single number to set the interval between x ticks
        elseif strcmpi('xtickInt', varargin{ii})
            xtickInt = varargin{ii+1}; % a single number to set the interval between x ticks
        elseif strcmpi('colorLUT', varargin{ii})
            colorLUT = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('show_colorbar', varargin{ii})
            show_colorbar = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('titleStr', varargin{ii})
            titleStr = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1}; % look up table (LUT)/colormap: 'turbo','parula','hot','jet', etc.
        end
	end	

	% create roiNames if it's empty
	if ~exist('roiNames','var')
		roiNum = size(fluroData,2);
		roiNames = cell(roiNum,1);
		for rn = 1:roiNum
			roiNames{rn} = sprintf('roi-%g',rn);
		end
	end


	% Sort the peri-stimulation traces according to the events time
	[sortedIDX,sortedFdSection,sortedEventMarker,sortedRowNames,timeDuration,posNum,sortedEventNumIDX] = sortPeriStimTraces(fluroData,timeData,...
			eventsTime,stimInfo,'preTime',preTime,'postTime',postTime,...
			'eventCat',eventCat,'stimEventCat',stimEventCat,'followEventCat',followEventCat,...
			'stimRefType',stimRefType,'roiNames',roiNames,'debugMode',debug_mode);

    f = fig_canvas(2,'unit_width',unit_width,'unit_height',unit_height,'column_lim',1,...
	    	'fig_name',titleStr); % create a figure
	if ~isempty(sortedIDX)


	    % plot the heatmap using function [plot_TemporalData_Color]
	    % Creat a figure to plot raster (first ax) and histogram (second ax)
	    % f = fig_canvas(2,'unit_width',0.4,'unit_height',0.4,'column_lim',1,...
	    % 	'fig_name',titleStr); % create a figure
	    tlo = tiledlayout(f, 13, 1); % setup tiles
	    ax = nexttile(tlo,[12 1]); % activate the ax for color plot
	    if ~exist('posNum','var')
	    	posNum = NaN;
	    end
	    plot_TemporalData_Color(gca,sortedFdSection,...
				'rowNames',sortedRowNames,'x_window',[-preTime -preTime+timeDuration],'xtickInt',xtickInt,...
				'show_colorbar',show_colorbar,'breakerLine',posNum,'markerIDX',sortedEventMarker,...
				'colorLUT',colorLUT);
	    % plot_TemporalData_Color(gca,fdSection,...
		% 		'rowNames',rowNamesSection,'x_window',[-preTime -preTime+timeRange],'xtickInt',xtickInt,...
		% 		'show_colorbar',show_colorbar,'breakerLine',posNum,'markerIDX',markerIDX);
	    xlabel('time (s)')

	    	% add a shade plot to display the stimulation range
	    ax = nexttile(tlo);
	    xlim([-preTime -preTime+timeDuration]);
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

	    varargout{1} = sortedFdSection; % fluorescence data
	    varargout{2} = sortedRowNames; % names for each row of fluorescence data
	    varargout{3} = [0 timeDuration]; % xdata
	else
		varargout{1} = []; % fluorescence data
		varargout{2} = []; % names for each row of fluorescence data
		varargout{3} = []; % xdata
	end
end

