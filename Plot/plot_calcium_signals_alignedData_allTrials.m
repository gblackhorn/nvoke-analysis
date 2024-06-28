function [varargout] = plot_calcium_signals_alignedData_allTrials(alignedData, varargin)
    % Plot calcium fluorescence as traces and color, and plot calcium events using scatter
    % for multiple trials. Use alignedData (a structure var) acquired from function 
    % "get_event_trace_allTrials"

    % Example:
    %   plot_calcium_signals_alignedData_allTrials(alignedData, 'filter_roi_tf', true, 'norm_FluorData', true);

     % Input parser
     p = inputParser;

     % Required input
     addRequired(p, 'alignedData', @isstruct);

     % Optional parameters with default values
     addParameter(p, 'filter_roi_tf', false, @islogical);
     addParameter(p, 'stim_names', {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}, @iscell);
     addParameter(p, 'filters', {[nan 1 nan], [1 nan nan], [nan nan nan]}, @iscell);
     addParameter(p, 'event_type', 'peak_time', @ischar);
     addParameter(p, 'norm_FluorData', false, @islogical);
     addParameter(p, 'sortROI', false, @islogical);
     addParameter(p, 'preTime', 0, @isnumeric);
     addParameter(p, 'postTime', [], @isnumeric);
     addParameter(p, 'activeHeatMap', true, @islogical);
     addParameter(p, 'stimEvents', struct('stimName', {'og-5s', 'ap-0.1s', 'og-5s ap-0.1s'}, 'eventCat', {'rebound', 'trig', 'rebound'}), @isstruct);
     addParameter(p, 'followDelayType', 'stimEvent', @ischar);
     addParameter(p, 'eventsTimeSort', 'off', @ischar);
     addParameter(p, 'plot_unit_width', 0.4, @isnumeric);
     addParameter(p, 'plot_unit_height', 0.4, @isnumeric);
     addParameter(p, 'show_colorbar', true, @islogical);
     addParameter(p, 'hist_binsize', 5, @isnumeric);
     addParameter(p, 'xtickInt_scale', 5, @isnumeric);
     addParameter(p, 'save_fig', false, @islogical);
     addParameter(p, 'save_dir', '', @ischar);
     addParameter(p, 'debug_mode', false, @islogical);
     addParameter(p, 'plot_marker', true, @islogical); % Added plot_marker
     addParameter(p, 'colorLUT', 'turbo', @ischar); % 'turbo' ,'magentaMap', 'cyanMap'
     addParameter(p, 'pick', nan, @isnumeric); % Added pick
     addParameter(p, 'title_prefix', '', @ischar); % Added title_prefix
     addParameter(p, 'gui_save', 'off', @ischar); % Added gui_save

    % Parse inputs
    parse(p, alignedData, varargin{:});

    % Assign parsed values to variables
    filter_roi_tf = p.Results.filter_roi_tf;
    stim_names = p.Results.stim_names;
    filters = p.Results.filters;
    event_type = p.Results.event_type;
    norm_FluorData = p.Results.norm_FluorData;
    sortROI = p.Results.sortROI;
    preTime = p.Results.preTime;
    postTime = p.Results.postTime;
    activeHeatMap = p.Results.activeHeatMap;
    stimEvents = p.Results.stimEvents;
    followDelayType = p.Results.followDelayType;
    eventsTimeSort = p.Results.eventsTimeSort;
    plot_unit_width = p.Results.plot_unit_width;
    plot_unit_height = p.Results.plot_unit_height;
    show_colorbar = p.Results.show_colorbar;
    hist_binsize = p.Results.hist_binsize;
    xtickInt_scale = p.Results.xtickInt_scale;
    save_fig = p.Results.save_fig;
    save_dir = p.Results.save_dir;
    debug_mode = p.Results.debug_mode;
    plot_marker = p.Results.plot_marker; % Added plot_marker
    colorLUT = p.Results.colorLUT; % Added colorLUT
    pick = p.Results.pick; % Added pick
    title_prefix = p.Results.title_prefix; % Added title_prefix
    gui_save = p.Results.gui_save; % Added gui_save

    % ====================
    % Main contents

    % Filter the ROIs in all trials using the stimulation effect
    if filter_roi_tf
        [alignedData_filtered] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
            'stim_names', stim_names, 'filters', filters);
        title_prefix = 'filtered';
    else
        alignedData_filtered = alignedData;
        title_prefix = '';
    end 

    % Get the save location with UI if save_fig is true
    if save_fig
        save_dir = uigetdir(save_dir, 'Choose a folder to save plots');
        if save_dir == 0
            error('Folder for saving figures is not selected')
        end
    end

    % Plot for each trial
    trial_num = numel(alignedData_filtered);
    for tn = 1:trial_num
        pause_plot = true;
        close all

        if debug_mode
            fprintf('trial %d/%d: %s\n', tn, trial_num, alignedData_filtered(tn).trialName)
            if tn == 17
                pause
            end
        end

        % Get the stimulation patch info for plotting the shades to indicate stimulation
        [patchCoor, stimTypes, stimTypeNum] = get_TrialStimPatchCoor_from_alignedData(alignedData_filtered(tn));
        stimInfo = alignedData_filtered(tn).stimInfo;

        % Filter ROIs if 'pick' is input as varargin
        trace_event_data = alignedData_filtered(tn).traces; % roi names, calcium fluorescence data, events' time info are all in the field 'traces'

        % Get the ROI names
        originRowNames = {alignedData_filtered(tn).traces.roi};
        roiNum = numel(alignedData_filtered(tn).traces);
        eventsTime = cell(roiNum, 1);
        eventCat = cell(roiNum, 1);
        for rn = 1:roiNum
            eventsTime{rn} = [alignedData_filtered(tn).traces(rn).eventProp.peak_time];
            eventCat{rn} = {alignedData_filtered(tn).traces(rn).eventProp.peak_category};
        end

        % Get the time information and traces
        [timeData, FluroData, FluroDataDecon] = get_TrialTraces_from_alignedData(alignedData_filtered(tn),...
            'norm_FluorData', norm_FluorData); 

        if ~isempty(FluroData)
            % Get the events' time
            [event_riseTime] = get_TrialEvents_from_alignedData(alignedData_filtered(tn), 'rise_time');
            [event_peakTime] = get_TrialEvents_from_alignedData(alignedData_filtered(tn), 'peak_time');
            [event_eventCat] = get_TrialEvents_from_alignedData(alignedData_filtered(tn), 'peak_category');

            % Calculate the numbers of events in each roi and sort the order of roi according to this (descending)
            if sortROI
                eventNums = cellfun(@(x) numel(x), event_riseTime);
                [~, descendIDX] = sort(eventNums, 'descend');
                originRowNames = originRowNames(descendIDX);
                FluroData = FluroData(:, descendIDX);
                FluroDataDecon = FluroDataDecon(:, descendIDX);
                event_riseTime = event_riseTime(descendIDX);
                event_peakTime = event_peakTime(descendIDX);
                event_eventCat = event_eventCat(descendIDX);
            end

            if strcmpi(event_type, 'rise_time')
                eventTime = event_riseTime;
            elseif strcmpi(event_type, 'peak_time')
                eventTime = event_peakTime;
            end

            if ~activeHeatMap || isempty(stimEvents)  % no filter for stimEvents (~activeHeatMap) or the information of stim and related events are missing
                StimEventsTime = NaN;
                followEventsTime = NaN;
            else
                % find the location of trial stim name in the stimEvents.stimName
                stimEventsIDX = find(strcmpi({stimEvents.stimName}, alignedData_filtered(tn).stim_name));
                if ~isempty(stimEventsIDX)
                    eventCat = stimEvents(stimEventsIDX).eventCat;
                    eventCatFollow = stimEvents(stimEventsIDX).eventCatFollow; 
                    stimRefType = stimEvents(stimEventsIDX).stimRefType; 
                    eventsIDX = cellfun(@(x) find(strcmpi(x, eventCat)), event_eventCat, 'UniformOutput', false);
                    followEventCatIDX = cellfun(@(x) find(strcmpi(x, eventCatFollow)), event_eventCat, 'UniformOutput', false); % the index of events with eventCatFollow
                    followEventIDX = cellfun(@(x) x+1, eventsIDX, 'UniformOutput', false); % the index of events after the stim-related events

                    % get the stimEventTime for each roi
                    StimEventsTime = cell(size(eventsIDX));
                    followEventsTime = cell(size(eventsIDX));
                    for rn = 1:numel(trace_event_data)
                        StimEventsTime{rn} = eventTime{rn}(eventsIDX{rn});
                        eventNumROI = numel(eventTime{rn}); % number of stim events in the current ROI

                        if ~isempty(followEventCatIDX{rn})
                            for m = 1:numel(followEventIDX{rn})
                                if isempty(find(followEventCatIDX{rn} == followEventIDX{rn}(m)))
                                    followEventIDX{rn}(m) = NaN;
                                    followEventsTime{rn}(m) = NaN;
                                else
                                    followEventsTime{rn}(m) = eventTime{rn}(followEventIDX{rn}(m));
                                end
                            end
                        end
                    end
                else
                    eventCat = '';
                    eventCatFollow = '';
                    stimRefType = 'start';
                    StimEventsTime = NaN;
                    followEventsTime = NaN;
                    activeHeatMap = false;
                end
            end

            % Compose the stem part of figure title
            trialName = alignedData_filtered(tn).trialName(1:15); % Get the date (yyyymmdd-hhmmss) part from trial name
            stimName = alignedData_filtered(tn).stim_name; % Get the stimulation name
            if ~isempty(title_prefix)
                title_prefix = sprintf('%s ', title_prefix); % add a space after the title_prefix in increase the readability when combine with other strings
            end
            title_str_stem = sprintf('%s %s', trialName, stimName); % compose a stem str used for both fig 1 and 2
            fig_title = cell(1, 3);

            % Figure 1: Plot the calcium fluorescence as traces and color (2 plots)
            if norm_FluorData
                norm_str = 'norm';
            else
                norm_str = '';
            end
            if sortROI
                sortStr = 'eventNumSorted';
            else
                sortStr = '';
            end
            fig_title{1} = sprintf('%s %s fluorTrace %s', title_str_stem, norm_str, sortStr); % Create the title string
            f(1) = fig_canvas(2, 'unit_width', plot_unit_width, 'unit_height', plot_unit_height,...
                'column_lim', 1, 'fig_name', fig_title{1}); % create a figure
            tlo = tiledlayout(f(1), 3, 1); % setup tiles
            ax = nexttile(tlo, [2, 1]); % activate the ax for trace plot
            plot_TemporalData_Trace(gca, timeData, FluroData, 'yData2', FluroDataDecon,...
                'ylabels', originRowNames, 'plot_marker', plot_marker,...
                'marker1_xData', event_peakTime, 'marker2_xData', event_riseTime, 'shadeData', patchCoor);
            trace_xlim = xlim;
            nexttile(tlo); % activate the ax for color plot
            plot_TemporalData_Color(gca, FluroData', 'rowNames', originRowNames, 'x_window', trace_xlim, 'show_colorbar', show_colorbar);
            sgtitle(fig_title{1})
            set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output

            % Figure 2: Plot the calcium events as scatter and show the events number in a histogram (2 plots)
            fig_title{2} = sprintf('%s event [%s] rasterAndHist %s', title_str_stem, event_type, sortStr);
            fig_title{2} = strrep(fig_title{2}, '_', '');
            f(2) = plot_raster_with_hist(eventTime, trace_xlim, 'shadeData', patchCoor,...
                'rowNames', originRowNames, 'hist_binsize', hist_binsize, 'xtickInt_scale', xtickInt_scale,...
                'titleStr', fig_title{2});
            sgtitle(fig_title{2})
            set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output

            % Figure 3: Plot a color plot. Difference between this one and the one in figure 1 is every
            % ROI trace is cut to several sections using stimulation repeat. One row contains the start
            % of stim to the start of the next stim. Each ROI contains the stim repeat number of rows
            fig_title{3} = sprintf('%s %s periStimColorMap %s stimEventsDelaySort-%s',...
                title_str_stem, norm_str, sortStr, eventsTimeSort); % Create the title string

            f(3) = plot_TemporalData_Color_seperateStimRepeats(gca, FluroData, timeData, stimInfo,...
                'preTime', preTime, 'postTime', postTime, 'stimRefType', stimRefType,...
                'eventsTime', eventTime, 'eventsTimeSort', eventsTimeSort, 'markEvents', plot_marker,...
                'roiNames', originRowNames, 'show_colorbar', show_colorbar, 'titleStr', fig_title{3},...
                'colorLUT', colorLUT, 'debug_mode', debug_mode); % ,'shadeData', patchCoor,'stimTypes', stimTypes
            sgtitle(fig_title{3})
            set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output

            fig_title{4} = sprintf('%s %s periStimColorMap %s firstSponAfterStimDelaySort-%s',...
                title_str_stem, norm_str, sortStr, eventsTimeSort); % Create the title string
            f(4) = plot_TemporalData_Color_seperateStimRepeats(gca, FluroData, timeData, stimInfo,...
                'preTime', preTime, 'postTime', postTime, 'stimRefType', stimRefType,...
                'eventCat', event_eventCat, 'eventsTime', eventTime, 'eventsTimeSort', eventsTimeSort,...
                'stimEventCat', eventCat, 'followEventCat', eventCatFollow, 'markEvents', plot_marker,...
                'roiNames', originRowNames, 'show_colorbar', show_colorbar, 'titleStr', fig_title{4},...
                'colorLUT', colorLUT, 'debug_mode', debug_mode); % ,'shadeData', patchCoor,'stimTypes', stimTypes
            sgtitle(fig_title{4})
            set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output

            % Save figures
            fig_num = numel(f);
            if save_fig
                for fn = 1:fig_num
                    if isempty(save_dir)
                        gui_save = 'on';
                    end
                    msg = 'Choose a folder to save calcium traces and events plots';
                    savePlot(f(fn), 'save_dir', save_dir, 'guiSave', gui_save,...
                        'guiInfo', msg, 'fname', fig_title{fn});
                end
                close all
            end
        end

        if save_fig
            pause_plot = false;
        end
        if pause_plot
            pause
        end
    end

    varargout{1} = save_dir;    
end



