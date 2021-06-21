%% clear the workspace and select data 
clearvars -except opt folder file_names ii nams;
% clc; 
close all; 

%% choose multiple datasets or just one  
neuron = Sources2D(); 
[subfolder, ~, ~] = fileparts(nams{1});
% nams = {'./data_1p.tif'};          % you can put all file names into a cell array; when it's empty, manually select files 
nams = neuron.select_multiple_files(nams);  %if nam is [], then select data interactively 

%% parameters  
% -------------------------    COMPUTATION    -------------------------  %
pars_envs = struct('memory_size_to_use', 256, ...   % GB, memory space you allow to use in MATLAB 
    'memory_size_per_patch', 5, ...   % GB, space for loading data within one patch 
    'patch_dims', [128, 128],...  %GB, patch size 
    'batch_frames', 6000);           % number of frames per batch 
  % -------------------------      SPATIAL      -------------------------  %
gSig = 16;           % pixel, gaussian width of a gaussian kernel for filtering the data. 0 means no filtering
gSiz = 32;          % pixel, neuron diameter
ssub = 1;           % spatial downsampling factor
with_dendrites = false;   % with dendrites or not
if with_dendrites
    % determine the search locations by dilating the current neuron shapes
    updateA_search_method = 'dilate';  %#ok<UNRCH>
    updateA_bSiz = 20;
    updateA_dist = neuron.options.dist;
else
    % determine the search locations by selecting a round area
    updateA_search_method = 'ellipse'; %#ok<UNRCH>
    updateA_dist = 5;
    updateA_bSiz = neuron.options.dist;
end
spatial_constraints = struct('connected', true, 'circular', false);  % you can include following constraints: 'circular'
spatial_algorithm = 'hals';

% -------------------------      TEMPORAL     -------------------------  %
% Fs = 10;             % frame rate
if exist('opt', 'var')
    if isfield(opt, 'Fs')
        Fs = opt.Fs;
    else
        Fs = 20;             % frame rate
    end

    if isfield(opt, 'keyword')
        keyword = opt.keyword;
    else
        keyword = 'ap1s';
    end
else
    Fs = 20;
    keyword = 'ap1s';
end
tsub = 1;           % temporal downsampling factor
deconv_options = struct('type', 'ar1', ... % model of the calcium traces. {'ar1', 'ar2'}
    'method', 'foopsi', ... % method for running deconvolution {'foopsi', 'constrained', 'thresholded'}
    'smin', -5, ...         % minimum spike size. When the value is negative, the actual threshold is abs(smin)*noise level
    'optimize_pars', true, ...  % optimize AR coefficients
    'optimize_b', true, ...% optimize the baseline);
    'max_tau', 100);    % maximum decay time (unit: frame);

nk = 3;             % detrending the slow fluctuation. usually 1 is fine (no detrending)
% when changed, try some integers smaller than total_frame/(Fs*30)
detrend_method = 'spline';  % compute the local minimum as an estimation of trend.

% -------------------------     BACKGROUND    -------------------------  %
bg_model = 'ring';  % model of the background {'ring', 'svd'(default), 'nmf'}
nb = 1;             % number of background sources for each patch (only be used in SVD and NMF model)
bg_neuron_factor = 1.4;
ring_radius = round(bg_neuron_factor * gSiz);  % when the ring model used, it is the radius of the ring used in the background model.
%otherwise, it's just the width of the overlapping area
num_neighbors = 50; % number of neighbors for each neuron

% -------------------------      MERGING      -------------------------  %
show_merge = false;  % if true, manually verify the merging step
merge_thr = 0.65;     % thresholds for merging neurons; [spatial overlap ratio, temporal correlation of calcium traces, spike correlation]
method_dist = 'max';   % method for computing neuron distances {'mean', 'max'}
dmin = 5;       % minimum distances between two neurons. it is used together with merge_thr
dmin_only = 2;  % merge neurons if their distances are smaller than dmin_only.
merge_thr_spatial = [0.8, 0.4, -inf];  % merge components with highly correlated spatial shapes (corr=0.8) and small temporal correlations (corr=0.1)

% -------------------------  INITIALIZATION   -------------------------  %
K = [];             % maximum number of neurons per patch. when K=[], take as many as possible.
min_corr = 0.9;     % default=0.8. minimum local correlation for a seeding pixel
min_pnr = 10;       % default=8. minimum peak-to-noise ratio for a seeding pixel
min_pixel = gSig^2;      % minimum number of nonzero pixels for each neuron
bd = 0;             % number of rows/columns to be ignored in the boundary (mainly for motion corrected data)
frame_range = [];   % when [], uses all frames
save_initialization = false;    % save the initialization procedure as a video.
use_parallel = true;    % use parallel computation for parallel computing
show_init = true;   % show initialization results
choose_params = true; % manually choose parameters
center_psf = true;  % set the value as true when the background fluctuation is large (usually 1p data)
% set the value as false when the background fluctuation is small (2p)

