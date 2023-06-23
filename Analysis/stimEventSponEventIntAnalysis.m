function [varargout] = stimEventSponEventIntAnalysis(alignedData,stimName,stimEventCat,varargin)
	% Caclulate the interval-1 between stim-related event and spontaneous event 
	% and the interval-2 between spontaneous events. Compare interval-1 and -2

	% alignedData: get this using the function 'get_event_trace_allTrials'
	% stimName: stimulation name, such as 'og-5s', 'ap-0.1s', or 'og-5s ap-0.1s'

	% Defaults
	% stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = [1 nan nan nan]; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG
	debugMode = false; % true/false

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('filters', varargin{ii})
	        filters = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    % elseif strcmpi('postStimDuration', varargin{ii})
	    %     postStimDuration = varargin{ii+1}; 
	    % elseif strcmpi('plot_raw_races', varargin{ii})
	    %     plot_raw_races = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('eventCat', varargin{ii})
	    %     eventCat = varargin{ii+1};
        % elseif strcmpi('fname', varargin{ii})
	    %     fname = varargin{ii+1};
	    end
	end


	% filter the alignedData with stimName
	stimNameAll = {alignedData.stim_name};
	stimPosIDX = find(cellfun(@(x) strcmpi(stimName,x),stimNameAll));
	alignedDataFiltered = alignedData(stimPosIDX);


	% filter the ROIs using filters
	[alignedDataFiltered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
		'stim_names',stim_names,'filters',filters);



	% loop through recordings
	recNum = numel(alignedDataFiltered)
	intData = cell(recNum,1);
	for n = 1:recNum
		recData = alignedDataFiltered(n);
		
	end

end