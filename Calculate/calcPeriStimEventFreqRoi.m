function [sectEventFreq,varargout] = calcPeriStimEventFreqRoi(eventTimeStamps,periStimSections,varargin)
	% Given event times and periStimSections (Bin edges), return the event frequencies in sections

	% eventTimeStamps: a vector of event time points
	% periStimSections: a matrix whos size is (stimRepeatNum, edgesNum)

	% Defaults
	alignEventsToStim = true; % align the eventTimeStamps to the onsets of the stimulations: subtract eventTimeStamps with stimulation onset time
	stimStartSecIDX = 3; % The nth column data in periStimSections is the start time of stimulation. Use this as 0 in peri-stim 
	round_digit_sig = 2; % round to the Nth significant digit for duration

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('alignEventsToStim', varargin{ii})
	        alignEventsToStim = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('stimStartSecIDX', varargin{ii})
	        stimStartSecIDX = varargin{ii+1}; 
	    % elseif strcmpi('plot_raw_races', varargin{ii})
	    %     plot_raw_races = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('eventCat', varargin{ii})
	    %     eventCat = varargin{ii+1};
        % elseif strcmpi('fname', varargin{ii})
	    %     fname = varargin{ii+1};
	    end
	end

	% calculate the repeat number of the stimulation
	stimRepearNum = size(periStimSections,1);

	% create a var to store the section durations
	sectionsDuration = NaN(stimRepearNum,size(periStimSections,2)-1);

	% create a var to store the histcounts
	eventHistCounts = NaN(stimRepearNum,size(periStimSections,2)-1);

	% create a cell var to store the event time points
	eventsPeriStimulus = cell(stimRepearNum,1); % create an empty cell array to store the EventTimeStamps around each stimulation

	% loop through all repeats and collect events for every stimRepeat
	for n = 1:stimRepearNum
		% get the section for a single stim repeat
		sectSingleRepeat = periStimSections(n,:);
		periStimRange = [sectSingleRepeat(1) sectSingleRepeat(end)];

		% get the events in a peri-stim range
		eventIDX = find(eventTimeStamps>=periStimRange(1) & eventTimeStamps<=periStimRange(2));
		eventsPeriStimulus{n} = eventTimeStamps(eventIDX);

		% change the event time to peri-stim
		if alignEventsToStim
			eventsPeriStimulus{n} = eventsPeriStimulus{n}-sectSingleRepeat(stimStartSecIDX);
			sectSingleRepeat = sectSingleRepeat-sectSingleRepeat(stimStartSecIDX);
			periStimSections(n,:) = sectSingleRepeat;
		end

		% calculate the durations of every section
		sectionsDuration(n,:) = diff(sectSingleRepeat);

		% hist-count the events in a single peri-stim range using periStimSections as the edges
		eventHistCounts(n,:) = histcounts(eventsPeriStimulus{n},sectSingleRepeat);
	end

	eventHistCountsAll = sum(eventHistCounts,1);
	sectionsDurationAll = sum(sectionsDuration,1);

	sectEventFreq = eventHistCountsAll./sectionsDurationAll;

	% round the first repeat of periStimSections to use it as representative edges
	modelSect = round(periStimSections(1,:),round_digit_sig,'significant');
	varargout{1} = modelSect;
end

