# Local CNMF-E Guide

Use this guide to run Guo's local CNMF-E calcium source extraction workflow on a PC, Mac, or local Linux workstation. This local workflow does not use SLURM, `sbatch`, Deigo, `/flash`, or cluster storage.

## What You Need

1. Original CNMF-E toolbox from GitHub:

```bash
git clone --recurse-submodules https://github.com/zhoupc/CNMF_E.git
```

CNMF-E provides `Sources2D`, so its `ca_source_extraction` folder must be on the MATLAB path:

```matlab
addpath(genpath('/path/to/CNMF_E/ca_source_extraction'), '-end')
```

2. Guo's lab wrapper code from the `nvoke-analysis` repository. CNMF-E alone is not enough.

Minimum local wrapper/helper files:

```text
nvoke-analysis/Process/cnmfe_process_local.m
nvoke-analysis/CNMFe_cluster/cnmfe_save_results.m
nvoke-analysis/Organize/
```

Recommended: use the full `nvoke-analysis` folder so all helper functions are available.

Add it to the MATLAB path:

```matlab
addpath(genpath('/path/to/nvoke-analysis'))
```

## Main Wrapper

Use one wrapper for both single recordings and batches:

```matlab
cnmfe_process_local(inputPath)
```

`inputPath` can be:

```text
/path/to/recording-MC.tiff
/path/to/one_recording_folder/
/path/to/parent_folder_with_recording_subfolders/
```

The wrapper skips a recording folder if it already contains `*results.mat`, unless you use `'force', true`.

## Example: Single Recording

```matlab
cnmfe_process_local('/path/to/recording_001/recording_001-MC.tiff', ...
    'Fs', 20);
```

## Example: Multiple Recordings In Subfolders

```matlab
cnmfe_process_local('/path/to/Exported_tiff/', ...
    'Fs', 20, ...
    'video', false, ...
    'memory_size_to_use', 32, ...
    'memory_size_per_patch', 2, ...
    'patch_dims', [128, 128], ...
    'maxNumCompThreads', 8);
```

## Parameters You May Tweak

These are the local resource settings:

```matlab
'memory_size_to_use', 32
'memory_size_per_patch', 2
'patch_dims', [128, 128]
'maxNumCompThreads', 8
'video', false
```

For a high-RAM workstation, you can try cluster-like resource settings:

```matlab
'memory_size_to_use', 256
'memory_size_per_patch', 8
'patch_dims', [256, 256]
```

The default CNMF-E analysis parameters inside `cnmfe_process_local.m` are the ones matched to the VIIO/VIAO cluster workflow:

```matlab
gSig = 14;
gSiz = 28;
min_corr = 0.8;
min_pnr = 8;
merge_thr = 0.65;
dmin = 10;
merge_thr_spatial = [1e-1, 0.65, 0];
deconv_options.type = 'ar2';
deconv_options.method = 'foopsi';
deconv_options.max_tau = Fs*5;
```

Changing local resource settings should mainly affect speed and memory use. Changing CNMF-E analysis parameters can change detected ROIs and should be documented.

## Output

Each processed recording folder will contain outputs such as:

```text
recording_name_results.mat
recording_name_contours.png
workspace_*.mat
```

`*_results.mat` is the main output for downstream nVoke analysis.

## Troubleshooting

If MATLAB says `Sources2D` is undefined, add CNMF-E `ca_source_extraction` to the path.

If MATLAB says `cnmfe_process_local` is undefined, add `nvoke-analysis` to the path.

If memory runs out, lower `memory_size_to_use`, `memory_size_per_patch`, or `patch_dims`, and keep `video` set to `false`.
