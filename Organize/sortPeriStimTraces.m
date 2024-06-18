function [sortedIDX,sortedFdSection,sortedEventMarker,sortedRowNames,timeDuration,posNum,varargout] = sortPeriStimTraces(traceData,timeInfo,eventsTime,stimInfo,varargin)
	% Sort the peri-stimulation traces according to the events time

	% First event's time after the stimulation (start/end)
	% First event's time after the stimulation related event. Use the time difference to the stim or stim-related events

	% traceData: each column contains data from one ROI 
	% timeInfo: a vector. Its length is same as the column number of traceData：each
	% eventsTime: cell var. cell number is the same as the row number of traceData (ROI number)
	% stimInfo: alignedData_trial.stimInfo

	% Example:
	%		

	% Defaults
	preTime = 0; % include time before stimulation starts for plotting
	postTime = []; % include time after stimulation ends for plotting. []: until the next stimulation starts
	stimRefType = 'start'; % 'start'/'end'. Using the start/end to calculate the delay of events
	nthDelay = 3; % calculate the delay of 1st to nth events in a peri-stim range
	sortDirection = 'descend'; % 'ascend'/'descend'

	eventCat = {};
	stimEventCat = '';
	followEventCat = '';

	debugMode = false;

	% Optionals
	for ii = 1:2:(nargin-4)
	    if strcmpi('eventCat', varargin{ii})
	        eventCat = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('stimEventCat', varargin{ii})
            stimEventCat = varargin{ii+1};
	    elseif strcmpi('followEventCat', varargin{ii})
            followEventCat = varargin{ii+1};
	    elseif strcmpi('preTime', varargin{ii})
            preTime = varargin{ii+1};
	    elseif strcmpi('postTime', varargin{ii})
            postTime = varargin{ii+1};
	    elseif strcmpi('stimRefType', varargin{ii})
            stimRefType = varargin{ii+1};
	    elseif strcmpi('nthDelay', varargin{ii})
            nthDelay = varargin{ii+1};
	    elseif strcmpi('sortDirection', varargin{ii})
            sortDirection = varargin{ii+1};
	    elseif strcmpi('roiNames', varargin{ii})
            roiNames = varargin{ii+1};
	    elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1};
	    end
	end

	% create roiNames if it's empty
	if ~exist('roiNames','var')
		roiNum = size(traceData,2);
		roiNames = cell(roiNum,1);
		for rn = 1:roiNum
			roiNames{rn} = sprintf('roi-%g',rn);
		end
	end


	if ~stimInfo.UnifiedStimDuration.varied
		% extract the stimulation ranges from the 'stimInfo'
		% add preTime and postTime to the stimulation ranges
		% find the closest time for 'new time ranges' (with pre and post) in timeInfo
		[timeRanges,timeRangesIDX,stimRanges,stimRangesIDX,timeDuration,datapointNum] = createTimeRangesUsingStimInfo(timeInfo,stimInfo,...
			'preTime',preTime,'postTime',postTime);

		switch stimRefType
			case 'start'
				stimRef = stimRanges(:,1);
				eventTimeCorrection = 0;
			case 'end'
				stimRef = stimRanges(:,2);
				eventTimeCorrection = stimRanges(1,2)-stimRanges(1,1);
			otherwise
				error('stimRefType must be [start] or [end]')
		end


		% loop through ROIs
		roiNum = size(traceData,2);
		stimNum = size(timeRanges,1);
		rowNum = roiNum*stimNum; % traces will be cutting into this number of pieces
		fdSection = NaN(roiNum*stimNum,datapointNum);
		% delay2StimMatrix{fn} = NaN(roiNum*stimNum,nthDelay);
		% delay2StimEventMatrix{fn} = NaN(roiNum*stimNum,nthDelay);
		rowNamesSection = cell(rowNum,1);
		eventsDelay2Stim = cell(rowNum,1);
		eventsDelay2StimEvent = cell(rowNum,1);
		rangEventsTimeAllSection = cell(rowNum,1);
		rangEventsCatAllSection = cell(rowNum,1);
		for rn = 1:roiNum
			% for debugging
			if debugMode
				fprintf(' - roi %d/%d: %s\n',rn,roiNum,roiNames{rn})
				% if rn == 2
				% 	pause
				% end
			end


			% get the events' time for every stimulation ranges and store them to cells
			[posTimeRanges,posRangeIDX,negRangeIDX,rangEventsTime,rangEventsIDX] = getRangeIDXwithEvents(eventsTime{rn},timeRanges);

			% get the and events' category for every stimulation ranges 
			if ~isempty(eventCat)
				rangEventsCat = cell(size(rangEventsTime));
				for sn = 1:stimNum
					if debugMode
						% fprintf('  - section %d/%d\n',sn,stimNum)
						% if sn == 6
						% 	pause
						% end
					end
					if ~isempty(rangEventsIDX{sn})
						rangEventsCat{sn} = {eventCat{rn}{rangEventsIDX{sn}}};
					end
				end
			else
				rangEventsCat = {};
			end


			% loop through stimulation ranges (sections)
			% eventsDelay2Stim = cell(size(rangEventsTime));
			% eventsDelay2StimEvent = cell(size(rangEventsTime));
			for sn = 1:stimNum
				% for debugging
				if debugMode
					% fprintf('  - section %d/%d\n',sn,stimNum)
					% if sn == 6
					% 	pause
					% end
				end

				rowIDX = (rn-1)*stimNum+sn;

				% create a section name for each stimulation range 
				rowNamesSection{rowIDX} = sprintf('%s-s%g',roiNames{rn},sn);

				% get a section of traceData using the new time ranges
				sTrace = traceData((timeRangesIDX(sn,1):timeRangesIDX(sn,2)),rn); % Get a section trace from one ROI from traceData
				sTraceRow = reshape(sTrace,[1,numel(sTrace)]); % ensure that sTraceRow is a row vector
				traceDataNum = numel(sTraceRow);
				fdSection(rowIDX,1:traceDataNum) = sTraceRow;


				% calculate the delay of events' time to stimRef
				eventsDelay2Stim{rowIDX} = rangEventsTime{sn}-stimRef(sn);

				% discard the events before the stimulation
				afterStimEventsIDX = find(eventsDelay2Stim{rowIDX} >= 0);
				eventsDelay2Stim{rowIDX} = eventsDelay2Stim{rowIDX}(afterStimEventsIDX)+eventTimeCorrection;
				rangEventsTime{sn} = rangEventsTime{sn}(afterStimEventsIDX)+eventTimeCorrection;
				if ~isempty(rangEventsCat)
					if ~isempty(rangEventsCat{sn})
						rangEventsCat{sn} = rangEventsCat{sn}(afterStimEventsIDX);
					end
				end


				% calculate the delay of events' time to the stim-related event if it exists
				if ~isempty(eventCat) && ~isempty(stimEventCat)
					stimEventCatIDX = find(strcmpi(rangEventsCat{sn},stimEventCat));
					if ~isempty(stimEventCatIDX)
						eventsDelay2StimEvent{rowIDX} = eventsDelay2Stim{rowIDX}-eventsDelay2Stim{rowIDX}(stimEventCatIDX);
						eventsDelay2StimEvent{rowIDX}(stimEventCatIDX) = []; % remove the delay of stim-related events itself 
					end

					% store the rangEventsCat to cells contain all ROIs and all sections
					rangEventsCatAllSection{rowIDX} = rangEventsCat{sn};
				end

				% store the rangEventsTime to cells contain all ROIs and all sections
				rangEventsTimeAllSection{rowIDX} = rangEventsTime{sn};
			end
		end


		% decide the filter type
		if ~isempty(eventCat)
			% optional filter: find the sections with stimulation related events and following event(s)
			if ~isempty(stimEventCat) && ~isempty(followEventCat)
				filterType = 'stimFollowEvents';

			% optional filter: find the sections with stimulation related events
			elseif ~isempty(stimEventCat) && isempty(followEventCat)
				filterType = 'stimEvents';
			else 
				filterType = 'noFilter';
			end
		else
			filterType = 'noFilter';
		end

		% filter rows
		tfIDX = logical(zeros(rowNum,1));
		if ~isempty(eventCat)
			for n = 1:rowNum
				stimEventCatIDX = find(strcmpi(rangEventsCatAllSection{n},stimEventCat));
				if ~isempty(stimEventCatIDX) 
					switch filterType
						case 'stimFollowEvents'
							followEventCatIDX = find(strcmpi(rangEventsCatAllSection{n},followEventCat));
							if ~isempty(followEventCatIDX)
								tfIDX(n) = true; % containing stim-related and follow events
							end
						case 'stimEvents'
							tfIDX(n) = true; % containing stim-related events
						otherwise
					end
				end
			end
		end
		posIDX = find(tfIDX == 1);
		negIDX = find(tfIDX == 0);
		filteredIDX = {posIDX negIDX};
		posNum = numel(posIDX);


		% sort the sections 
		% - number of events
		eventsNumPerRow = cellfun(@(x) numel(x),rangEventsTimeAllSection);
		[sortedEventsNumPerRow,sortedEventNumIDX] = sort(eventsNumPerRow,sortDirection);



		% separate the data to pos and neg groups. 'f_': filtered 
		% f_fdSection = cell(2,1); 
		f_eventsDelay2Stim = cell(2,1); 
		f_eventsDelay2StimEvent = cell(2,1); 
		f_delay2StimMatrix = cell(2,1); 
		f_delay2StimEventMatrix = cell(2,1); 
		% sortedIDX = cell(2,1);
		sortedIDX_delay2Stim = cell(2,1);
		sortedIDX_delay2StimEvent = cell(2,1);
		for fn = 1:numel(filteredIDX)
			IDX = filteredIDX{fn};
			if IDX ~= 0
				% f_fdSection{fn} = fdSection(IDX,:);
				f_eventsDelay2Stim{fn} = eventsDelay2Stim(IDX);

				if strcmpi(filterType,'stimFollowEvents')
					f_eventsDelay2StimEvent{fn} = eventsDelay2StimEvent(IDX);
				end

				f_delay2StimMatrix{fn} = NaN(numel(IDX),nthDelay);
				f_delay2StimEventMatrix{fn} = NaN(numel(IDX),nthDelay);
				sortedIDX_delay2Stim{fn} = NaN(numel(IDX),nthDelay);
				sortedIDX_delay2StimEvent{fn} = NaN(numel(IDX),nthDelay);
				for i = 1:numel(IDX)
					for m = 1:nthDelay
						delay2StimNum = numel(f_eventsDelay2Stim{fn}{i});
						if delay2StimNum >= m
							f_delay2StimMatrix{fn}(i,m) = f_eventsDelay2Stim{fn}{i}(m);
						end

						if strcmpi(filterType,'stimFollowEvents')
							delay2StimEventNum = numel(f_eventsDelay2StimEvent{fn}{i});
							if delay2StimEventNum >= m
								f_delay2StimEventMatrix{fn}(i,m) = f_eventsDelay2StimEvent{fn}{i}(m);
							end
						end
					end
				end

				for m = 1:nthDelay
					[~,nthSortedIDX] = sort(f_delay2StimMatrix{fn}(:,m));
					sortedIDX_delay2Stim{fn}(:,m) = reshape(IDX(nthSortedIDX),[],1);

					if strcmpi(filterType,'stimFollowEvents')
						[~,nthSortedIDX] = sort(f_delay2StimEventMatrix{fn}(:,m));
						sortedIDX_delay2StimEvent{fn}(:,m) = reshape(IDX(nthSortedIDX),[],1);
					end
				end
			end
		end

		% combine the data from pos and neg groups together
		% f_fdSection = vertcat(f_fdSection{:});
		f_eventsDelay2Stim = vertcat(f_eventsDelay2Stim{:});
		f_eventsDelay2StimEvent = vertcat(f_eventsDelay2StimEvent{:});
		sortedIDX_delay2Stim = vertcat(sortedIDX_delay2Stim{:});
		sortedIDX_delay2StimEvent = vertcat(sortedIDX_delay2StimEvent{:});
		% delay2StimMatrix = vertcat(delay2StimMatrix{:});
		% delay2StimEventMatrix = vertcat(delay2StimEventMatrix{:});
		varargout{1} = sortedEventNumIDX;
		switch filterType
			case 'stimFollowEvents'
				sortedIDX = sortedIDX_delay2Stim(:,2);
				% sortedIDX = sortedIDX_delay2StimEvent(:,1);
				sortedFdSection = fdSection(sortedIDX,:);
				sortedRowNames = rowNamesSection(sortedIDX);
				sortedEventMarker = eventsDelay2Stim(sortedIDX);
				% sortedEventMarker{1,2} = num2cell(delay2StimMatrix(sortedIDX,2));
				% sortedEventMarker{1,1} = num2cell(delay2StimMatrix(sortedIDX,1));
				% sortedEventMarker{1,2} = num2cell(delay2StimMatrix(sortedIDX,2));
				% sortedEventMarker{1,2} = num2cell(delay2StimEventMatrix(sortedIDX,1));

				varargout{2} = sortedIDX_delay2StimEvent; % 1st to nth sorting. 1st column  = sortedIDX
				% varargout{3} = delay2StimMatrix; % un-sorted 'delay2Stim'. nth column = nth events in a fdSection
				% varargout{4} = delay2StimEventMatrix; % un-sorted 'delay2StimEvent'. nth column = nth events in a fdSection
			case 'stimEvents'
				sortedIDX = sortedIDX_delay2Stim(:,1);
				sortedFdSection = fdSection(sortedIDX,:);
				sortedRowNames = rowNamesSection(sortedIDX);
				sortedEventMarker = eventsDelay2Stim(sortedIDX);
				% sortedEventMarker{1,1} = num2cell(delay2StimMatrix(sortedIDX,1));

				varargout{2} = sortedIDX_delay2Stim; % 1st to nth sorting. 1st column  = sortedIDX
				% varargout{3} = delay2StimMatrix; % un-sorted 'delay2Stim'. nth column = nth events in a fdSection
				% varargout{4} = delay2StimEventMatrix; % un-sorted 'delay2StimEvent'. nth column = nth events in a fdSection
			case 'noFilter'
				sortedIDX = sortedIDX_delay2Stim(:,1);
				sortedFdSection = fdSection(sortedIDX,:);
				sortedRowNames = rowNamesSection(sortedIDX);
				sortedEventMarker = eventsDelay2Stim(sortedIDX);
				% sortedEventMarker{1,1} = num2cell(delay2StimMatrix(sortedIDX,1));

				varargout{2} = sortedIDX_delay2Stim; % 1st to nth sorting. 1st column  = sortedIDX
				% varargout{3} = delay2StimMatrix; % un-sorted 'delay2Stim'. nth column = nth events in a fdSection
				% varargout{4} = delay2StimEventMatrix; % un-sorted 'delay2StimEvent'. nth column = nth events in a fdSection
			otherwise
		end


		% sort the sections using the delay of events
		% - events' time to stimRefType

		% sort the sections using the delay of events
		% - events' time to the stim-related event
	else
		% sortedIDX,sortedFdSection,sortedEventMarker,sortedRowNames,timeDuration,posNum
		sortedIDX = [];
		sortedFdSection = [];
		sortedEventMarker = [];
		sortedRowNames = [];
		timeDuration = [];
		posNum = [];
		varargout{1} = []; 
		varargout{2} = []; 
		% varargout{3} = []; 
		% varargout{4} = [];
	end
end