function [QTM_FilenameAndTimestamp,varargout] = get_QTM_FilenameAndTimestamp(varargin)
    % Read all QTM mat files in a folder and create a structure containing QTM file names and
    % recording start time

    % save the output with a GUI if varargin for saveMeta is true

    % Defaults
    GUIinput = true; % Use GUI to browse a folder containing QTM mat files
    QTMmatFolderPath = ''; % 
    saveMeta = false; % true/false. Save the QTM meta data containing file names and timestamps

    % Optionals
    for ii = 1:2:(nargin)
        if strcmpi('QTMmatFolderPath', varargin{ii})
            QTMmatFolderPath = varargin{ii+1}; 
        elseif strcmpi('saveMeta', varargin{ii})
            saveMeta = varargin{ii+1};
        end
    end 


    % Select a folder containing QTM mat file is GUIinput is true and/or QTMmatFolderPath is empty
    if GUIinput || isempty(QTMmatFolderPath)
        QTMmatFolderPath = uigetdir(QTMmatFolderPath,...
            'Select a folder containing QTM mat files (recording metadata)');
        if QTMmatFolderPath == 0
            error('Folder not selected. QTM mat file list not created')
        end
    end


    % Get a list of QMT mat files, which contain the metadata
    QTM_matFilesInfo = dir(fullfile(QTMmatFolderPath,'*.mat'));
    fileNum = numel(QTM_matFilesInfo);

    QTM_FilenameAndTimestamp_fields = {'QTM_filenames','recStartTime'};
    QTM_FilenameAndTimestamp = empty_content_struct(QTM_FilenameAndTimestamp_fields,fileNum);

    % Print out the mat file folder and tell the user it is currently working on it
    fprintf('\nReading QTM mat files from the folder: %s\n',QTMmatFolderPath);

    for n = 1:fileNum
        % Read QTM mat file and get the metaData
        mat_fullPath = fullfile(QTM_matFilesInfo(n).folder,QTM_matFilesInfo(n).name);
        [~,mat_fileStem,~] = fileparts(mat_fullPath);
        matInfo = matfile(mat_fullPath);
        metaData = matInfo.(mat_fileStem);

        % Get the qtm file name from the meta data
        [~,QTM_fileStem,~] = fileparts(metaData.File);

        
        % Split the timestamp and keep the former part 
        timestamp_full = metaData.Timestamp;
        split_str = split(timestamp_full); % Split the string at whitespace characters
        recStartTime = join(split_str(1:2), " "); % Take the first part as the timestamp

        % Convert the time format to 'yyyy-mm-dd-hh-mm-ss'
        recStartTime = datetime(recStartTime, 'InputFormat', 'yyyy-MM-dd, HH:mm:ss.SSS', 'TimeZone', 'local'); % Extract the date and time components from the timestamp
        formatted_date = datestr(recStartTime, 'yyyy-mm-dd-HH-MM-SS'); % Convert the datetime object to a string in the desired format

        % Save the mat file name and its timestamp
        QTM_FilenameAndTimestamp(n).QTM_filenames = QTM_fileStem;
        QTM_FilenameAndTimestamp(n).recStartTime = formatted_date;
    end

    % Save the structure QTM_FilenameAndTimestamp
    if saveMeta
        [outputFile_name,outputFile_folder] = uiputfile(fullfile(QTMmatFolderPath,'QTM_files_metaData.mat'),...
            'Save the the file names and the measurement start time of QTM recordings into a mat file');

        save(fullfile(outputFile_folder,outputFile_name),QTM_FilenameAndTimestamp);
    end

    varargout{1} = QTMmatFolderPath;
end