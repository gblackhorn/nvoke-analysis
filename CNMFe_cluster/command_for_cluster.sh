# Login the cluster 

# Note: Set up the direct access to the deigo cluster from outside. It also works when your device
# is in the OIST network

# Log into the Deigo using terminal (UNIX) or MobaXterm (Windows)
# Use your own deigo access to replace the part after 'ssh -X'
# ssh deigo-ext
ssh -X da-guo@deigo.oist.jp



# ====================
# Workflow of CNMFe process on deigo cluster

# 1. Go to the personal folder on flash. Flash is a fast storage. Cluster can access data here very
# quickly
# Modify the location below to your own flash folder
cd /flash/UusisaariU/GD/



# 2. (Optional) Manually update matlab codes and bash files using rsync if something is modified
# rsync -av 
# Modify the locations below to your folders
# Assign a bucket location containing the CNMFe related bash and matlab files to 'bucketCodeDir'
bucketCodeDir='/bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/'

# Assign a flash location for storing matlab codes to 'flashCodeDir'
flashCodeDir='/flash/UusisaariU/GD/code/' 

# Assign a flash location for storing bash files to 'flashHomeDir'
flashHomeDir='/flash/UusisaariU/GD/'

# sync matlab code and bash files from bucket to flash
rsync -av --include '*/' --include '*.m' --exclude '*' deigo:$bucketCodeDir/ $flashCodeDir/
rsync -av --include '*/' --include '*.sh' --exclude '*' deigo:$bucketCodeDir/ $flashHomeDir/

# sync matlab code and bash files from flash to bucket 
rsync -av --include '*/' --include '*.m' --exclude '*' $flashCodeDir/ deigo:$bucketCodeDir/ 
rsync -av --include '*/' --include '*.sh' --exclude '*' $flashHomeDir/ deigo:$bucketCodeDir/ 



# 3. Copy data files from bucket to flash using rsync

# Set folder path on Bucket to Copy data from bucket to flash
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/20230609_re-run_motion-correction/'
# bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/series_20230627/'
# bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/Moscope/INSCOPIX_tiff/M8/'
# bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/Moscope/INSCOPIX_tiff/M9_BMC/'
# bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/Moscope/INSCOPIX_tiff/M9_extra/'

# Create a folder, if it doesn't exist, to store data
mkdir /flash/UusisaariU/GD/data_series # make a folder with a fixed name
mktemp -d /flash/UusisaariU/GD/20230609_reMC_data.XXXXXX # make a folder whos name is a fixed string followed by a random string (.XXXXXX) 

# Assign the new dir to 'flashdatadir'
flashdatadir='/flash/UusisaariU/GD/data_series'

# Copy the content in bucketdatadir to flashdatadir using rsync
rsync -av --no-group --no-perms deigo:$bucketdatadir/ $flashdatadir/ 



# 4. Start an automatic job using bash

# Read and modify the slurm.sh file before running it. 
# nano xxxxxx.slurm.sh 
nano batch_nocopy_cnmfe_process.slurm.sh 

# slurm.sh file contains the information of 'folder_to_process' and 'Fs' (sampling frequency)

# CNMFe process of all the tiff files in the subfolders of 'flashdatadir'
sbatch batch_nocopy_cnmfe_process.slurm.sh 

# CNMFe process of series tiff files (taken from the same FOVs) in the subfolders of 'flashdatadir'
sbatch batch_nocopy_series_cnmfe_process.slurm.sh

# sbatch batch_figure_video.slurm.sh



# 5. Sync the CNMFe output back to bucket from flash
# Note: make sure the 'flashdatadir' and 'bucketdatadir' are correct
# You can use the lines in part 3 to re-assign the locations to 'flashdatadir' and 'bucketdatadir'
rsync -av --no-group --no-perms $flashdatadir/ deigo:$bucketdatadir/



# ====================
# Usefull commands

# Quickly read the cluster task report (slurm-xxxxxxxx.out) and bash files containing commands and
# tasks (.sh)
less slurm-xxxxxxxx.out # xxxxxxxx is the job ID


# Check the ongoing tasks. This will show the IDs of ongoing jobs
squeue


# Run a job from bash (using slurm.sh file)
sbatch *.slurm.sh


# Cancel a job
scancel xxxxxxx # xxxxxxx is a job ID


# rsync will be used for copying files between bucket and flash folders

# The rsync command with the options `-av --no-group --no-perms A B` will perform a file
# synchronization from the source directory `A` to the destination directory `B`. Here's what each
# option does:

# - `-a`: Archive mode, which preserves permissions, timestamps, symbolic links, and other file
#   attributes. It is equivalent to using `-rlptgoD`.

# - `-v`: Verbose mode, which displays detailed output during the synchronization process, showing
#   the files being transferred.

# - `--no-group`: Exclude group information during the synchronization. This means the group
#   ownership of files and directories will not be preserved in the destination.

# - `--no-perms`: Exclude permission information during the synchronization. This means the
#   permissions of files and directories will not be preserved in the destination.

# Overall, the `rsync` command will copy the contents of directory `A` to directory `B` while
# preserving the file timestamps and symbolic links. However, the group ownership and permissions
# of the files and directories will not be preserved in the destination.

# By default, rsync synchronizes files from the source directory to the destination directory,
# ensuring that the destination matches the source. It will not remove any files in the destination
# that are not present in the source.



# ====================
# If needed, you can run some script using a matlab with GUI

# Load matlab module 
module load matlab



# Run matlab with specified resource
# -t 1-0: 1 day
srun -p compute -t 1-0 --nodes=1 --ntasks=1 --cpus-per-task=32 --mem-per-cpu=8G --x11 --pty matlab
# srun -p short -t 0-1 --mem=10G -c8 --x11 --pty matlab
# srun -p compute -t 1-0 --mem=256G -c16 --x11 --pty bash

# srun matlab -nosplash 
# srun matlab -nosplash "cluster_interactive_matlab_bash;quit"



# Open the scripts below 
# - command_for_cnmfe_with_manual_intervention.m
# - cnmfe_large_data_script_cluster.m
# viewNeurons.m