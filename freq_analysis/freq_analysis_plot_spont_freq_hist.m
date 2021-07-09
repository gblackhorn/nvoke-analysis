function [varargout] = freq_analysis_plot_spont_freq_hist(spont_freq_hist,event_info_table,setting,varargin)
    % Plot histogram of spontaneous event frequency 
    %   spont_freq_hist: histogram bar values (.counts) and bin edges (.edges)
    %   event_hist_edge: histogram bin edges
    %   event_info_table: table data. output of fun "freq_analysis_events_info_allTrials"  
    %   setting: structure data. containing information of how data was processed, trial name, roi name, etc.


    % Defaults
    stim_name = 'stimulation';
    SavePlot = false;
    SaveTo = pwd;

    % Optionals
    for ii = 1:2:(nargin-3)
    	if strcmpi('stim_name', varargin{ii})
    		stim_name = varargin{ii+1};
        elseif strcmpi('nbins', varargin{ii})
            nbins = varargin{ii+1};
        elseif strcmpi('SavePlot', varargin{ii})
            SavePlot = varargin{ii+1};
        elseif strcmpi('SaveTo', varargin{ii})
            SaveTo = varargin{ii+1};
         end
    end

    % Main contents



    % Add information to title
    unique_rois = unique(event_info_table(:, {'recording_name', 'roi_name'}));
    trial_num = length(unique(unique_rois.recording_name));
    roi_num = size(unique_rois, 1);

    % Plot
    freq_histplot = figure; % histogram of spontaneous frequency of used ROIs
    histogram('BinEdges', spont_freq_hist.edges, 'BinCounts', spont_freq_hist.counts);
    xlabel('Frequency (Hz)')
    ylabel('Number')
    spont_freq_hist_title = {[stim_name, ' Spontaneous event frequency'],...
        ['min spontaneous freq = ', num2str(setting.min_spont_freq), 'Hz'],...
        [num2str(trial_num), ' trials; ', num2str(roi_num), ' ROIs']};
    spont_freq_hist_title = strrep(spont_freq_hist_title, '_', ' ');
    title(spont_freq_hist_title)

    if SavePlot
        figfile = spont_freq_hist_title{1, 1};
        figdir = SaveTo;
        fig_fullpath = fullfile(figdir, figfile);
        savefig(gcf, [fig_fullpath, '.fig']);
        saveas(gcf, [fig_fullpath, '.jpg']);
        saveas(gcf, [fig_fullpath, '.svg']);
    end 
end