function [varargout] = batchMod_nVoke2_filenames(varargin)
    % Batch modify the file names in a selected folder
    % Replace the characters in the oldStr with the newStr

    % This function will ask you:
    %   1. Select a folder containing QTM mat files
    %   2. Select a folder containing nVoke files
    %   3. Select a folder to save the copies of renamed nVoke files after renaming

    % Defaults
    nVoke_name_repIDX = [1 19]; % This indicates the number of characters containing the datetime info at the beginning of nvoke file names 

    QTMmatFolderPath = ''; % Use GUI to browse a folder containing QTM mat files
    save_QTM_metaData = false; % true/false. Save the QTM meta data containing file names and timestamps

    nVokeRawDataFolder = ''; % Use GUI to browse a folder containing QTM mat files
    nVokeRenameDataFolder = ''; % Use GUI to browse a folder containing QTM mat files

    timeError = 5; % the start time error between a pair of QTM and isxd recordings. unit: seconds
% overwrite = false; % true/false. Create new DFF files if this is true.

    % Optionals
    for ii = 1:2:(nargin)
        if strcmpi('QTMmatFolderPath', varargin{ii})
            QTMmatFolderPath = varargin{ii+1}; 
        elseif strcmpi('save_QTM_metaData', varargin{ii})
            save_QTM_metaData = varargin{ii+1};
        elseif strcmpi('nVokeRawDataFolder', varargin{ii})
            nVokeRawDataFolder = varargin{ii+1}; 
        elseif strcmpi('nVokeRenameDataFolder', varargin{ii})
            nVokeRenameDataFolder = varargin{ii+1}; 
        elseif strcmpi('timeError', varargin{ii})
            timeError = varargin{ii+1};
        % elseif strcmpi('nonstimMean_pos', varargin{ii})
        %     nonstimMean_pos = varargin{ii+1};
        end
    end 

    % Read all QTM mat files in a folder and create a structure containing QTM file names and
    % recording start time
    [QTM_FilenameAndTimestamp,QTMmatFolderPath] = get_QTM_FilenameAndTimestamp('QTMmatFolderPath',QTMmatFolderPath,...
        'saveMeta',save_QTM_metaData);


    % Select a folder containing raw nVoke2 recording, of which you want to change the file names
    % using the info from QTM_FilenameAndTimestamp
    nVokeRawDataFolder = uigetdir(nVokeRawDataFolder,...
        'Select a folder containing nVoke2 raw data');


    % Find the nVoke2 recording (including isxd, gpio and imu files) for each QTM mat file using the
    % time information
    isxd_fileInfo = dir(fullfile(nVokeRawDataFolder,'*.isxd')); % get isxd file list
    gpio_fileInfo = dir(fullfile(nVokeRawDataFolder,'*.gpio')); % get isxd file list
    imu_fileInfo = dir(fullfile(nVokeRawDataFolder,'*.imu')); % get isxd file list
    nVoke_fileInfo = [isxd_fileInfo;gpio_fileInfo;imu_fileInfo];
    nVoke_fileNames = {nVoke_fileInfo.name}; % get a cell array of nVoke file names
    nVoke_recStartTime = cellfun(@(x) x(nVoke_name_repIDX(1):nVoke_name_repIDX(2)),nVoke_fileNames,'UniformOutput',false); % get a cell array of nVoke recording start time
    nVoke_recStartTime_array = cellfun(@(x) datetime(x,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local'),...
        nVoke_recStartTime); % Convert the the isxd_recStartTime to a date-time array

    nVoke_oldNew_filenames = empty_content_struct({'oldNames','newNames'},numel(nVoke_fileInfo));
    [nVoke_oldNew_filenames(:).oldNames] = deal(nVoke_fileNames{:});

    % isxd_fileNames = {isxd_fileInfo.name}; % get a cell array of isxd file names
    % isxd_recStartTime = cellfun(@(x) x(1:19),isxd_fileNames,'UniformOutput',false); % get a cell array of isxd recording start time
    % isxd_recStartTime_array = cellfun(@(x) datetime(x,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local'),...
    %     isxd_recStartTime); % Convert the the isxd_recStartTime to a date-time array
    QTMnum = numel(QTM_FilenameAndTimestamp);
    for n = 1:QTMnum
        QTM_fileName_stem = QTM_FilenameAndTimestamp(n).QTM_filenames;
        QTM_recStartTime = QTM_FilenameAndTimestamp(n).recStartTime;
        QTM_recStartTime_array = datetime(QTM_recStartTime,'InputFormat', 'yyyy-MM-dd-HH-mm-ss', 'TimeZone', 'local');

        % Calculate the time difference (in seconds) of start time between isxd recordings and a single QTM recording
        timeDiff = seconds(nVoke_recStartTime_array-QTM_recStartTime_array);

        % Find the time difference smaller than the timeError
        paired_nVoke_idx = find(abs(timeDiff)<timeError);

        % loop through the paired_nVoke_idx and generate new name using QTM_fileName_stem
        pairedNum = numel(paired_nVoke_idx);
        for p = 1:pairedNum
            oldName = nVoke_fileNames{paired_nVoke_idx(p)};
            % newName = oldName;
            repStr = extractBetween(oldName,nVoke_name_repIDX(1),nVoke_name_repIDX(2));
            newName = strrep(oldName,repStr{:},QTM_fileName_stem);
            % newName(1:nVoke_name_dtNum) = QTM_fileName_stem;
            nVoke_oldNew_filenames(paired_nVoke_idx(p)).newNames = newName;
        end
    end

    % check if there are files paired with QTM files
    newNames = {nVoke_oldNew_filenames.newNames};
    all_empty = all(cellfun(@isempty, newNames));
    if all_empty
        fprintf('There is no paired recordings between folders\n - %s\n - %s\n',...
            QTMmatFolderPath,nVokeRawDataFolder);
        return
    end

    % Select a folder to save the renamed nVoke2 files
    nVokeRenameDataFolder = uigetdir(nVokeRenameDataFolder,...
        'Select a folder to save the renamed nVoke files');


    % Rename the nVoke files with the QTM filename and add -nVoke-video/gpio/imu to indicate what
    % recordings they are. Copy them to another folder.
    % Do not delete the original ones
    fprintf('Rename files in folder 1 and save them to foler 2\n 1. %s\n 2. %s\n\n',...
        nVokeRawDataFolder,nVokeRenameDataFolder);
    for m = 1:numel(nVoke_fileInfo)
        % rename the file and save it to the folder [nVokeRenameDataFolder] if the new name for it is not empty
        if ~isempty(nVoke_oldNew_filenames(m).newNames)
            oldFilePath = fullfile(nVokeRawDataFolder,nVoke_oldNew_filenames(m).oldNames);
            newFilePath = fullfile(nVokeRenameDataFolder,nVoke_oldNew_filenames(m).newNames);
            copyfile(oldFilePath,newFilePath);
            fprintf(' - %s >> %s\n',...
                nVoke_oldNew_filenames(m).oldNames,nVoke_oldNew_filenames(m).newNames);
        end
    end

    % Save the old and new names of nVoke files as csv to the same folder of the renamed nVoke files 
    % Convert the structure to a table
    nVoke_oldNew_filenames_table = struct2table(nVoke_oldNew_filenames);
    table_filepath = fullfile(nVokeRenameDataFolder,'OldNewFileNames.csv')

    % Save the table as a CSV file
    writetable(nVoke_oldNew_filenames_table, table_filepath);

    % optional output1: the list of old and renamed nVoke files
    varargout{1} = nVoke_oldNew_filenames;

    % optional output2: Where are the QTM mat files and nVoke raw data. Where are the renamed nVoke
    % files saved to 
    debriefing.QTM_folder = QTMmatFolderPath;
    debriefing.nVoke_folder = nVokeRawDataFolder;
    debriefing.nVoke_newFolder = nVokeRenameDataFolder;
    varargout{2} = debriefing; 
end