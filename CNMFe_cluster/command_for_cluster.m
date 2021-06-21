# update codes
cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/*.sh /flash/UusisaariU/GD/
cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/*.m /flash/UusisaariU/GD/code/
cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/ /flash/UusisaariU/GD/code/



% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/* /flash/UusisaariU/GD/
% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/CNMF_E/ /flash/UusisaariU/GD/
% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/get_cnmfe_workspace_path.m /flash/UusisaariU/GD/
% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/Organize/get_subfoler_content.m /flash/UusisaariU/GD/


% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/batch_cnmfe_process.slurm.sh /flash/UusisaariU/GD/
% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/batch_nocopy_cnmfe_process.slurm.sh /flash/UusisaariU/GD/
% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/cnmfe_large_data_script_cluster.m /flash/UusisaariU/GD/
% cp -r /bucket/UusisaariU/PERSONAL_FILES/Guoda/codes/nvoke-analysis/CNMFe_cluster/batch_figure_video.slurm.sh /flash/UusisaariU/GD/


# start an interactive job
module load matlab
srun -p short -t 0-1 --mem=10G -c8 --x11 --pty matlab
srun -p compute -t 1-0 --mem=256G -c16 --x11 --pty matlab


# sync process data back to bucket
flashdatadir='/flash/UusisaariU/GD/data_folder.5rx8nM'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach_cluster_trial/'

flashdatadir='/flash/UusisaariU/GD/data_folder.teRXkO'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/series/'
rsync -av --no-group --no-perms $flashdatadir/ deigo:$bucketdatadir/



# Copy data from bucket to /flash
flashdatadir='/flash/UusisaariU/GD/data_folder.9mHEqf'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_add_videos/'
cp -r $bucketdatadir/* $flashdatadir/

flashdatadir='/flash/UusisaariU/GD/data_folder.teRXkO/2021-04-05_loc1/'
bucketdatadir='/bucket/UusisaariU/PROCESSED_DATA_BACKUPS/nRIM_MEMBERS/guoda/Inscopix/Projects/Exported_tiff/IO_ventral_approach/series/2021-04-05_loc1/'
rsync -av --no-group --no-perms deigo:$bucketdatadir/ $flashdatadir/ 




# Lines for debugging
cp -r $flashdatadir/2021-03-26-15-02-24_crop/ /flash/UusisaariU/GD/data_temp
cp -r $flashdatadir/2021-03-26-15-33-36_crop/ /flash/UusisaariU/GD/data_temp
