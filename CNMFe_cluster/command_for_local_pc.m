%% Local PC workflow for CNMF-E calcium source extraction
% This is the local counterpart of the cluster workflow. It uses the same
% VIIO/VIAO CNMF-E analysis parameters, but lets you adjust local RAM/CPU
% settings. No SLURM or cluster commands are needed.

%% 1. Add code to MATLAB path
nvokeAnalysisPath = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(nvokeAnalysisPath))

% Default assumes CNMF_E is next to nvoke-analysis. Edit this if needed.
cnmfeSourcePath = fullfile(fileparts(nvokeAnalysisPath), ...
    'CNMF_E', 'ca_source_extraction');
addpath(genpath(cnmfeSourcePath), '-end')

%% 2. Set input
% Use either a single MC tif/tiff file, one recording folder, or a parent
% folder containing recording subfolders.
inputPath = '/path/to/Exported_tiff/';

%% 3. Run locally
cnmfe_process_local(inputPath, ...
    'Fs', 20, ...
    'video', false, ...
    'memory_size_to_use', 32, ...
    'memory_size_per_patch', 2, ...
    'patch_dims', [128, 128], ...
    'maxNumCompThreads', 8);

%% 4. Optional examples
% Process a single file:
% cnmfe_process_local('/path/to/recording_001/recording_001-MC.tiff', 'Fs', 20)

% Reprocess even when *results.mat exists:
% cnmfe_process_local(inputPath, 'Fs', 20, 'force', true)

% For a high-RAM workstation, use cluster-like resource settings:
% cnmfe_process_local(inputPath, 'Fs', 20, ...
%     'memory_size_to_use', 256, ...
%     'memory_size_per_patch', 8, ...
%     'patch_dims', [256, 256], ...
%     'maxNumCompThreads', 16);
