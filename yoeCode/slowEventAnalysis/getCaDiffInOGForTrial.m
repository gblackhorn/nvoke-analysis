function [caDiffOG] = getCaDiffInOGForTrial(trialData, plotWhere)
% get absolute difference between mean ca trace during all OG trials in all
% ROIS, and the mean ca 

if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end



frameRate = getFrameRateForTrial(trialData);
[OGLEDstarts OGLEDends] = getOGLEDstartStopsforTrial(trialData, frameRate);
nROIs = getNROIsFromTrialData(trialData);
trialIDs = getTrialIDsFromROIdataStruct(trialData);
trialType = getTrialTypeFromROIdataStruct(trialData);


for roi = 1:nROIs
    trace = getROItraceFromTrialData(trialData, roi);    
    [caDiffOG{roi}] = getCaDiffOGforROI(trace, OGLEDstarts, OGLEDends);
    
end


NROWS = 2;
NCOLS = ceil (nROIs / NROWS);
xAx = [1:nROIs];


for roi = 1:nROIs
    meanDiff = mean(caDiffOG{roi}, 'omitnan');
    stdDiff = std(caDiffOG{roi}, 'omitnan');
    nStims = length(caDiffOG{roi});
    
    bar(roi, meanDiff, 'FaceColor', 'blue', 'FaceAlpha', 0.4);
 
    errorbar(roi, meanDiff, stdDiff, 'CapSize', 20, 'Color', 'black', 'LineStyle', 'none', 'LineWidth', 2);
    

    scatter(ones(nStims, 1)*roi, caDiffOG{roi}, 50, 'filled','MarkerEdgeColor','black', 'jitter','on', 'jitterAmount',0.3);


end

xlabel ('ROI #');
titleString = (['Mean fluorescence change during stimulation ' trialType ' in trial ' trialIDs{1}]);
title (titleString);