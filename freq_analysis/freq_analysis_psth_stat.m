function [zscore_val,varargout] = freq_analysis_psth_stat(bin_val,bin_edge,varargin)
    % Return zscores of bins starting from stimulation. Using pre-stim bins as baseline
    %   bin_val: values in bins
    %	bin_edge: edges of bins   
    % Note: peak info from lowpassed data is used
    % example: 
    %   [zscore_val,zscore_significant] = freq_analysis_psth_stat(bin_val,bin_edge,...
    %    'baseline_duration', 5, 'zscore_win', setting.stim_winT);


    % Defaults
    baseline_duration = 5; % second
    stim_bin_end = length(bin_val);
    
    % Optionals
    for ii = 1:2:(nargin-2)
    	if strcmpi('baseline_duration', varargin{ii})
    		baseline_duration = varargin{ii+1};
    	elseif strcmpi('zscore_win', varargin{ii})
    		zscore_win = varargin{ii+1};
    	% % elseif strcmpi('rebound_winT', varargin{ii})
    	% % 	setting.rebound_winT = varargin{ii+1};
    	% elseif strcmpi('sortout_event', varargin{ii})
    	% 	setting.sortout_event = varargin{ii+1};
     %    elseif strcmpi('pre_stim_duration', varargin{ii})
     %        setting.pre_stim_duration = varargin{ii+1};
    	% elseif strcmpi('post_stim_duration', varargin{ii})
     %        setting.post_stim_duration = varargin{ii+1};
     %    elseif strcmpi('min_spont_freq', varargin{ii})
     %        setting.min_spont_freq = varargin{ii+1};
     %    elseif strcmpi('nbins', varargin{ii})
     %        nbins = varargin{ii+1}; % number of bins for event histogram plots
     %    elseif strcmpi('BinWidth', varargin{ii})
     %        setting.BinWidth = varargin{ii+1}; % number of bins for event histogram plots
        end
    end


    % Main contents
    stim_bin_start = find(bin_edge==min(abs(bin_edge)), 1);
    if exist('zscore_win', 'var')
        [M, stim_bin_end_edge_up] = min(abs(bin_edge-zscore_win));
        stim_bin_end = stim_bin_end_edge_up-1;
    end
    [base_bin_start_M, base_bin_start] = min(abs(bin_edge-(-baseline_duration)));
    base_bin_end = stim_bin_start-1;

    baseline_val = bin_val(base_bin_start:base_bin_end);
    baseline_val_mean = mean(baseline_val);
    baseline_val_std = std(baseline_val);

    stim_val = bin_val(stim_bin_start:stim_bin_end);
    zscore_val = (stim_val-baseline_val_mean)./baseline_val_std;

    zscore_significant = zeros(size(zscore_val));
    idx_significant = find(abs(zscore_val) > 2);
    zscore_significant(idx_significant) = 1;

    pre_stim_array = NaN(1, (length(bin_val)-stim_bin_end));
    post_stim_array = NaN(1, (stim_bin_end+1));
    zscore_val = [pre_stim_array zscore_val pre_stim_array];
    zscore_significant = [pre_stim_array zscore_significant pre_stim_array];


    
    varargout{1} = zscore_significant;
    % varargout{2} = event_info_high_freq_rois;
    % varargout{3} = spont_freq_hist;
end