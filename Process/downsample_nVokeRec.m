function downsample_nVokeRec(movieFolder, outputFolder, varargin)
% DOWNSAMPLE_NVOKEREC  Batch‑downsample nVoke (isxd) recordings.
% -------------------------------------------------------------------------
% Wraps Inscopix `isx.preprocess` to perform **optional** temporal and/or
% spatial down‑sampling on a collection of movies.
%
% Positional arguments
%   movieFolder   – Required. Folder containing source *.isxd files.
%   outputFolder  – Optional. Destination folder for down‑sampled files.
%                   • Pass '' or omit to save next to the originals.
%
% Name–value pairs (optional)
%   'keyword'              – Wildcard for file search   [ '*.isxd' ]
%   'temporal_factor'      – int ≥1  (1 = no temporal DS)
%   'spatial_factor'       – int ≥1  (1 = no spatial DS)
%   'overwrite'            – true/false  [false]
%   'fix_defective_pixels' – true/false  [false]
%   'trim_early_frames'    – true/false  [false]
%
% Examples
%   % Down‑sample temporally ×4; save beside originals
%   downsample_nVokeRec('E:/data', [], 'temporal_factor',4)
%
%   % Down‑sample spatially ×2 and save to a new folder
%   downsample_nVokeRec('E:/data', 'E:/out', 'spatial_factor',2)
% -------------------------------------------------------------------------
% 2025‑05‑28  Guo Da / ChatGPT‑o3

%% ----------------------- Positional argument checks --------------------
if nargin < 1 || ~ischar(movieFolder) || ~isfolder(movieFolder)
    error('First argument must be an existing folder path.');
end

if nargin < 2 || isempty(outputFolder)
    outputFolder = movieFolder;  % default = same folder
elseif ~ischar(outputFolder)
    error('outputFolder must be a character vector.');
end

% Ensure destination exists (create if necessary)
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

%% ----------------------- Parse name‑value options ----------------------

p = inputParser;
addParameter(p, 'keyword',               '*.isxd', @ischar);
addParameter(p, 'temporal_factor',       1,        @(x)isnumeric(x)&&x>=1&&mod(x,1)==0);
addParameter(p, 'spatial_factor',        1,        @(x)isnumeric(x)&&x>=1&&mod(x,1)==0);
addParameter(p, 'overwrite',             false,    @(x)islogical(x)&&isscalar(x));
addParameter(p, 'fix_defective_pixels',  false,    @(x)islogical(x)&&isscalar(x));
addParameter(p, 'trim_early_frames',     false,    @(x)islogical(x)&&isscalar(x));

parse(p, varargin{:});
opts = p.Results;

%% ---------------------------- Early exit ------------------------------
if opts.temporal_factor == 1 && opts.spatial_factor == 1
    fprintf('[downsample_nVokeRec] Both down‑sample factors are 1 → nothing to do.\n');
    return;
end

%% --------------------------- File discovery ---------------------------
inputInfo = dir(fullfile(movieFolder, opts.keyword));
fileCount = numel(inputInfo);
if fileCount == 0
    warning('No files matched "%s" in %s', opts.keyword, movieFolder);
    return;
end

fprintf('\nDown‑sampling %d movie(s)\n  • input : %s\n  • output: %s\n', ...
        fileCount, movieFolder, outputFolder);

%% --------------------------- Processing loop --------------------------
for k = 1:fileCount
    inFile = fullfile(movieFolder, inputInfo(k).name);
    [~, stem] = fileparts(inFile);
    outFile = fullfile(outputFolder, sprintf('%s-DS.isxd', stem));

    if exist(outFile, 'file') && ~opts.overwrite
        fprintf(' • (%d/%d) Skipping existing file: %s\n', k, fileCount, getFileName(outFile));
        continue;
    end

    try
        isx.preprocess({inFile}, {outFile}, ...
            'temporal_downsample_factor', opts.temporal_factor, ...
            'spatial_downsample_factor',  opts.spatial_factor,  ...
            'fix_defective_pixels',       opts.fix_defective_pixels, ...
            'trim_early_frames',          opts.trim_early_frames);

        fprintf(' ✓ (%d/%d) Down‑sampled: %s → %s\n', k, fileCount, inputInfo(k).name, getFileName(outFile));
    catch ME
        fprintf(' ✗ (%d/%d) Failed: %s\n   %s\n', k, fileCount, inputInfo(k).name, ME.message);
    end
end

fprintf('\nFinished down‑sampling.\n');
end

%% -----------------------------------------------------------------------
function f = getFileName(fp)
[~, f, ext] = fileparts(fp);
f = [f, ext];
end
