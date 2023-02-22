function [roi_tauInfo,varargout] = get_decayCurveTau(alignedData_trials,varargin)
	% Collect mean tau of decay during stimulation from all ROIs

	% Defaults
	filter_roi_tf = false; % do not filter ROIs by default

	stimName = 'og-5s';
	stimEffect_filter = [0 nan nan]; % [ex in rb]. ex: excitation. in: inhibition. rb: rebound
	rsquare_thresh = 0.7;

	norm_FluorData = false; % true/false. whether to normalize the FluroData

	save_fig = false; % Do not save figures by default
	gui_save = 'off'; % Do not use gui to save
	save_dir = '';

	debug_mode = false;

	% Optionals
	for ii = 1:2:(nargin-1)
	    if strcmpi('filter_roi_tf', varargin{ii})
	        filter_roi_tf = varargin{ii+1}; % number array. An index of ROI traces will be collected 
	    elseif strcmpi('stimName', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	        stimName = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    % elseif strcmpi('stim_effect_filter', varargin{ii}) % trace mean value comparison (stim vs non stim). output of stim_effect_compare_trace_mean_alltrial
	    %     stim_effect_filter = varargin{ii+1}; % normalize every FluoroData trace with its max value
	    elseif strcmpi('stimEffect_filter', varargin{ii})
            stimEffect_filter = varargin{ii+1};
	    elseif strcmpi('rsquare_thresh', varargin{ii})
            rsquare_thresh = varargin{ii+1};
	    elseif strcmpi('save_fig', varargin{ii})
            save_fig = varargin{ii+1};
	    elseif strcmpi('gui_save', varargin{ii})
            gui_save = varargin{ii+1};
	    elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
	    elseif strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
	    end
	end

	% ====================
	% Get trials applied with specified stimulation (use 'stimName')
	trial_stimNames = {alignedData_trials.stim_name}; % Get stimulation names from all trials
	tf_stimName = strcmpi(trial_stimNames,stimName); % Compare the stim names with the specified one
	alignedData_trials = alignedData_trials(tf_stimName); % Keep the trials applied with the specified stimulation


	% Filter the ROIs in trials using the stimulation effect (Optional)
	if filter_roi_tf
		[alignedData_trials] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData_trials,...
			'stim_names',stimName,'filters',stimEffect_filter);
	end 


	% Go through every ROI in every trial and get the decay tau
	trial_num = numel(alignedData_trials); 
	roi_tauInfo_cell = cell(1,trial_num);
	for tn = 1:trial_num
		% Get the data for curve fitting: timeData, timeRanges for curvefitting, 
		trialName = alignedData_trials(tn).trialName(1:15); % yyyymmdd-hhmmss
		[timeData,FluroData] = get_TrialTraces_from_alignedData(alignedData_trials(tn),...
			'norm_FluorData',norm_FluorData); 
		timeRanges = alignedData_trials(tn).stimInfo.UnifiedStimDuration.range;

		% Go through ROIs in a single trial and get the decay curve fitting information
		roi_num = numel(alignedData_trials(tn).traces);
		roi_tauInfo_cell{tn} = empty_content_struct({'trialName','roiName','yfit','tauInfo','tauMean'});
		for rn = 1:roi_num
			roiName = alignedData_trials(tn).traces(rn).roi;
			roi_FluroData = FluroData(:,rn);
			roi_eventTime = [alignedData_trials(tn).traces(rn).eventProp.rise_time];  
			[curvefit,tauInfo] = GetDecayFittingInfo_neuron(timeData,roi_FluroData,...
				timeRanges,roi_eventTime,rsquare_thresh);
			% Add decay tau to alignedData structure
			alignedData_trials(tn).traces(rn).tauInfo = tauInfo;

			% Create a new structure containing ROI names, their trial name, curvefit info, and mean tau for
			% output
			roi_tauInfo_cell{tn}(rn).trialName = trialName;
			roi_tauInfo_cell{tn}(rn).roiName = roiName;
			roi_tauInfo_cell{tn}(rn).yfit = curvefit;
			roi_tauInfo_cell{tn}(rn).tauInfo = tauInfo;
			roi_tauInfo_cell{tn}(rn).tauMean = tauInfo.mean;
		end
	end
	roi_tauInfo = [roi_tauInfo_cell{:}];

	varargout{1} = alignedData_trials;

end


