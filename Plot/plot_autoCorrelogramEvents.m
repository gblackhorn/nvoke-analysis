function [binnedACG,varargout] = plot_autoCorrelogramEvents(alignedData,varargin)
	%
	% 

	% Example:
	%	[ACG_Events,cEventNum] = plot_autoCorrelogramEvents(alignedData_allTrials,...
	%		'timeType','rise_time','stimName','ap-0.1s','stimEventCat','trig');
	
	% Defaults
	timeType = 'rise_time'; % 'rise'/'peak_time'
	sponEventCat = 'spon';
	stimEventCat = ''; % use 'trig' for ap, 'rebound' for 'og', use 'interval-trigger' or 'rebound' for og&ap
	stimName = '';

	preEventDuration = 3; % unit: s. find other events in this duration before the event
	postEventDuration = 3; % unit: s. find other events in this duration after the event
	excludOGpost = 1; % exclude this amount of time after the end of OG stimulation
	remove_centerEvents = false; % true/false. Remove the center events
	normData = false; % normalize the count of the event

	fieldKeyWord = 'Event'; % Key word to locate the fields containing ACG event time info in ACG_Events structure variable

	plot_unit_width = 0.45; % normalized size of a single plot to the display
	plot_unit_height = 0.4; % nomralized size of a single plot to the display
	binWidth = 1; % the width of single histogram bin. the default value is 1 s.
	facecolor = '#4CA2D9'; % histogram face color
	edgecolor = 'k'; % histogram edge color. 'none'
	subtitleFontSize = 14;
	titleFontSize = 16;

	saveFig = false;
	save_dir = '';
	gui_save = false;

	debugMode = false; % true/false


	% Optionals inputs. Use these using get_eventsCount_autoCorrelogram(_,'varargin_name',varargin_value)
	for ii = 1:2:(nargin-1)
	    if strcmpi('timeType', varargin{ii})
            timeType = varargin{ii+1};
	    elseif strcmpi('remove_centerEvents', varargin{ii})
            remove_centerEvents = varargin{ii+1};
	    elseif strcmpi('preEventDuration', varargin{ii})
            preEventDuration = varargin{ii+1};
	    elseif strcmpi('postEventDuration', varargin{ii})
            postEventDuration = varargin{ii+1};
	    elseif strcmpi('normData', varargin{ii})
            normData = varargin{ii+1};
	    elseif strcmpi('stimName', varargin{ii})
            stimName = varargin{ii+1};
	    elseif strcmpi('stimEventCat', varargin{ii})
            stimEventCat = varargin{ii+1};
	    elseif strcmpi('binWidth', varargin{ii})
            binWidth = varargin{ii+1};
	    elseif strcmpi('saveFig', varargin{ii})
            saveFig = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
	    elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1};
	    end
	end


	% Add some more time if the stimulation is optogenetics or stimEvent cat is 'rebound'
	if contains(stimName,'og','IgnoreCase',true) || contains(stimEventCat,'rebound','IgnoreCase',true)
		preEventDuration = preEventDuration+excludOGpost;
	end


	% Get structure containing ACG_events
	[ACG_events_struct,cEventTotalNum] = get_autoCorrelogramEvents_trials(alignedData,...
		'timeType',timeType,'stimName',stimName,'stimEventCat',stimEventCat,...
		'preEventDuration',preEventDuration,'postEventDuration',postEventDuration,...
		'remove_centerEvents',remove_centerEvents);


	% Get field names
	ACG_Events_fieldnames = fieldnames(ACG_events_struct);


	% Use a keyword (fieldKeyWord) to find which field(s) contain event data
	eventField_tf = contains(ACG_Events_fieldnames,fieldKeyWord,'IgnoreCase',true);
	eventFieldNames = ACG_Events_fieldnames(find(eventField_tf));


	% Use stimName if all the contents in this field are the same
	stimNames = {ACG_events_struct.stimName};
	if isequal(stimNames{:}) 
		stimNameStr = ACG_events_struct(1).stimName;
	else
		stimNameStr = 'variousStim';
	end


	% Set the histogram edges using binWidth 
	HistEdges = [-preEventDuration:binWidth:postEventDuration];


	% Decide the normalization method
	if normData
		normVal = 'probability';
	else
		normVal = 'count';
	end


	% loop through eventFieldNames and plot
	eventFieldNum = numel(eventFieldNames);
	titleStr = sprintf('autoCorrelogram of calcium events %s [%s %s] binwidth-%gs %s',...
		timeType,stimNameStr,stimEventCat,binWidth,normVal);
	titleStr = strrep(titleStr,'_',' ');
	[f,f_rowNum,f_colNum] = fig_canvas(eventFieldNum,'unit_width',plot_unit_width,'unit_height',plot_unit_height,'column_lim',2,...
		'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);

	% Create an output structure to store the binned data and the center-events (data at zero) number
	binnedACG = empty_content_struct({'stimName','eventCat','events','cEventNum','binnedEvents'},eventFieldNum);

	for n = 1:eventFieldNum
		eventCat = eventFieldNames{n}; % Get the field name for the current event

		% Organize the event time. Collect all of them from different cells and combine them into a single vector
		eventsTimeStamp = {ACG_events_struct.(eventCat)};
		eventsTimeStamp = [eventsTimeStamp{:}];


		% group events in bins 
		% [eventCountInBins,HistEdges] = histcounts(eventsTimeStamp,HistEdges); % get the event numbers in histbins

		% Create subtitle string
		subtitlestr = sprintf('%s [%s] %g-centerEvents',eventCat,stimNameStr,cEventTotalNum.(eventCat));
		subtitlestr = strrep(subtitlestr,'_',' ');


		% plot
		ax = nexttile(tlo);
		N = histogram(eventsTimeStamp,HistEdges,'Normalization',normVal,...
			'FaceColor',facecolor,'EdgeColor',edgecolor);
		% bar(HistEdges(1:end-1), eventCountInBins, 'hist', 'color', faceColor, 'EdgeColor', 'none');
		title(subtitlestr,'FontSize',subtitleFontSize)

		binnedACG(n).stimName = stimNameStr;
		binnedACG(n).eventCat = eventCat;
		binnedACG(n).events = eventsTimeStamp;
		binnedACG(n).cEventNum = cEventTotalNum.(eventCat);
		binnedACG(n).binnedEvents = N;
	end
	sgtitle(titleStr,'FontSize',titleFontSize)

	% Save figure and statistics
	if saveFig
		if isempty(save_dir)
			gui_save = 'on';
		end
		msg = 'Choose a folder to save autoCorrelograms';
		save_dir = savePlot(f,'save_dir',save_dir,'guiSave',gui_save,...
			'guiInfo',msg,'fname',titleStr);
		save(fullfile(save_dir, [titleStr, '_data']),...
		    'binnedACG');
	end 

	varargout{1} = save_dir;
end