# nvoke-analysis
Processing, exporting, analyzing nvoke recordings

1. Use "nvoke_file_process.m" to generate -PP (pre-processed), -BP (spatial filtered), -MC (motion corrected) and -DFF (deltaF/F) recordings, and to copy all these files and GPIO file to project folder.
2. Certain manual work need to be done in IDPS (inscopix data processing software).
	- Import all the files generated and copied by "nvoke_file_process.m" to IDPS in step 1.
	- Draw ROI on "*-DFF.isxd" recordings in IDPS.
	- Manually export GPIO info from IDPS.
3. Export processed files (except GPIO) from isxd file to tiff and csv with "nvoke_export_file.mlapp" for future analysis.  
4. Use "plot_roi_gpio.m" to read ROI and GPIO info and plot traces.