% -------------------------  Residual   -------------------------  %
min_corr_res = 0.7;
min_pnr_res = 6;
seed_method_res = 'auto';  % method for initializing neurons from the residual
update_sn = true;

% ----------------------  WITH MANUAL INTERVENTION  --------------------  %
with_manual_intervention = false;

% -------------------------  FINAL RESULTS   -------------------------  %
save_demixed = true;    % save the demixed file or not
kt = 3;                 % frame intervals

% -------------------------    UPDATE ALL    -------------------------  %
neuron.updateParams('gSig', gSig, ...       % -------- spatial --------
    'gSiz', gSiz, ...
    'ring_radius', ring_radius, ...
    'ssub', ssub, ...
    'search_method', updateA_search_method, ...
    'bSiz', updateA_bSiz, ...
    'dist', updateA_bSiz, ...
    'spatial_constraints', spatial_constraints, ...
    'spatial_algorithm', spatial_algorithm, ...
    'tsub', tsub, ...                       % -------- temporal --------
    'deconv_options', deconv_options, ...
    'nk', nk, ...
    'detrend_method', detrend_method, ...
    'background_model', bg_model, ...       % -------- background --------
    'nb', nb, ...
    'ring_radius', ring_radius, ...
    'num_neighbors', num_neighbors, ...
    'merge_thr', merge_thr, ...             % -------- merging ---------
    'dmin', dmin, ...
    'method_dist', method_dist, ...
    'min_corr', min_corr, ...               % ----- initialization -----
    'min_pnr', min_pnr, ...
    'min_pixel', min_pixel, ...
    'bd', bd, ...
    'center_psf', center_psf);
neuron.Fs = Fs;

%% distribute data and be ready to run source extraction 
neuron.getReady_batch(pars_envs, subfolder); 

%% initialize neurons in batch mode 
neuron.initComponents_batch(K, save_initialization, use_parallel); 

%% udpate spatial components for all batches
neuron.update_spatial_batch(use_parallel); 

%% udpate temporal components for all bataches
neuron.update_temporal_batch(use_parallel); 

%% update background 
neuron.update_background_batch(use_parallel); 

%% delete neurons 
% do manual deletion with "cnmfe_series_delete_rois" afterwards

%% merge neurons 
neuron = cnmfe_series_merge_rois(neuron,show_merge,merge_thr_spatial,...
    min_corr_res,min_pnr_res,seed_method_res,...
    'keyword', keyword, 'save_initialization', save_initialization, 'use_parallel', use_parallel,...
    'save_workspace', save_workspace);

%% get the correlation image and PNR image for all neurons 
neuron.correlation_pnr_batch(); 

%% concatenate temporal components 
neuron.concatenate_temporal_batch(); 
% neuron.viewNeurons([],neuron.C_raw); 


%% View all ROI components and delete components manually
% neuron.viewNeurons([],neuron.C_raw); 


%% save workspace for future analysis
log_folder = neuron.P.log_folder;
neuron.save_workspace_batch(log_folder); 


%% Save results. Save shapes and traces of neurons
nbatches = length(neuron.batches);
for mbatch = 1:nbatches
    batch_k = neuron.batches{mbatch};
    neuron_bat = batch_k.neuron;

    [neuron_bat_folder, neuron_bat_name_stem, ~] = fileparts(neuron_bat.file);

    cnmfe_save_results(neuron_bat,...
        'folder', subfolder, 'save_workspace', true, 'save_contours', true);


    % results = neuron_bat.obj2struct();
    % results_filename = sprintf('%s%s%s_results.mat', subfolder, filesep, neuron_bat_name_stem);
    % save(results_filename, 'results');

    % neuron_bat.save_neurons(); % Save shapes and traces of neuorn

    % Coor = neuron_bat.show_contours(0.6);
    % contours_fullpath = fullfile(subfolder, [neuron_bat_name_stem, '_contours']);
    % % saveas(gcf, contours_fullpath, 'jpeg');
    % print(contours_fullpath, '-dpng');
end



%% Creat a video with concatenate temporal batch. 
% amp_ac = 140;
% range_ac = 5+[0, amp_ac];
% multi_factor = 10;
% range_Y = [0, amp_ac*multi_factor];

nbatches = length(neuron.batches);
for mbatch = 1:nbatches
    batch_k = neuron.batches{mbatch};
    neuron_bat = batch_k.neuron;

    fprintf('\ncreating video for batch %d/%d\n', mbatch, nbatches);
    % avi_filename = neuron_bat.show_demixed_video(save_demixed, kt, [], amp_ac, range_ac, range_Y, multi_factor);
    avi_filename = neuron_bat.show_demixed_video(save_demixed, kt, []);
end







