function [stimEventCatPairs,varargout] = setStimEventCatPairs(stimDurationStruct,varargin)
    % This function stores the pairs of stimulations and their related event category

    % stimDurationStruct: alignedData_allTrials(n).stimInfo.StimDuration  

    % These pairs can be used to find the correct stimulation for calculating
    % the event delay if combined stimulations are used



    % Defaults

    % Get the event cateogry name information by calling function 'set_CatNames_for_mod_cat_name.m'
    [cat_setting] = set_CatNames_for_mod_cat_name('event');
    eventCatNames = cat_setting.cat_names; % event category names. Defaults: {'spon', 'trig', 'trig-AP', 'opto-delay', 'rebound'};

	% Optionals
	% for ii = 1:2:(nargin-2)
	%     if strcmpi('errCali', varargin{ii})
	%         errCali = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
    %     elseif strcmpi('eventType', varargin{ii})
	%         eventType = varargin{ii+1};
	%     end
	% end	


	% Get the stimulation type(s)
	stimTypes = {stimDurationStruct.type};
	stimDurationFieldNames = fieldnames(stimDurationStruct);


	% Check if the stimulation use multiple types
	stimTypeNum = numel(stimDurationStruct);
	if stimTypeNum > 1
		combinedStim = true;
	else
		combinedStim = false;
	end


	% Get the event name numbers
	eventNameNum = numel(eventCatNames);


	% Create an empty structure to store the stimulation related event and stimulation category pairs
	stimEventCatPairs = empty_content_struct({'eventName','stimCategoty','stimRanges','stimDurInfo'},...
		eventNameNum);


	for n = 1:eventNameNum
		stimEventCatPairs(n).eventName = eventCatNames{n};
		if combinedStim
			% Get the index of stimulation duration info for optogenetics (og) and airpuff (ap)
			ogIDX = find(strcmpi(stimTypes,'og'));
			apIDX = find(strcmpi(stimTypes,'ap'));

			if strcmpi(eventCatNames{n},'spon')
				stimEventCatPairs(n).stimCategoty = '';
				stimEventCatPairs(n).stimRanges = [];
				stimEventCatPairs(n).stimDurInfo = empty_content_struct(stimDurationFieldNames,0);
			elseif strcmpi(eventCatNames{n},'trig-AP')
				stimEventCatPairs(n).stimCategoty = stimDurationStruct(apIDX).type;
				stimEventCatPairs(n).stimRanges = stimDurationStruct(apIDX).range;
				stimEventCatPairs(n).stimDurInfo = stimDurationStruct(apIDX);
			else
				stimEventCatPairs(n).stimCategoty = stimDurationStruct(ogIDX).type;
				stimEventCatPairs(n).stimRanges = stimDurationStruct(ogIDX).range;
				stimEventCatPairs(n).stimDurInfo = stimDurationStruct(ogIDX);
			end
		else
			if strcmpi(eventCatNames{n},'spon')
				stimEventCatPairs(n).stimCategoty = '';
				stimEventCatPairs(n).stimRanges = [];
				stimEventCatPairs(n).stimDurInfo = empty_content_struct(stimDurationFieldNames,0);
			else
				stimEventCatPairs(n).stimCategoty = stimDurationStruct.type;
				stimEventCatPairs(n).stimRanges = stimDurationStruct.range;
				stimEventCatPairs(n).stimDurInfo = stimDurationStruct;
			end
		end
	end
end

