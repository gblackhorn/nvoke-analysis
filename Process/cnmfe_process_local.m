function processedFiles = cnmfe_process_local(inputPath, varargin)
%CNMFE_PROCESS_LOCAL Run local CNMF-E processing for one recording or a folder.
%   cnmfe_process_local(inputPath) processes either:
%     1) one motion-corrected tif/tiff recording, or
%     2) a parent folder containing recording subfolders.
%
%   The CNMF-E analysis parameters match the cluster workflow used for the
%   VIIO/VIAO project. Only local resource settings such as RAM, patch size,
%   CPU threads, and video generation are exposed as options.

    if nargin < 1 || isempty(inputPath)
        inputPath = uigetdir(pwd, ...
            'Select a recording tif/tiff file parent folder or recording folder');
        if isequal(inputPath, 0)
            processedFiles = {};
            return
        end
    end

    opt = parseInputs(varargin{:});
    addLocalPaths();

    if ~isempty(opt.maxNumCompThreads)
        maxNumCompThreads(opt.maxNumCompThreads);
    end

    fileNames = findRecordings(inputPath, opt.force);
    fprintf('%d recording file(s) will be processed locally:\n', numel(fileNames));
    disp(fileNames)

    for ii = 1:numel(fileNames)
        fprintf('\n\nProcessing %d/%d: %s\n', ii, numel(fileNames), fileNames{ii});
        processOneRecording(fileNames{ii}, opt);
        fprintf('\nCNMF-E finished %d/%d: %s\n', ii, numel(fileNames), fileNames{ii});
    end

    processedFiles = fileNames;
end

function opt = parseInputs(varargin)
    opt = struct();
    opt.Fs = 20;
    opt.video = false;
    opt.memory_size_to_use = 32;
    opt.memory_size_per_patch = 2;
    opt.patch_dims = [128, 128];
    opt.use_parallel = true;
    opt.maxNumCompThreads = [];
    opt.force = false;

    for ii = 1:2:numel(varargin)
        switch lower(varargin{ii})
            case 'fs'
                opt.Fs = varargin{ii+1};
            case 'video'
                opt.video = varargin{ii+1};
            case 'memory_size_to_use'
                opt.memory_size_to_use = varargin{ii+1};
            case 'memory_size_per_patch'
                opt.memory_size_per_patch = varargin{ii+1};
            case 'patch_dims'
                opt.patch_dims = varargin{ii+1};
            case 'use_parallel'
                opt.use_parallel = varargin{ii+1};
            case 'maxnumcompthreads'
                opt.maxNumCompThreads = varargin{ii+1};
            case 'force'
                opt.force = varargin{ii+1};
            otherwise
                error('Unknown option: %s', varargin{ii});
        end
    end
end

function addLocalPaths()
    repoRoot = fileparts(fileparts(mfilename('fullpath')));
    addpath(genpath(repoRoot));

    cnmfeRoot = fullfile(fileparts(repoRoot), 'CNMF_E', 'ca_source_extraction');
    if exist('Sources2D', 'class') ~= 8 && isfolder(cnmfeRoot)
        addpath(genpath(cnmfeRoot), '-end');
    end
end

function fileNames = findRecordings(inputPath, force)
    if isfile(inputPath)
        [folderPath, ~, ext] = fileparts(inputPath);
        if ~isTiffExt(ext)
            error('Input file must be a tif/tiff recording: %s', inputPath);
        end
        if hasExistingResult(folderPath) && ~force
            fprintf('Skip existing CNMF-E result: %s\n', folderPath);
            fileNames = {};
        else
            fileNames = {inputPath};
        end
        return
    end

    if ~isfolder(inputPath)
        error('Input path does not exist: %s', inputPath);
    end

    directTiff = chooseRecordingFile(inputPath);
    if ~isempty(directTiff)
        if hasExistingResult(inputPath) && ~force
            fprintf('Skip existing CNMF-E result: %s\n', inputPath);
            fileNames = {};
        else
            fileNames = {directTiff};
        end
        return
    end

    folderContent = dir(inputPath);
    subfolders = folderContent([folderContent.isdir]);
    subfolders = subfolders(~startsWith({subfolders.name}, '.'));
    subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'}));

    fileNames = {};
    for i = 1:numel(subfolders)
        subfolder = fullfile(inputPath, subfolders(i).name);
        if hasExistingResult(subfolder) && ~force
            fprintf('Skip existing CNMF-E result: %s\n', subfolder);
            continue
        end

        tiffFile = chooseRecordingFile(subfolder);
        if isempty(tiffFile)
            fprintf('No MC tif/tiff file found in: %s\n', subfolder);
            continue
        end
        fileNames{end+1, 1} = tiffFile; %#ok<AGROW>
    end
