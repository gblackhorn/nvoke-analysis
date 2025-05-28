% STARTUP_NVOKE.M – Dedicated initialization for **nVoke‑analysis**
% -------------------------------------------------------------------------
% This startup script is meant to be run **instead of** the AnalysisVIIO
% startup when you switch projects.  It *purges* any previously‑added project
% folders (e.g. AnalysisVIIO) so that identically named functions do not
% clash.  The nVoke‑analysis codebase is then added with highest precedence,
% while generic libraries are appended with lower precedence.
% -------------------------------------------------------------------------
% Usage:
%   ▸ Put this file in the root of the *nVoke-analysis* repo.
%   ▸ Run it at the start of a MATLAB session (or call it manually) before
%     executing nVoke scripts.
% -------------------------------------------------------------------------

%% 0. House‑clean the MATLAB path
% Reset to factory defaults to ensure no leftover folders (e.g. AnalysisVIIO)
% linger and cause name conflicts.
restoredefaultpath;   % <- clears everything except built‑in toolboxes
rehash toolboxcache;

fprintf('[nVoke] MATLAB path reset to default.\n');

%% 1. Determine project root & name
projectFolder = fileparts(mfilename('fullpath'));   % folder containing this file
[~, projectName] = fileparts(projectFolder);

fprintf('[%s] Project folder: %s\n', projectName, projectFolder);

%% 2. Build global configuration struct
global nvkCfg;
nvkCfg = struct( ...
    'projectName',   projectName, ...
    'projectFolder', projectFolder, ...
    'codeFolder',    fullfile(projectFolder, 'code'), ...
    'dataFolder',    fullfile(projectFolder, 'data'), ...
    'resultsFolder', fullfile(projectFolder, 'results'), ...
    'startupTime',   datetime('now') ...
);

%% 3. Core library paths (ordered by precedence)
% 3a. nVoke-analysis itself – goes **first** so duplicates win.
addpath(genpath(projectFolder));

% 3b. Shared utilities (lower precedence)
sharedLibPath = 'D:\guoda\Documents\MATLAB\Codes\SharedLibs';
if isfolder(sharedLibPath)
    addpath(genpath(sharedLibPath), '-end');
end

% 3c. Third‑party toolboxes (also lower precedence)
cnmfePath = 'D:\guoda\Documents\MATLAB\Codes\CNMF_E\ca_source_extraction';
if isfolder(cnmfePath)
    addpath(genpath(cnmfePath), '-end');
end

fprintf('[nVoke] Paths configured.\n');

%% 4. Optional: report duplicate functions (diagnostic only)
% dupList = checkForDuplicates({'functionName1', 'functionName2'});
% (Implement `checkForDuplicates` in SharedLibs if needed.)

%% 5. Clean up temporary variables
clear sharedLibPath cnmfePath projectFolder projectName;

disp('nVoke-analysis startup complete.');
