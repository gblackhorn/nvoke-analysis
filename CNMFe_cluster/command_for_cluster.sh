# Login the cluster 
# Note: Set up the direct access to the deigo cluster from outside. It also works when your device is in the OIST network
# Log into the Deigo using terminal (UNIX) or MobaXterm (Windows)
# ssh deigo-ext
ssh -X da-guo@deigo.oist.jp

# Go to the personal folder
cd /flash/UusisaariU/GD/

# Quickly read the cluster task report (slurm-xxxxxxxx.out) and bash files containing commands and tasks (.sh)
less slurm-xxxxxxxx.out

# update codes
cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/*.sh /flash/UusisaariU/GD/
cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/*.m /flash/UusisaariU/GD/code/
cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/ /flash/UusisaariU/GD/code/


# Copy data from bucket to /flash
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/2022-09-27/'

# If folder does not exist, creat one
# flashdatadir=$(mktemp -d /flash/UusisaariU/GD/data_folder20220927.XXXXXX) 
mktemp -d /flash/UusisaariU/GD/data_folder20220927.XXXXXX
# assign the new dir to 'flashdatadir'

# If folder exists on cluster, specify it 
flashdatadir='/flash/UusisaariU/GD/data_folder.par_test'


# Copy the content in bucketdatadir to flashdatadir
rsync -av --no-group --no-perms deigo:$bucketdatadir/ $flashdatadir/ 
# cp -r $bucketdatadir/* $flashdatadir/



 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/* /flash/UusisaariU/GD/
 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/CNMF_E/ /flash/UusisaariU/GD/
 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/get_cnmfe_workspace_path.m /flash/UusisaariU/GD/
 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/get_subfoler_content.m /flash/UusisaariU/GD/


 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/batch_cnmfe_process.slurm.sh /flash/UusisaariU/GD/
 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/batch_nocopy_cnmfe_process.slurm.sh /flash/UusisaariU/GD/
 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/cnmfe_large_data_script_cluster.m /flash/UusisaariU/GD/
 # cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/batch_figure_video.slurm.sh /flash/UusisaariU/GD/


# start an interactive job
module load matlab
srun -p short -t 0-1 --mem=10G -c8 --x11 --pty matlab
srun -p compute -t 1-0 --mem=256G -c16 --x11 --pty matlab
srun -p compute -t 1-0 --mem=256G -c16 --x11 --pty bash
srun -p compute -t 1-0 --nodes=1 --ntasks=1 --cpus-per-task=32 --mem-per-cpu=8G --x11 --pty matlab

srun matlab -nosplash 
srun matlab -nosplash "cluster_interactive_matlab_bash;quit"


# sync process data back to bucket
flashdatadir='/flash/UusisaariU/GD/data_folder.qNDugf'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach_cluster_trial/'

flashdatadir='/flash/UusisaariU/GD/data_folder.reprocess_recordings/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/2022.05-06_reprocess_recordings/'
rsync -av --no-group --no-perms $flashdatadir/ deigo:$bucketdatadir/







# Lines for debugging
cp -r $flashdatadir/2021-03-26-15-02-24_crop/ /flash/UusisaariU/GD/data_temp
cp -r $flashdatadir/2021-03-26-15-33-36_crop/ /flash/UusisaariU/GD/data_temp
