function [alignedData_TrialSeries_sync,varargout] = sync_rois(alignedData_TrialSeries,varargin)
    % Sync the rois in series trials (Same FOV, same ROI set)
    % This code is only compatible with alignedData var format

    % alignedData_TrialSeries: structure var containing a single series of trials
    
    % Defaults
    ref_stim = ''; % stimulation used as the reference. If it is not empty, trials 
                    % using the same ROI set will all synced to the specified stimulation trial
    ref_SpikeCat = {''}; % category of spikes will be kept in ref stim group
    nonref_SpikeCat = {''}; % category of spikes will be kept in non-ref stim group

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('ref_stim', varargin{ii})
    		ref_stim = varargin{ii+1}; % GPIO-1-1s is usually used
    	elseif strcmpi('ref_SpikeCat', varargin{ii})
    		ref_SpikeCat = varargin{ii+1};
    	elseif strcmpi('nonref_SpikeCat', varargin{ii})
    		nonref_SpikeCat = varargin{ii+1};
    %   elseif strcmpi('RowNameField', varargin{ii})
    %         RowNameField = varargin{ii+1};
      end
    end

    %% main contents
    % find the ROIs existing in all trials
    trial_num = numel(alignedData_TrialSeries); %number of trials in this series
    roi_cells = cell(1,trial_num); % cell array to store the ROI names from each trial
    stim_names = {alignedData_TrialSeries.stim_name};

    if ~isempty(ref_stim)
        ref_idx = find(strcmp(ref_stim,stim_names));
        if isempty(ref_idx) || numel(ref_idx)>1
            str_error = sprintf('Func [sync_rois]:\n reference trial (stim: %s) is empty or more than one', ref_stim);
            error(str_error)
        end
        ROI_others = {};
    end

    % Get ROI names from each trial
    for tn = 1:trial_num
        roi_cells{tn} = {alignedData_TrialSeries(tn).traces.roi}; % all ROI names from a single trial
        if isempty(ref_stim)
            if tn == 1
                ROI_intersect = roi_cells{tn};
            else
                ROI_intersect = intersect(ROI_intersect,roi_cells{tn});
            end
        else
            if tn == ref_idx
                ROI_ref = roi_cells{tn}; % ROI names in ref trial
            else
                ROI_others = [ROI_others, roi_cells{tn}];
            end
        end
    end

    if ~isempty(ref_stim)
        ROI_intersect = intersect(ROI_ref, ROI_others);
    end

    % Creat alignedData_TrialSeries_sync
    alignedData_TrialSeries_sync = alignedData_TrialSeries;
    for tn = 1:trial_num
        [C, ia, ib] = intersect(roi_cells{tn}, ROI_intersect);
        alignedData_TrialSeries_sync(tn).traces = alignedData_TrialSeries(tn).traces(ia);

        % filter events according to settings: ref_SpikeCat and nonref_SpikeCat
        if isempty(ref_stim)
            if ~isempty(nonref_SpikeCat)
                SpikeCat_keep = nonref_SpikeCat;
                % [alignedData_eventInfo_filtered] = filter_event_and_trace_in_alignedData(alignedData_TrialSeries_sync(tn).traces,...
                %     'peak_category','tags_keep',nonref_SpikeCat);
            end
        else
            if tn == ref_idx
                SpikeCat_keep = ref_SpikeCat;
            else
                SpikeCat_keep = nonref_SpikeCat;
            end
        end
        [alignedData_TrialSeries_sync(tn).traces] = filter_event_and_trace_in_alignedData(alignedData_TrialSeries_sync(tn).traces,...
            'peak_category','tags_keep',SpikeCat_keep);
    end

    varargout{1} = ROI_intersect; % names of ROIs exsisting in all series trials
    varargout{2} = numel(ROI_intersect); % number of synced ROIs
end

