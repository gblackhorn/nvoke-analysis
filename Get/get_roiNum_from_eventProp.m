function [TrialRoiList,varargout] = get_roiNum_from_eventProp(eventProp,varargin)
    % Creat a list that involves trial, roi names, number of roi from the information in eventProp
    % The TrialRoiList will be used to count ROI numbers

    % eventProp: a structure variable containing event properties 
    debug_mode = false; % true/false

    for ii = 1:2:(nargin-2)
        if strcmpi('debug_mode', varargin{ii})
            debug_mode = varargin{ii+1};
        % elseif strcmpi('norm_par_suffix', varargin{ii})
        %     norm_par_suffix = varargin{ii+1};
        end
    end

    %% main contents
    trial_names = {eventProp.trialName};
    trial_unique = unique(trial_names);
    trial_num = numel(trial_unique);
    neuron_num = 0;
    trial_roi_list = empty_content_struct({'trialName','roi_list','roi_num','neg_roi_list','neg_roi_num'},trial_num);
    for tn = 1:trial_num
    	if debug_mode
    		fprintf('[get_roiNum_from_eventProp] trial (%d/%d): %s\n',tn,trial_num,trial_unique{tn});
    	end

    	tf_trial = strcmp(trial_names,trial_unique{tn});
    	idx_trial = find(tf_trial);
    	trial_eventProp = eventProp(idx_trial);
    	roi_unique = unique({trial_eventProp.roiName});
    	roi_num = numel(roi_unique);
    	neuron_num = neuron_num+roi_num;

    	TrialRoiList(tn).trialName = trial_unique{tn};
    	TrialRoiList(tn).roi_list = roi_unique;
    	TrialRoiList(tn).roi_num = roi_num;
    end
    varargout{1} = trial_num;
    varargout{2} = sum([TrialRoiList.roi_num]);
end

