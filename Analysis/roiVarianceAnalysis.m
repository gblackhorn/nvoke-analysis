function [varargout] = roiVarianceAnalysis(alignedData,propertyName,varargin)
    % Analyze the variance of specified event properties

    % alignedData: output of function 'get_event_trace_allTrials'
    % propertyName: structure fields in alignedData(n).traces(m).eventProp
    %   - rise_duration
    %   - FWHM
    %   - peak_mag_delta
    %   - peak_delta_norm_hpstd


    % default
    peakCat = 'spon';
    normData = false; % normalize the data with the mean of spontaneous event property
    normLabel = '[normalized to spon]'; % Used to compose the figure titile

    createFig = false;
    titleStr = sprintf('ROI prop variance');


    unit_width = 0.06; % normalized to display
    unit_height = 0.3; % normalized to display
    column_lim = 1; % number of axes column

    MaxViolinPerPlot = 15;

    debugMode = false;


    % Optionals
    for ii = 1:2:(nargin-2)
        if strcmpi('plotWhere', varargin{ii})
            plotWhere = varargin{ii+1}; 
        elseif strcmpi('peakCat', varargin{ii})
            peakCat = varargin{ii+1}; 
        elseif strcmpi('normData', varargin{ii})
            normData = varargin{ii+1}; 
        end
    end 


    % Get the specified event properties and calculate the variance, STD, and SEM for every ROI
    [roiEventVal,recNames,roiNames,roiVariance,roiStd,roiSem] = getEventPropFromROIs(alignedData,...
        propertyName,'peakCat',peakCat,'normData',true);

    % Find the recordings with empty variance, STD, and SEM. Remove them
    emptyRecIDX = find(cellfun(@isempty,roiVariance));
    roiEventVal(emptyRecIDX) = [];
    recNames(emptyRecIDX) = [];
    roiNames(emptyRecIDX) = [];
    roiVariance(emptyRecIDX) = [];
    roiStd(emptyRecIDX) = [];
    roiSem(emptyRecIDX) = [];

    % Get the number of recordings
    recNum = numel(recNames);
    recNames = cellfun(@(x) strrep(x,'-','T'),recNames,'UniformOutput',false);
    recNames = cellfun(@(x) ['D',x],recNames,'UniformOutput',false);


    % Get the max and min of roiVariance, and roiStd. Calculate the range margin for y axis in the plots
    roiVarianceAll = vertcat(roiVariance{:});
    roiVarianceMax = max(roiVarianceAll);
    roiVarianceMin = min(roiVarianceAll);
    rangMarginVariance = (roiVarianceMax-roiVarianceMin)/10;

    roiStdAll = vertcat(roiStd{:});
    roiStdMax = max(roiStdAll);
    roiStdMin = min(roiStdAll);
    rangMarginStd = (roiStdMax-roiStdMin)/10;


    % Create violin plots to show the variance/STD
    rowNum = ceil(recNum/MaxViolinPerPlot);
    [fV,f_rowNum,f_colNum] = fig_canvas(rowNum,'unit_width',...
        unit_width*MaxViolinPerPlot,'unit_height',unit_height,'column_lim',1,...
        'fig_name',titleStr); % create a figure
    [fStd,~,~] = fig_canvas(rowNum,'unit_width',...
        unit_width*MaxViolinPerPlot,'unit_height',unit_height,'column_lim',1,...
        'fig_name',titleStr); % create a figure
    tloV = tiledlayout(fV, rowNum, MaxViolinPerPlot); % setup tiles
    tloStd = tiledlayout(fStd, rowNum, MaxViolinPerPlot); % setup tiles

    for i = 1:rowNum
        if i == 1
            plotWidth = MaxViolinPerPlot;

            if rowNum == 1
                groupIDX = [1:recNum];
            else
                groupIDX = [1:MaxViolinPerPlot];
            end
        elseif i > 1 && i < rowNum
            plotWidth = MaxViolinPerPlot;
            groupIDX = [(i-1)*MaxViolinPerPlot+1:(i-1)*MaxViolinPerPlot+MaxViolinPerPlot];
        elseif i == rowNum && i ~= 1
            plotWidth = recNum-(i-1)*MaxViolinPerPlot;
            groupIDX = [(i-1)*MaxViolinPerPlot+1:recNum];
        end

        % Create a structure used for violin plots
        violinVariance = empty_content_struct(recNames(groupIDX),1);
        violinStd = empty_content_struct(recNames(groupIDX),1);
        for j = groupIDX(1):groupIDX(end)
            violinVariance.(recNames{j}) = roiVariance{j};
            violinStd.(recNames{j}) = roiStd{j};
        end

        if debugMode
            fprintf('Create plot %d/%d\n',i,rowNum)
            if i == 2
                pause
            end
        end

        % Plot roi Variance in plot tloV, axV
        axV = nexttile(tloV,[1 plotWidth]); 
        violinplot(violinVariance);
        ylim([roiVarianceMin-rangMarginVariance roiVarianceMax+rangMarginVariance])
        xtickangle(45);
        xlabel('Recording Date and Time')
        ylabel('Variance')
        if normData
            titleVariance = sprintf('ROI %s %s variance',propertyName,normLabel);
        else
            titleVariance = sprintf('ROI %s variance',propertyName);
        end
        titleVariance = strrep(titleVariance,'_','-');
        sgtitle(titleVariance)

        % Plot roi Variance in plot tloStd, axV
        axStd = nexttile(tloStd,[1 plotWidth]); 
        violinplot(violinStd);
        ylim([roiStdMin-rangMarginStd roiStdMax+rangMarginStd])
        xtickangle(45);
        xlabel('Recording Date and Time')
        ylabel('Variance')
        if normData
            titleSTD = sprintf('ROI %s %s STD',propertyName,normLabel);
        else
            titleSTD = sprintf('ROI %s STD',propertyName);
        end
        titleSTD = strrep(titleSTD,'_','-');
        sgtitle(titleSTD)
    end
end
