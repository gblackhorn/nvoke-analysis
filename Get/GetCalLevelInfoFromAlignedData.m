function [CaLevelData,varargout] = GetCalLevelInfoFromAlignedData(alignedData_allTrials,stim_name)
    % Get x&y-aligned (y aligned at the baseline, x aligned at the onset of stim) calcium signal
    % traces and the aligned time info from alignedData_allTrials. Specify the trials with one content in the field stim_name

    
    % Defaults
    norm2hpStd = true;


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

    n_num = empty_content_struct({'recList','recNum','roiNum','stimNum'},1); 
    n_num(1).recList = {alignedData_filtered.trialName};
    n_num(1).recList = n_num(1).recList(:); % ensure it's vertical
    n_num(1).recNum = alignedData_filtered_num;
    n_num.roiNum = 0;

    psth_timeinfo = alignedData_filtered(1).timeCaLevel;

    % Pre-allocate RAM for vars
    psth_ca_val = cell(1,alignedData_filtered_num);
    recNamesCell = cell(1,alignedData_filtered_num); % Rec name strings. One cell contains recNames for all stim repeats from all rois in a single recording
    roiNamesCell = cell(1,alignedData_filtered_num); % ROI name strings. One cell: all stim repeats from all rois in a single rec
    for an = 1:alignedData_filtered_num
        recName = extractDateTimeFromFileName(alignedData_filtered(an).trialName);
        trial_data = alignedData_filtered(an).traces;
        roiNum = numel(trial_data);
        n_num.roiNum = n_num.roiNum+roiNum;

        psth_ca_val_trial = cell(1,roiNum);
        roiNamesInOneRoi = cell(1,roiNum); % Each cell: Roi names for all stim repeats in a single roi
        for rn = 1:roiNum
            roiName = alignedData_filtered(an).traces(rn).roi;
            psth_ca_val_trial{rn} = alignedData_filtered(an).traces(rn).CaLevelTrace;

            % STD of highpass-filtered trace data
            hpStd = alignedData_filtered(an).traces(rn).hpStd;

            if norm2hpStd
                psth_ca_val_trial{rn} = psth_ca_val_trial{rn}./hpStd;
            end

            roiNamesInOneRoi{rn} = repmat({roiName},1,size(psth_ca_val_trial{rn},2));
        end
        psth_ca_val{an} = [psth_ca_val_trial{:}];
        roiNamesCell{an} = [roiNamesInOneRoi{:}];
        recNamesCell{an} = repmat({recName},1,numel(roiNamesCell{an}));
    end
    all_psth_ca_val = [psth_ca_val{:}];
    % CaLevelData = empty_content_struct({'time','data'},1);
    CaLevelData.time = psth_timeinfo;
    CaLevelData.data = all_psth_ca_val;
    CaLevelData.recTags = [recNamesCell{:}];
    CaLevelData.roiTags = [roiNamesCell{:}];
    CaLevelData.recRoiTags = cellfun(@(r, n) [r, ' ', n], CaLevelData.recTags, CaLevelData.roiTags, 'UniformOutput', false);

    n_num.stimNum = size(all_psth_ca_val,2);

    varargout{1} = n_num; % trial, roi, and stimulation numbers
end

