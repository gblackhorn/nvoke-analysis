function [FolderPath,varargout] = set_folder_path_ventral_approach(DataFolder,AnalysisFolder,varargin)
	% Return a series of paths to save and load files for ventral approach analysis 

	% DataFolder: raw and process recordings are organized from here 
    % AnalysisFolder: All analysis and figure folders are organized from here

	% Defaults
    % IgnoreCase = true; % ignore case if arrayVar and tag contain strings

	% Optionals
    % for ii = 1:2:(nargin-2)
    %     if strcmpi('IgnoreCase', varargin{ii})
    %         IgnoreCase = varargin{ii+1}; % cell array containing strings. Keep groups containing these words
    %     % elseif strcmpi('tags_discard', varargin{ii})
    %     %     tags_discard = varargin{ii+1}; % cell array containing strings. Discard groups containing these words
    %     % elseif strcmpi('clean_ap_entry', varargin{ii})
    %     %     clean_ap_entry = varargin{ii+1}; % true: discard delay and rebound categories from airpuff experiments
    %     end
    % end

    %% Main content
    % raw and processed recordings:
    FolderPath.data = DataFolder;
    FolderPath.recording = fullfile(FolderPath.data, 'recordings');
    FolderPath.recordingVA = fullfile(FolderPath.recording, 'IO_virus_ventral approach');
    FolderPath.project = fullfile(FolderPath.data, 'Projects');
    FolderPath.ExportTiff = fullfile(FolderPath.project, 'Exported_tiff');
    FolderPath.cnmfe = fullfile(FolderPath.project, 'Processed_files_for_matlab_analysis');

    % statistics
    FolderPath.analysis = AnalysisFolder;
    FolderPath.ventralApproach = fullfile(FolderPath.analysis, 'nVoke_ventral_approach');
    FolderPath.fig = fullfile(FolderPath.analysis, 'nVoke_ventral_approach');
    % FolderPath.invitro = fullfile(FolderPath.analysis, 'Kevin_calcium_imaging_slice');
end