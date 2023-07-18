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
	splitLongStim = [1]; % If the stimDuration is longer than stimEffectDuration, the stimDuration 
						%  part after the stimEffectDuration will be splitted. If it is [1 1], the
						% time during stimulation will be splitted using edges below
						% [stimStart, stimEffectDuration, stimEffectDuration+splitLongStim, stimEnd] 

	groupName.base = 'baseline'; % baseline at the very beginning
	groupName.preBase = 'preStim'; % before stimulation and after groupName.base
	groupName.firstStim = 'firstStim'; % start from stimStart and last 'stimEffectDuration'
	groupName.lateFirstStim = 'lateFirstStim'; % after groupName.first/secondStim and before stimEnd
	groupName.postFirstStim = 'postFirstStim'; % from first-stim end and last 'stimEffectDuration'
	groupName.secondStim = 'secondStim'; % start from the second-stim start and last 'stimEffectDuration'
	groupName.baseAfter = 'baseAfter'; % last group for the baseline after the stimulation

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
        elseif strcmpi('splitLongStim', varargin{ii})
	        splitLongStim = varargin{ii+1};
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

		% create a cell array to store the names of groups set by the edges
		periStimGroups = cell(1,(sectionEdgesNum-1));

		% 4th edge:use the second stim start  
		periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(end)).range(:,1);
		periStimGroups{4} = groupName.secondStim;

		% 5th edge: use the secondStimStart + stimEffectDuration  
		periStimEdges(:,5) = stimDurationStruct(stimStartSortIDX(end)).range(:,1)+stimEffectDuration;
		periStimGroups{5} = groupName.lateFirstStim;

		% 6th edge: use the firstStimEnd   
		periStimEdges(:,6) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);
		periStimGroups{6} = groupName.postFirstStim;

		% 7th edge: use the firstStimEnd + stimEffectDuration   
		periStimEdges(:,7) = stimDurationStruct(stimStartSortIDX(1)).range(:,2)+stimEffectDuration;
		periStimGroups{7} = groupName.baseAfter;

		% list the section edge using stimulation start;
		stimStartSecIDX = [stimStartSecIDX 4];
	else
		compStim = false;
		if stimDurationStruct.fixed < stimEffectDuration
			sectionEdgesNum = 5;
			% create the output var and fill it with nan
			periStimEdges = NaN(stimRepeatNum,sectionEdgesNum);

			% create a cell array to store the names of groups set by the edges
			periStimGroups = cell(1,(sectionEdgesNum-1));

			% % 4th edge:use the stimStart+  postStimDuration
			% periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+stimEffectDuration;
		else

			% number of edges during stimulation after the stimEffectDuration. StimEnd is not counted
			lateStimEdgesNum = numel(splitLongStim);

			sectionEdgesNum = 7+lateStimEdgesNum;
			% create the output var and fill it with nan
			periStimEdges = NaN(stimRepeatNum,sectionEdgesNum);

			% create a cell array to store the names of groups set by the edges
			periStimGroups = cell(1,(sectionEdgesNum-1));

			% If the late part of the stimulation will be splitted
			if lateStimEdgesNum > 0
				% check if the last element in splitLongStim is still in the stimDuration
				if stimEffectDuration+splitLongStim(end) >= stimDurationStruct.fixed
					error('the last element in splitLongStim is >= stimDuration, stimWindow cannot be further splitted')
				end

				for n = 1:lateStimEdgesNum
					periStimEdges(:,4+n) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+stimEffectDuration+splitLongStim(n);
					periStimGroups{4+n} = sprintf('%s-%g',groupName.lateFirstStim,n);
				end
			end


			% 3rd last edge:use the stimEnd
			periStimEdges(:,sectionEdgesNum-2) = stimDurationStruct(stimStartSortIDX(1)).range(:,2);
			periStimGroups{sectionEdgesNum-2} = groupName.postFirstStim;

			% 2nd last edge:stimEnd +  postStimDuration
			periStimEdges(:,sectionEdgesNum-1) = stimDurationStruct(stimStartSortIDX(1)).range(:,2)+stimEffectDuration;
			periStimGroups{sectionEdgesNum-1} = groupName.baseAfter;
			% periStimEdges(:,6) = stimDurationStruct(stimStartSortIDX(1)).range(:,2)+stimEffectDuration;

		end

		% 4th edge:use the stimStart +  stimEffectDuration
		periStimEdges(:,4) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+stimEffectDuration;
		periStimGroups{4} = groupName.baseAfter;

	end

	% 1st edge: firstStimStart-preStimDuration.
	periStimEdges(:,1) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)-preStimDuration;
	periStimGroups{1} = groupName.base;

	% 2nd edge: baseline end as the second edge
	periStimEdges(:,2) = stimDurationStruct(stimStartSortIDX(1)).range(:,1)+PeriBaseRange(2);
	periStimGroups{2} = groupName.preBase;

	% 3rd edge: use the first stim start 
	periStimEdges(:,3) = stimDurationStruct(stimStartSortIDX(1)).range(:,1);
	periStimGroups{3} = groupName.firstStim;

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
	varargout{2} = periStimGroups;
end

