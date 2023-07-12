function [intData,varargout] = stimEventSponEventIntAnalysis(alignedData,stimName,stimEventCat,varargin)
	% Caclulate the interval-1 between stim-related events and following events (usually spontaneous
	% event) and the interval-2 between spontaneous events. Compare interval-1 and -2

	% alignedData: get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'
	% stimEventCat: such as 'trig', 'rebounds', etc.

	% Defaults
	% stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	eventTimeType = 'peak_time'; % rise_time/peak_time
	followEventCat = 'spon';
	filters = [1 nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

	maxDiff = 5; % the max difference between the stim-related and the following events

	plotUnitWidth = 0.4;
	plotUnitHeight = 0.4;
	columnLim = 2;

	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('filters', varargin{ii})
	        filters = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('followEventCat', varargin{ii})
	        followEventCat = varargin{ii+1}; 
	    elseif strcmpi('eventTimeType', varargin{ii})
	        eventTimeType = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('maxDiff', varargin{ii})
	        maxDiff = varargin{ii+1};
        elseif strcmpi('debugMode', varargin{ii})
	        debugMode = varargin{ii+1};
	    end
	end

	% filter the alignedData with stimName
	stimNameAll = {alignedData.stim_name};
	stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
	alignedDataFiltered = alignedData(stimPosIDX);


	% filter the ROIs using filters
	[alignedDataFiltered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedDataFiltered,...
		'stim_names',stimName,'filters',filters);


	% loop through recordings
	recNum = numel(alignedDataFiltered);
	intDataCell = cell(1,recNum);
	for n = 1:recNum
		recData = alignedDataFiltered(n);
		recName = recData.trialName;

		if debugMode
			fprintf('recording %g/%g: %s\n',n,recNum,recName)
			if n == 5
				pause
			end
		end

		if ~isempty(recData.traces)

			% Get the stimulation-related events and the first following events after them in ROIs
			[stimFollowEventsPair] = getStimEventFollowEventROI(recData,stimEventCat,followEventCat,...
				'maxDiff',maxDiff,'eventTimeType',eventTimeType);

			% Get the the intervals between spontaneous events in all the ROIs in a recording
			[sponEventInt] = getSponEventsInt(recData,...
				'maxDiff',maxDiff,'followEventCat',followEventCat,'eventTimeType',eventTimeType);

			% combine the fields from 'stimFollowEventsPair' and 'sponEventInt'
			[eventInt] = combineStuctFields(stimFollowEventsPair,sponEventInt);

			% loop through the ROIs. Make some further calculation and mark the empty ROIs 
			roiDisIDX = [];
			for rn = 1:numel(eventInt)
				if isempty(eventInt(rn).stimFollowDiffTime) || isempty(eventInt(rn).sponEventsTimeIntMean)
					roiDisIDX = [roiDisIDX rn];
				else
					% calculate the mean value of stimFollowDiffTime for a ROI
					% eventInt(rn).stimFollowDiffTimeROI = mean(eventInt(rn).stimFollowDiffTime);

					eventInt(rn).stimFollowVSsponInt = eventInt(rn).stimFollowDiffTimeROI-eventInt(rn).sponEventsTimeIntMean;
				end
			end

			% discard the ROIs marked in roiDisIDX
			eventInt(roiDisIDX) = [];

			% add recording name to eventInt
			[eventInt.recName] = deal(recName);
			intDataCell{n} = eventInt;
		end
	end

	% find the empty cells in intDataCell and delete them
	emptyRecTF = cellfun(@(x) isempty(x),intDataCell);
	emptyRecIDX = find(emptyRecTF);
	intDataCell(emptyRecIDX) = [];

	% concatenate eventInt from all recordings
	intData = horzcat(intDataCell{:});



	% Create figure canvas
	titleStr = sprintf('stimEvent-followEvent-diff vs sponEvent-int [%s %s maxDiff-%gs]',...
		stimName,stimEventCat,maxDiff);
	[f,f_rowNum,f_colNum] = fig_canvas(4,'unit_width',plotUnitWidth,'unit_height',plotUnitHeight,...
		'column_lim',columnLim,'fig_name',titleStr); % create a figure
	tlo = tiledlayout(f,f_rowNum,f_colNum);



	% compare the mean values of each ROI. Paired data
	eventTimeDiffMean.stimAndFollowIntROI = [intData.stimFollowDiffTimeROI];
	eventTimeDiffMean.sponIntROI = [intData.sponEventsTimeIntMean];
	% eventTimeDiffMean.statName = 'paired ttest';

	% paired ttest
	pttest.name = 'paired ttest';
	[pttest.h,pttest.p] = ttest(eventTimeDiffMean.stimAndFollowIntROI,eventTimeDiffMean.sponIntROI);
	eventTimeDiffMean.pttest = pttest;
	pttestTable = struct2table(eventTimeDiffMean.pttest);

	% plot mean value data
	ax = nexttile(tlo);
	gca;
	violinplot(eventTimeDiffMean);

	% plot paired ttest table
	ax = nexttile(tlo);
	plotUItable(gcf,gca,pttestTable);




	% Plot all event intervals
	eventTimeDiff.stimAndFollowInt = [intData.stimFollowDiffTime];
	% eventTimeDiff.stimAndFollowInt = horzcat(intData.stimFollowDiffTime);
	sponIntCell = cellfun(@(x) horzcat(x{:}),{intData.sponEventsTimeInt},'UniformOutput',false);
	eventTimeDiff.sponInt = horzcat(sponIntCell{:});

	% un-paired ttest
	upttest.name = 'two-sample ttest';
	[upttest.h,upttest.p] = ttest2(eventTimeDiff.stimAndFollowInt,eventTimeDiff.sponInt);
	eventTimeDiff.upttest = upttest;
	ttestTable = struct2table(eventTimeDiff.upttest);

	% plot mean value data
	ax = nexttile(tlo);
	gca;
	violinplot(eventTimeDiff);

	% plot paired ttest table
	ax = nexttile(tlo);
	plotUItable(gcf,gca,ttestTable);

	sgtitle(titleStr);



	varargout{1} = eventTimeDiffMean;
	varargout{2} = eventTimeDiff;
	varargout{3} = f;
	varargout{4} = titleStr;
end