function [analysisResult,varargout] = stimCurveFitAnalysis(alignedData,varargin)
    % Conclude the the data of stimulation caused curve fit
    %   - How many neurons with/without fitted curve
    %   - Percentage of fitted curve: number of fitted curve/number of stimualtion
    %   - Calculate the event frequency before the stimulation. Separate the trials with and without fitted curves

    % default
    filter_roi_tf = false; % true/false. If true, screen ROIs using stim_names and stimulation effects (filters)
    stim_names = {'og-5s','og-5s ap-0.1s'}; % compare the alignedData.stim_name with these strings and decide what filter to use
    filters = {[0 nan nan nan], [0 nan nan nan]}; % [ex in rb exApOg]. ex: excitation. in: inhibition. rb: rebound. exApOg: exitatory effect of AP during OG

    preStimTimeDuration = 5; % unit: sec. Time duration prio to the stimulation. Event frequency will be calculated 
    eventTimeType = 'peak_time'; % 'rise_time'/'peak_time'. category of event used for calculate the frequency
    debugMode = true;

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
        elseif strcmpi('debugMode', varargin{ii})
            debugMode = varargin{ii+1};
        % elseif strcmpi('save_dir', varargin{ii})
        %     save_dir = varargin{ii+1};
        % elseif strcmpi('gui_save', varargin{ii})
        %     gui_save = varargin{ii+1};
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
        preEventFreqStruct = empty_content_struct(preEventFreqFieldNames,roiNumAll(rn)*uniStimRepeat,2);
        for n = 1:roiNumAll(rn)

            roiName = tracesData(n).roi;

            if debugMode
                fprintf(' - roi %g/%g: %s\n',n,roiNumAll(rn),roiName)
                % if rn == 7
                %     pause
                % end
            end

            eventTime = [tracesData(n).eventProp.(eventTimeType)];
            stimCurveFit = tracesData.StimCurveFit;
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
    % analysisResult.preEventFreqMeanFit = mean(analysisResult.preEventFreq);



    % visualize the results

    % venn diagrams: roiFit vs roiNotFit (number and perc)

    % violin plot and/or bar plot: the percentage of fitted curve in ROIs

    % viollin plot and/or bar plot: tau

    % violin plot and/or bar plot: preEventFrquency (fit vs not fit)

end


