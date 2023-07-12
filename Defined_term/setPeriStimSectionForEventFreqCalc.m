function [periStimEdges,varargout] = setPeriStimSectionForEventFreqCalc(timeInfo,stimInfo,varargin)
	% Set the section edges in a peri-stimulation window. 

	% So far, only support the single or the 2-stim composite stimulation
	% One stimulation is inside of another

	% timeInfo: full time information
	% stimInfo: content in a single entry of aliignedDta.stimInfo

	% Defaults
	preStimDuration = 5;
	postStimDuration = 10;

	PeriBaseRange = [-preStimDuration -2];
	% stimEffectStart = 'start'; % Use this to set the start for the stimulation effect range
	stimEffectDuration = 1; % unit: second. Use this to set the end for the stimulation effect range

	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-2)
	    if strcmpi('preStimDuration', varargin{ii})
	        preStimDuration = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('postStimDuration', varargin{ii})
	        postStimDuration = varargin{ii+1}; 
	    elseif strcmpi('PeriBaseRange', varargin{ii})
	        PeriBaseRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stimEffectDuration', varargin{ii})
	        stimEffectDuration = varargin{ii+1};
        % elseif strcmpi('fname', varargin{ii})
	    %     fname = varargin{ii+1};
	    end
	end

	% check the stimulation info and decide the section numbers accordingly
	stimDurationStruct = stimInfo.StimDuration;
	stimRepeatNum = stimInfo.UnifiedStimDuration.repeats;

	% periPreStimRange = cell(1,numel(stimDurationStruct));
	% periPostStimRange = cell(1,numel(stimDurationStruct));

	stimRangeAlignedAll = vertcat(stimInfo.StimDuration.range_aligned);
	[stimStartSort, stimStartSortIDX] = sort(stimRangeAlignedAll(:,1)); 
	[stimEndSort, stimEndSortIDX] = sort(stimRangeAlignedAll(:,2)); 

	stimStartSecIDX = [];

	if numel(stimDurationStruct) > 1
		compStim = true; % multiple stimulation form a composite stimulation
		sectionEdgesNum = 8;

		% create the output var and fill it with nan
		periStimEdges = NaN(stimRepeatNum,sectionEdgesNum);


		% 4th edge:use the second stim start  
		periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(end)).range(:,1);

		% 5th edge: use the secondStimStart + stimEffectDuration  
		periStimEdges(:,5) = stimDurationStruct(stimStartSortIDX(end)).range(:,1)+stimEffectDuration;

		% 6th edge: use the firstStimEnd   
		periStimEdges(:,6) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);

		% 7th edge: use the firstStimEnd + stimEffectDuration   
		periStimEdges(:,7) = stimDurationStruct(stimStartSortIDX(1)).range(:,2)+stimEffectDuration;

		% list the section edge using stimulation start;
		stimStartSecIDX = [stimStartSecIDX 4];
	else
		compStim = false;
		if stimDurationStruct.fixed < stimEffectDuration
			sectionEdgesNum = 5;
			% create the output var and fill it with nan
			periStimEdges = NaN(stimRepeatNum,sectionEdgesNum);

			% % 4th edge:use the stimStart+  postStimDuration
			% periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+stimEffectDuration;
		else
			sectionEdgesNum = 7;
			% create the output var and fill it with nan
			periStimEdges = NaN(stimRepeatNum,sectionEdgesNum);

			% % 4th edge:use the stimStart+  postStimDuration
			% periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+stimEffectDuration;

			% 5th edge:use the stimEnd
			periStimEdges(:,5) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);

			% 6th edge:stimEnd +  postStimDuration
			periStimEdges(:,6) = stimDurationStruct(stimStartSortIDX(1)).range(:,2)+stimEffectDuration;

		end

		% 4th edge:use the stimStart +  postStimDuration
		periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+stimEffectDuration;

	end

	% 1st edge: firstStimStart-preStimDuration.
	periStimEdges(:,1) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)-preStimDuration;

	% 2nd edge: baseline end as the second edge
	periStimEdges(:,2) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+PeriBaseRange(2);

	% 3rd edge: use the first stim start 
	periStimEdges(:,3) = stimDurationStruct(stimStartSortIDX(1)).range(:,1);

	% final edge: use the firstStimEnd + postStimDuration
	periStimEdges(:,end) = stimDurationStruct(stimStartSortIDX(1)).range(:,2)+postStimDuration;


	% list the section edge using stimulation start;
	stimStartSecIDX = [stimStartSecIDX 3];


	% % Find the closest value in the timeInfo
	% for sn = 1:size(periStimEdges,2)
	% 	[periStimEdges(:,sn),closestIndex] = find_closest_in_array(periStimEdges(:,sn),timeInfo);

	% end
	% periStimEdges = reshapt(periStimEdges,1,[]);
	% closestIndex = reshapt(closestIndex,1,[]);

	varargout{1} = stimRepeatNum;
end

