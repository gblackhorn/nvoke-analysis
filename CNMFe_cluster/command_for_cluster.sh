# Login the cluster 
# Note: Set up the direct access to the deigo cluster from outside. It also works when your device is in the OIST network
# Log into the Deigo using terminal (UNIX) or MobaXterm (Windows)
# ssh deigo-ext
ssh -X da-guo@deigo.oist.jp

# Go to the personal folder
cd /flash/UusisaariU/Ana/

# Quickly read the cluster task report (slurm-xxxxxxxx.out) and bash files containing commands and tasks (.sh)
less slurm-xxxxxxxx.out

# update codes
bucketCodeDir='/bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/'
flashCodeDir='/flash/UusisaariU/GD/code/' 
flashHomeDir='/flash/UusisaariU/GD/'

# sync code from bucket to flash
rsync -av --include '*/' --include '*.m' --exclude '*' deigo:$bucketCodeDir/ $flashCodeDir/
rsync -av --include '*/' --include '*.sh' --exclude '*' deigo:$bucketCodeDir/ $flashHomeDir/
# sync code from flash to bucket 
rsync -av --include '*/' --include '*.m' --exclude '*' $flashCodeDir/ deigo:$bucketCodeDir/ 
rsync -av --include '*/' --include '*.sh' --exclude '*' $flashHomeDir/ deigo:$bucketCodeDir/ 



# cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/*.sh /flash/UusisaariU/GD/
# cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/*.m /flash/UusisaariU/GD/code/
# cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/ /flash/UusisaariU/GD/code/


# Set folder path on Bucket to Copy data from bucket to /flash
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/20230609_re-run_motion-correction/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/series_20230627/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/Moscope/M9_BMC/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/Moscope/INSCOPIX_tiff/M8/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/Moscope/INSCOPIX_tiff/M9_BMC/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/Moscope/INSCOPIX_tiff/M9_extra/'

# If folder does not exist, creat one
# flashdatadir=$(mktemp -d /flash/UusisaariU/GD/data_folder20220927.XXXXXX) 
mkdir /flash/UusisaariU/GD/data_series
mktemp -d /flash/UusisaariU/GD/20230609_reMC_data.XXXXXX
# assign the new dir to 'flashdatadir'

# If folder exists on cluster, specify it 
flashdatadir='/flash/UusisaariU/GD/data_series'
flashdatadir='/flash/UusisaariU/GD/data_MOS_M8.FYzJWT'
flashdatadir='/flash/UusisaariU/GD/data_MOS_M9_BMC.1U26sa'
flashdatadir='/flash/UusisaariU/GD/data_MOS_M9_extra.qqRGrS'


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


# start an automatic job
sbatch batch_nocopy_cnmfe_process.slurm.sh 
sbatch batch_figure_video.slurm.sh
sbatch batch_nocopy_cnmfe_process.slurm.sh



# start an interactive job
module load matlab
srun -p short -t 0-1 --mem=10G -c8 --x11 --pty matlab
srun -p compute -t 1-0 --mem=256G -c16 --x11 --pty matlab
srun -p compute -t 1-0 --mem=256G -c16 --x11 --pty bash
srun -p compute -t 1-0 --nodes=1 --ntasks=1 --cpus-per-task=32 --mem-per-cpu=8G --x11 --pty matlab

srun matlab -nosplash 
srun matlab -nosplash "cluster_interactive_matlab_bash;quit"


# sync process data back to bucket
flashdatadir='/flash/UusisaariU/GD/data_folder20230219.zErjoE'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/2023-02-19/'

flashdatadir='/flash/UusisaariU/GD/data_folder20221010.ggFe7G'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/2022-10-10/'
rsync -av --no-group --no-perms $flashdatadir/ deigo:$bucketdatadir/



# update codes on bucket when changes were made on cluster
cp -r /flash/UusisaariU/GD/*.sh  /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/
cp -r /flash/UusisaariU/GD/code/*.m  /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/
cp -r /flash/UusisaariU/GD/code/ /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/ 




# Lines for debugging
cp -r $flashdatadir/2021-03-26-15-02-24_crop/ /flash/UusisaariU/GD/data_temp
cp -r $flashdatadir/2021-03-26-15-33-36_crop/ /flash/UusisaariU/GD/data_temp
