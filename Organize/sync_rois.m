function [alignedData_TrialSeries_sync,varargout] = sync_rois(alignedData_TrialSeries,varargin)
    % Sync the rois in series trials (Same FOV, same ROI set)
    % This code is only compatible with alignedData var format

    % alignedData_TrialSeries: structure var containing a single series of trials
    
    % Defaults

    % Optionals for inputs
    % for ii = 1:2:(nargin-1)
    % 	if strcmpi('trans', varargin{ii})
    % 		trans = varargin{ii+1};
    % 	elseif strcmpi('keep_rowNames', varargin{ii})
    % 		keep_rowNames = varargin{ii+1};
    % 	elseif strcmpi('keep_colNames', varargin{ii})
    % 		keep_colNames = varargin{ii+1};
    %     elseif strcmpi('RowNameField', varargin{ii})
    %         RowNameField = varargin{ii+1};
    %     end
    % end

    %% main contents
    % find the ROIs existing in all trials
    trial_num = numel(alignedData_TrialSeries); %number of trials in this series
    roi_cells = cell(1,trial_num); % cell array to store the ROI names from each trial

    for tn = 1:trial_num
        roi_cells{tn} = {alignedData_TrialSeries(tn).traces.roi}; % all ROI names from a single trial
        if tn == 1
            ROI_intersect = roi_cells{tn};
        else
            ROI_intersect = intersect(ROI_intersect,roi_cells{tn});
        end
    end

    % Creat alignedData_TrialSeries_sync
    alignedData_TrialSeries_sync = alignedData_TrialSeries;
    for tn = 1:trial_num
        [C, ia, ib] = intersect(roi_cells{tn}, ROI_intersect);
        alignedData_TrialSeries_sync(tn).traces = alignedData_TrialSeries(tn).traces(ia);
    end

    varargout{1} = ROI_intersect; % names of ROIs exsisting in all series trials
    varargout{2} = numel(ROI_intersect); % number of synced ROIs
end

