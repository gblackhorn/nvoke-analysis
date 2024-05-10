function figPathForVIIO = initProjFigPathVIIO(varargin)
    % Copy the loc tag (subnuclei information) of ROIs from one recdata file to another

    % Defaults
    GUImode = false; % true/false. Use GUI to locate the DataFolder and AnalysisFolder

    % Use varargin{1} for GUImode if it exists
    if nargin == 1
        GUImode = varargin{1};
    end

    if GUImode
        DataFolder = uigetdir(matlabroot,'Choose a folder containing data and project folders');
        AnalysisFolder = uigetdir(matlabroot,'Choose a folder containing analysis');
    else
        PC_name = getenv('COMPUTERNAME'); 
        % set folders for different situation
        DataFolder = 'G:\Workspace\Inscopix_Seagate';

        if strcmp(PC_name, 'GD-AW-OFFICE')
            AnalysisFolder = 'D:\guoda\Documents\Workspace\Analysis\'; % office desktop
        elseif strcmp(PC_name, 'BLADE14-GD')
            AnalysisFolder = 'C:\Users\guoda\Documents\Workspace\Analysis'; % laptop
        else
            fprintf('Folder info has not been set up for this computer [%s]. Init with GUI\n',PC_name)
            DataFolder = uigetdir(matlabroot,'Choose a folder containing data and project folders');
            AnalysisFolder = uigetdir(matlabroot,'Choose a folder containing analysis');
        end
    end

    figPathForVIIO = set_folder_path_ventral_approach(DataFolder,AnalysisFolder);
end
