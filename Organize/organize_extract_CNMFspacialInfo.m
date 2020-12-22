function [ROIdata_spacialInfo] = organize_extract_CNMFspacialInfo(source_var)
    % add spacial info of ROI from CNMFe *results.mat to trace stucture of ROIdata,
    % ROIdata_peakevent, or modified_ROIdata
    %   results.A and results.Cn are needed by func roimap to draw ROIs. This
    %   function will add results.A and results.Cn to where time_info and trace info are stored.
    cnmfe_results.A = source_var.A;
    cnmfe_results.Cn = source_var.Cn;
    ROIdata_spacialInfo = cnmfe_results;
end

