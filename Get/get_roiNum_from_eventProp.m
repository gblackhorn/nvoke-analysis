function [TrialRoiList,varargout] = get_roiNum_from_eventProp(eventProp,varargin)
    % Creat a list that involves trial, roi names, number of roi from the information in eventProp
    % The TrialRoiList will be used to count ROI numbers

    % eventProp: a structure variable containing event properties 

    % for ii = 1:2:(nargin-2)
    %     if strcmpi('par', varargin{ii})
    %         par = varargin{ii+1};
    %     elseif strcmpi('norm_par_suffix', varargin{ii})
    %         norm_par_suffix = varargin{ii+1};
    %     end
    % end

    %% main contents
    trial_names = {eventProp_temp.trialName};
    trial_unique = unique(trial_names);
    trial_num = numel(trial_unique);
    neuron_num = 0;
    trial_roi_list = empty_content_struct({'trialName','roi_list','roi_num','neg_roi_list','neg_roi_num'},trial_num);
    for tn = 1:trial_num
    	tf_trial = strcmp(trial_names,trial_unique{tn});
    	idx_trial = find(tf_trial);
    	trial_eventProp = eventProp_temp(idx_trial);
    	roi_unique = unique({trial_eventProp.roiName});
    	roi_num = numel(roi_unique);
    	neuron_num = neuron_num+roi_num;

    	TrialRoiList(tn).trialName = trial_unique{tn};
    	TrialRoiList(tn).roi_list = roi_unique;
    	TrialRoiList(tn).roi_num = roi_num;
    end
end

