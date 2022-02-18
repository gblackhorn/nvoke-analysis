figure;

PREwin = 15; POSTwin = 150;

subplot(2, 3, 1); hold on;
allSpikes_nostim = plotAllSpikesAllTrials(ROIdata_nostim, PREwin, POSTwin, gca);
meanNoStim = mean(allSpikes_nostim', 'omitnan');
meanNoStim = meanNoStim - meanNoStim(PREwin-10);

subplot(2, 3, 2); hold on;
allSpikes_AP = plotAllSpikesAllTrials(ROIdata_AP_contra, PREwin, POSTwin, gca);
meanAP = mean(allSpikes_AP', 'omitnan');
meanAP = meanAP - meanAP(PREwin-10);


subplot(2, 3, 4); hold on;
allSpikes_OGLED5 = plotAllSpikesAllTrials(ROIdata_OGLED5, PREwin, POSTwin, gca);
meanOGLED5 = mean(allSpikes_OGLED5', 'omitnan');
meanOGLED5 = meanOGLED5 - meanOGLED5(PREwin-10);


subplot(2, 3, 5); hold on;
allSpikes_OGLED10 = plotAllSpikesAllTrials(ROIdata_OGLED10, PREwin, POSTwin, gca);
meanOGLED10 = mean(allSpikes_OGLED10', 'omitnan');
meanOGLED10 = meanOGLED10 - meanOGLED10(PREwin-10);

subplot(2, 3, 6); hold on;
allSpikes_OGLED1 = plotAllSpikesAllTrials(ROIdata_OGLED1, PREwin, POSTwin, gca);
meanOGLED1 = mean(allSpikes_OGLED1', 'omitnan');
meanOGLED1 = meanOGLED1 - meanOGLED1(PREwin-10);

frameRate = getFrameRateForTrial(ROIdata_OGLED10(1, :));
xAx = [1:PREwin+POSTwin+1];
xAx = xAx ./ frameRate;



subplot(2, 3, 3); hold on;
plot (xAx, meanNoStim ,'LineWidth', 3);
plot (xAx, meanAP,'LineWidth', 3);
plot (xAx, meanOGLED1,'LineWidth', 3);
plot (xAx, meanOGLED5,'LineWidth', 3);
plot (xAx, meanOGLED10,'LineWidth', 3);
xlabel ('sec');

legend({'no stim' 'airpuff'  'OGLED1'  'OGLED5' 'OGLED10'});