end

function tf = isTiffExt(ext)
    tf = any(strcmpi(ext, {'.tif', '.tiff'}));
end

function tf = hasExistingResult(folderPath)
    tf = ~isempty(dir(fullfile(folderPath, '*results.mat')));
end

function tiffFile = chooseRecordingFile(folderPath)
    tiffInfo = [
        dir(fullfile(folderPath, '*-MC*.tif*'));
        dir(fullfile(folderPath, '*MC*.tif*'));
        dir(fullfile(folderPath, '*-mc*.tif*'));
        dir(fullfile(folderPath, '*mc*.tif*'))];
    if isempty(tiffInfo)
        tiffFile = '';
        return
    end

    tiffInfo = tiffInfo(~contains({tiffInfo.name}, '-dff', 'IgnoreCase', true));
    if isempty(tiffInfo)
        tiffFile = '';
        return
    end

    fullpaths = fullfile({tiffInfo.folder}, {tiffInfo.name});
    [~, uniqueIdx] = unique(lower(fullpaths), 'stable');
    tiffInfo = tiffInfo(uniqueIdx);

    if numel(tiffInfo) > 1
        [~, largestFileIdx] = max([tiffInfo.bytes]);
        tiffInfo = tiffInfo(largestFileIdx);
        fprintf('Multiple MC tif/tiff files found in %s; using largest file: %s\n', ...
            folderPath, tiffInfo.name);
    end

    tiffFile = fullfile(tiffInfo.folder, tiffInfo.name);
end

