figure; 

subplot (2, 3, 1); hold on;
plotAllTrigSpikesFromGroup(ROIdata_AP_contra, 5, 15, gca);



subplot (2,3, 2); hold on;
plotAllTrigSpikesFromGroup(ROIdata_OGLED1, 5, 15, gca);

subplot (2, 3, 3); hold on;
plotAllTrigSpikesFromGroup(ROIdata_OGLED5, 5, 15, gca);

subplot (2, 3, 4); hold on;
plotAllTrigSpikesFromGroup(ROIdata_OGLED10, 5, 15, gca);

% subplot (2, 3, 5); hold on;
% 
% plotAllTrigSpikesFromGroup(ROIdata_OGLED1510, 5, 15, gca);
% title ('OG 5 and 10 s trials pooled');