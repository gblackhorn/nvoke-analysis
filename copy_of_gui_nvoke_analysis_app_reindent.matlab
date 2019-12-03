classdef nvoke_plot_app < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        InscopixDataAnalysisLabel    matlab.ui.control.Label
        PlotButtonGroup              matlab.ui.container.ButtonGroup
        StimulationtriggeredresponseButton  matlab.ui.control.RadioButton
        ResponsetriggeredresponseButton  matlab.ui.control.RadioButton
        Button3                      matlab.ui.control.RadioButton
        FiltersPanel                 matlab.ui.container.Panel
        BaselinePanel                matlab.ui.container.Panel
        StablebaselineCheckBox       matlab.ui.control.CheckBox
        RisingbaselineCheckBox       matlab.ui.control.CheckBox
        DeclinebaselineCheckBox      matlab.ui.control.CheckBox
        PeakPanel                    matlab.ui.container.Panel
        nopeakCheckBox               matlab.ui.control.CheckBox
        Peak_1afteronsetofstimulationCheckBox  matlab.ui.control.CheckBox
        Peak_2afterendofstimulationCheckBox  matlab.ui.control.CheckBox
        CalciumindicatorButtonGroup  matlab.ui.container.ButtonGroup
        GCaMP6sButton                matlab.ui.control.RadioButton
        GCaMP6fButton                matlab.ui.control.RadioButton
        StimulationButtonGroup       matlab.ui.container.ButtonGroup
        OptogeneticsOgLEDButton      matlab.ui.control.RadioButton
        AirpufftooneeyeGPIO1Button   matlab.ui.control.RadioButton
        Button3_3                    matlab.ui.control.RadioButton
        DataPanel                    matlab.ui.container.Panel
        ROIdatafileEditFieldLabel    matlab.ui.control.Label
        ROIdatafileEditField         matlab.ui.control.EditField
        ViarablenameLabel            matlab.ui.control.Label
        viarableloadedLabel_name     matlab.ui.control.Label
        BrowseButton_ROIdata         matlab.ui.control.Button
        TabGroup                     matlab.ui.container.TabGroup
        PlotTab                      matlab.ui.container.Tab
        PeakdetectionbinsizesPanel   matlab.ui.container.Panel
        Peak_1afteronsetofstimulationSliderLabel  matlab.ui.control.Label
        Peak_1afteronsetofstimulationSlider  matlab.ui.control.Slider
        Peak_2afterendofstimulationSliderLabel  matlab.ui.control.Label
        Peak_2afterendofstimulationSlider  matlab.ui.control.Slider
        Peak_1_bin_edit              matlab.ui.control.NumericEditField
        Peak_2_bin_edit              matlab.ui.control.NumericEditField
        PlotUpdateButton             matlab.ui.control.Button
        UIAxes_all_traces            matlab.ui.control.UIAxes
        UIAxes_all_traces_mean       matlab.ui.control.UIAxes
        StimulationdurationEdit      matlab.ui.control.NumericEditField
        StimulationdurationsSliderLabel  matlab.ui.control.Label
        StimulationdurationSlider    matlab.ui.control.Slider
        PloteverysinglerecordingsCheckBox  matlab.ui.control.CheckBox
        PauseaftereachsinglerecordingplotCheckBox  matlab.ui.control.CheckBox
        SavesinglerecordingplotsCheckBox  matlab.ui.control.CheckBox
        SavealldataaverageCheckBox   matlab.ui.control.CheckBox
        SaveaverageplotButton        matlab.ui.control.Button
        Table                        matlab.ui.container.Tab
        PlotsinglerecordingPanel     matlab.ui.container.Panel
        FoldertosavePlotsEditFieldLabel  matlab.ui.control.Label
        FoldertosavePlotsEditField   matlab.ui.control.EditField
        BrowseButton_figs            matlab.ui.control.Button
    end

    
    properties (Access = private)
        folder_ROIdata = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data'; % default folder for ROIdata mat files
        folder_plots = 'G:\Workspace\Inscopix_Seagate\Analysis\IO_GCaMP-IO_ChrimsonR-CN_ventral\ROI_data\peaks'; % default folder for ventral approach plots
        lowpass_fpass = 0.1;
        highpass_fpass = 0.1;
        peakinfo_row_name = 'Peak_lowpassed';
        ROIdataVar;
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: BrowseButton_ROIdata
        function BrowseButton_ROIdataPushed(app, event)
            [ROIdata_file, app.folder_ROIdata] = uigetfile([app.folder_ROIdata, '\*.mat'], 'Choose a mat file containing ROIdata'); % input file path info. Choose a motion corrected file
            ROIdataFilepath = fullfile(app.folder_ROIdata, ROIdata_file);
            if ROIdataFilepath ~= 0
                app.ROIdatafileEditField.Value = ROIdataFilepath;
                matObj = matfile(app.ROIdatafileEditField.Value);
                varlist = who(matObj);
                app.ROIdataVar = varlist{1};
                viarableloadedLabel_name.Text = app.ROIdataVar;
            end
        end

        % Button pushed function: PlotUpdateButton
        function PlotUpdateButtonPushed(app, event)
            if isempty(app.ROIdataVar)
                display('Load a mat file containing ROIdata')
            else
                load(app.ROIdatafileEditField.Value); % load data variable 'ROIdata_peakevent'
                switch app.PlotButtonGroup.SelectedObject.Text
                case 'Stimulation triggered response'
                    stimuli_triggered_response = 1;
                    mat_empty = ~cellfun(@isempty,ROIdata_peakevent); % logical array showing emptiness of cells data
                    idx_no_stimuli = find(mat_empty(:, 3)==0);
                    ROIdata_peakevent(idx_no_stimuli, :) = [];
                    switch app.StimulationButtonGroup.SelectedObject.Text
                    case 'Optogenetics (OgLED)'
                        mat_stimuli_type = cellfun(@(x) strcmp('GPIO1', x),ROIdata_peakevent,'UniformOutput',false);
                        idx_GPIO = double(cell2mat(mat_stimuli_type));
                        row_idx_GPIO = find(idx_GPIO(:,3));
                        ROIdata_peakevent(row_idx_GPIO, :) = [];
                        ROIdata = ROIdata_peakevent;

                        
                    case 'Airpuff to one eye (GPIO1)'
                        mat_stimuli_type = cellfun(@(x) strcmp('OG_LED', x),ROIdata_peakevent,'UniformOutput',false);
                        idx_ogled = double(cell2mat(mat_stimuli_type));
                        row_idx_ogled = find(idx_ogled(:,3));
                        ROIdata_peakevent(row_idx_ogled, :) = [];
                        ROIdata = ROIdata_peakevent;
                    end

                    % whether group ROIs according to peak
                    % events
                    check_no_peak = app.nopeakCheckBox.Value;
                    check_quick_peak = app.Peak_1afteronsetofstimulationCheckBox.Value;
                    check_post_peak = app.Peak_2afterendofstimulationCheckBox.Value;
                    
                    % Peak onset criteria
                    duration_quick_peak = app.Peak_1afteronsetofstimulationSlider.Value;
                    duration_after_peak = app.Peak_2afterendofstimulationSlider.Value;
                    
                    % Stimulation duration
                    stimuli_duration = app.StimulationdurationSlider.Value;
                    recording_num = size(ROIdata, 1);
                    for rn = 1:recording_num
                        recording_name = ROIdata{rn, 1};
                        stimulation = ROIdata{rn, 3}{1, 1};
                        channel = ROIdata{rn, 4}; % GPIO channels
                        gpio_signal = cell(1, (length(channel)-2)); % pre-allocate number of stimulation to gpio_signal used to store signal time and value
                        gpio_x = cell(1, (length(channel)-2)); % pre-allocate gpio_x
                        gpio_y = cell(1, (length(channel)-2)); % pre-allocate gpio_y
                        for nc = 1:(length(channel)-2) % number of GPIOs used for stimulation
                            gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
                            gpio_signal{nc}(:, 1) = channel(nc+2).time_value(:, 1); % time value of GPIO signal
                            gpio_signal{nc}(:, 2) = channel(nc+2).time_value(:, 2); % voltage value of GPIO signal
                            gpio_rise_loc = find(gpio_signal{nc}(:, 2)); % locations of GPIO voltage not 0, ie stimuli start
                            gpio_rise_num = length(gpio_rise_loc); % number of GPIO voltage rise
                            
                            % Looking for stimulation groups. Many stimuli are train signal. Ditinguish trains by finding rise time interval >=5s
                            % Next line calculate time interval between to gpio_rise. (Second:End stimuli_time)-(first:Second_last stimuli_time)
                            gpio_rise_interval{nc} = gpio_signal{nc}(gpio_rise_loc(2:end), 1)-gpio_signal{nc}(gpio_rise_loc(1:(end-1)), 1);
                            train_interval_loc{nc} = find(gpio_rise_interval{1, nc} >= 5); % If time interval >=5s, this is between end of a train and start of another train
                            train_end_loc{rn, nc} = [gpio_rise_loc(train_interval_loc{nc}); gpio_rise_loc(end)]; % time of the train_end rises start
                            train_start_loc{rn, nc} = [gpio_rise_loc(1); gpio_rise_loc(train_interval_loc{nc}+1)]; % time of the train_start rises start
                            
                            gpio_train_start_time{rn, nc} = gpio_signal{nc}(train_start_loc{rn, nc}, 1); % time point when GPIO trains start
                            gpio_train_end_time{rn, nc} = gpio_signal{nc}(train_end_loc{rn, nc}+1, 1); % time point when GPIO trains end
                            gpio_train_interval_time(rn, nc) = gpio_train_start_time{rn, nc}(2, 1)-gpio_train_start_time{rn, nc}(1, 1); % between the first train to second train start
                            gpio_train_interval_time(rn, nc) = round(gpio_train_interval_time(rn, nc)); % round the interval to closest integer
                            gpio_train_duration(rn, nc) = gpio_train_end_time{rn, nc}(1, 1)-gpio_train_start_time{rn, nc}(1, 1); % duration of 1 train stimulation
                            gpio_train_duration(rn, nc) = round(gpio_train_duration(rn, nc));
                            
                            % gpio_x = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_x used to plot GPIO with "patch" function
                            % gpio_y = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_y used to plot GPIO with "patch" function
                            for ng = 1:gpio_rise_num % number of GPIO voltage rise, ie stimuli
                                gpio_x{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
                                gpio_x{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
                                gpio_x{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);
                                gpio_x{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);

                                gpio_y{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
                                gpio_y{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
                                gpio_y{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
                                gpio_y{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
                            end
                            ROIdata{rn, 4}(nc+2).time_value_plot(:, 1) = gpio_x; % store continuous gpio_x info in ROIdata channel table. This is for patch plot function
                            ROIdata{rn, 4}(nc+2).time_value_plot(:, 2) = gpio_y; % store continuous gpio_y info in ROIdata channel table.
                            gpio_lim_loc{nc, 1} = find(gpio_y{nc}(:, 1) == 0); % location of gpio voltage ==0 in gpio_y
                            gpio_lim_loc{nc, 2} = find(gpio_y{nc}(:, 1)); % location of gpio voltage ~=0 in gpio_y
                        end
                    end
                    if stimuli_duration ~= 0
                       idx_chosen_stimuli_duration = find(gpio_train_duration(:, 1)==stimuli_duration);
                       ROIdata = ROIdata(idx_chosen_stimuli_duration, :);
                    end

                    % settings for plot and save
                    if app.PloteverysinglerecordingsCheckBox.Value == 1
                        if app.SavesinglerecordingplotsCheckBox.Value == 0
                            plot_traces = 1;
                        else
                            plot_traces = 2;
                        end
                    else
                        plot_traces = 0;
                    end
                    pause_step = app.PauseaftereachsinglerecordingplotCheckBox.Value;

                    % Calculation of ROI data and plot.
                    % Modified from fun 'nvoke_correct_peakdata'
                    if plot_traces == 2
                        if app.folder_plots ~= 0
                            app.folder_plots = uigetdir(app.folder_plots, 'Select a folder to save figures');
                        else
                            app.folder_plots = uigetdir(app.folder_ROIdata, 'Select a folder to save figures');
                        end
                    end
                        
                    chosen_recording_num = size(ROIdata, 1);
                    for rn = 1:chosen_recording_num
                        recording_name = ROIdata{rn, 1};
                        
                        % next lines are used for debug. show file numer and name
                        % rn 
                        % display(recording_name)
                        
                        peakinfo_row = find(strcmp(app.peakinfo_row_name, ROIdata{rn, 5}.Properties.RowNames));
                        recording_rawdata = ROIdata{rn,2};
                        [recording_rawdata, recording_time, roi_num_all] = ROI_calc_plot(recording_rawdata);
                        recording_timeinfo = recording_rawdata{:, 1}; % array not table
                        recording_fr(rn) = round(1/(recording_timeinfo(2)-recording_timeinfo(1)));
                        recording_code = rn;
                        roi_num = size(ROIdata{rn, 5}, 2); % total roi numbers after handpick
                        
                        recording_highpassed = ROIdata{rn,2};
                        recording_thresh = ROIdata{rn,2};
                        recording_lowpassed = ROIdata{rn,2};
                            
                        for roi_n = 1:roi_num
                            roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_n};
                            roi_rawdata_loc = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames));

                            roi_rawdata = recording_rawdata{:, roi_rawdata_loc};
                            roi_lowpasseddata = lowpass(roi_rawdata, app.lowpass_fpass, recording_fr(rn));
                            roi_highpassed = highpass(roi_rawdata, app.highpass_fpass, recording_fr(rn));

                            recording_highpassed{:, roi_rawdata_loc} = roi_highpassed;
                            recording_lowpassed{:, roi_rawdata_loc} = roi_lowpasseddata;

                            thresh = mean(roi_highpassed)+5*std(roi_highpassed);
                            recording_thresh{:, roi_rawdata_loc} = ones(size(recording_timeinfo))*thresh;

                            peak_loc_time = ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_loc_s_'); % peaks' time
                            rise_start_time = ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Rise_start_s_');
                            decay_stop_time = ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Decay_stop_s_');

                            peak_num = length(peak_loc_time);
                            for pn = 1:peak_num
                                [min_peak closestIndex_peak] = min(abs(recording_timeinfo-peak_loc_time(pn)));
                                [min_rise closestIndex_rise] = min(abs(recording_timeinfo-rise_start_time(pn)));
                                [min_decay closestIndex_decay] = min(abs(recording_timeinfo-decay_stop_time(pn)));

                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_loc')(pn) = closestIndex_peak;
                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Rise_start')(pn) = closestIndex_rise;
                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Decay_stop')(pn) = closestIndex_decay;

                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_mag')(pn) = roi_lowpasseddata(closestIndex_peak);
                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Rise_duration_s_')(pn) = peak_loc_time(pn)-rise_start_time(pn);
                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('decay_duration_s_')(pn) = decay_stop_time(pn)-peak_loc_time(pn);

                                peakmag_relative_rise = roi_lowpasseddata(closestIndex_peak)-roi_lowpasseddata(closestIndex_rise);
                                peakmag_relative_decay = roi_lowpasseddata(closestIndex_peak)-roi_lowpasseddata(closestIndex_decay);
                                ROIdata{rn, 5}{peakinfo_row, roi_n}{:, :}.('Peak_mag_relative')(pn) = max(peakmag_relative_rise, peakmag_relative_decay);
                            end
                        end
                        
                        if plot_traces ~= 0
                            % if plot_traces == 1 || 2
                            %   % plot_col_num = ceil(roi_num/5);
                            %   % plot_fig_num = ceil(plot_col_num/2);
                            %   % subplot_multi_factor = 1;
                            %   % close all
                            % elseif plot_traces == 3 || 4
                            plot_col_num = ceil(roi_num/5)*3; % one column of triggered response plot for each 2-column wide original traces
                            plot_fig_num = ceil(plot_col_num/6); % 3 columns for 1 group of data (*5 ROIs)
                            subplot_multi_factor = 3;
                            close all
                            % end

                            if isempty(ROIdata{rn, 3})
                                GPIO_trace = 0; % no stimulation used during recording, don't show GPIO trace
                            else
                                GPIO_trace = 1; % show GPIO trace representing stimulation
                                stimulation = ROIdata{rn, 3}{1, 1};
                                channel = ROIdata{rn, 4}; % GPIO channels
                                gpio_signal = cell(1, (length(channel)-2)); % pre-allocate number of stimulation to gpio_signal used to store signal time and value
                                gpio_x = cell(1, (length(channel)-2)); % pre-allocate gpio_x
                                gpio_y = cell(1, (length(channel)-2)); % pre-allocate gpio_y
                                for nc = 1:(length(channel)-2) % number of GPIOs used for stimulation

                                    gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
                                    gpio_signal{nc}(:, 1) = channel(nc+2).time_value(:, 1); % time value of GPIO signal
                                    gpio_signal{nc}(:, 2) = channel(nc+2).time_value(:, 2); % voltage value of GPIO signal
                                    gpio_rise_loc = find(gpio_signal{nc}(:, 2)); % locations of GPIO voltage not 0, ie stimuli start
                                    gpio_rise_num = length(gpio_rise_loc); % number of GPIO voltage rise

                                    % Looking for stimulation groups. Many stimuli are train signal. Ditinguish trains by finding rise time interval >=5s
                                    % Next line calculate time interval between to gpio_rise. (Second:End stimuli_time)-(first:Second_last stimuli_time)
                                    gpio_rise_interval{nc} = gpio_signal{nc}(gpio_rise_loc(2:end), 1)-gpio_signal{nc}(gpio_rise_loc(1:(end-1)), 1);
                                    train_interval_loc{nc} = find(gpio_rise_interval{1, nc} >= 5); % If time interval >=5s, this is between end of a train and start of another train
                                    train_end_loc{nc} = [gpio_rise_loc(train_interval_loc{nc}); gpio_rise_loc(end)]; % time of the train_end rises start
                                    train_start_loc{nc} = [gpio_rise_loc(1); gpio_rise_loc(train_interval_loc{nc}+1)]; % time of the train_start rises start

                                    gpio_train_start_time{nc} = gpio_signal{nc}(train_start_loc{nc}, 1); % time point when GPIO trains start
                                    gpio_train_end_time{nc} = gpio_signal{nc}(train_end_loc{nc}+1, 1); % time point when GPIO trains end

                                    % gpio_x = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_x used to plot GPIO with "patch" function
                                    % gpio_y = zeros(gpio_rise_num*4, length(channel)-2); % pre-allocate gpio_y used to plot GPIO with "patch" function
                                    for ng = 1:gpio_rise_num % number of GPIO voltage rise, ie stimuli
                                        gpio_x{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
                                        gpio_x{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 1);
                                        gpio_x{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);
                                        gpio_x{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 1);

                                        gpio_y{nc}(1+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
                                        gpio_y{nc}(2+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
                                        gpio_y{nc}(3+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng), 2);
                                        gpio_y{nc}(4+(ng-1)*4, 1) = gpio_signal{nc}(gpio_rise_loc(ng)+1, 2);
                                    end
                                    gpio_lim_loc{nc, 1} = find(gpio_y{nc}(:, 1) == 0); % location of gpio voltage ==0 in gpio_y
                                    gpio_lim_loc{nc, 2} = find(gpio_y{nc}(:, 1)); % location of gpio voltage ~=0 in gpio_y
                                end
                            end

                            for p = 1:plot_fig_num % figure number
                               peak_plot_handle(p) = figure (p);
                               set(gcf, 'Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); % [x y width height]

                               for q = 1:2 % column group num for ROI. When plot_traces=1||2, subplot column = q, when 3||4 subplot column == q*4
                                    if (plot_col_num/subplot_multi_factor-(p-1)*2-q) > 0
                                        last_row = 5;
                                    else
                                        last_row = roi_num-(p-1)*10-(q-1)*5;
                                    end
                                    for m = 1:last_row
                                        % next lines are for debug
                                        % p
                                        % q
                                        % m
                                        % if rn==6 && p==1 && q==1 && m==2
                                            % pause
                                        % end
                                        % ====================
                                        
                                        roi_plot = (p-1)*10+(q-1)*5+m; % the number of roi to be plot
                                        roi_name = ROIdata{rn,5}.Properties.VariableNames{roi_plot}; % roi name ('C0, C1...')
                                        roi_col_loc_data = find(strcmp(roi_name, recording_rawdata.Properties.VariableNames)); % the column number of this roi in recording_rawdata (ROI_table)
                                        roi_col_loc_cal = find(strcmp(roi_name, ROIdata{rn, 5}.Properties.VariableNames)); % the column number of this roi in calculated peak-related info

                                        roi_col_data = recording_rawdata{:, roi_col_loc_data}; % roi data
                                        peak_time_loc = ROIdata{rn, 5}{1, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
                                        peak_value = ROIdata{rn, 5}{1, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

                                        roi_col_data_lowpassed = recording_lowpassed{:, roi_col_loc_data}; % roi data
                                        peak_time_loc_lowpassed{rn, roi_plot} = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_loc_s_'); % peak_loc as time
                                        peak_value_lowpassed{rn, roi_plot} = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Peak_mag'); % peak magnitude

                                        peak_rise_turning_loc{rn, roi_plot} = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Rise_start_s_');
                                        peak_rise_turning_value{rn, roi_plot} = roi_col_data_lowpassed(ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Rise_start'));
                                        peak_decay_turning_loc{rn, roi_plot} = ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Decay_stop_s_');
                                        peak_decay_turning_value{rn, roi_plot} = roi_col_data_lowpassed(ROIdata{rn, 5}{peakinfo_row, (roi_col_loc_cal)}{:, :}.('Decay_stop'));

                                        roi_col_data_highpassed = recording_highpassed{:, roi_col_loc_data}; % roi data
                                        thresh_data = recording_thresh{:, roi_col_loc_data};

                                        % sub_handle(roi_plot) = subplot(6, 2, q+(m-1)*2);
                                        sub_handle(roi_plot) = subplot(6, 8, [(q*4-3)+(m-1)*8, (q*4-3)+(m-1)*8+1]);
                                        plot(recording_timeinfo, roi_col_data, 'k') % plot original data
                                        hold on
                                        % plot(peak_time_loc, peak_value, 'ro', 'linewidth', 2) % plot peak marks
                                        % plot(recording_timeinfo, roi_col_data_highpassed, 'b') % plot highpass filtered data
                                        % plot(recording_timeinfo, thresh_data, '--k'); % plot thresh hold line
                                        plot(recording_timeinfo, roi_col_data_lowpassed, 'm'); % plot lowpass filtered data
                                        % plot(peak_time_loc_lowpassed{rn, roi_plot}, peak_value_lowpassed{rn, roi_plot}, 'yo', 'linewidth', 2) %plot lowpassed data peak marks
                                        % plot(peak_rise_turning_loc{rn, roi_plot}, peak_rise_turning_value{rn, roi_plot}  '>b', peak_decay_turning_loc{rn, roi_plot}, peak_decay_turning_value{rn, roi_plot}, '<b', 'linewidth', 2) % plot start and end of transient, turning point
                                        ylim_gpio = ylim;

                                        if GPIO_trace == 1

                                            gpio_color = {'cyan', 'magenta', 'yellow'};
                                            for ncp = 1:(length(channel)-2) % number of channel plot
                                                % loc_nonzero = find(gpio_y(:, ncp));
                                                gpio_y{ncp}(gpio_lim_loc{ncp, 2} , 1) = ylim_gpio(2); % expand gpio_y upper lim to max of y-axis
                                                % loc_zero = find(gpio_y(:, ncp)==0); % loction of gpio value =0 in gpio_y
                                                gpio_y{ncp}(gpio_lim_loc{ncp, 1} , 1) = ylim_gpio(1); % expand gpio_y lower lim to min of y-axis
                                                patch(gpio_x{ncp}(:, 1), gpio_y{ncp}(:, 1), gpio_color{ncp}, 'EdgeColor', 'none', 'FaceAlpha', 0.7)
                                            end
                                        end
                                    
                                        axis([0 recording_timeinfo(end) ylim_gpio(1) ylim_gpio(2)])
                                        set(get(sub_handle(roi_plot), 'YLabel'), 'String', roi_name);
                                        hold off

                                        first_gpio_train_start_loc = find(gpio_x{1}(:, 1)==gpio_train_start_time{1}(1), 1); % location of first train starts
                                        first_gpio_train_end_loc = find(gpio_x{1}(:, 1)==gpio_train_end_time{1}(1), 1, 'last'); % location of first train ends
                                        gpio_x_trig_plot = gpio_x{1}(first_gpio_train_start_loc:first_gpio_train_end_loc, 1); % gpio_x of the first train
                                        gpio_x_trig_plot = gpio_x_trig_plot-gpio_x_trig_plot(1, 1); % gpio_x starts from 0
                                        gpio_y_trig_plot = gpio_y{1}(first_gpio_train_start_loc:first_gpio_train_end_loc); % gpio_y of the first train

                                        % Plot stimuli triggered response. 
                                        if GPIO_trace == 1
                                            subplot(6, 8, (q*4+(m-1)*8-1)) % plot stimulation triggered responses. All sweeps
                                            pre_stimuli_duration = 3; % duration before stimulation onset
                                            post_stimuli_duration = 6; % duration after stimulation end
                                            baseline_duration = 1; % time duration before stimulation used to calculate baseline for y-axis aligment
                                            pre_stimuli_time = gpio_train_start_time{1}-pre_stimuli_duration; % plot from 3s before stimuli start. The "first GPIO stimuli"
                                            post_stimuli_time = gpio_train_end_time{1}+post_stimuli_duration; % plot until 6s after stimuli end
                                            plot_duration = post_stimuli_time-pre_stimuli_time; % duration of plot
 
                                            patch(gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7)
                                            hold on
 
                                            erase_trace = []; % according to the peak check in the following loop, if trace is not plotted, its data will not be used for all data average neither
                                            plot_trace = 1; % default: plot any stimuli triggered trace. Status will be changed if peak check not pass in the following section
                                            for tn = 1:length(pre_stimuli_time) % number of stimulation trains
                                                % check the existence of peak(s) in "stimuli_onset - peak_1_duration" and in "stimuli_end - peak_2_duration"
                                                if check_no_peak == 1 || check_quick_peak == 1 || check_post_peak == 1
                                                    time_start_peak1_check = gpio_train_start_time{1}(tn);
                                                    time_end_peak1_check = time_start_peak1_check+app.Peak_1_bin_edit.Value;
                                                    time_start_peak2_check = gpio_train_end_time{1}(tn);
                                                    time_end_peak2_check = time_start_peak2_check+app.Peak_2_bin_edit.Value;
                                                    logIdx_peak1 = peak_time_loc_lowpassed{rn, roi_plot}>time_start_peak1_check & peak_time_loc_lowpassed{rn, roi_plot}<time_end_peak1_check;
                                                    logIdx_peak2 = peak_time_loc_lowpassed{rn, roi_plot}>time_start_peak2_check & peak_time_loc_lowpassed{rn, roi_plot}<time_end_peak2_check;
                                                    exist_peak1 = find(logIdx_peak1);
                                                    exist_peak2 = find(logIdx_peak2);
                                                    if check_no_peak == 1
                                                        if ~isempty(exist_peak1) || ~isempty(exist_peak2)
                                                            erase_trace = [erase_trace; tn];
                                                            plot_trace = 0;
                                                        else
                                                            plot_trace =1;
                                                        end
                                                    elseif check_quick_peak == 1 && check_post_peak == 1
                                                        if isempty(exist_peak1) && isempty(exist_peak2)
                                                            erase_trace = [erase_trace; tn];
                                                            plot_trace = 0;
                                                        else
                                                            plot_trace = 1;
                                                        end
                                                    else
                                                        if check_quick_peak == 1
                                                            if isempty(exist_peak1)
                                                                erase_trace = [erase_trace; tn];
                                                                plot_trace = 0;
                                                            else
                                                                plot_trace = 1;
                                                            end
                                                        elseif check_post_peak == 1
                                                            if isempty(exist_peak2)
                                                                erase_trace = [erase_trace; tn];
                                                                plot_trace = 0;
                                                            else
                                                                plot_trace = 1;
                                                            end
                                                        end
                                                    end
                                                end
                                                    
                                                if plot_trace == 1
                                                    [val_min, idx_min] = min(abs(recording_timeinfo-pre_stimuli_time(tn)));
                                                    [val_max, idx_max] = min(abs(recording_timeinfo-post_stimuli_time(tn)));
                                                    recording_timeinfo_trig_plot{rn, roi_plot, tn} = recording_timeinfo(idx_min:idx_max)-gpio_train_start_time{1}(tn);

                                                    idx_min_base = idx_min+recording_fr(rn)*(pre_stimuli_duration-baseline_duration); % loc of first data point of "baseline_duration" before stimulation
                                                    idx_max_base = find((recording_timeinfo-gpio_train_start_time{1}(tn))<0, 1, 'last'); % loc of last data point of "baseline_duration" before stimulation
                                                    roi_col_data_base = mean(roi_col_data(idx_min_base:idx_max_base)); % baseline before 'tn' stimulation

                                                    roi_col_data_trig_plot{rn, roi_plot, tn} = roi_col_data(idx_min:idx_max)-roi_col_data_base;
                                                    % roi_col_data_lowpassed_trig_plot = roi_col_data_lowpassed(idx_min:idx_max);
                                                    data_point_num{rn, roi_plot}(tn) = length(recording_timeinfo_trig_plot{rn, roi_plot, tn}); % data points of each triggered plot

                                                    plot(recording_timeinfo_trig_plot{rn, roi_plot, tn}, roi_col_data_trig_plot{rn, roi_plot, tn}, 'k'); % plot raw data sweeps
                                                    % plot(recording_timeinfo_trig_plot{rn, roi_plot, tn}, roi_col_data_lowpassed_trig_plot, 'm'); % plot lowpassed data
                                                elseif plot_trace == 0
                                                    recording_timeinfo_trig_plot{rn, roi_plot, tn} = [];
                                                    roi_col_data_trig_plot{rn, roi_plot, tn} = [];
                                                    data_point_num{rn, roi_plot}(tn) = 0;
                                                end
                                            end
                                            hold off
                                           
                                            data_plot_num_chosen{rn, roi_plot} = data_point_num{rn, roi_plot};
                                            if ~isempty(erase_trace)
                                                % recording_timeinfo_trig_plot{rn, roi_plot, erase_trace} = []; % delete rows didn't pass peak check
                                                % roi_col_data_trig_plot{rn, roi_plot, erase_trace} = []; % % delete rows didn't pass peak check
                                                data_plot_num_chosen{rn, roi_plot}(erase_trace)= []; % data_plot_num_chosen include length of data points actually being plotted
                                            end

                                            data_point_num_unique = unique(data_plot_num_chosen{rn, roi_plot}, 'sorted'); % unique data points length
                                            if ~isempty(data_point_num_unique)
                                                datapoint_for_average = cell(1, length(data_point_num_unique));
                                                average_datapoint = cell(1, length(data_point_num_unique));
                                                std_datapoint  = cell(1, length(data_point_num_unique));
                                                if length(data_point_num_unique) ~= 1
                                                    for sn = 1:length(data_point_num_unique) % segment (according to number of datapoints) number of datapoints with different length
                                                        if sn == 1
                                                            segment_start = 1;
                                                        else
                                                            segment_start = data_point_num_unique(sn-1)+1;
                                                        end
                                                        segment_end = data_point_num_unique(sn);
                                                        available_sweeps = find(data_point_num{rn, roi_plot} >= segment_end);
                                                            for swn = 1:length(available_sweeps) % swn: sweep number
                                                                if swn == 1
                                                                    datapoint_for_average{sn} = roi_col_data_trig_plot{rn, roi_plot, available_sweeps(swn)}(segment_start:segment_end);
                                                                else
                                                                    datapoint_for_average{sn} = [datapoint_for_average{sn} roi_col_data_trig_plot{rn, roi_plot, available_sweeps(swn)}(segment_start:segment_end)];
                                                                end
                                                            end
                                                            average_datapoint{sn} = mean(datapoint_for_average{sn}, 2);
                                                            % ste_datapoint{sn} = std(datapoint_for_average{sn}, 0, 2)/sqrt(size(datapoint_for_average{sn}, 2));
                                                            std_datapoint{sn} = std(datapoint_for_average{sn}, 0, 2);
                                                        if sn == 1
                                                            average_data_trig_plot = average_datapoint{sn};
                                                            std_data_trig_plot = std_datapoint{sn};
                                                        else
                                                            average_data_trig_plot = [average_data_trig_plot; average_datapoint{sn}];
                                                            std_data_trig_plot = [std_data_trig_plot; std_datapoint{sn}];
                                                        end
                                                    end
                                                else
                                                    datapoint_for_average = cat(2, roi_col_data_trig_plot{rn, roi_plot, :});
                                                    average_data_trig_plot = mean(datapoint_for_average, 2);
                                                    std_data_trig_plot = std(datapoint_for_average, 0, 2)/sqrt(size(datapoint_for_average, 2));
                                                end
                                                std_plot_upper_line = average_data_trig_plot+std_data_trig_plot;
                                                std_plot_lower_line = average_data_trig_plot-std_data_trig_plot;
                                                std_plot_area_y = [std_plot_upper_line; flip(std_plot_lower_line)];
                                                % loc_longest_time_trig_plot = find(sort(data_point_num), 1, 'last');
                                                [longest_time_trig_plot,loc_longest_time_trig_plot] = max(data_point_num{rn, roi_plot}, [],'linear');
                                                average_data_trig_plot_x = recording_timeinfo_trig_plot{rn, roi_plot, loc_longest_time_trig_plot};
                                                std_plot_area_x = [average_data_trig_plot_x; flip(average_data_trig_plot_x)];
                                                subplot(6, 8, (q*4+(m-1)*8)) % plot stimulation triggered responses. Averaged
                                                patch(gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7)
                                                hold on
                                                plot(average_data_trig_plot_x, average_data_trig_plot, 'k');
                                                if ~isempty(std_plot_area_y)
                                                    patch(std_plot_area_x, std_plot_area_y, 'yellow', 'EdgeColor', 'none', 'FaceAlpha', 0.3) %'#EDB120'
                                                end
                                            end
                                        end

                                    end
                                    if GPIO_trace == 1 % plot stimulation trace GPIO signal (GPIO1, ogLED, etc.)
                                        subplot(6, 8, [40+(q-1)*4+1,40+(q-1)*4+2]);
                                        for nc = 1:length(channel)-2
                                                            gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
                                                            x = channel(nc+2).time_value(:, 1);
                                                            y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
                                                            stairs(x, y{nc});
                                                            hold on
                                        end
                                        axis([0 recording_timeinfo(end) 0 max(y{1})+1])
                                        hold off
                                        legend(stimulation, 'Location', "SouthOutside");
                                    end
                                    % if GPIO_trace == 1
                                    %   subplot(6, 2, 10+q);
                                    %   for nc = 1:length(channel)-2
                                    %       gpio_offset = 6; % in case there are multiple stimuli, GPIO traces will be stacked, seperated by offset 6
                                    %       x = channel(nc+2).time_value(:, 1);
                                    %       y{nc} = channel(nc+2).time_value(:, 2)+(length(channel)-2-nc)*gpio_offset;
                                    %       stairs(x, y{nc});
                                    %       hold on
                                    %   end
                                    %   axis([0 recording_time 0 max(y{1})+1])
                                    %   hold off
                                    %   legend(stimulation, 'Location', "SouthOutside");
                                    % end
                                end
                                sgtitle(ROIdata{rn, 1}, 'Interpreter', 'none');
                                if plot_traces == 2 && ~isempty(app.folder_plots)
                                    figfile = [ROIdata{rn,1}(1:(end-4)), '-handpick-', num2str(p), '.fig'];
                                    figfullpath = fullfile(app.folder_plots,figfile);
                                    savefig(gcf, figfullpath);
                                    jpgfile_name = [figfile(1:(end-3)), 'jpg'];
                                    jpgfile_fullpath = fullfile(app.folder_plots, jpgfile_name);
                                    saveas(gcf, jpgfile_fullpath);
                                    svgfile_name = [figfile(1:(end-3)), 'svg'];
                                    svgfile_fullpath = fullfile(app.folder_plots, svgfile_name);
                                    saveas(gcf, svgfile_fullpath);
                                end
                                if pause_step == 1
                                    disp('Press any key to continue')
                                    pause;
                                end
                            end
                        end

                    end
                    % Calculate mean value of all ROIs from all recordings
                    cla(app.UIAxes_all_traces, 'reset')
                    cla(app.UIAxes_all_traces_mean, 'reset')
                    fr_num = unique(recording_fr, 'sorted'); 
                    recording_fr_min = min(fr_num); % find the lowest recording frequency. Downgrade recordings to this number and calculate the mean value
                    trace_count = 1; % count all trace number
                    patch(app.UIAxes_all_traces, gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7);
                    hold(app.UIAxes_all_traces, 'on')
                    for fn = 1:length(fr_num) % fn - freqency number
                        log_idx_fr = recording_fr==fr_num(fn); % logical index of recordings with (fn)th low frequency 
                        idx_fr = find(log_idx_fr);
                        fr_num(fn)=round(fr_num(fn));
                        fr_multiplier = fr_num(fn)/fr_num(1); % how many times this frequency is compare to lowest frequency
                        if ~isinteger(int8(fr_multiplier)) %MATLAB® stores a real number as a double type by default. Convert the number to a signed 8-bit integer type using the int8 function
                            % warning('Higher recording frequency is not an interger multiple of the lowest one')
                        else
                            for frn = 1:length(idx_fr) % number of recordings with frequency fr_num(fn)
                                [rs, rois, ts] = size(recording_timeinfo_trig_plot(frn, :, :)); % rs: recording size (1). rois: roi size. ts: trace size
                                for rn = 1:rois
                                    for tn = 1:ts
                                        if ~isempty(recording_timeinfo_trig_plot{frn, rn, tn})
                                            if fn == 1
                                                timeinfo_all_trace{trace_count, 1} = recording_timeinfo_trig_plot{frn, rn, tn};
                                                dff_all_trace{trace_count, 1} = roi_col_data_trig_plot{frn, rn, tn};
                                                data_point_num_all_trace(trace_count, 1) = length(dff_all_trace{trace_count, 1}); % count data points for calculating average
                                            else % if frequency is higher, use fr_multiplier to downgrade data
                                                timeinfo_all_trace{trace_count, 1} = recording_timeinfo_trig_plot{frn, rn, tn}(1:fr_multiplier:end);
                                                dff_all_trace{trace_count, 1} = roi_col_data_trig_plot{frn, rn, tn}(1:fr_multiplier:end);
                                                data_point_num_all_trace(trace_count, 1) = length(dff_all_trace{trace_count, 1});
                                            end
                                            plot(app.UIAxes_all_traces, timeinfo_all_trace{trace_count, 1} , dff_all_trace{trace_count, 1}, 'k');
                                            trace_count = trace_count+1;
                                        end
                                    end
                                end
                            end

                        end
                    end
                    hold(app.UIAxes_all_traces, 'off')
                    datapoint_num_all_unique = unique(data_point_num_all_trace, 'sorted');
                    datapoint_num_all_for_average = cell(1, length(datapoint_num_all_unique));
                    average_datapoint_all = cell(1, length(datapoint_num_all_unique));
                    std_datapoint_all = cell(1, length(datapoint_num_all_unique));
                    for dsn = 1:length(datapoint_num_all_unique) % datapoint_segment_num. calculate mean value in different segment of datapoint length
                        if dsn == 1
                            data_segment_start = 1;
                        else
                            data_segment_start = datapoint_num_all_unique(dsn-1)+1;
                        end
                        data_segment_end = datapoint_num_all_unique(dsn);
                        available_traces = find(data_point_num_all_trace >= data_segment_end);
                        for atn = 1:length(available_traces) % all trace number
                            if atn == 1
                                datapoint_num_all_for_average{dsn} = dff_all_trace{available_traces(atn)}(data_segment_start:data_segment_end);
                            else
                                datapoint_num_all_for_average{dsn} = [datapoint_num_all_for_average{dsn} dff_all_trace{available_traces(atn)}(data_segment_start:data_segment_end)];
                            end
                        end
                        average_datapoint_all{dsn} = mean(datapoint_num_all_for_average{dsn}, 2);
                        std_datapoint_all{dsn} = std(datapoint_num_all_for_average{dsn}, 0, 2);
                        if dsn == 1
                            average_datapoint_all_plot = average_datapoint_all{dsn};
                            std_datapoint_all_plot = std_datapoint_all{dsn};
                        else
                            average_datapoint_all_plot = [average_datapoint_all_plot; average_datapoint_all{dsn}];
                            std_datapoint_all_plot = [std_datapoint_all_plot; std_datapoint_all{dsn}];
                        end
                    end
                    % datapoint_num_all_for_average = cat(2, dff_all_trace{:});
                    % average_datapoint_all_plot = mean(datapoint_num_all_for_average, 2);
                    % std_datapoint_all_plot = std(datapoint_num_all_for_average, 0, 2);
                    std_all_plot_upper_line = average_datapoint_all_plot+std_datapoint_all_plot;
                    std_all_plot_lower_line = average_datapoint_all_plot-std_datapoint_all_plot;
                    std_all_plot_area_y = [std_all_plot_upper_line; flip(std_all_plot_lower_line)]; % prepare a close path for patch fun to plot std shade

                    [longest_timeinfo_all_trace, loc_longest_timeinfo_all_trace] = max(data_point_num_all_trace, [], 'linear');
                    average_datapoint_all_plot_time = timeinfo_all_trace{loc_longest_timeinfo_all_trace};
                    std_datapoint_all_plot_time = [average_datapoint_all_plot_time; flip(average_datapoint_all_plot_time)];
                    patch(app.UIAxes_all_traces_mean, gpio_x_trig_plot, gpio_y_trig_plot, 'cyan', 'EdgeColor', 'none', 'FaceAlpha', 0.7);
                    hold(app.UIAxes_all_traces_mean, 'on')
                    plot(app.UIAxes_all_traces_mean, average_datapoint_all_plot_time, average_datapoint_all_plot, 'k');
                    patch(app.UIAxes_all_traces_mean, std_datapoint_all_plot_time, std_all_plot_area_y, 'yellow', 'EdgeColor', 'none', 'FaceAlpha', 0.3)
                    hold(app.UIAxes_all_traces_mean, 'off')
                    
                    switch app.PlotButtonGroup.SelectedObject.Text 
                         case 'Stimulation triggered response'
                             trigger_str = 'stimulation';
                         case 'Response triggered response'
                             trigger_str = 'response';
                     end
                     switch app.StimulationButtonGroup.SelectedObject.Text
                         case 'Optogenetics (OgLED)'
                             stimulation_str = ['LED-', num2str(app.StimulationdurationSlider.Value), 's'];
                         case 'Airpuff to one eye (GPIO1)'
                             stimulation_str = ['airpuff-1s']; % GPIO trigger signal doesn't determine airpuff duration. The duration is set to 1s by puff machine
                     end
                     if app.nopeakCheckBox.Value == 1
                         peak_1_check_duration_str = [num2str(app.Peak_1_bin_edit.Value), 's'];
                         peak_2_check_duration_str = [num2str(app.Peak_2_bin_edit.Value), 's'];
                         peak_filter_str = ['nopeak', '-', peak_1_check_duration_str, '-', peak_2_check_duration_str];
                     elseif app.Peak_1afteronsetofstimulationCheckBox.Value == 1 || app.Peak_2afterendofstimulationCheckBox.Value == 1
                         if app.Peak_1afteronsetofstimulationCheckBox.Value == 1
                             peak_1_check_duration_str = [num2str(app.Peak_1_bin_edit.Value), 's'];
                             peak_filter_str_part1 = ['peak1', '-', peak_1_check_duration_str];
                         else
                             peak_filter_str_part1 = '';
                         end
                         if app.Peak_2afterendofstimulationCheckBox.Value == 1
                             peak_2_check_duration_str = [num2str(app.Peak_2_bin_edit.Value), 's'];
                             peak_filter_str_part2 = ['peak2', '-', peak_2_check_duration_str];
                         else
                             peak_filter_str_part2 = '';
                         end
                         peak_filter_str = [peak_filter_str_part1, '-', peak_filter_str_part2];
                     else
                         peak_filter_str = '';
                     end
                     plotfilename_stem = [trigger_str, ' ', stimulation_str, ' ', peak_filter_str];
                     plotfilename_sweeps = [plotfilename_stem, ' ', 'sweeps'];
                     plotfilename_mean = [plotfilename_stem, ' ', 'mean'];

                     title(app.UIAxes_all_traces, plotfilename_sweeps);
                     title(app.UIAxes_all_traces_mean, plotfilename_mean);
                end
            end


            

        end

        % Value changed function: StimulationdurationSlider
        function StimulationdurationSliderValueChanged(app, event)
            value = app.StimulationdurationSlider.Value;
            app.StimulationdurationEdit.Value = value;
        end

        % Value changed function: StimulationdurationEdit
        function StimulationdurationEditValueChanged(app, event)
            value = app.StimulationdurationEdit.Value;
            app.StimulationdurationSlider.Value = value;
        end

        % Value changed function: FoldertosavePlotsEditField
        function FoldertosavePlotsEditFieldValueChanged(app, event)
            value = app.FoldertosavePlotsEditField.Value;
            app.folder_plots = value;
        end

        % Button pushed function: BrowseButton_figs
        function BrowseButton_figsPushed(app, event)
            app.folder_plots = uigetdir(app.folder_plots, 'Select a folder to save figures');
            if app.folder_plots ~= 0
                app.FoldertosavePlotsEditField.Value = app.folder_plots;
            end
        end

        % Callback function
        function Peak_1_bin_editValueChanged(app, event)
            value = app.Peak_1_bin_edit.Value;
            app.Peak_1afteronsetofstimulationSlider.Value = value;
        end

        % Callback function
        function Peak_2_bin_editValueChanged(app, event)
            value = app.Peak_2_bin_edit.Value;
            app.Peak_2afterendofstimulationSlider = Value;
        end

        % Value changed function: 
        % Peak_1afteronsetofstimulationSlider
        function Peak_1afteronsetofstimulationSliderValueChanged(app, event)
            value = app.Peak_1afteronsetofstimulationSlider.Value;
            app.Peak_1_bin_edit.Value = value;
        end

        % Value changed function: Peak_2afterendofstimulationSlider
        function Peak_2afterendofstimulationSliderValueChanged(app, event)
            value = app.Peak_2afterendofstimulationSlider.Value;
            app.Peak_2_bin_edit.Value = value;
        end

        % Value changed function: nopeakCheckBox
        function nopeakCheckBoxValueChanged(app, event)
            value = app.nopeakCheckBox.Value;
            if value == 1
                app.Peak_1afteronsetofstimulationCheckBox.Value = 0;
                app.Peak_2afterendofstimulationCheckBox.Value = 0;
                app.Peak_1afteronsetofstimulationSlider.Enable = 1;
                app.Peak_2afterendofstimulationSlider.Enable = 1;
                app.Peak_1_bin_edit.Enable = 1;
                app.Peak_2_bin_edit.Enable = 1;
            elseif value == 0
%                 app.Peak_1afteronsetofstimulationCheckBox.Value = 0;
%                 app.Peak_2afterendofstimulationCheckBox.Value = 0;
                app.Peak_1afteronsetofstimulationSlider.Enable = 0;
                app.Peak_2afterendofstimulationSlider.Enable = 0;
                app.Peak_1_bin_edit.Enable = 0;
                app.Peak_2_bin_edit.Enable = 0;
            end
        end

        % Value changed function: 
        % Peak_1afteronsetofstimulationCheckBox
        function Peak_1afteronsetofstimulationCheckBoxValueChanged(app, event)
            value = app.Peak_1afteronsetofstimulationCheckBox.Value;
            if value == 1
                app.nopeakCheckBox.Value = 0;
                app.Peak_1afteronsetofstimulationSlider.Enable = 1;
                app.Peak_1_bin_edit.Enable = 1;
                if app.Peak_2afterendofstimulationCheckBox.Value == 0
                    app.Peak_2afterendofstimulationSlider.Enable = 0;
                    app.Peak_2_bin_edit.Enable = 0;
                else
                    app.Peak_2afterendofstimulationSlider.Enable = 1;
                    app.Peak_2_bin_edit.Enable = 1;
                end
            elseif value == 0
                app.Peak_1afteronsetofstimulationSlider.Enable = 0;
                app.Peak_1_bin_edit.Enable = 0;
            end
        end

        % Value changed function: 
        % Peak_2afterendofstimulationCheckBox
        function Peak_2afterendofstimulationCheckBoxValueChanged(app, event)
            value = app.Peak_2afterendofstimulationCheckBox.Value;
            if value == 1
                app.nopeakCheckBox.Value = 0;
                app.Peak_2afterendofstimulationSlider.Enable = 1;
                app.Peak_2_bin_edit.Enable = 1;
                if app.Peak_1afteronsetofstimulationCheckBox == 0
                    app.Peak_1afteronsetofstimulationSlider.Enable = 0;
                    app.Peak_1_bin_edit.Enable = 0;
                else
                    app.Peak_1afteronsetofstimulationSlider.Enable = 1;
                    app.Peak_1_bin_edit.Enable = 1;
                end
            elseif value == 0
                app.Peak_2afterendofstimulationSlider.Enable = 0;
                app.Peak_2_bin_edit.Enable = 0;
            end
        end

        % Value changed function: Peak_1_bin_edit
        function Peak_1_bin_editValueChanged2(app, event)
            value = app.Peak_1_bin_edit.Value;
            app.Peak_1afteronsetofstimulationSlider.Value = value;
        end

        % Value changed function: Peak_2_bin_edit
        function Peak_2_bin_editValueChanged2(app, event)
            value = app.Peak_2_bin_edit.Value;
            app.Peak_2afterendofstimulationSlider.Value = value;
        end

        % Button pushed function: SaveaverageplotButton
        function SaveaverageplotButtonPushed(app, event)
            app.folder_plots = uigetdir(app.folder_plots, 'Select a folder to save figures');
            if app.folder_plots ~= 0
                app.FoldertosavePlotsEditField.Value = app.folder_plots;
            end 
            switch app.PlotButtonGroup.SelectedObject.Text 
                 case 'Stimulation triggered response'
                     trigger_str = 'stimulation';
                 case 'Response triggered response'
                     trigger_str = 'response';
             end
             switch app.StimulationButtonGroup.SelectedObject.Text
                 case 'Optogenetics (OgLED)'
                     stimulation_str = ['LED-', num2str(app.StimulationdurationSlider.Value), 's'];
                 case 'Airpuff to one eye (GPIO1)'
                     stimulation_str = ['airpuff-1s']; % GPIO trigger signal doesn't determine airpuff duration. The duration is set to 1s by puff machine
             end
             if app.nopeakCheckBox.Value == 1
                 peak_1_check_duration_str = [num2str(app.Peak_1_bin_edit.Value), 's'];
                 peak_2_check_duration_str = [num2str(app.Peak_2_bin_edit.Value), 's'];
                 peak_filter_str = ['no_peak', '-', peak_1_check_duration_str, '-', peak_2_check_duration_str];
             elseif app.Peak_1afteronsetofstimulationCheckBox == 1 || app.Peak_2afterendofstimulationCheckBox == 1
                 if app.Peak_1afteronsetofstimulationCheckBox == 1
                     peak_1_check_duration_str = [num2str(app.Peak_1_bin_edit.Value), 's'];
                     peak_filter_str_part1 = ['peak1', '-', peak_1_check_duration_str];
                 else
                     peak_filter_str_part1 = '';
                 end
                 if app.Peak_2afterendofstimulationCheckBox == 1
                     peak_2_check_duration_str = [num2str(app.Peak_2_bin_edit.Value), 's'];
                     peak_filter_str_part2 = ['peak2', '-', peak_2_check_duration_str];
                 else
                     peak_filter_str_part2 = '';
                 end
                 peak_filter_str = [peak_filter_str_part1, '_', peak_filter_str_part2];
             else
                 peak_filter_str = '';
             end
             plotfilename_stem = [trigger_str, '_', stimulation_str, '_', peak_filter_str];
             plotfilename_sweeps = [plotfilename_stem, '_sweeps'];
             plotfilename_mean = [plotfilename_stem, '_mean'];
             
             plotfilename_sweeps_fig = [plotfilename_sweeps, '.fig'];
             plotfilename_mean_fig = [plotfilename_stem, '.fig'];
             plotfilename_sweeps_jpg = [plotfilename_sweeps, '.jpg'];
             plotfilename_mean_jpg = [plotfilename_stem, '.jpg'];
             plotfilename_sweeps_svg = [plotfilename_sweeps, '.svg'];
             plotfilename_mean_svg = [plotfilename_stem, '.svg'];
             
             % plotfilename_sweeps_fig_fullpath = fullfile(app.folder_plots, plotfilename_sweeps_fig);
             % saveas(app.UIAxes_all_traces, plotfilename_sweeps_fig_fullpath);
             % plotfilename_mean_fig_fullpath = fullfile(app.folder_plots, plotfilename_mean_fig);
             % saveas(app.UIAxes_all_traces_mean, plotfilename_mean_fig_fullpath);
             
             % plotfilename_sweeps_jpg_fullpath = fullfile(app.folder_plots, plotfilename_sweeps_jpg);
             % saveas(app.UIAxes_all_traces, plotfilename_sweeps_jpg_fullpath);
             % plotfilename_mean_jpg_fullpath = fullfile(app.folder_plots, plotfilename_mean_jpg);
             % saveas(app.UIAxes_all_traces_mean, plotfilename_mean_jpg_fullpath);

             % plotfilename_sweeps_svg_fullpath = fullfile(app.folder_plots, plotfilename_sweeps_svg);
             % saveas(app.UIAxes_all_traces, plotfilename_sweeps_svg_fullpath);
             % plotfilename_mean_svg_fullpath = fullfile(app.folder_plots, plotfilename_mean_svg);
             % saveas(app.UIAxes_all_traces_mean, plotfilename_mean_svg_fullpath);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1624 981];
            app.UIFigure.Name = 'UI Figure';

            % Create InscopixDataAnalysisLabel
            app.InscopixDataAnalysisLabel = uilabel(app.UIFigure);
            app.InscopixDataAnalysisLabel.FontSize = 20;
            app.InscopixDataAnalysisLabel.FontWeight = 'bold';
            app.InscopixDataAnalysisLabel.Position = [51 932 225 24];
            app.InscopixDataAnalysisLabel.Text = 'Inscopix Data Analysis';

            % Create PlotButtonGroup
            app.PlotButtonGroup = uibuttongroup(app.UIFigure);
            app.PlotButtonGroup.Title = 'Plot';
            app.PlotButtonGroup.Position = [51 710 225 106];

            % Create StimulationtriggeredresponseButton
            app.StimulationtriggeredresponseButton = uiradiobutton(app.PlotButtonGroup);
            app.StimulationtriggeredresponseButton.Text = 'Stimulation triggered response';
            app.StimulationtriggeredresponseButton.Position = [11 60 185 22];
            app.StimulationtriggeredresponseButton.Value = true;

            % Create ResponsetriggeredresponseButton
            app.ResponsetriggeredresponseButton = uiradiobutton(app.PlotButtonGroup);
            app.ResponsetriggeredresponseButton.Text = 'Response triggered response';
            app.ResponsetriggeredresponseButton.Position = [11 38 180 22];

            % Create Button3
            app.Button3 = uiradiobutton(app.PlotButtonGroup);
            app.Button3.Text = 'Button3';
            app.Button3.Position = [11 16 65 22];

            % Create FiltersPanel
            app.FiltersPanel = uipanel(app.UIFigure);
            app.FiltersPanel.Title = 'Filters';
            app.FiltersPanel.Position = [51 229 225 475];

            % Create BaselinePanel
            app.BaselinePanel = uipanel(app.FiltersPanel);
            app.BaselinePanel.Title = 'Baseline';
            app.BaselinePanel.Position = [11 153 201 93];

            % Create StablebaselineCheckBox
            app.StablebaselineCheckBox = uicheckbox(app.BaselinePanel);
            app.StablebaselineCheckBox.Enable = 'off';
            app.StablebaselineCheckBox.Text = 'Stable baseline';
            app.StablebaselineCheckBox.Position = [11 49 104 22];

            % Create RisingbaselineCheckBox
            app.RisingbaselineCheckBox = uicheckbox(app.BaselinePanel);
            app.RisingbaselineCheckBox.Enable = 'off';
            app.RisingbaselineCheckBox.Text = 'Rising baseline';
            app.RisingbaselineCheckBox.Position = [11 28 104 22];

            % Create DeclinebaselineCheckBox
            app.DeclinebaselineCheckBox = uicheckbox(app.BaselinePanel);
            app.DeclinebaselineCheckBox.Enable = 'off';
            app.DeclinebaselineCheckBox.Text = 'Decline baseline';
            app.DeclinebaselineCheckBox.Position = [11 7 110 22];

            % Create PeakPanel
            app.PeakPanel = uipanel(app.FiltersPanel);
            app.PeakPanel.Title = 'Peak';
            app.PeakPanel.Position = [11 10 202 130];

            % Create nopeakCheckBox
            app.nopeakCheckBox = uicheckbox(app.PeakPanel);
            app.nopeakCheckBox.ValueChangedFcn = createCallbackFcn(app, @nopeakCheckBoxValueChanged, true);
            app.nopeakCheckBox.Text = 'no peak';
            app.nopeakCheckBox.Position = [10 86 65 22];

            % Create Peak_1afteronsetofstimulationCheckBox
            app.Peak_1afteronsetofstimulationCheckBox = uicheckbox(app.PeakPanel);
            app.Peak_1afteronsetofstimulationCheckBox.ValueChangedFcn = createCallbackFcn(app, @Peak_1afteronsetofstimulationCheckBoxValueChanged, true);
            app.Peak_1afteronsetofstimulationCheckBox.Text = {'Peak_1: '; 'after onset of stimulation'};
            app.Peak_1afteronsetofstimulationCheckBox.Position = [10 55 153 28];

            % Create Peak_2afterendofstimulationCheckBox
            app.Peak_2afterendofstimulationCheckBox = uicheckbox(app.PeakPanel);
            app.Peak_2afterendofstimulationCheckBox.ValueChangedFcn = createCallbackFcn(app, @Peak_2afterendofstimulationCheckBoxValueChanged, true);
            app.Peak_2afterendofstimulationCheckBox.Text = {'Peak_2: '; 'after end of stimulation'};
            app.Peak_2afterendofstimulationCheckBox.Position = [10 26 144 28];

            % Create CalciumindicatorButtonGroup
            app.CalciumindicatorButtonGroup = uibuttongroup(app.FiltersPanel);
            app.CalciumindicatorButtonGroup.Title = 'Calcium indicator';
            app.CalciumindicatorButtonGroup.Position = [11 371 202 74];

            % Create GCaMP6sButton
            app.GCaMP6sButton = uiradiobutton(app.CalciumindicatorButtonGroup);
            app.GCaMP6sButton.Enable = 'off';
            app.GCaMP6sButton.Text = 'GCaMP6s';
            app.GCaMP6sButton.Position = [11 28 78 22];
            app.GCaMP6sButton.Value = true;

            % Create GCaMP6fButton
            app.GCaMP6fButton = uiradiobutton(app.CalciumindicatorButtonGroup);
            app.GCaMP6fButton.Enable = 'off';
            app.GCaMP6fButton.Text = 'GCaMP6f';
            app.GCaMP6fButton.Position = [11 6 75 22];

            % Create StimulationButtonGroup
            app.StimulationButtonGroup = uibuttongroup(app.FiltersPanel);
            app.StimulationButtonGroup.Title = 'Stimulation';
            app.StimulationButtonGroup.Position = [12 256 201 106];

            % Create OptogeneticsOgLEDButton
            app.OptogeneticsOgLEDButton = uiradiobutton(app.StimulationButtonGroup);
            app.OptogeneticsOgLEDButton.Text = 'Optogenetics (OgLED)';
            app.OptogeneticsOgLEDButton.Position = [11 60 144 22];
            app.OptogeneticsOgLEDButton.Value = true;

            % Create AirpufftooneeyeGPIO1Button
            app.AirpufftooneeyeGPIO1Button = uiradiobutton(app.StimulationButtonGroup);
            app.AirpufftooneeyeGPIO1Button.Text = 'Airpuff to one eye (GPIO1)';
            app.AirpufftooneeyeGPIO1Button.Position = [11 38 164 22];

            % Create Button3_3
            app.Button3_3 = uiradiobutton(app.StimulationButtonGroup);
            app.Button3_3.Text = 'Button3';
            app.Button3_3.Position = [11 16 65 22];

            % Create DataPanel
            app.DataPanel = uipanel(app.UIFigure);
            app.DataPanel.Title = 'Data';
            app.DataPanel.Position = [51 825 1263 96];

            % Create ROIdatafileEditFieldLabel
            app.ROIdatafileEditFieldLabel = uilabel(app.DataPanel);
            app.ROIdatafileEditFieldLabel.HorizontalAlignment = 'right';
            app.ROIdatafileEditFieldLabel.Position = [11 45 72 22];
            app.ROIdatafileEditFieldLabel.Text = 'ROI data file';

            % Create ROIdatafileEditField
            app.ROIdatafileEditField = uieditfield(app.DataPanel, 'text');
            app.ROIdatafileEditField.Position = [104 45 648 22];

            % Create ViarablenameLabel
            app.ViarablenameLabel = uilabel(app.DataPanel);
            app.ViarablenameLabel.Position = [17 13 86 22];
            app.ViarablenameLabel.Text = 'Viarable name:';

            % Create viarableloadedLabel_name
            app.viarableloadedLabel_name = uilabel(app.DataPanel);
            app.viarableloadedLabel_name.Position = [103 13 275 22];
            app.viarableloadedLabel_name.Text = 'no viarable loaded';

            % Create BrowseButton_ROIdata
            app.BrowseButton_ROIdata = uibutton(app.DataPanel, 'push');
            app.BrowseButton_ROIdata.ButtonPushedFcn = createCallbackFcn(app, @BrowseButton_ROIdataPushed, true);
            app.BrowseButton_ROIdata.Position = [765 45 74 22];
            app.BrowseButton_ROIdata.Text = 'Browse';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [318 34 1235 687];

            % Create PlotTab
            app.PlotTab = uitab(app.TabGroup);
            app.PlotTab.Title = 'Plot';

            % Create PeakdetectionbinsizesPanel
            app.PeakdetectionbinsizesPanel = uipanel(app.PlotTab);
            app.PeakdetectionbinsizesPanel.Title = 'Peak detection bin size (s)';
            app.PeakdetectionbinsizesPanel.Position = [26 76 758 97];

            % Create Peak_1afteronsetofstimulationSliderLabel
            app.Peak_1afteronsetofstimulationSliderLabel = uilabel(app.PeakdetectionbinsizesPanel);
            app.Peak_1afteronsetofstimulationSliderLabel.HorizontalAlignment = 'center';
            app.Peak_1afteronsetofstimulationSliderLabel.Position = [12 38 136 28];
            app.Peak_1afteronsetofstimulationSliderLabel.Text = {'Peak_1: '; 'after onset of stimulation'};

            % Create Peak_1afteronsetofstimulationSlider
            app.Peak_1afteronsetofstimulationSlider = uislider(app.PeakdetectionbinsizesPanel);
            app.Peak_1afteronsetofstimulationSlider.Limits = [0 10];
            app.Peak_1afteronsetofstimulationSlider.ValueChangedFcn = createCallbackFcn(app, @Peak_1afteronsetofstimulationSliderValueChanged, true);
            app.Peak_1afteronsetofstimulationSlider.Enable = 'off';
            app.Peak_1afteronsetofstimulationSlider.Position = [169 53 187 3];
            app.Peak_1afteronsetofstimulationSlider.Value = 1;

            % Create Peak_2afterendofstimulationSliderLabel
            app.Peak_2afterendofstimulationSliderLabel = uilabel(app.PeakdetectionbinsizesPanel);
            app.Peak_2afterendofstimulationSliderLabel.HorizontalAlignment = 'center';
            app.Peak_2afterendofstimulationSliderLabel.Position = [391 38 127 28];
            app.Peak_2afterendofstimulationSliderLabel.Text = {'Peak_2: '; 'after end of stimulation'};

            % Create Peak_2afterendofstimulationSlider
            app.Peak_2afterendofstimulationSlider = uislider(app.PeakdetectionbinsizesPanel);
            app.Peak_2afterendofstimulationSlider.Limits = [0 10];
            app.Peak_2afterendofstimulationSlider.ValueChangedFcn = createCallbackFcn(app, @Peak_2afterendofstimulationSliderValueChanged, true);
            app.Peak_2afterendofstimulationSlider.HandleVisibility = 'off';
            app.Peak_2afterendofstimulationSlider.Enable = 'off';
            app.Peak_2afterendofstimulationSlider.Position = [539 53 187 3];
            app.Peak_2afterendofstimulationSlider.Value = 1;

            % Create Peak_1_bin_edit
            app.Peak_1_bin_edit = uieditfield(app.PeakdetectionbinsizesPanel, 'numeric');
            app.Peak_1_bin_edit.ValueChangedFcn = createCallbackFcn(app, @Peak_1_bin_editValueChanged2, true);
            app.Peak_1_bin_edit.Enable = 'off';
            app.Peak_1_bin_edit.Position = [30 12 100 22];
            app.Peak_1_bin_edit.Value = 1;

            % Create Peak_2_bin_edit
            app.Peak_2_bin_edit = uieditfield(app.PeakdetectionbinsizesPanel, 'numeric');
            app.Peak_2_bin_edit.ValueChangedFcn = createCallbackFcn(app, @Peak_2_bin_editValueChanged2, true);
            app.Peak_2_bin_edit.Enable = 'off';
            app.Peak_2_bin_edit.Position = [405 12 100 22];
            app.Peak_2_bin_edit.Value = 1;

            % Create PlotUpdateButton
            app.PlotUpdateButton = uibutton(app.PlotTab, 'push');
            app.PlotUpdateButton.ButtonPushedFcn = createCallbackFcn(app, @PlotUpdateButtonPushed, true);
            app.PlotUpdateButton.FontWeight = 'bold';
            app.PlotUpdateButton.Position = [826 45 138 22];
            app.PlotUpdateButton.Text = 'Plot / Update';

            % Create UIAxes_all_traces
            app.UIAxes_all_traces = uiaxes(app.PlotTab);
            title(app.UIAxes_all_traces, 'Sweeps from all recordings')
            xlabel(app.UIAxes_all_traces, 'Time (s)')
            ylabel(app.UIAxes_all_traces, 'DF/F')
            app.UIAxes_all_traces.PlotBoxAspectRatio = [1.33931777378815 1 1];
            app.UIAxes_all_traces.Position = [56 214 515 403];

            % Create UIAxes_all_traces_mean
            app.UIAxes_all_traces_mean = uiaxes(app.PlotTab);
            title(app.UIAxes_all_traces_mean, 'Mean of sweeps from all recordings')
            xlabel(app.UIAxes_all_traces_mean, 'Time (s)')
            ylabel(app.UIAxes_all_traces_mean, 'DF/F')
            app.UIAxes_all_traces_mean.PlotBoxAspectRatio = [1.33931777378815 1 1];
            app.UIAxes_all_traces_mean.Position = [644 214 512 401];

            % Create StimulationdurationEdit
            app.StimulationdurationEdit = uieditfield(app.PlotTab, 'numeric');
            app.StimulationdurationEdit.ValueChangedFcn = createCallbackFcn(app, @StimulationdurationEditValueChanged, true);
            app.StimulationdurationEdit.Position = [45 24 100 22];

            % Create StimulationdurationsSliderLabel
            app.StimulationdurationsSliderLabel = uilabel(app.PlotTab);
            app.StimulationdurationsSliderLabel.HorizontalAlignment = 'right';
            app.StimulationdurationsSliderLabel.Position = [29 45 132 22];
            app.StimulationdurationsSliderLabel.Text = 'Stimulation duration (s) ';

            % Create StimulationdurationSlider
            app.StimulationdurationSlider = uislider(app.PlotTab);
            app.StimulationdurationSlider.Limits = [0 10];
            app.StimulationdurationSlider.ValueChangedFcn = createCallbackFcn(app, @StimulationdurationSliderValueChanged, true);
            app.StimulationdurationSlider.MinorTicks = [0 1 2 3 4 5 6 7 8 9 10];
            app.StimulationdurationSlider.Position = [182 54 183 3];

            % Create PloteverysinglerecordingsCheckBox
            app.PloteverysinglerecordingsCheckBox = uicheckbox(app.PlotTab);
            app.PloteverysinglerecordingsCheckBox.Text = 'Plot every single recordings';
            app.PloteverysinglerecordingsCheckBox.Position = [826 151 170 22];
            app.PloteverysinglerecordingsCheckBox.Value = true;

            % Create PauseaftereachsinglerecordingplotCheckBox
            app.PauseaftereachsinglerecordingplotCheckBox = uicheckbox(app.PlotTab);
            app.PauseaftereachsinglerecordingplotCheckBox.Text = 'Pause after each single recording plot';
            app.PauseaftereachsinglerecordingplotCheckBox.Position = [826 130 226 22];
            app.PauseaftereachsinglerecordingplotCheckBox.Value = true;

            % Create SavesinglerecordingplotsCheckBox
            app.SavesinglerecordingplotsCheckBox = uicheckbox(app.PlotTab);
            app.SavesinglerecordingplotsCheckBox.Text = 'Save single recording plots';
            app.SavesinglerecordingplotsCheckBox.Position = [826 109 166 22];

            % Create SavealldataaverageCheckBox
            app.SavealldataaverageCheckBox = uicheckbox(app.PlotTab);
            app.SavealldataaverageCheckBox.Text = 'Save all data average';
            app.SavealldataaverageCheckBox.Position = [826 85 138 22];

            % Create SaveaverageplotButton
            app.SaveaverageplotButton = uibutton(app.PlotTab, 'push');
            app.SaveaverageplotButton.ButtonPushedFcn = createCallbackFcn(app, @SaveaverageplotButtonPushed, true);
            app.SaveaverageplotButton.FontWeight = 'bold';
            app.SaveaverageplotButton.Position = [826 14 138 22];
            app.SaveaverageplotButton.Text = 'Save average plot';

            % Create Table
            app.Table = uitab(app.TabGroup);
            app.Table.Title = 'Table';

            % Create PlotsinglerecordingPanel
            app.PlotsinglerecordingPanel = uipanel(app.UIFigure);
            app.PlotsinglerecordingPanel.Title = 'Plot single recording';
            app.PlotsinglerecordingPanel.Position = [319 734 995 82];

            % Create FoldertosavePlotsEditFieldLabel
            app.FoldertosavePlotsEditFieldLabel = uilabel(app.PlotsinglerecordingPanel);
            app.FoldertosavePlotsEditFieldLabel.HorizontalAlignment = 'right';
            app.FoldertosavePlotsEditFieldLabel.Position = [3 30 112 22];
            app.FoldertosavePlotsEditFieldLabel.Text = 'Folder to save Plots';

            % Create FoldertosavePlotsEditField
            app.FoldertosavePlotsEditField = uieditfield(app.PlotsinglerecordingPanel, 'text');
            app.FoldertosavePlotsEditField.ValueChangedFcn = createCallbackFcn(app, @FoldertosavePlotsEditFieldValueChanged, true);
            app.FoldertosavePlotsEditField.Position = [136 30 760 22];

            % Create BrowseButton_figs
            app.BrowseButton_figs = uibutton(app.PlotsinglerecordingPanel, 'push');
            app.BrowseButton_figs.ButtonPushedFcn = createCallbackFcn(app, @BrowseButton_figsPushed, true);
            app.BrowseButton_figs.Position = [908 30 74 22];
            app.BrowseButton_figs.Text = 'Browse';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = nvoke_plot_app

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end