function processOneRecording(nam, opt)
    close all;

    neuron = Sources2D();
    [subfolder, filenameStem, ~] = fileparts(nam);
    nam = neuron.select_data(nam);

    pars_envs = struct('memory_size_to_use', opt.memory_size_to_use, ...
        'memory_size_per_patch', opt.memory_size_per_patch, ...
        'patch_dims', opt.patch_dims);

    % Spatial parameters matched to CNMFe_cluster/cnmfe_large_data_script_cluster.m.
    gSig = 14;
    gSiz = 28;
    ssub = 1;
    with_dendrites = false;
    if with_dendrites
        updateA_search_method = 'dilate'; %#ok<UNRCH>
        updateA_bSiz = 20;
    else
        updateA_search_method = 'ellipse';
        updateA_bSiz = neuron.options.dist;
    end
    spatial_constraints = struct('connected', true, 'circular', false);
    spatial_algorithm = 'hals_thresh';

    Fs = opt.Fs;
    tsub = 1;
    deconv_flag = true;
    deconv_options = struct('type', 'ar2', ...
        'method', 'foopsi', ...
        'smin', -5, ...
        'optimize_pars', true, ...
        'optimize_b', true, ...
        'max_tau', Fs*5);

    nk = 1;
    detrend_method = 'spline';

    bg_model = 'ring';
    nb = 1;
    ring_radius = round(1.5 * gSiz);
    num_neighbors = [];
    bg_ssub = 2;

    show_merge = false;
    merge_thr = 0.65;
    method_dist = 'max';
    dmin = 10;
    dmin_only = 4;
    merge_thr_spatial = [1e-1, 0.65, 0];

    K = [];
    min_corr = 0.8;
    min_pnr = 8;
    min_pixel = gSig^2;
    bd = 0;
    frame_range = [];
    save_initialization = false;
    use_parallel = opt.use_parallel;
    show_init = false;
    choose_params = false;
    center_psf = true;

    min_corr_res = 0.7;
    min_pnr_res = 6;
    seed_method_res = 'auto';
    update_sn = true;
    with_manual_intervention = false;
    save_demixed = true;
    kt = 3;

    neuron.updateParams('gSig', gSig, ...
        'gSiz', gSiz, ...
        'ring_radius', ring_radius, ...
        'ssub', ssub, ...
        'search_method', updateA_search_method, ...
        'bSiz', updateA_bSiz, ...
        'dist', updateA_bSiz, ...
        'spatial_constraints', spatial_constraints, ...
        'spatial_algorithm', spatial_algorithm, ...
        'tsub', tsub, ...
        'deconv_flag', deconv_flag, ...
        'deconv_options', deconv_options, ...
        'nk', nk, ...
        'detrend_method', detrend_method, ...
        'background_model', bg_model, ...
        'nb', nb, ...
        'ring_radius', ring_radius, ...
        'num_neighbors', num_neighbors, ...
        'bg_ssub', bg_ssub, ...
        'merge_thr', merge_thr, ...
        'dmin', dmin, ...
        'method_dist', method_dist, ...
        'min_corr', min_corr, ...
        'min_pnr', min_pnr, ...
        'min_pixel', min_pixel, ...
        'bd', bd, ...
        'center_psf', center_psf);
    neuron.Fs = Fs;

    neuron.getReady(pars_envs);

    if choose_params
        [gSig, gSiz, ring_radius, min_corr, min_pnr] = neuron.set_parameters(); %#ok<ASGLU>
    end

    [center, Cn, PNR] = neuron.initComponents_parallel(K, frame_range, ...
        save_initialization, use_parallel); %#ok<NASGU,ASGLU>
    neuron.compactSpatial();

    if show_init
        figure();
        ax_init = axes(); %#ok<NASGU>
        imagesc(Cn, [0, 1]); colormap gray;
        hold on;
        plot(center(:, 2), center(:, 1), '.r', 'markersize', 10);
        pause
    end

    if isempty(neuron.ids)
        fprintf('No neuron seed was found in the initialization step.\nSkip recording: %s\n', ...
            filenameStem);
        return
    end

    neuron.update_background_parallel(use_parallel);
    neuron_init = neuron.copy(); %#ok<NASGU>

    neuron.merge_neurons_dist_corr(show_merge);
    neuron.merge_high_corr(show_merge, merge_thr_spatial);

    [center_res, Cn_res, PNR_res] = neuron.initComponents_residual_parallel([], ...
        save_initialization, use_parallel, min_corr_res, min_pnr_res, seed_method_res); %#ok<NASGU,ASGLU>
    neuron_init_res = neuron.copy(); %#ok<NASGU>

    if update_sn
        neuron.update_spatial_parallel(use_parallel, true);
    else
        neuron.update_spatial_parallel(use_parallel);
    end
    neuron.merge_high_corr(show_merge, merge_thr_spatial);

    for m = 1:2 %#ok<FXUP>
        neuron.update_temporal_parallel(use_parallel);
        neuron.remove_false_positives();
        if ~isempty(neuron.ids)
            neuron.merge_neurons_dist_corr(show_merge);
        end
    end

    neuron.options.spatial_algorithm = 'nnls';
    if with_manual_intervention
        show_merge = true;
        neuron.orderROIs('snr');
        neuron.viewNeurons([], neuron.C_raw);
        neuron.merge_close_neighbors(true, dmin_only);
        tags = neuron.tag_neurons_parallel();
        ids = find(tags > 0);
        if ~isempty(ids)
            neuron.viewNeurons(ids, neuron.C_raw);
        end
    end

    neuron.update_background_parallel(use_parallel);
    neuron.update_spatial_parallel(use_parallel);
    neuron.update_temporal_parallel(use_parallel);

    K = size(neuron.A, 2);
    tags = neuron.tag_neurons_parallel(); %#ok<NASGU>
    neuron.remove_false_positives();

    if isempty(neuron.ids)
        return
    end

    neuron.merge_neurons_dist_corr(show_merge);
    neuron.merge_high_corr(show_merge, merge_thr_spatial);

    if K ~= size(neuron.A, 2)
        neuron.update_spatial_parallel(use_parallel);
        neuron.update_temporal_parallel(use_parallel);
        neuron.remove_false_positives();
    end

    neuron.orderROIs('snr');
    workspaceFullpath = fullfile(neuron.P.log_folder, ...
        ['workspace_', strrep(get_date(), ' ', '_'), '.mat']);
    save(workspaceFullpath, 'neuron', 'save_*', 'show_*', ...
        'use_parallel', 'with_*', '-v7.3');

    cnmfe_save_results(neuron, ...
        'folder', subfolder, 'save_workspace', true, 'save_contours', true);

    if opt.video
        amp_ac = 140;
        range_ac = 5 + [0, amp_ac];
        avi_filename = neuron.show_demixed_video(save_demixed, kt, [], ...
            amp_ac, range_ac); %#ok<NASGU>
        neuron.save_neurons();
    end
end
