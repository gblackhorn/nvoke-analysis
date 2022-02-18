function [event_hist,varargout] = freq_analysis_histogram(all_trial_data,varargin)
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
    setting.sortout_event = 'rise'; % use rise location to sort peak
    setting.pre_stim_duration = 10; % seconds
    setting.post_stim_duration = 10; % seconds
    setting.min_spont_freq = 0; % event will be used for histogram if its ROI spontaneous frequency if higher than this
    setting.BinWidth = 1; % second
    SaveTo = pwd; % save plot to dir
    SavePlot = false;

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('stim_time_error', varargin{ii})
    		setting.stim_time_error = varargin{ii+1};
    	% elseif strcmpi('stim_winT', varargin{ii})
    	% 	setting.stim_winT = varargin{ii+1};
    	% elseif strcmpi('rebound_winT', varargin{ii})
    	% 	setting.rebound_winT = varargin{ii+1};
    	elseif strcmpi('sortout_event', varargin{ii})
    		setting.sortout_event = varargin{ii+1};
        elseif strcmpi('pre_stim_duration', varargin{ii})
            setting.pre_stim_duration = varargin{ii+1};
    	elseif strcmpi('post_stim_duration', varargin{ii})
            setting.post_stim_duration = varargin{ii+1};
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
    % Extract information from every single event meeting criteriors
    [event_info_all_trials] = freq_analysis_events_info_allTrials(all_trial_data,...
        'stim_time_error', setting.stim_time_error, 'stim_winT', setting.stim_winT,...
            'sortout_event', setting.sortout_event,...
            'pre_stim_duration', setting.pre_stim_duration, 'post_stim_duration', setting.post_stim_duration);

    event_idx_high_freq_rois = event_info_all_trials.spont_event_freq >= setting.min_spont_freq; % screen event with the roi spontaneous event frequency
    event_info_high_freq_rois = event_info_all_trials(event_idx_high_freq_rois, :);

    event_time_2_stim_combine = [event_info_high_freq_rois.event_time_2_stim_pre; event_info_high_freq_rois.event_time_2_stim_post];


    % Count event time relative to stimulation starting point for histogram plot
    if exist('nbins', 'var')
        [event_hist.counts,event_hist.edges]=histcounts(event_info_high_freq_rois.event_time_2_stim, nbins);
        % [event_hist.counts,event_hist.edges]=histcounts(event_time_2_stim_combine, nbins);
        setting.nbins = nbins;
    else
        [event_hist.counts,event_hist.edges]=histcounts(event_info_high_freq_rois.event_time_2_stim, 'BinWidth', setting.BinWidth);
        % [event_hist.counts,event_hist.edges]=histcounts(event_time_2_stim_combine, 'BinWidth', setting.BinWidth);
        setting.nbins = length(event_hist.counts);
    end

    % Use data before stimulation as baseline and calculate zscore of data during stimulation
    [stim_zscore.val,stim_zscore.significant] = freq_analysis_psth_stat(event_hist.counts,event_hist.edges,...
        'baseline_duration', 5, 'zscore_win', setting.stim_winT);


    % Extract information, such as spontaneous events' number and repeat numbers of stim from "event_info_all_trials"
    [unique_rois, ia, ic] = unique(event_info_high_freq_rois(:, {'recording_name', 'roi_name'}), 'rows');
    [spont_freq_hist.counts,spont_freq_hist.edges]=histcounts(event_info_high_freq_rois.spont_event_freq(ia));

    win_repeat = sum(event_info_high_freq_rois.stim_num_per_roi(ia));
    win_duration = setting.pre_stim_duration+setting.stim_winT+setting.post_stim_duration;
    bin_duration = win_duration/setting.nbins;
    bin_duration_total = bin_duration*win_repeat;
    event_hist.freq = event_hist.counts./bin_duration_total;

    % group data into bins using event_hist.edges
    % [group_idx,grouped_val_mean,grouped_val_ste,grouped_val_num] = freq_analysis_group_events(event_info_high_freq_rois.event_time_2_stim,...
    %     event_hist.edges,event_info_high_freq_rois.peak_mag_norm);
    [group_idx_pre,grouped_val_mean_pre,grouped_val_ste_pre,grouped_val_num_pre] = freq_analysis_group_events(event_info_high_freq_rois.event_time_2_stim_pre,...
        event_hist.edges,event_info_high_freq_rois.peak_mag_norm);
    [group_idx_post,grouped_val_mean_post,grouped_val_ste_post,grouped_val_num_post] = freq_analysis_group_events(event_info_high_freq_rois.event_time_2_stim_post,...
        event_hist.edges,event_info_high_freq_rois.peak_mag_norm);
    grouped_val_mean = [grouped_val_mean_pre(~isnan(grouped_val_mean_pre)), grouped_val_mean_post(~isnan(grouped_val_mean_post))];
    grouped_val_ste = [grouped_val_ste_pre(~isnan(grouped_val_ste_pre)), grouped_val_ste_post(~isnan(grouped_val_ste_post))];
    grouped_val_num = [grouped_val_num_pre(grouped_val_num_pre~=0), grouped_val_num_post(grouped_val_num_post~=0)];


    if SavePlot
        figdir = uigetdir(SaveTo,...
            'Select a folder to save figures');
        if figdir == 0
            fprint('no folder seleted to save figures');
            return
        end
    else
        figdir = SaveTo;
    end
    % plot
    stim_name = strrep(all_trial_data{1, stim_str_col}{:}, '_', ' '); % replace underscore with space for format in plot title
    freq_analysis_plot_event_hist(event_hist.counts,event_hist.edges,event_info_high_freq_rois,setting,...
        'stim_name', stim_name,...
        'SavePlot', SavePlot,'SaveTo', figdir); % event number along histogram
    freq_analysis_plot_event_hist(event_hist.freq,event_hist.edges,event_info_high_freq_rois,setting,...
        'stim_name', stim_name, 'y_axis', 'Event frequency Hz',...
        'SavePlot', SavePlot,'SaveTo', figdir); % event freq along time histogram
    freq_analysis_plot_spont_freq_hist(spont_freq_hist,event_info_high_freq_rois,setting,...
        'stim_name', stim_name,...
        'SavePlot', SavePlot,'SaveTo', figdir); % spontaneous event frequency histogram

    freq_analysis_plot_val_bar(grouped_val_mean,grouped_val_ste,...
        event_hist.edges,setting, 'n_num', grouped_val_num,...
        'stim_name', stim_name, 'y_axis', 'Peal_mag_norm_2_hp_std',...
        'SavePlot', SavePlot,'SaveTo', figdir);

    
    varargout{1} = setting;
    varargout{2} = event_info_high_freq_rois;
    varargout{3} = spont_freq_hist;
    varargout{4} = stim_zscore;
    varargout{5} = figdir;
end