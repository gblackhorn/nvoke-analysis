% STARTUP_NVOKE.M – Dedicated initialization for **nVoke‑analysis**
% -------------------------------------------------------------------------
%  ▸ Purges any previously‑added project folders so duplicate‑named functions
%    cannot collide with nVoke‑analysis.
%  ▸ Adds the nVoke‑analysis repo first, then generic libraries, CNMF‑E, and
%    finally the Inscopix *isx* MATLAB API (installed with Inscopix Data
%    Processing).
%  ▸ Keeps the script data‑agnostic; no *.mat* files are loaded.
% -------------------------------------------------------------------------
% Usage:
%   Place this file in the root of *nVoke‑analysis* and run it at the start
%   of a MATLAB session (or call it manually) before executing nVoke code.
% -------------------------------------------------------------------------

%% 0. Reset MATLAB path to factory default
restoredefaultpath;                  % clears everything except built‑ins
rehash toolboxcache;
fprintf('[nVoke] MATLAB path reset to default.\n');

%% 1. Determine project root & name
projectFolder = fileparts(mfilename('fullpath'));
[~, projectName] = fileparts(projectFolder);
fprintf('[%s] Project folder: %s\n', projectName, projectFolder);

%% 2. Global configuration struct
global nvkCfg;
nvkCfg = struct( ...
    'projectName',   projectName, ...
    'projectFolder', projectFolder, ...
    'codeFolder',    fullfile(projectFolder, 'code'), ...
    'dataFolder',    fullfile(projectFolder, 'data'), ...
    'resultsFolder', fullfile(projectFolder, 'results'), ...
    'startupTime',   datetime('now') ...
);

%% 3. Library paths (ordered by precedence)
% 3a. nVoke‑analysis source – **highest precedence**
addpath(genpath(projectFolder));

% 3b. Shared utilities (lower precedence)
sharedLibPath = 'D:\guoda\Documents\MATLAB\Codes\SharedLibs';
if isfolder(sharedLibPath)
    addpath(genpath(sharedLibPath), '-end');
end

% 3c. CNMF‑E toolbox (lower precedence)
cnmfePath = 'D:\guoda\Documents\MATLAB\Codes\CNMF_E\ca_source_extraction';
if isfolder(cnmfePath)
    addpath(genpath(cnmfePath), '-end');
end

% 3d. Inscopix *isx* MATLAB API – **add only the top folder (no subfolders)**
inscopixApiPath = 'C:\Program Files\Inscopix\Data Processing';
if isfolder(inscopixApiPath)
    addpath(inscopixApiPath, '-end');   % do NOT use genpath per vendor doc
    nvkCfg.inscopixApiPath = inscopixApiPath;  % record in config
    fprintf('[nVoke] Inscopix API added: %s\n', inscopixApiPath);
else
    warning('[nVoke] Inscopix API path not found: %s', inscopixApiPath);
end

fprintf('[nVoke] Paths configured.\n');

%% 4. Optional: diagnostic duplicate checker
% dupList = checkForDuplicates({'function1','function2'});

%% 5. Clean up temporary variables
clear sharedLibPath cnmfePath inscopixApiPath projectFolder projectName;

disp('nVoke‑analysis startup complete.');
