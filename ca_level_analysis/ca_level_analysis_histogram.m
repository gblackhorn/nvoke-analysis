function [ca_level_bin,varargout] = ca_level_analysis_histogram(all_trial_data,varargin)
    % Return the peristimulus time histogram from a cell array including 
    % multiple trials using the same kind of stimulation.
    %   all_trial_data: a cell array containing information of multiple trials 
    % Note: peak info from lowpassed data is used
    % example: 
    % [event_histcounts,setting,event_info_high_freq_rois,spont_freq_hist,stim_zscore] = freq_analysis_histogram(recdata_organized,...
    %   'sortout_event', 'peak', 'BinWidth', 1, 'min_spont_freq', 0.05, 'savePlot', save_to_dir);


    % Extract useful info from trial data
    rec_name_col = 1;
    trace_col = 2;
    stim_str_col = 3;
    gpio_col = 4;
    peak_info_col = 5;
    stimulation_win = all_trial_data{1, gpio_col}(3).stim_range; % 3 is the first gpio channel used for stimulation. if 2 stimuli were used, 4 is the second
    
    % settings
    setting.stim_time_error = 0; % due to low temperal resolution and error in lowpassed data, start and end time point of stimuli can be extended
    setting.stim_winT = stimulation_win(1, 2)-stimulation_win(1, 1); % the duration of stimulation 
    setting.rebound_winT = 1; % second. rebound window duration
    % setting.sortout_event = 'rise'; % use rise location to sort peak
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds
    setting.sample_freq = 10; % if recording has different sampling frequency, resample it to this value 
    setting.min_spont_freq = 0; % event will be used for histogram if its ROI spontaneous frequency if higher than this
    setting.BinWidth = 1; % second
    SaveTo = pwd; % save plot to dir
    SavePlot = false;

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	elseif strcmpi('stim_winT', varargin{ii})
    		setting.stim_winT = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
        elseif strcmpi('sample_freq', varargin{ii})
            setting.sample_freq = varargin{ii+1};
        elseif strcmpi('min_spont_freq', varargin{ii})
            setting.min_spont_freq = varargin{ii+1};
        elseif strcmpi('nbins', varargin{ii})
            nbins = varargin{ii+1}; % number of bins for event histogram plots
        elseif strcmpi('BinWidth', varargin{ii})
            setting.BinWidth = varargin{ii+1}; % number of bins for event histogram plots
        elseif strcmpi('SavePlot', varargin{ii})
            SavePlot = varargin{ii+1};
        elseif strcmpi('SaveTo', varargin{ii})
            SaveTo = varargin{ii+1};
        end
    end


    % Main contents
    win_duation = setting.pre_stim_duration+setting.stim_winT+setting.post_stim_duration;

    % extract lowpass trace data around each stimulation
    [ca_level_all_trials,roi_spont_event_all_trials] = ca_level_analysis_events_info_allTrials(all_trial_data,...
        'stim_time_error', setting.stim_time_error, 'stim_winT', setting.stim_winT,...
        'pre_stim_duration', setting.pre_stim_duration, 'post_stim_duration', setting.post_stim_duration,...
        'sample_freq', setting.sample_freq);

    trace_point_number = size(ca_level_all_trials, 2); % number of points in trace
    time_info = (0:trace_point_number)/setting.sample_freq-setting.pre_stim_duration;

    ca_level_idx_high_freq = roi_spont_event_all_trials.spont_event_freq >= setting.min_spont_freq;
    ca_level_high_freq = ca_level_all_trials(ca_level_idx_high_freq, :); % discard traces from ROIs with low spontaneous event freq
    roi_spont_event_high_freq_rois = roi_spont_event_all_trials(ca_level_idx_high_freq, :); % discard traces from ROIs with low spontaneous event freq

    % Get edge idx for bins
    if exist('nbins', 'var')
        edge_interval = (setting.pre_stim_duration+setting.stim_winT+setting.post_stim_duration)/nbins;
        setting.BinWidth = edge_interval;
    else
        edge_interval = setting.BinWidth;
        nbins = round(win_duation/edge_interval);
    end
    time_edge = [-setting.pre_stim_duration:edge_interval:round(setting.stim_winT+setting.post_stim_duration)];
    [edge_exist_log, edge_idx] = ismember(time_edge, time_info); % find time_edge in time_info.
    setting.nbins = nbins;

    ca_level_bin.mean = NaN(1, setting.nbins);
    ca_level_bin.std = NaN(1, setting.nbins);
    ca_level_bin.ste = NaN(1, setting.nbins);
    for bn = 1:setting.nbins
        ca_level_bin_data = ca_level_high_freq(:, edge_idx(bn):edge_idx(bn+1));
        ca_level_bin.mean(bn) = mean(ca_level_bin_data, 'all', 'omitnan');
        ca_level_bin.std(bn) = std(ca_level_bin_data, 0, 'all', 'omitnan');
        ca_level_bin.ste(bn) = ca_level_bin.std(bn)/sqrt(nnz(~isnan(ca_level_bin_data)));
    end

    % Extract information, such as spontaneous events' number and repeat numbers of stim from "event_info_all_trials"
    win_repeat = size(ca_level_high_freq, 1);
    [unique_rois, ia, ic] = unique(roi_spont_event_high_freq_rois(:, {'recording_name', 'roi_name'}), 'rows');
    trial_num = length(unique(unique_rois.recording_name));
    roi_num = size(unique_rois, 1);


    if SavePlot
        figdir = uigetdir(SaveTo,...
            'Select a folder to save figures');
    else
        figdir = SaveTo;
    end
    stim_name = strrep(all_trial_data{1, stim_str_col}{:}, '_', ' '); % replace underscore with space for format in plot title

    freq_analysis_plot_val_bar(ca_level_bin.mean,ca_level_bin.ste,time_edge,setting,...
        'stim_name', stim_name, 'y_axis', 'mean of deltaF/F',...
        'trial_num', trial_num, 'roi_num', roi_num, 'repeats', win_repeat,...
        'SavePlot', SavePlot,'SaveTo', figdir);

    varargout{1} = setting;
    varargout{2} = ca_level_high_freq;
    % varargout{3} = spont_freq_hist;
    % varargout{4} = stim_zscore;
    % varargout{5} = figdir;
end