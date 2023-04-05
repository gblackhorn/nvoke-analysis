function [eventIntAll,varargout] = get_eventTimeInt(alignedData,eventType,varargin)
	%Get the event time and calculate their intervals 

	% intervals are calculated in each ROI, and the data from all ROIs from all trials are concatenated

	% eventType: 'rise_time', 'peak_time'



	% Defaults
	filter_roi_tf = false; % do not filter ROIs by default
	stim_names = {'og-5s','ap-0.1s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
	filters = {[nan 1 nan], [1 nan nan], [nan nan nan]}; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound

	% xlabelStr = '';
	% ylabelStr = 'Probability Density';
	% titleStr = 'Hist with PDF';

	% fontSize_tick = 12;
	% fontSize_label = 14;
	% fontSize_title = 16;

	% Optionals
	for ii = 1:2:(nargin-2)
		if strcmpi('filter_roi_tf', varargin{ii})
		    filter_roi_tf = varargin{ii+1}; % number array. An index of ROI traces will be collected 
		elseif strcmpi('stim_names', varargin{ii})
		    stim_names = varargin{ii+1}; % number array. An index of ROI traces will be collected 
		elseif strcmpi('filters', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
		    filters = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    % elseif strcmpi('xlabelStr', varargin{ii})
        %     xlabelStr = varargin{ii+1};
	    % elseif strcmpi('ylabelStr', varargin{ii})
        %     ylabelStr = varargin{ii+1};
	    % elseif strcmpi('titleStr', varargin{ii})
        %     titleStr = varargin{ii+1};
	    end
	end

	% Filter alignedData using stimulation names (optional) and stimulation effect (optional)
	if filter_roi_tf
		[alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
			'stim_names',stim_names,'filters',filters);
	end 



	% Loop through trials
	trialNum = numel(alignedData);
	eventIntTrials = cell(1,trialNum);
	for tn = 1:trialNum
		% get the events time (rise or peak) from all ROIs in a single trial
		eventsTime = get_TrialEvents_from_alignedData(alignedData(tn),eventType);
		
		% calculate the event intervals
		eventsInt = cellfun(@(x) diff(x),eventsTime,'UniformOutput',false);

		% concatenate ROIs' event intervals 
		eventIntTrials{tn} = [eventsInt{:}];
	end


	% Concatenate data
	eventIntAll = [eventIntTrials{:}];
end