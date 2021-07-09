function [varargout] = freq_analysis_plot_val_bar(meanVal,errorVal,bin_edge,setting,varargin)
    % Bar plot with error bars along time. Grouped by bin edges used in other histogram analysis
    %   meanVal: bar y data
    %   errorVal: error bar data
    %   bin_edge: used to make x data  
    %   setting: structure data. containing information of how data was processed, trial name, roi name, etc.


    % Defaults
    stim_name = 'stimulation';
    y_axis = ' ';
    SavePlot = false;
    SaveTo = pwd;
    if ~isfield(setting, 'sortout_event')
        setting.sortout_event = 'N/A';
    end

    % Optionals
    for ii = 1:2:(nargin-4)
    	if strcmpi('stim_name', varargin{ii})
    		stim_name = varargin{ii+1};
        elseif strcmpi('y_axis', varargin{ii})
            y_axis = varargin{ii+1};
        elseif strcmpi('n_num', varargin{ii})
            n_num = varargin{ii+1};
        elseif strcmpi('trial_num', varargin{ii})
            trial_num = varargin{ii+1};
        elseif strcmpi('roi_num', varargin{ii})
            roi_num = varargin{ii+1};
        elseif strcmpi('event_num', varargin{ii})
            event_num = varargin{ii+1};
        elseif strcmpi('repeats', varargin{ii})
            repeats = varargin{ii+1};
        elseif strcmpi('SavePlot', varargin{ii})
            SavePlot = varargin{ii+1};
        elseif strcmpi('SaveTo', varargin{ii})
            SaveTo = varargin{ii+1};
       end
    end



    % Main contents
    figure;
    % bars
    bin_half_width = (bin_edge(2)-bin_edge(1))/2;
    x = bin_edge(1:(end-1))+bin_half_width;
    bar(x, meanVal, 1) % 1: bar width is 100%, no space between bars

    hold on

    % error bars
    er = errorbar(x, meanVal, errorVal);
    er.Color = [0 0 0];
    er.LineStyle = 'none';  

    

    % stimulation patch
    axesInfo = gca;
    stim_patch(:, 1) = [0 0 setting.stim_winT setting.stim_winT];
    stim_patch(:, 2) = [axesInfo.YLim(1) axesInfo.YLim(2) axesInfo.YLim(2) axesInfo.YLim(1)];
    connect_order = [1 2 3 4];
    patch('Faces', connect_order, 'Vertices', stim_patch,...
        'FaceColor', '#E895EB', 'EdgeColor', 'none', 'FaceAlpha', 0.5) % mark the stimulation perior

    hold off

    % labels and title
    % add n numbers
    if exist('n_num', 'var')
        text(x, meanVal, num2str(n_num'),'vert','bottom','horiz','center'); 
        box off
    end

    xlabel('time (s)')
    y_axis = strrep(y_axis, '_', ' ');
    ylabel(y_axis)
    bar_title = {[stim_name, ' ', y_axis],...
        ['event time = ', setting.sortout_event, ' time'],...
        [stim_name, ' duration = ', num2str(setting.stim_winT), 's'],...
        ['min spontaneous freq = ', num2str(setting.min_spont_freq), 'Hz']};
    % if exist('trial_num', 'var') && exist('roi_num', 'var') && exist('event_num', 'var') 
    %     bar_title = {bar_title,...
    %     [num2str(trial_num), ' trials; ', num2str(roi_num), ' ROIs; ', num2str(event_num), ' events']};
    % end

    if exist('trial_num', 'var') && exist('roi_num', 'var')
        bar_title = [bar_title,...
        [num2str(trial_num), ' trials; ', num2str(roi_num), ' ROIs; ']];
    end
    if exist('event_num', 'var')
        bar_title = [bar_title,...
        [num2str(event_num), ' events']];
    end
    if exist('repeats', 'var')
        bar_title = [bar_title,...
        [num2str(repeats), ' repeatss']];
    end


    bar_title = strrep(bar_title, '_', ' ');
    title(bar_title)

    if SavePlot
        figfile = bar_title{1, 1};
        figdir = SaveTo;
        fig_fullpath = fullfile(figdir, figfile);
        savefig(gcf, [fig_fullpath, '.fig']);
        saveas(gcf, [fig_fullpath, '.jpg']);
        saveas(gcf, [fig_fullpath, '.svg']);
    end

end