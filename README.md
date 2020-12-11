# nvoke-analysis
Processing, exporting, analyzing nvoke recordings. Using workflow.m to go through processing 

1. Use "nvoke_file_process.m" to generate -PP (pre-processed), -BP (spatial filtered), -MC (motion corrected) and -DFF (deltaF/F) recordings, and to copy all these files and GPIO file to project folder.
2. Certain manual work need to be done in IDPS (inscopix data processing software) and with CNMFe code.
	- CNMFe process motion corrected data and export mat file containing ROI traces. Or draw ROI in IDPS and export ROI traces as csv 
	- Manually export GPIO info (including stimulation info) from IDPS.
3. Export processed files (except GPIO) from isxd file to tiff and csv with "nvoke_export_file.mlapp" for future analysis if not using CNMFe.  
4. Use "plot_roi_gpio.m" to read ROI and GPIO info and plot traces.
5. Integrate ROI trace info and GPIO info from multiple recodings to a single .mat file with ROI_matinfo2matlab.m for further analysis.
6. Follow the guide in workflow.m
