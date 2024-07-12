function [eventIntStruct,varargout] = getEventIntervalFromRef(alignedData,refEventCat,releventEventLoc,varargin)
	% Get the time stamps of events in a specific category (reference) and the time stamps of their preceeding/following
	% (pre/post) events. Calculate the time difference between the pairs. Store data in a structVar, eventIntStruct

	% Input parser
	p = inputParser;

	% Required input
	addRequired(p, 'alignedData', @isstruct);
	addRequired(p, 'refEventCat', @ischar); % category of leading event
	addRequired(p, 'releventEventLoc', @ischar); % 'pre'/'post'. The location of relevent event. Pre or post to the ref event

	% Optional parameters with default values
	addParameter(p, 'eventTimeType', 'peak_time', @islogical); % 'peak_time'/'rise_time'. Type of event time
	addParameter(p, 'maxDiff', '5', @isnumeric); % The max difference between leading and following events
												 % If the diff is longer, the paired data will be discarded

	% Parse inputs
	parse(p, alignedData, refEventCat, releventEventLoc, varargin{:});

	% Assign parsed values to variables
	alignedData = p.Results.alignedData;
	refEventCat = p.Results.refEventCat;
	releventEventLoc = p.Results.releventEventLoc;
	eventTimeType = p.Results.eventTimeType;
	maxDiff = p.Results.maxDiff;


	% Get the recording number
	recNum = numel(alignedData);

	% Create cells to store the event intervals. One cell per recording
	eventIntStructRecCell = cell(recNum, 1);

	% Loop through all the recordings
	for rn = 1:recNum
		% Get the name of the recording
		recName = getShortRecName(alignedData(rn).trialName);

		% Get the number and names of neurons
		neuronNum = numel(alignedData(rn).traces);
		% neuronNames = {alignedData(rn).traces.roi};

		% Get the time stamps and categories of events from neurons
		if neuronNum ~= 0
			eventIntStructNeuronCell = cell(neuronNum, 1);
			for nn = 1:neuronNum
				eventIntStructNeuronCell{nn} = getEventIntFromNeuron(alignedData(rn).traces(nn), eventTimeType,...
					refEventCat, releventEventLoc, maxDiff, recName);
			end

			% Concatenate the data from neurons
			eventIntStructRecCell{rn} = vertcat(eventIntStructNeuronCell{:});
		end
	end

	% Concatenate the data from recordings
	eventIntStruct = vertcat(eventIntStructRecCell{:});
end

function shortRecName = getShortRecName(recName)
	% Get the date-time part from the recording name

	% Find the index of the first underscore
	underscoreIndex = find(recName == '_', 1);

	% Separate the parts of the string
	shortRecName = recName(1:underscoreIndex-1);
end

function eventIntStructNeuron = getEventIntFromNeuron(neuronDataStruct, eventTimeType, refEventCat, releventEventLoc, maxDiff, recName)
	% Get the time stamps of paired leading and following events from a neuron

	neuronName = neuronDataStruct.roi; % Get neuron name

	% Get the categories of events and the idx of leading events
	eventProps = neuronDataStruct.eventProp;
	eventCats = {eventProps.peak_category}; 
	refEventTF = strcmpi(eventCats, refEventCat); 
	refEventIDX = find(refEventTF);


	% Create an empty struct var to store the data
	structLength = sum(refEventTF);
	eventIntStructNeuronFields = {'recName', 'roi', 'leadingEventCat', 'leadingEventTime', 'followingEventCat', 'followingEventTime', 'pairCat', 'pairTimeDiff'};
	eventIntStructNeuron = empty_content_struct(eventIntStructNeuronFields, structLength);

	% Loop through eventIntStructNeuron and fill in the data
	if structLength > 0
		[eventIntStructNeuron.recName] = deal(recName);		
		[eventIntStructNeuron.roi] = deal(neuronName);		
		% [eventIntStructNeuron.leadingEventCat] = deal(leadingEventCat);		
		% [eventIntStructNeuron.followingEventCat] = deal(followingEventCat);		
		% [eventIntStructNeuron.pairCat] = deal([leadingEventCat, '-', followingEventCat]);		

		disEntryIDX = []; % Used to store the idx of entry to be discarded
		for sl = 1:structLength 
			switch releventEventLoc
				case 'pre'
					if refEventIDX(sl) ~= 1 % if the ref event is not the first event
						idx = refEventIDX(sl);
						% Fill the data for the leading event
						eventIntStructNeuron(sl).leadingEventTime = eventProps(idx-1).(eventTimeType);
						eventIntStructNeuron(sl).leadingEventCat = eventProps(idx-1).peak_category;

						% Fill the data for the following event
						eventIntStructNeuron(sl).followingEventTime = eventProps(idx).(eventTimeType);
						eventIntStructNeuron(sl).followingEventCat = eventProps(idx).peak_category;

						% Calculate the time diff between the leading and the following events
						eventIntStructNeuron(sl).pairTimeDiff = eventIntStructNeuron(sl).followingEventTime - eventIntStructNeuron(sl).leadingEventTime;

						% Fill the pair category of leading and following events
						eventIntStructNeuron(sl).pairCat = ['preEvent', '-', eventIntStructNeuron(sl).followingEventCat];

						% Mark the entry as to-be discarded if the event interval is bigger than maxDiff 
						if eventIntStructNeuron(sl).pairTimeDiff > maxDiff
							disEntryIDX = [disEntryIDX, sl];
						end
					else
						disEntryIDX = [disEntryIDX, sl];
					end
				case 'post'
					if refEventIDX(sl) ~= numel(eventCats) % if the ref event is not the last event
						idx = refEventIDX(sl);
						% Fill the data for the leading event
						eventIntStructNeuron(sl).leadingEventTime = eventProps(idx).(eventTimeType);
						eventIntStructNeuron(sl).leadingEventCat = eventProps(idx).peak_category;

						% Fill the data for the following event
						eventIntStructNeuron(sl).followingEventTime = eventProps(idx+1).(eventTimeType);
						eventIntStructNeuron(sl).followingEventCat = eventProps(idx+1).peak_category;

						% Calculate the time diff between the leading and the following events
						eventIntStructNeuron(sl).pairTimeDiff = eventIntStructNeuron(sl).followingEventTime - eventIntStructNeuron(sl).leadingEventTime;

						% Fill the pair category of leading and following events
						eventIntStructNeuron(sl).pairCat = [eventIntStructNeuron(sl).leadingEventCat, '-', 'postEvent'];

						if eventIntStructNeuron(sl).pairTimeDiff > maxDiff
							disEntryIDX = [disEntryIDX, sl];
						end
					else
						disEntryIDX = [disEntryIDX, sl];
					end
			end





			% 	if strcmpi(eventProps(idx+1).peak_category, followingEventCat)
			% 		eventIntStructNeuron(sl).followingEventTime = eventProps(idx+1).(eventTimeType);

			% 		% Calculate the time diff between the leading and the following events
			% 		eventIntStructNeuron(sl).pairTimeDiff = eventIntStructNeuron(sl).followingEventTime - eventIntStructNeuron(sl).leadingEventTime;
			% 		if eventIntStructNeuron(sl).pairTimeDiff > maxDiff
			% 			disEntryIDX = [disEntryIDX, sl];
			% 		end
			% 	else
			% 		disEntryIDX = [disEntryIDX, sl];
			% 	end
			% else
			% 	disEntryIDX = [disEntryIDX, sl];
			% end
		end

		% Discard the entries marked by disEntryIDX
		eventIntStructNeuron(disEntryIDX) = [];
	end
end

