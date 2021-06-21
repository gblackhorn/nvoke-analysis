function [group_idx,varargout] = freq_analysis_group_events(aligned_event_time,edges,varargin)
    % Return the indices of the groups, defined by "edges", that contain the elements of aligned_event_time.
    %   trial_data: a cell array containing information of 1 single trial 
    %	stimulation_win: 2-col number array. lower bounds are the starts of windows, and upper bounds are the ends
    %   recording_time: single column array from decon or raw data   
    % Note: peak info from lowpassed data is used
    % example: 
    % [event_histcounts,setting,event_info_high_freq_rois,spont_freq_hist] = freq_analysis_histogram(recdata_organized,...
    %   'sortout_event', 'peak', 'nbins', 40, 'min_spont_freq', 0.05);


    % group data
    group_idx = discretize(aligned_event_time, edges);
    group_num = length(edges)-1;

    if nargin>2 % varargin exists
        val_num = length(varargin);
        grouped_val = cell(val_num, group_num);
        grouped_val_num = zeros(1, group_num);
        for n = 1:group_num
            event_idx = find(group_idx==n);
            grouped_val_num(n) = length(event_idx);
            for vn = 1:val_num
                grouped_val{vn, n} = varargin{vn}(event_idx);
            end
        end
        grouped_val_mean = cellfun(@mean, grouped_val);
        grouped_val_std = cellfun(@std, grouped_val);
        grouped_val_ste = grouped_val_std./sqrt(grouped_val_num);
    end

   
    varargout{1} = grouped_val_mean';
    varargout{2} = grouped_val_ste;
    varargout{3} = grouped_val_num;
    varargout{4} = grouped_val_std;
end