function [varargout] = plot_ROIevent_scatter_from_trial(trialData,varargin)
    % plot events as scatter all ROIS in a trial: lowpassed, deconvoluted
    
    % Defaults
    plotInterval = 5; % offset on y axis to seperate data from various ROIs
    sz = 20; % marker area
    plot_hist = true;
    hist_binsize = 5; % the size of the bin, used to calculate the edges of the bins

    save_fig = false;
    save_dir = '';

    % Optionals for inputs
    for ii = 1:2:(nargin-1)
    	if strcmpi('plotInterval', varargin{ii})
    		plotInterval = varargin{ii+1};
    	elseif strcmpi('plot_hist', varargin{ii})
    		plot_hist = varargin{ii+1};
        elseif strcmpi('hist_binsize', varargin{ii})
            hist_binsize = varargin{ii+1};
        elseif strcmpi('sz', varargin{ii})
            sz = varargin{ii+1};
    	elseif strcmpi('save_fig', varargin{ii})
    		save_fig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        end
    end

    %% main contents
    nROIs = getNROIsFromTrialData(trialData);
    frameRate = getFrameRateForTrial(trialData);
    trialType = getTrialTypeFromROIdataStruct(trialData);
    nFrames = getTrialLengthInFrames(trialData);
    trialID = getTrialIDsFromROIdataStruct(trialData);
    fovInfo = get_fov_info(trialData);

    peak_properties_col = 5;
    xAx = trialData{2}.lowpass.Time; % use time information from lowpass data
    roi_num = size(trialData{peak_properties_col},2);

    % f = figure;
    f = figure('Units', 'Normalized', 'OuterPosition', [0.05, 0.05, 0.95, 0.95 ]); 

    % hold on

    roi_names = cell(roi_num,1);
    trace_y_pos = zeros(1, roi_num);
    trace_y_tick = cell(size(trace_y_pos));
    spikeFrames_all_cell = cell(roi_num,1);

    if plot_hist
        tlo = tiledlayout(f,2,1);
        ax = nexttile(tlo);
    end

    hold on
    for rn = 1:roi_num
        roi_name = trialData{peak_properties_col}(:,rn).Properties.VariableNames{:};
        roi_names{rn} = roi_name;
        trace_y_pos(rn) = trace_y_pos(rn)-rn*plotInterval;
        trace_y_tick{rn} = roi_name;

        spikeFrames = getSpikeFramesForROI(trialData,rn, 'rise');
        spikeFrames_all_cell{rn} = spikeFrames;
        if (find (~isnan(spikeFrames)))
            spike_y = trace_y_pos(rn)*ones(size(spikeFrames));
            s1= scatter (xAx(spikeFrames), spike_y,sz,'k|','filled',...
                'MarkerEdgeColor', 'k','LineWidth', 1);
        else
            s1 = [];
        end
    end
    spikeFrames_all = cell2mat(spikeFrames_all_cell);
    spikeFrames_all(isnan(spikeFrames_all)) = [];
    spikeTime_all = xAx(spikeFrames_all); % used to plot the histogram showing the spike counts of all rois at different time
    yticks(flip(trace_y_pos));
    yticklabels(flip(trace_y_tick));
    set(gca,'Xtick',[xAx(1):10:xAx(end)])

    if nROIs ~= 0
        drawStims(trialData, gca);
        set(gca,'children',flipud(get(gca,'children')))
    end

    trialID_title = strrep(trialID{1}, '_', ' ');
    titleString = sprintf('scatter Lowpass ROI event from trial %s yInt%d',trialID_title,plotInterval);

    if ~isempty(strfind(trialType, 'OG-LED')) || ~isempty(strfind(trialType, 'GPIO-1'))
        trialType_new = replace(trialType, 'OG-LED', 'OG-stim');
        trialType_new = replace(trialType, 'GPIO-1', 'AIRPUFF-stim');
    else
        trialType_new = 'no stim';
    end
    % file_name = [titleString ', with ', trialType_new]; 
    file_name = sprintf('%s with %s',titleString,trialType_new); 

    if ~isempty(fovInfo)
        titleString = {file_name; fovInfo};
    else
        titleString = file_name;
    end

    title(titleString);
    xlabel ('sec');
    scatter_xl = xlim;

    if plot_hist
        ax = nexttile(tlo);
        hist_binedge = [xAx(1):hist_binsize:xAx(end)];
        if xAx(end) > hist_binedge(end)
            hist_binedge = [hist_binedge xAx(end)];
        end
        histogram(spikeTime_all,hist_binedge);
        xlim(scatter_xl)
    end

    if save_fig
        % dt = datestr(now, 'yyyymmdd');
        % fname = sprintf('%s-%s',title_str,dt);
        fname = file_name;
        if isempty(save_dir)
            save_dir = uigetdir;
        end
        savePlot(f,...
            'guiSave', 'off', 'save_dir', save_dir, 'fname', fname);
    end

end

