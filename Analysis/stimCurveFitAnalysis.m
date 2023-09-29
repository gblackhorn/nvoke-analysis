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


    % Optionals
    for ii = 1:2:(nargin-1)
        if strcmpi('filter_roi_tf', varargin{ii})
            filter_roi_tf = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('stimName', varargin{ii})
            stim_names = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        elseif strcmpi('filters', varargin{ii})
            filters = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % elseif strcmpi('titleStr', varargin{ii})
        %     titleStr = varargin{ii+1}; % struct var including fields 'cat_type', 'cat_names' and 'cat_merge'
        % % elseif strcmpi('normToFirst', varargin{ii})
        % %     normToFirst = varargin{ii+1};
        % elseif strcmpi('save_fig', varargin{ii})
        %     save_fig = varargin{ii+1};
        % elseif strcmpi('save_dir', varargin{ii})
        %     save_dir = varargin{ii+1};
        % elseif strcmpi('gui_save', varargin{ii})
        %     gui_save = varargin{ii+1};
        end
    end 

    % --
    % filter the trials and ROIs
    if filter_roi_tf    
        [alignedData] = Filter_AlignedDataTraces_withStimEffect_multiTrial(alignedData,...
                    'stim_names',stim_names,'filters',filters);
    end

    
    % --
    % loop through all the recordings to collect data
    recNum = numel(alignedData); % number of recordings
    roiNumAll = NaN(recNum,1); % number of ROIs in each recording
    roiNumFit = NaN(recNum,1); % number of ROIs with curve fitting during related to stimulations in each recording
    FitPercCell = cell(recNum,1); % percentage of fitted curve in ROIs
    preEventFreqFieldNames = {'eventFreq','fit','tau'};
    preEventFreqCells = cell(recNum,1);

    for rn = 1:recNum
        trialData = alignedData(rn);
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
        preEventFreqStruct = empty_content_struct(preEventFreqFieldNames,roiNumAll(rn)*uniStimRepeat);
        for n = 1:roiNumAll(rn)
            eventTime = [tracesData(n).(eventTimeType)];
            stimCurveFit = tracesData.StimCurveFit;
            curveFitIdx = [stimCurveFit.SN];
            curveFitTau = [stimCurveFit.tau];

            % loop through stimulation repeats
            for sn = 1:uniStimRepeat
                % find events in pre-stim ranges and calculate the event frequency
                preStimEventNum = numel(find(eventTime>=preStimRange(sn,1) & eventTime<preStimRange(sn,2)));
                preEventFreqIDX = (n-1)*uniStimRepeat+sn;
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
        preEventFreqCells{rn} = preEventFreqStruct;
    end
    FitPerc = cat(2,FitPercCell{:});
    preEventFreq = cat(2,preEventFreqCells{:});

    analysisResultFieldNames = {'filterStatus','filterStimName','filterStimEffect',...
    'roiNumAll','roiNumFit','roiNumNotFit','fitCurvePerc','fitCurvePercMean',...
    'preStimTimeDuration','eventTimeType','preEventFreq','preEventFreqMean'};


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
    analysisResult.preEventFreq = preEventFreq;
    analysisResult.preEventFreqMean = mean(preEventFreq);

end


