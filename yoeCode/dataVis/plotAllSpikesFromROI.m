function R = plotAllSpikesFromROI (trialData, ROI, PREwin, POSTwin, plotWhere)
% if plotWhere is given, it is a handle for axes for plotting
% if not given, make a new fig
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end

spikeTraces = getAllspikeCaTracesForRoi(trialData, ROI, PREwin, POSTwin);

traceLen = length(spikeTraces);

% xAx = [1:traceLen];
% xAx = xAx ./ 10;
xAx = trialData{ROI, 2}.lowpass.Time; % use time information from lowpass data

plot(xAx, spikeTraces, 'blue');
plot(xAx, mean(spikeTraces', 'omitnan'), 'black', 'LineWidth', 2);


R = 1;
