#!/bin/bash
#SBATCH -p compute
#SBATCH -t 1-0
#SBATCH --mem=256G
#SBATCH -c 32

# Load matlab
module load matlab 

# matlab program with options for batch processing
# mlab_cmd="matlab -nosplash -nodisplay -nojvm -nodesktop"
mlab_cmd="matlab -nosplash -nodisplay -nodesktop"

# set inputs
folder_to_process=/flash/UusisaariU/GD/data_folder.xKs2rn/
save_results=false	
plot_contour=false
plot_roi_traces=false
creat_video=true

# enter the user directory on flash
cd /flash/UusisaariU/GD/code

# Run code for CNMFe process
${mlab_cmd} -r "folder_to_process='${folder_to_process}'; save_results=${save_results}; plot_contour=${plot_contour}; plot_roi_traces=${plot_roi_traces}; creat_video=${creat_video}; cnmfe_series_gen_plot_video_cluster('folder', folder_to_process, 'save_results', save_results, 'plot_contour', plot_contour, 'plot_roi_traces', plot_roi_traces, 'creat_video', creat_video);"

# # Sync temp dir with cnmfe output to data folder in the bucket
# rsync -av --no-group --no-perms $tempdir/ deigo:$folder_to_process/

# # Clean up by removing our temporary directory
# rm -r $tempdir