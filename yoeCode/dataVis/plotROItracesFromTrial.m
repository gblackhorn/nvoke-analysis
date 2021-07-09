function [varargout] = plotROItracesFromTrial (trialData, varargin)
% plot traces from all ROIS in a trial: lowpassed, deconvoluted
% scatter on info from peak locations for lowpassed, deconv, 
% also rise and decay (from lowpassed)

%ROI traces are shifted on page to make easier to be seen
% input is one row from ROIdatastructure

% Default
SavePlot = false;
SaveTo = pwd; % save plot to dir
SaveWithGUI = false;
traceNum_perFig = 10;
plotInterval = 20; % offset for traces on y axis to seperate them
vis = 'on'; % set the 'visible' of figures

% Optionals
for ii = 1:2:(nargin-1)
    if strcmpi('SavePlot', varargin{ii})
        SavePlot = varargin{ii+1};
    elseif strcmpi('SaveTo', varargin{ii})
        SaveTo = varargin{ii+1};
    elseif strcmpi('SaveWithGUI', varargin{ii})
        SaveWithGUI = varargin{ii+1};
    elseif strcmpi('traceNum_perFig', varargin{ii})
        traceNum_perFig = varargin{ii+1};
    elseif strcmpi('vis', varargin{ii})
        vis = varargin{ii+1};
    end
end

if SavePlot && SaveWithGUI
    SaveTo = uigetdir(SaveTo,...
            'Select a folder to save figures');
    if SaveTo == 0
        disp('Folder for saving figures not selected')
        return
    end
end

% Main contents
nROIs = getNROIsFromTrialData(trialData);
frameRate = getFrameRateForTrial(trialData);
trialType = getTrialTypeFromROIdataStruct(trialData);
nFrames = getTrialLengthInFrames(trialData);
trialID = getTrialIDsFromROIdataStruct(trialData);
fovInfo = get_fov_info(trialData);
% if isfield(trialData{2}, 'FOV_loc')
%     fovInfo = get_fov_info(trialData{2}.FOV_loc);
% end

peak_properties_col = 5;
xAx = trialData{2}.lowpass.Time; % use time information from lowpass data

nFig = ceil(nROIs/traceNum_perFig);




for fn = 1:nFig
    roi_num_start = (fn-1)*traceNum_perFig+1;
    roi_num_end = min([nROIs, fn*traceNum_perFig]);

    f(fn) = figure('Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ], 'visible', vis); 
    hold on

    if exist('p', 'var')
        clear p % clear figure info from previous figure
    end

    % xAx = [1:nFrames];
    % xAx = xAx ./ frameRate;
    % xAx = trialData{2}.lowpass.Time; % use time information from lowpass data

    
    roi_names = cell((roi_num_end-roi_num_start+1), 1);
    for ROI = roi_num_start:roi_num_end
        ROI_plot_idx = ROI-(fn-1)*traceNum_perFig; % the index of ROI in a figure
        
        % display(['ROI ', num2str(ROI)]) % For debugging

        roi_name = trialData{peak_properties_col}(:,ROI).Properties.VariableNames{:};
        roi_names{ROI_plot_idx} = roi_name;
        
        fullTrace = getROItraceFromTrialData(trialData, ROI, 'lowpass', 'roi_name', roi_name);
        fullTraceShifted = fullTrace - (ROI_plot_idx*plotInterval);
        deconTrace = getROItraceFromTrialData(trialData, ROI, 'decon', 'roi_name', roi_name);
        deconTraceShifted = deconTrace - (ROI_plot_idx*plotInterval);
        
        p(ROI_plot_idx) = plot (xAx, fullTraceShifted, 'LineWidth', 1, 'Color','k');
        p(ROI_plot_idx) = plot (xAx, deconTraceShifted, 'LineWidth', 1.5);
        
        spikeFrames = getSpikeFramesForROI(trialData,ROI, 'lowpass');
        if (find (~isnan(spikeFrames)))
            s1= scatter (xAx(spikeFrames), fullTraceShifted(spikeFrames), 'b*', 'LineWidth', 1);
        else
            s1 = [];
        end
        
        spikeFramesDecon = getSpikeFramesForROI(trialData,ROI, 'decon');
        if (find (~isnan(spikeFramesDecon)))
            s2= scatter (xAx(spikeFramesDecon), deconTraceShifted(spikeFramesDecon), 'ro', 'LineWidth', 1);
        else
            s2 = [];
        end
        
        riseFrames = getSpikeFramesForROI(trialData,ROI, 'rise');
        if (find (~isnan(riseFrames)))
            s3= scatter (xAx(riseFrames), fullTraceShifted(riseFrames), 'g>', 'LineWidth', 1);
        else
            s3 = [];
        end
        
         decayFrames = getSpikeFramesForROI(trialData,ROI, 'decay');
        if (find (~isnan(decayFrames)))
            s4= scatter (xAx(decayFrames), fullTraceShifted(decayFrames), 'c<');
        else
            s4 = [];
        end
        
        
    end

    if nROIs ~= 0
        % annotateStims(trialData, gca);
        drawStims(trialData, gca);
        set(gca,'children',flipud(get(gca,'children')))
        % ROIns = [1:nROIs]';
        % legendStr = cellstr(num2str(ROIns));
        legendStr = roi_names;
        legend([p s1 s2 s3 s4] , [legendStr ;'L'; 'D'; 'r'; 'd'], 'Location', 'northeastoutside');
    end

    trialID_title = strrep(trialID{1}, '_', ' ');
    titleString = (['Lowpass ROI traces from trial ', trialID_title, ' - ', num2str(fn)]);
    % if (strcmp(trialType, 'GPIO1-1s'))
    %     titleString = [titleString ', with AIRPUFF stim']; 
    % else
        
    %     if (contains(trialType, 'OG-LED'))
    %         titleString = [titleString ', with OPTOGEN stim'];
    %     else
    %         titleString = [titleString ', no stim'];
    %     end
        
    % end

    if ~isempty(strfind(trialType, 'OG-LED')) || ~isempty(strfind(trialType, 'GPIO-1'))
        trialType_new = replace(trialType, 'OG-LED', 'OPTOGEN-stim');
        trialType_new = replace(trialType, 'GPIO-1', 'AIRPUFF-stim');
    else
        trialType_new = 'no stim';
    end
    file_name = [titleString ', with ', trialType_new]; 

    if ~isempty(fovInfo)
        titleString = {file_name; fovInfo};
    else
        titleString = file_name;
    end

    title(titleString);
    xlabel ('sec');
    % R = 1;

    if SavePlot
        figfile = file_name;
        fig_fullpath = fullfile(SaveTo, figfile);
        savefig(gcf, [fig_fullpath, '.fig']);
        saveas(gcf, [fig_fullpath, '.jpg']);
        saveas(gcf, [fig_fullpath, '.svg']);
        % close(gcf)
    end
end