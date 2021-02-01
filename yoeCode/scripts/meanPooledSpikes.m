

stdAPspikes = std(APspikeTraces', 'omitnan');
stdOGspikes = std(OGSpikeTraces', 'omitnan');
stdSpontSpikes = std(spontSpikeTraces', 'omitnan');

cla
errorbar(xAx, meanOGspikes, stdOGspikes ./ sqrt(176), 'LineWidth', 3)
errorbar(xAx, meanAPspikes, stdAPspikes ./ sqrt(97), 'LineWidth', 3)
errorbar(xAx, meanSpontSpikes, stdSpontSpikes ./ sqrt(2703), 'LineWidth', 3)
xlabel ('sec');

legend({'OG start n = 176' 'Airpuff n = 97' 'noStim n = 2703' }, 'FontSize', 14)

title ('All trials all ROIs pooled, mean +- SEM, 1 sec trigger window', 'FontSize', 14);

xAx = [1:111]./10;