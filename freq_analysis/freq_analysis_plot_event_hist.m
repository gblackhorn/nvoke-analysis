function [varargout] = freq_analysis_plot_event_hist(event_hist_val,event_hist_edge,event_info_table,setting,varargin)
    % Plot histogram of event number/frequency
    %   event_hist_val: histogram bar values
    %	event_hist_edge: histogram bin edges
    %   event_info_table: table data. output of fun "freq_analysis_events_info_allTrials"    
    %   setting: structure data. containing information of how data was processed, trial name, roi name, etc.

    % % settings

    % Defaults
    stim_name = 'stimulation';
    y_axis = 'Event number';
    SavePlot = false;
    SaveTo = pwd;

    % Optionals
    for ii = 1:2:(nargin-4)
    	if strcmpi('stim_name', varargin{ii})
    		stim_name = varargin{ii+1};
        elseif strcmpi('y_axis', varargin{ii})
            y_axis = varargin{ii+1};
        elseif strcmpi('nbins', varargin{ii})
            nbins = varargin{ii+1};
        elseif strcmpi('SavePlot', varargin{ii})
            SavePlot = varargin{ii+1};
        elseif strcmpi('SaveTo', varargin{ii})
            SaveTo = varargin{ii+1};
        end
    end



    % Main contents
    event_histplot = figure; % histogram of event count and scatter of peak value normalized to highpass std
    % Plot histogram of event count
    hold on
    yyaxis left
    histogram('BinEdges', event_hist_edge, 'BinCounts', event_hist_val);

    axesInfo = gca;
    stim_patch(:, 1) = [0 0 setting.stim_winT setting.stim_winT];
    stim_patch(:, 2) = [axesInfo.YLim(1) axesInfo.YLim(2) axesInfo.YLim(2) axesInfo.YLim(1)];
    connect_order = [1 2 3 4];
    patch('Faces', connect_order, 'Vertices', stim_patch,...
        'FaceColor', '#E895EB', 'EdgeColor', 'none', 'FaceAlpha', 0.5) % mark the stimulation perior
    xlabel('time (s)')
    y_axis = strrep(y_axis, '_', ' ');
    ylabel(y_axis)

    % Plot peak normalized to highpass std on the same figure
    yyaxis right
    sz = 15; % size of each circle
    scatter(event_info_table.event_time_2_stim, event_info_table.peak_mag_norm,...
        sz, 'filled')
    ylabel('Peak norm to highpass-std')
    hold off

    % Add information to title
    unique_rois = unique(event_info_table(:, {'recording_name', 'roi_name'}));
    trial_num = length(unique(unique_rois.recording_name));
    roi_num = size(unique_rois, 1);
    event_num = size(event_info_table, 1);
    event_hist_title = {[stim_name, ' ', y_axis, ' histogram'],...
        ['event time = ', setting.sortout_event, ' time'],...
        [stim_name, ' duration = ', num2str(setting.stim_winT), 's'],...
        ['min spontaneous freq = ', num2str(setting.min_spont_freq), 'Hz'],...
        [num2str(trial_num), ' trials; ', num2str(roi_num), ' ROIs; ', num2str(event_num), ' events']};
    event_hist_title = strrep(event_hist_title, '_', ' ');
    title(event_hist_title)   

    if SavePlot
        figfile = event_hist_title{1, 1};
        figdir = SaveTo;
        fig_fullpath = fullfile(figdir, figfile);
        savefig(gcf, [fig_fullpath, '.fig']);
        saveas(gcf, [fig_fullpath, '.jpg']);
        saveas(gcf, [fig_fullpath, '.svg']);
    end 

    varargout{1} = trial_num;
    varargout{2} = roi_num;
    varargout{3} = event_num;
end