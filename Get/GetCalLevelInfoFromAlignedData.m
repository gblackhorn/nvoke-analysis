function [CaLevelData,varargout] = GetCalLevelInfoFromAlignedData(alignedData_allTrials,stim_name)
    % Get x&y-aligned (y aligned at the baseline, x aligned at the onset of stim) calcium signal
    % traces and the aligned time info from alignedData_allTrials. Specify the trials with one content in the field stim_name

    
    % Defaults


    % Optionals for inputs
    % for ii = 1:2:(nargin-2)
    % 	if strcmpi('ref_idx', varargin{ii})
    % 		ref_idx = varargin{ii+1}; % input should be an numeric array
    % 	elseif strcmpi('newF_prefix', varargin{ii})
    % 		newF_prefix = varargin{ii+1};
    % 	elseif strcmpi('newF_suffix', varargin{ii})
    % 		newF_suffix = varargin{ii+1};
    %     % elseif strcmpi('RowNameField', varargin{ii})
    %     %     RowNameField = varargin{ii+1};
    %     end
    % end

    %% main contents
    stim_names = {alignedData_allTrials.stim_name};
    chosen_trial_idx = find(strcmpi(stim_names,stim_name));
    alignedData_filtered = alignedData_allTrials(chosen_trial_idx);
    alignedData_filtered_num = numel(alignedData_filtered);

    n_num = empty_content_struct({'trial_list','trial_num','roi_num','stim_num'},1); 
    n_num(1).trial_list = {alignedData_filtered.trialName};
    n_num(1).trial_list = n_num(1).trial_list(:);
    n_num(1).trial_num = alignedData_filtered_num;
    n_num.roi_num = 0;

    psth_timeinfo = alignedData_filtered(1).timeCaLevel;
    psth_ca_val = cell(1,alignedData_filtered_num);
    for an = 1:alignedData_filtered_num
        trial_data = alignedData_filtered(an).traces;
        roi_num = numel(trial_data);
        n_num.roi_num = n_num.roi_num+roi_num;
        psth_ca_val_trial = cell(1,roi_num);
        for rn = 1:roi_num
            psth_ca_val_trial{rn} = alignedData_filtered(an).traces(rn).CaLevelTrace;
        end
        psth_ca_val{an} = [psth_ca_val_trial{:}];
    end
    all_psth_ca_val = [psth_ca_val{:}];
    CaLevelData = empty_content_struct({'time','data'},1);
    CaLevelData(1).time = psth_timeinfo;
    CaLevelData(1).data = all_psth_ca_val;
    n_num.stim_num = size(all_psth_ca_val,2);

    varargout{1} = n_num; % trial, roi, and stimulation numbers
end

