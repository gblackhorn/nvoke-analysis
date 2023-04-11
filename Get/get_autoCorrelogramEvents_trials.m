function [ACG_events_struct,varargout] = get_autoCorrelogramEvents_trials(alignedData,varargin)
	%Get the time of events around center events (auto-correlogram events) from multiple trials
	% 

	% Example:
	%	[ACG_Events,cEventNum] = get_autoCorrelogramEvents_trials(alignedData_allTrials,...
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
	    elseif strcmpi('stimName', varargin{ii})
            stimName = varargin{ii+1};
	    elseif strcmpi('stimEventCat', varargin{ii})
            stimEventCat = varargin{ii+1};
	    elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1};
	    end
	end


	% Filter the trials using stimulation name if it is not empty
	if ~isempty(stimName)
		stimNames = {alignedData.stim_name};
		stimNames_tf = strcmpi(stimNames,stimName);
		alignedData = alignedData(find(stimNames_tf));
	end


	% Create an empty structure to store the ACG_events (auto-correlogram events) from each trial
	if ~isempty(stimEventCat)
		getStimEvents = true;
		% stimEventsFieldName = sprintf('%s_%s',stimName,stimEventCat);
		% stimEventsFieldName = strrep(stimEventsFieldName, '-', '_');    % replace '-' with ''
		% stimEventsFieldName = strrep(stimEventsFieldName, ' ', '_');   % replace ' ' with '_'

		stimEventsFieldName = sprintf('%sEvents',stimEventCat);
		stimEventsFieldName = strrep(stimEventsFieldName, '-', '_');    % replace '-' with '_'
		ACG_events_structFields = {'trialName','stimName','sponEvents',stimEventsFieldName};
	else
		getStimEvents = false;
		ACG_events_structFields = {'trialName','sponEvents'};
	end


	% loop through trials and get the ACG_events
	trialNum = numel(alignedData);
	ACG_events_struct = empty_content_struct(ACG_events_structFields,trialNum);
	cEventSponTotalNum = 0; % number of spontaneous center events.
	cEventStimTotalNum = 0; % number of stimulation related center events.
	for n = 1:trialNum
		% Fill the trial name field
		ACG_events_struct(n).trialName = alignedData(n).trialName;

		if debugMode
			fprintf('trial %g/%g: %s\n',n,trialNum,ACG_events_struct(n).trialName);
		end

		% Get the stimulation windows and recording timeInfo. Use them to get non-stim windows
		recTime = alignedData(n).fullTime; % recording timestamps
		if ~isempty(stimName)
			stimWins = alignedData(n).stimInfo.UnifiedStimDuration.range;
			[~,sponWins,~,stimDuration,sponDuration] = get_condition_win(stimWins,recTime,...
				'exclude_duration',excludOGpost);
		else
			sponWins = [recTime(1) recTime(end)];
		end

		% Get the ACG_events from every ROI
		ROIinfo = alignedData(n).traces;
		ROInum = numel(ROIinfo);
		ACG_events_spon_ROIs = cell(1,ROInum);
		ACG_events_stim_ROIs = cell(1,ROInum);
		for rn = 1:ROInum
			if debugMode
				fprintf('	- roi %g/%g: %s\n',rn,ROInum,ROIinfo(rn).roi);
			end

			eventSpecTable = ROIinfo(rn).eventProp;

			% get the ACG events for spontaneous events
			[ACG_events_spon_ROIs{rn},cEventSponNum] = get_autoCorrelogramEvents_roi(eventSpecTable,...
				'win_range',sponWins,'timeType',timeType,...
				'preEventDuration',preEventDuration,'postEventDuration',postEventDuration,...
				'remove_centerEvents',remove_centerEvents);
			cEventSponTotalNum = cEventSponTotalNum+cEventSponNum;

			% get the ACG events for stimulation related ones
			if getStimEvents
				[ACG_events_stim_ROIs{rn},cEventStimNum] = get_autoCorrelogramEvents_roi(eventSpecTable,...
					'cat_keywords',{stimEventCat},'timeType',timeType,...
					'preEventDuration',preEventDuration,'postEventDuration',postEventDuration,...
					'remove_centerEvents',remove_centerEvents);
				cEventStimTotalNum = cEventStimTotalNum+cEventStimNum;
			end
		end
		ACG_events_struct(n).sponEvents = [ACG_events_spon_ROIs{:}];
		if getStimEvents
			ACG_events_struct(n).stimName = stimName;
			ACG_events_struct(n).(stimEventsFieldName) = [ACG_events_stim_ROIs{:}];
		end
	end

	cEventTotalNum.sponEvents = cEventSponTotalNum;
	cEventTotalNum.(stimEventsFieldName) = cEventStimTotalNum;
	varargout{1} = cEventTotalNum;
	% varargout{1} = cEventSponTotalNum;
	% varargout{2} = cEventStimTotalNum;
end