% manully delet bad ROIs
nvoke_data = ROIdata; % specify the variable containing all ROI_data
rec_row = 1; % specify recording number
roiID = [2 5 6 7]; % specify roi needed to be deleted

% data_decon = nvoke_data{rec_row,2}.decon;
% data_raw = nvoke_data{rec_row,2}.raw;

nvoke_data{rec_row,2}.decon(:, (roiID+1)) = [];
nvoke_data{rec_row,2}.raw(:, (roiID+1)) = [];

ROIdata = nvoke_data;

% data_decon(:, (roiID+1)) = [];
% data_raw(:, (roiID+1)) = [];