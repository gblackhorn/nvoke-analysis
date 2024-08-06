function [varargout] = plotNeuronEdgesAndTraces(alignedData,varargin)
    % Get eventProp from every ROI and every trials in alignedData, and group them accroding to settings

    % Defaults
    plotUnitWidth = 0.3;
    plotUnitHeight = 0.5;
    columnLim = 3;


    % Create an instance of the inputParser
    p = inputParser;

    % Required input
    addRequired(p, 'alignedData', @isstruct);

    % Add optional parameters to the input parser
    addParameter(p, 'saveFig', false, @islogical);
    addParameter(p, 'saveDir', '', @ischar);
    addParameter(p, 'saveWithGui', true, @islogical);
    % addParameter(p, 'pausePlot', true, @islogical); % Pause after plotting one recording
    addParameter(p, 'debugMode', false, @islogical);

    % Parse inputs
    parse(p, alignedData, varargin{:});

    % Retrieve parsed values
    saveFig = p.Results.saveFig;
    saveDir = p.Results.saveDir;
    saveWithGui = p.Results.saveWithGui;
    % pausePlot = p.Results.pausePlot;
    debugMode = p.Results.debugMode;


    % By default, pause plotting when not saving figures
    if saveFig
        pausePlot = false;
    else
        pausePlot = true;
    end

    % Loop through the recordings
    for n = 1:numel(alignedData)
        % Get the date-time info from the recording name
        shortRecName = extractDateTimeFromFileName(alignedData(n).trialName); % Get he yyyyddmm-hhmmss from recording file name

        % Get the 2D matrix for plotting the FOV
        imageMatrix = alignedData(n).roi_map; 

        % Get the ROI edges
        roiBoundaries = {alignedData(n).traces.roiEdge}; 

        % Get the ROI names
        roiNames = {alignedData(n).traces.roi}; 
        shortRoiNames = cellfun(@(x) x(7:end),roiNames,'UniformOutput',false); % Remove 'neuron' from the roi names

        % Get the time information
        timeData = alignedData(n).fullTime;

        % Get the traces data
        tracesData = [alignedData(n).traces.fullTrace];

        if ~isempty(alignedData(n).traces)
            % Get the event time 
            eventTime = get_TrialEvents_from_alignedData(alignedData(n),'peak_time'); % Get the time of event peaks

            % Get the stimulation patch info for plotting the shades to indicate stimulation
            [patchCoor, stimTypes, stimTypeNum] = get_TrialStimPatchCoor_from_alignedData(alignedData(n));


            % Creat figures for plotting
            close all
            figName = sprintf('%s FOV and traces', shortRecName);
            % titleRecFOV = [shortRecName,' FOV'];
            [f, fRowNum, fColNum] = fig_canvas(3,'unit_width', plotUnitWidth, 'unit_height', plotUnitHeight,...
            'column_lim', columnLim,'fig_name',figName); % Create a figure for plots
            tlo = tiledlayout(f,fRowNum,fColNum);

            % Create FOV plot
            axFOV = nexttile(tlo, 1);
            plotCalciumImagingWithROIs(imageMatrix, roiBoundaries, shortRoiNames,...
                'Title', 'FOV', 'AxesHandle', axFOV);

            % Create traces plot
            axTraces = nexttile(tlo, 2, [1, 2]);
            % [~, ~] = plot_TemporalData_Trace(axTraces, CaLevelDataA.data, CaLevelDataA.time,...
            %     'shadeType', shadeType, 'plot_combined_data', plotCombinedData,'plot_raw_traces', plotRawTraces,...
            %     'color', colorGroupA, 'y_range', yRange, 'tickInt_time', tickInt_time);


            plot_TemporalData_Trace(gca, timeData, tracesData,...
                'ylabels', shortRoiNames, 'showYtickRight', true, 'shadeData', patchCoor, ...
                'titleStr', 'CNMFeTraces', 'plot_marker', true,'marker1_xData', eventTime);

            sgtitle(figName)

            set(gcf, 'Renderer', 'painters'); % Use painters renderer for better vector output
            % plot_TemporalData_Trace(gca, timeData, FluroData, 'yData2', FluroDataDecon,...
            %     'ylabels', originRowNames, 'plot_marker', plot_marker,...
            %     'marker1_xData', event_peakTime, 'marker2_xData', event_riseTime, 'shadeData', patchCoor);

            if saveFig 
                if n ~= 1 || ~saveWithGui
                    saveWithGui = false;
                end
                    saveDir = savePlot(f,'save_dir', saveDir, 'guiSave', saveWithGui, 'fname', figName);
            end

            if pausePlot
                pause
            end
        end
    end

    varargout{1} = saveDir;
end

