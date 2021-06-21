function R = plotROItracesFromTrial (trialData)
% plot traces from all ROIS in a trial: lowpassed, deconvoluted
% scatter on info from peak locations for lowpassed, deconv, 
% also rise and decay (from lowpassed)

%ROI traces are shifted on page to make easier to be seen
% input is one row from ROIdatastructure

nROIs = getNROIsFromTrialData(trialData);
frameRate = getFrameRateForTrial(trialData);
trialType = getTrialTypeFromROIdataStruct(trialData);
nFrames = getTrialLengthInFrames(trialData);
trialID = getTrialIDsFromROIdataStruct(trialData);

figure; hold on;
% xAx = [1:nFrames];
% xAx = xAx ./ frameRate;
xAx = trialData{2}.lowpass.Time; % use time information from lowpass data

plotInterval = 20;
for ROI = 1:nROIs
    
    fullTrace = getROItraceFromTrialData(trialData, ROI, 'lowpass');
    fullTraceShifted = fullTrace - (ROI*plotInterval);
    deconTrace = getROItraceFromTrialData(trialData, ROI, 'decon');
    deconTraceShifted = deconTrace - (ROI*plotInterval);
    
    p(ROI) = plot (xAx, fullTraceShifted, 'LineWidth', 1);
    p(ROI) = plot (xAx, deconTraceShifted, 'LineWidth', 1);
    
    spikeFrames = getSpikeFramesForROI(trialData,ROI, 'lowpass');
    if (find (~isnan(spikeFrames)))
       s1= scatter (xAx(spikeFrames), fullTraceShifted(spikeFrames), 'b*');
    end
    
    spikeFramesDecon = getSpikeFramesForROI(trialData,ROI, 'decon');
    if (find (~isnan(spikeFramesDecon)))
        s2= scatter (xAx(spikeFramesDecon), deconTraceShifted(spikeFramesDecon), 'ro');
    end
    
    riseFrames = getSpikeFramesForROI(trialData,ROI, 'rise');
    if (find (~isnan(riseFrames)))
        s3= scatter (xAx(riseFrames), fullTraceShifted(riseFrames), 'g>');
    end
    
     decayFrames = getSpikeFramesForROI(trialData,ROI, 'decay');
    if (find (~isnan(decayFrames)))
        s4= scatter (xAx(decayFrames), fullTraceShifted(decayFrames), 'c<');
    end
    
    
end


annotateStims(trialData, gca);
ROIns = [1:nROIs]';
legendStr = cellstr(num2str(ROIns));
legend([p s1 s2 s3 s4] , [legendStr ;'L'; 'D'; 'r'; 'd'] );


titleString = (['Lowpass ROI traces from trial ' trialID{1}]);
if (strcmp(trialType, 'GPIO1-1s'))
    titleString = [titleString ', with AIRPUFF stim']; 
else
    
    if (contains(trialType, 'OG-LED'))
        titleString = [titleString ', with OPTOGEN stim'];
    else
        titleString = [titleString ', no stim'];
    end
    
end

title(titleString);
xlabel ('sec');
R = 1;