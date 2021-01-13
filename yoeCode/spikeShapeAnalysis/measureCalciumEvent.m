function [spikeAmps] = measureCalciumEvent(calciumEventTraces, PREwin, POSTwin, frameRate, plotWhere)

% if plotWhere is given, it is a handle for axes for plotting
% if not given, make a new fig
if (~exist('plotWhere', 'var'))
    scatterPlotH = figure(); hold on;
else
    axes(plotWhere);
end


[traceLength nEvents] = size(calciumEventTraces);
xAx = [1:traceLength];
xAx = xAx ./ frameRate;
calciumEventTrace_baselineShifted = calciumEventTraces - calciumEventTraces(1, :);
spikeAmps = calciumEventTrace_baselineShifted(PREwin, :);
axes(plotWhere); hold on;
plot (xAx, calciumEventTrace_baselineShifted, 'b', 'HandleVisibility','off');
plot(xAx, mean(calciumEventTrace_baselineShifted', 'omitnan'), 'r', 'LineWidth', 2, 'HandleVisibility','off');
peakXarr = ones(nEvents, 1)*PREwin;
s = scatter (peakXarr ./ frameRate, spikeAmps, 'green', 'filled');
xlabel ('sec');
xlim ([0 10]);
legend ({' peak '});




%alignedTraces = alignCaEventsOnPeak(calciumEventTrace, PREwin, POSTwin);