function [alignedData_sync,varargout] = sync_rois_multiseries(alignedData,varargin)
    % Recognize the serieses in alignedData, and ync the rois in series trials (Same FOV, same ROI set)
    % This code is only compatible with alignedData var format

    % alignedData: structure var containing multiple seriese of trials (Same FOV, same ROI set)
    
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
    [sNum,sTrialIDX] = get_series_trials_structVer(alignedData);

    series_cell = cell(1, sNum);
    ROIs = cell(1,sNum);
    ROIs_num = NaN(1,sNum);
    for sn = 1:sNum
        series_data = alignedData(sTrialIDX{sn});
        [series_cell{sn},ROIs{sn},ROIs_num] = sync_rois(series_data);
    end
    alignedData_sync = [series_cell{:}];
    varargout{1} = ROIs; % ROI sets for each series. 1 cell 1 series
    varargout{2} = ROIs_num; % number of ROIs in each series
end

