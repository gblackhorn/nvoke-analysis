function [varargout] = get_baseline_change(stimRange,timeInfo,roiTrace,varargin)
	% Return baseChange and alignedTrace  

	% varargout{1} = baseChange. Change of calcium level during stim (relative to baseline prior to stim)
	% varargout{2} = alignedTrace. Traces aligned to stimulation onset.

	% stimRange: a n x 2 array. n is the repeat times of a stim in a trial
	% timeInfo: time information for a single trial recording
	% roiTrace: trace data for a single roi. It has the same length as the timeInfo

	% Defaults
	base_timeRange = 2; % default 2s. 
	postStim_timeRange = 2; % default 2s.
    stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended

	% Optionals
	for ii = 1:2:(nargin-3)
	    if strcmpi('base_timeRange', varargin{ii})
	        base_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
	    elseif strcmpi('postStim_timeRange', varargin{ii})
	        postStim_timeRange = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stim_time_error', varargin{ii})
	        stim_time_error = varargin{ii+1};
	    end
	end	

	%% Content
	stimRange(:,1) = stimRange(:,1)-stim_time_error; 
	stimRange(:,2) = stimRange(:,2)+stim_time_error;

	repeatNum = size(stimRange,1);
	freq = round(1/(timeInfo(10)-timeInfo(9))); % recording frequency
	stimDur = stimRange(1,2)-stimRange(1,1); % unit: second

	datapointNum_stim = round(stimDur*freq);
	datapointNum_base = round(base_timeRange*freq);
	datapointNum_postStim = round(postStim_timeRange*freq);
	datapointNum = datapointNum_base+datapointNum_stim+datapointNum_postStim;
	alignedTrace_raw = NaN(datapointNum, repeatNum);
	alignedTrace_yAlign = NaN(datapointNum, repeatNum); % subtract mean value of baseline (baseVal)

	[stimOnset,stimOnset_loc] = find_closest_in_array(stimRange(:,1), timeInfo); 

	% idx in roiTrace
	data_start = stimOnset_loc-datapointNum_base; 
	data_end = stimOnset_loc+datapointNum_stim-1+datapointNum_postStim; 

	% idx of data in aligned traces
	range_base = [1,datapointNum_base];
	range_stim = [(datapointNum_base+1),(datapointNum_base+datapointNum_stim)];
	range_postStim = [(range_stim+1),(range_stim+datapointNum_postStim)];

	% mean value during/around one stimulation repeat
	meanVal.baseVal = NaN(1, repeatNum);
	meanVal.stimVal = NaN(1, repeatNum);
	meanVal.stimVal_norm = NaN(1, repeatNum);
	meanVal.stimVal_delta = NaN(1, repeatNum); % delta/baseVal
	meanVal.stimMinVal = NaN(1, repeatNum);
	meanVal.stimMinVal_norm = NaN(1, repeatNum);
	meanVal.stimMinVal_delta = NaN(1, repeatNum);
	meanVal.postStimVal = NaN(1, repeatNum); 

	for rn = 1:repeatNum
		alignedTrace_raw(:,rn) = roiTrace(data_start(rn):data_end(rn));
		meanVal.baseVal(rn) = mean(alignedTrace_raw(range_base(1):range_base(2),rn)); 
		meanVal.stimVal(rn) = mean(alignedTrace_raw(range_stim(1):range_stim(2),rn)); 
		meanVal.stimVal_norm(rn) = meanVal.stimVal(rn)/meanVal.baseVal(rn); 
		meanVal.stimVal_delta(rn) = (meanVal.stimVal(rn)-meanVal.baseVal(rn))/meanVal.baseVal(rn); 
		meanVal.stimMinVal(rn) = min(alignedTrace_raw(range_stim(1):range_stim(2),rn)); 
		meanVal.stimMinVal_norm(rn) = meanVal.stimMinVal(rn)/meanVal.baseVal(rn); 
		meanVal.stimMinVal_delta(rn) = (meanVal.stimMinVal(rn)-meanVal.baseVal(rn))/meanVal.baseVal(rn); 
		meanVal.postStimVal(rn) = mean(alignedTrace_raw(range_postStim(1):range_postStim(2),rn)); 
		alignedTrace_yAlign(:,rn) = alignedTrace_raw(:,rn)-meanVal.baseVal(rn);
	end

	% average value of all stim repeats
	baseChange.Change_norm = mean(meanVal.stimVal_norm); 
	baseChange.Change_delta = mean(meanVal.stimVal_delta);

	% average value of all stim repeats (use the minimum value in the stim range)
	baseChange.ChangeMin_norm = mean(meanVal.stimMinVal_norm); % 
	baseChange.ChangeMin_delta = mean(meanVal.stimMinVal_delta);

	baseChange.stimInfo.freq = freq;
	baseChange.stimInfo.baseDur = base_timeRange;
	baseChange.stimInfo.stimDur = stimDur;
	baseChange.stimInfo.postStimDur = postStim_timeRange;

	alignedTrace.timeInfo = [(0-datapointNum_base/freq):1/freq:(datapointNum_stim-1+datapointNum_postStim)/freq]';
	alignedTrace.raw = alignedTrace_raw;
	alignedTrace.yAlign = alignedTrace_yAlign; % subtrace baseVal(s) from trace(s). 

	varargout{1} = baseChange; 
	varargout{2} = alignedTrace; % 
end