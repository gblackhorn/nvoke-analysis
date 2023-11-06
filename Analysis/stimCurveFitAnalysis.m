function [analysisResult,varargout] = stimCurveFitAnalysis(alignedData,varargin)
    % Conclude the the data of stimulation caused curve fit
    %   - How many neurons with/without fitted curve
    %   - Percentage of fitted curve: number of fitted curve/number of stimualtion
    %   - Calculate the event frequency before the stimulation. Group the stimulations based on if
    %     there is a fitted curves. By default, only the neurons having at least one fitted curve
    %     will be included in this analysis

    % default variables
    filter_roi_tf = false; % true/false. If true, screen ROIs using stim_names and stimulation effects (filters)
    stim_names = {'og-5s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
    filters = {[0 nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

    preStimTimeDuration = 5; % unit: sec. Time duration prio to the stimulation. Event frequency will be calculated 
    eventTimeType = 'peak_time'; % 'rise_time'/'peak_time'. category of event used for calculate the frequency

    eventFreqROIset = 'fitPos'; % fitPos/all. fitPos: only use the neurons with at least one fit. All: use all neurons

    % default figure parameters
    unit_width = 0.2; % normalized to display
    unit_height = 0.2; % normalized to display
    column_lim = 4; % number of axes column
    row_lim = 4;

    saveFig = false;
    save_dir = '';
    guiSave = true; % Options: 'on'/'off'. whether use the gui to choose the save_dir

    debugMode = false;

    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('filter_roi_tf', varargin{ii})
            filter_roi_tf = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stim_names', varargin{ii})
            stim_names = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('filters', varargin{ii})
            filters = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('preStimTimeDuration', varargin{ii})
            preStimTimeDuration = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('eventTimeType', varargin{ii})
            eventTimeType = varargin{ii+1};
        elseif strcmpi('eventFreqROIset', varargin{ii})
            eventFreqROIset = varargin{ii+1};
        elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1};
        elseif strcmpi('saveFig', varargin{ii})
            saveFig = varargin{ii+1};
        elseif strcmpi('save_dir', varargin{ii})
            save_dir = varargin{ii+1};
        elseif strcmpi('guiSave', varargin{ii})
            guiSave = varargin{ii+1};
        end
    end 

    % --
    % filter the trials and ROIs
    if filter_roi_tf    
        [alignedData] = filter_groups_in_structure(alignedData,'stim_name','exact_words',stim_names);
        [alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
                    'stim_names',stim_names,'filters',filters);
    end
    
    % --
    % loop through all the recordings to collect data
    recNum = numel(alignedData); % number of recordings
    roiNumAll = NaN(recNum,1); % number of ROIs in each recording
    roiNumFit = NaN(recNum,1); % number of ROIs with curve fitting during related to stimulations in each recording
    FitPercCell = cell(recNum,1); % percentage of fitted curve in ROIs
    preEventFreqFieldNames = {'trialName','roiName','stimIDX','eventFreq','fit','tau'};
    preEventFreqCells = cell(1,recNum);

    for rn = 1:recNum
        trialData = alignedData(rn);
        trialName = trialData.trialName;

        if debugMode
            fprintf('trial %d/%d: %s\n',rn,recNum,trialName);
            if rn == 35
                pause
            end
        end

        % get the combined (unified) stimulation ranges for a recording
        uniStim = trialData.stimInfo.UnifiedStimDuration;
        uniStimRanges = uniStim.range; % n*2 matrix (starts and ends). n is the number of repeats.
        uniStimRepeat = uniStim.repeats; % number of repeats
        preStimRange = [uniStimRanges(:,1)-preStimTimeDuration, uniStimRanges(:,1)]; % time ranges used for calculating preStim event freq

        % get the number of all ROIs and the number of ROIs with fitted curvers
        tracesData = trialData.traces;
        roiFitIdx = find([tracesData.StimCurveFit_TauNum]); % index of ROIs with curve fitting
        roiNumAll(rn) = numel(tracesData);
        roiNumFit(rn) = numel(roiFitIdx);

        % collect the percentage of fitted curve (in every ROI).
        FitPercCell{rn} = [tracesData(roiFitIdx).StimCurveFit_TauNum]./uniStimRepeat;

        % loop through ROIs, and collect event frequency before each stimulation in a duration of 'preStimTimeDuration'. 
        switch eventFreqROIset
            case 'fitPos'
                preEventFreqStruct = empty_content_struct(preEventFreqFieldNames,roiNumFit(rn)*uniStimRepeat);
                traceDataFreq = tracesData(roiFitIdx);
            case 'all'
                preEventFreqStruct = empty_content_struct(preEventFreqFieldNames,roiNumAll(rn)*uniStimRepeat);
                traceDataFreq = tracesData;
            % otherwise
        end
        roiNum = numel(traceDataFreq); % Number of ROIs in the (rn)th recording for event frequency analysis

        for n = 1:roiNum
            roiName = traceDataFreq(n).roi;

            if debugMode
                fprintf(' - roi %g/%g: %s\n',n,roiNumAll(rn),roiName)
                % if rn == 7
                %     pause
                % end
            end

            eventTime = [traceDataFreq(n).eventProp.(eventTimeType)];
            stimCurveFit = traceDataFreq.StimCurveFit;
            curveFitIdx = [stimCurveFit.SN];
            curveFitTau = [stimCurveFit.tau];

            % loop through stimulation repeats
            for sn = 1:uniStimRepeat
                % find events in pre-stim ranges and calculate the event frequency
                preStimEventNum = numel(find(eventTime>=preStimRange(sn,1) & eventTime<preStimRange(sn,2)));
                preEventFreqIDX = (n-1)*uniStimRepeat+sn;
                preEventFreqStruct(preEventFreqIDX).trialName = trialName;
                preEventFreqStruct(preEventFreqIDX).roiName = roiName;
                preEventFreqStruct(preEventFreqIDX).stimIDX = sn;
                preEventFreqStruct(preEventFreqIDX).eventFreq = preStimEventNum/preStimTimeDuration;

                % check if this stimulation causes a fitted curve
                stimCurveFitIDX = find(curveFitIdx==sn);
                if ~isempty(stimCurveFitIDX)
                    preEventFreqStruct(preEventFreqIDX).fit = true;
                    preEventFreqStruct(preEventFreqIDX).tau = curveFitTau(stimCurveFitIDX);
                else
                    preEventFreqStruct(preEventFreqIDX).fit = false;
                    preEventFreqStruct(preEventFreqIDX).tau = NaN;
                end
            end
        end
        preEventFreqCells{rn} = preEventFreqStruct';
    end
    FitPerc = cat(2,FitPercCell{:});
    preEventFreq = cat(2,preEventFreqCells{:});

    analysisResultFieldNames = {'filterStatus','filterStimName','filterStimEffect',...
    'roiNumAll','roiNumFit','roiNumNotFit','fitCurvePerc','fitCurvePercMean',...
    'preStimTimeDuration','eventTimeType','preEventFreqAll','preEventFreqFit','preEventFreqNotFit',...
    'preEventFreqFitMean','preEventFreqNotFitMean','tau','tauMean'};

    preEventFreqFitVal = [preEventFreq.fit];
    preEventFreqFitIDX = find(preEventFreqFitVal==1);
    preEventFreqNotFitIDX = find(preEventFreqFitVal==0);
    preEventFreqFit = [preEventFreq(preEventFreqFitIDX).eventFreq];
    preEventFreqNotFit = [preEventFreq(preEventFreqNotFitIDX).eventFreq];
    preEventFreqFitMean = mean(preEventFreqFit);
    preEventFreqNotFitMean = mean(preEventFreqNotFit);
    tau = [preEventFreq(preEventFreqFitIDX).tau];
    tauMean = mean(tau);

    analysisResult.filterStatus = filter_roi_tf;
    analysisResult.filterStimName = stim_names;
    analysisResult.filterStimEffect = filters;
    analysisResult.roiNumAll = sum(roiNumAll);
    analysisResult.roiNumFit = sum(roiNumFit);
    analysisResult.roiNumNotFit = analysisResult.roiNumAll-analysisResult.roiNumFit;
    analysisResult.fitCurvePerc = FitPerc;
    analysisResult.fitCurvePercMean = mean(FitPerc);
    analysisResult.preStimTimeDuration = preStimTimeDuration;
    analysisResult.eventTimeType = eventTimeType;
    analysisResult.preEventFreqAll = preEventFreq;
    analysisResult.preEventFreqFit = preEventFreqFit;
    analysisResult.preEventFreqNotFit = preEventFreqNotFit;
    analysisResult.preEventFreqFitMean = preEventFreqFitMean;
    analysisResult.preEventFreqNotFitMean = preEventFreqNotFitMean;
    analysisResult.tau = tau;
    analysisResult.tauMean = tauMean;


    % ==========
    % visualize the results
    % create a canvas
    [f,f_rowNum,f_colNum] = fig_canvas(16,'unit_width',unit_width,'unit_height',unit_height,...
        'row_lim',row_lim,'column_lim',column_lim);
    tiledlayout(f,f_rowNum,f_colNum)

    % pie chart: roiFit vs roiNotFit (number and perc)
    % nexttile(1,[2 2]);
    nexttile(1);
    pieData = [analysisResult.roiNumFit analysisResult.roiNumNotFit];
    sliceNames = {'ROIs with decay curves', 'ROIs without decay curves'};
    pieChartTitleStr = 'Pie Chart roiNumFit vs roiNumNotFit';
    stylishPieChart(pieData,'sliceNames',sliceNames,'titleStr',pieChartTitleStr,'plotWhere',gca);

    % violin plot and/or bar plot: the percentage of fitted curve in ROIs
    nexttile(5);
    violinplot(analysisResult.fitCurvePerc(:),{'ROI decay perc'}); % ,'Width',0.1
    set(gca,'box','off')
    set(gca,'TickDir','out')
    title('Perc of fitted curve in ROIs')
    nexttile(6);
    decayPercInfo = barplot_with_errBar(analysisResult.fitCurvePerc(:),'barNames','ROI decay perc','plotWhere',gca);

    % viollin plot and/or bar plot: tau
    nexttile(3);
    violinplot(analysisResult.tau(:),{'Decay tau'}); % ,'Width',0.1
    set(gca,'box','off')
    set(gca,'TickDir','out')
    title('Tau of decays')
    nexttile(4);
    decayTauInfo = barplot_with_errBar(analysisResult.tau(:),'barNames','Decay tau','plotWhere',gca);

    % violin plot and/or bar plot: preEventFrquency (fit vs not fit)
    nexttile(7);
    preEventFreqDataViolin = struct('PEFnoDecay',analysisResult.preEventFreqNotFit,...
        'PEFdecay',analysisResult.preEventFreqFit);
    violinplot(preEventFreqDataViolin);
    set(gca,'box','off')
    set(gca,'TickDir','out')
    title(sprintf('preEventFrquency (decay vs no-decay) [roiSet: %s]',eventFreqROIset))
    % title('preEventFrquency (decay vs no-decay)')
    nexttile(8);
    preEventFreqDataBar = {analysisResult.preEventFreqFit(:),analysisResult.preEventFreqNotFit(:)};
    preEventFreqInfo = barplot_with_stat(preEventFreqDataBar,'group_names',{'PEFdecay','PEFnoDecay'},...
        'stat','upttest','ylabelStr','eventFreq','plotWhere',gca);

    % scatter plot of the tau-VS-preEventFreq
    nexttile(11,[2 2])
    stylishScatter(analysisResult.tau, analysisResult.preEventFreqFit,'plotWhere',gca,...
        'xlabelStr','Tau (s)','ylabelStr','preEventFreq (Hz)',...
        'titleStr','Fitted-curve-tau VS pre-curve-eventFreq');

    % Plot the bar and errbar val as numbers in a UItable
    nexttile(9,[1 2]);
    PEFmeanAndSte = struct('barNames',{preEventFreqInfo.data.group},...
        'barVal',{preEventFreqInfo.data.mean_val},'errBarVal',{preEventFreqInfo.data.ste_val});
    meanAndSte = struct2table([decayPercInfo decayTauInfo PEFmeanAndSte]);
    plotUItable(gcf,gca,meanAndSte);
    title('Mean (bar) and Ste (errBar) values')

    % stat result for violin plot and/or bar plot: preEventFrquency (fit vs not fit)
    nexttile(13,[1 2])
    PEFstat = struct('method',preEventFreqInfo.stat.stat_method,...
        'pVal',preEventFreqInfo.stat.p,'h',preEventFreqInfo.stat.h);
    PEFstatTab = struct2table(PEFstat);
    plotUItable(gcf,gca,PEFstatTab);
    title('stat for preEventFrquency (fit vs not fit)')

    % Save the plot
    if saveFig
        defaultFullPath = fullfile(save_dir,'stimCurveFitAnalysis.svg');
        if guiSave
            [fName,save_dir,indx] = uiputfile({'*.svg';'*.jpg';'*.fig'},...
                'Save stimCurveFitAnalysis figures',...
                defaultFullPath);
            if indx
                [~,fNameStem,fExt] = fileparts(fName);
            else
                return
            end
        else
            fNameStem = 'stimCurveFitAnalysis';
        end

        % This will save the figure to 3 files, as svg, jpg, and fig
        [save_dir] = savePlot(gcf,'save_dir',save_dir,'guiSave',false,...
            'fname',fNameStem);
    end
end


