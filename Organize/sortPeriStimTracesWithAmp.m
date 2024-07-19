function [periStimMatSort,eventMarkerSort,periStimRowNamesSort,timeDuration,posNum,varargout] = sortPeriStimTracesWithAmp(traceData,timeInfo,stimInfo,eventsTime,eventAmp,eventCat,varargin)
	% Sort the peri-stimulation traces using the peak amplitude of stimulation related events

	% First event's time after the stimulation (start/end)
	% First event's time after the stimulation related event. Use the time difference to the stim or stim-related events

	% traceData: each column contains data from one ROI 
	% timeInfo: a vector. Its length is same as the column number of traceData：each
	% eventsTime: cell var. cell number is the same as the row number of traceData (ROI number)
	% stimInfo: alignedData_trial.stimInfo
	% eventAmp: cell var. Cell number is the same as the row number of traceData (ROI number)

	% Example:
	%		

	% Defaults


	% Create an instance of the inputParser
	p = inputParser;

	% Required input
	addRequired(p, 'traceData', @isnumeric);
	addRequired(p, 'timeInfo', @isnumeric);
	addRequired(p, 'stimInfo', @isstruct);
	addRequired(p, 'eventsTime', @iscell);
	addRequired(p, 'eventAmp', @iscell);
	addRequired(p, 'eventCat', @iscell);

	% Add optional parameters to the input p
	addParameter(p, 'relevantEventDirect', '', @ischar); % 'pre'/'post'. The location of relevent event. Pre or post to the ref event
	addParameter(p, 'preTime', 5, @isnumeric); 
	addParameter(p, 'postTime', 5, @isnumeric);
	addParameter(p, 'stimRefType', 'start', @ischar); % 'start'/'end'. Find the stim-related (reference) event after the start or end of the stimulation
	addParameter(p, 'stimRefTime', 1, @isnumeric); % Time duration used to catch the stim-related (reference) events
	addParameter(p, 'stimRefCat', '', @ischar); % Time duration used to catch the stim-related (reference) events
	addParameter(p, 'roiNames', {}, @iscell); % Names of ROIs
	addParameter(p, 'debugMode', false, @islogical);

	% Parse inputs
	parse(p, traceData, timeInfo, stimInfo, eventsTime, eventAmp, eventCat, varargin{:});

	% Retrieve parsed values
	relevantEventDirect = p.Results.relevantEventDirect;
	preTime = p.Results.preTime;
	postTime = p.Results.postTime;
	stimRefType = p.Results.stimRefType;
	stimRefTime = p.Results.stimRefTime;
	stimRefCat = p.Results.stimRefCat;
	roiNames = p.Results.roiNames;
	debugMode = p.Results.debugMode;



	% create roiNames if it's empty
	if ~exist('roiNames','var')
		roiNum = size(traceData,2);
		roiNames = cell(roiNum,1);
		for rn = 1:roiNum
			roiNames{rn} = sprintf('roi-%g',rn);
		end
	end


	% The sorting only works on recording with repeated stimulation (All repeats must be same) 
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

		% Allocate RAM
		roiNum = size(traceData,2);
		stimNum = size(timeRanges,1);
		rowNum = roiNum*stimNum; % traces will be cutting into this number of pieces
		periStimMat = NaN(roiNum*stimNum,datapointNum);
		% delay2StimMatrix{fn} = NaN(roiNum*stimNum,nthDelay);
		% delay2StimEventMatrix{fn} = NaN(roiNum*stimNum,nthDelay);
		periStimRowNames = cell(rowNum,1);
		eventsDelay2Stim = cell(rowNum,1);
		Diff2StimRefEvent = cell(rowNum,1);
		eventMarker = cell(rowNum,1);
		stimRefEventTF = logical(zeros(rowNum,1));
		stimRefEventAmp = nan(rowNum,1);
		% rangEventsTimeAllSection = cell(rowNum,1);
		% rangEventsCatAllSection = cell(rowNum,1);

		% loop through ROIs
		for rn = 1:roiNum
			% for debugging
			if debugMode
				fprintf(' - roi %d/%d: %s\n',rn,roiNum,roiNames{rn})
				% if rn == 2
				% 	pause
				% end
			end


			% Get the events' time for every stimulation ranges and store them to cells
			[~,~,~,rangEventsTime,rangEventsIDX] = getRangeIDXwithEvents(eventsTime{rn},timeRanges);

			% Get the categories and amplitudes of event for every stimulation ranges 
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
					rangEventsAmp{sn} = eventAmp{rn}(rangEventsIDX{sn});
				end
			end


			% Loop through stimulation ranges (sections)
			for sn = 1:stimNum
				% for debugging
				if debugMode
					% fprintf('  - section %d/%d\n',sn,stimNum)
					% if sn == 6
					% 	pause
					% end
				end

				rowIDX = (rn-1)*stimNum+sn;

				% Create a section name for each stimulation range 
				periStimRowNames{rowIDX} = sprintf('%s-s%g',roiNames{rn},sn);

				% Get a section of traceData using the new time ranges
				sTrace = traceData((timeRangesIDX(sn,1):timeRangesIDX(sn,2)),rn); % Get a section trace from one ROI from traceData
				sTraceRow = reshape(sTrace,[1,numel(sTrace)]); % ensure that sTraceRow is a row vector
				traceDataNum = numel(sTraceRow);
				periStimMat(rowIDX,1:traceDataNum) = sTraceRow;


				% Calculate the relevant time of events to stimRef
				eventsDelay2Stim{rowIDX} = rangEventsTime{sn}-stimRef(sn);

				% % Discard the events before the stimulation
				% afterStimEventsIDX = find(eventsDelay2Stim{rowIDX} >= 0);
				% eventsDelay2Stim{rowIDX} = eventsDelay2Stim{rowIDX}(afterStimEventsIDX)+eventTimeCorrection;
				% % rangEventsTime{sn} = rangEventsTime{sn}(afterStimEventsIDX)+eventTimeCorrection;
				% rangEventsCat{sn} = rangEventsCat{sn}(afterStimEventsIDX);
				% rangEventsAmp{sn} = rangEventsAmp{sn}(afterStimEventsIDX);


				% Look for the stimRef events using 'stimRefTime' or 'stimRefCat'
				if ~isempty(stimRefCat) % Use the input, 'stimRefCat', to find the stimRef event
					stimEventIDX = find(strcmpi(rangEventsCat{sn},stimRefCat) & eventsDelay2Stim{rowIDX} > 0);
				else % Use 'stimRefTime' defined time range to find the stimRef event
					stimEventIDX = find(eventsDelay2Stim{rowIDX} > 0 & eventsDelay2Stim{rowIDX} <= stimRefTime);
				end

				% Get the amplitude of stimEvents
				if ~isempty(stimEventIDX)
					stimRefEventAmp(rowIDX) = rangEventsAmp{sn}(stimEventIDX);
				end

				% Calculate the time delay if 'stimEventIDX' is not empty
				if ~isempty(stimEventIDX)
					Diff2StimRefEvent{rowIDX} = eventsDelay2Stim{rowIDX} - eventsDelay2Stim{rowIDX}(stimEventIDX);
					eventMarker{rowIDX} = Diff2StimRefEvent{rowIDX} + eventTimeCorrection;
					stimRefEventTF(rowIDX) = true;
				end
			end
		end


		% Get the periStim traces with stimEvents
		posNum = sum(stimRefEventTF);
		periStimMatPos = periStimMat(stimRefEventTF,:); % traces in periStimMat with stimEvents
		periStimRowNamesPos = periStimRowNames(stimRefEventTF); % Names of rows with stimEvents
		stimRefEventAmpPos = stimRefEventAmp(stimRefEventTF);
		Diff2StimRefEventPos = Diff2StimRefEvent(stimRefEventTF);
		eventMarkerPos = eventMarker(stimRefEventTF);

		% Get the periStim traces without stimEvents
		periStimMatNeg = periStimMat(~stimRefEventTF,:); % traces in periStimMat with stimEvents
		periStimRowNamesNeg = periStimRowNames(~stimRefEventTF); % Names of rows with stimEvents
		stimRefEventAmpNeg = stimRefEventAmp(~stimRefEventTF);
		Diff2StimRefEventNeg = Diff2StimRefEvent(~stimRefEventTF);
		eventMarkerNeg = eventMarker(~stimRefEventTF);


		% Sort the positive (with stimEvents) rows with the amplitude of stimEvents
		[StimRefEventAmpPosSort, ampSortIDX] = sort(stimRefEventAmpPos, 'descend'); % sort the amp in a descending order
		periStimMatPosSort =  periStimMatPos(ampSortIDX,:);
		periStimRowNamesPosSort = stimRefEventAmpPos(ampSortIDX);
		Diff2StimRefEventPosSort = Diff2StimRefEventPos(ampSortIDX);
		eventMarkerPosSort = eventMarkerPos(ampSortIDX);

		% Combine the pos (with stimEvents) and neg (without stimEvents) periStim traces
		periStimMatSort = vertcat(periStimMatPosSort, periStimMatNeg);
		periStimRowNamesSort = vertcat(periStimRowNamesPos, periStimRowNamesNeg);
		stimRefEventAmpSort = vertcat(StimRefEventAmpPosSort, stimRefEventAmpNeg);
		Diff2StimRefEventSort = vertcat(Diff2StimRefEventPosSort, Diff2StimRefEventNeg);
		eventMarkerSort = vertcat(eventMarkerPosSort, eventMarkerNeg);
	else
		% ampSortIDX,periStimMatSort,Diff2StimRefEventSort,periStimRowNamesSort,timeDuration,posNum
		periStimMatSort = [];
		eventMarkerSort = [];
		periStimRowNamesSort = [];
		timeDuration = [];
		posNum = [];
		varargout{1} = []; 
		varargout{2} = []; 
		% varargout{3} = []; 
		% varargout{4} = [];
	end
end