function [varargout] = motionCorrect_nVokeRec(movieFolder, outputFolder, varargin)
    % Use spatial bandpass filter and motion correction algorithm to stabilize the movies (isxd files)
    % Modified to allow separate input and output folders.

    % Defaults
    keyword = '';           % Filter for selecting specific input files
    overwrite = false;      % If true, existing output files will be overwritten
    low_cutoff = 0.005;     % Low spatial frequency cutoff for bandpass filtering
    high_cutoff = 0.5;      % High spatial frequency cutoff
    mc_reference_frame = 1; % Frame to use as reference during motion correction
    global_registration_weight = 1; % Weight for global registration
    max_translation = 20;   % Maximum pixel shift allowed during registration
    reference_segment_index = 0;    % Reference segment index for correction
    rmBPfile = false;       % If true, delete bandpass filtered file after correction

    % Parse optional inputs
    for ii = 1:2:(nargin-2)
        if strcmpi('keyword', varargin{ii})
            keyword = varargin{ii+1};
        elseif strcmpi('overwrite', varargin{ii})
            overwrite = varargin{ii+1};
        elseif strcmpi('low_cutoff', varargin{ii})
            low_cutoff = varargin{ii+1};
        elseif strcmpi('high_cutoff', varargin{ii})
            high_cutoff = varargin{ii+1};
        elseif strcmpi('mc_reference_frame', varargin{ii})
            mc_reference_frame = varargin{ii+1};
        elseif strcmpi('rmBPfile', varargin{ii})
            rmBPfile = varargin{ii+1};
        end
    end

    % Locate files matching the keyword in the input folder
    input_fileInfo = dir(fullfile(movieFolder, keyword));
    movie_num = numel(input_fileInfo);

    startMSG = sprintf('\nMotion correcting %g movies (isxd files)\n - input folder: %s\n - output folder: %s',...
        movie_num, movieFolder, outputFolder);
    disp(startMSG)
    disp('Motion-corrected movie list:')

    % Process each matching file
    for mn = 1:movie_num
        input_file_fullpath = fullfile(movieFolder, input_fileInfo(mn).name);
        [~, file_name_stem, ~] = fileparts(input_file_fullpath);

        bp_filename = [file_name_stem, '-BP.isxd'];
        mc_filename = [file_name_stem, '-BP-MC.isxd'];

        bp_file_fullpath = fullfile(outputFolder, bp_filename);
        mc_file_fullpath = fullfile(outputFolder, mc_filename);

        % Check if output already exists
        existFileInfo = dir(bp_file_fullpath);

        if isempty(existFileInfo) || overwrite
            % Apply spatial bandpass filter
            isx.spatial_filter(input_file_fullpath, bp_file_fullpath, ...
                'low_cutoff', low_cutoff, 'high_cutoff', high_cutoff);

            % Perform motion correction
            isx.motion_correct(bp_file_fullpath, mc_file_fullpath, ...
                'max_translation', max_translation, ...
                'reference_segment_index', reference_segment_index, ...
                'reference_frame_index', mc_reference_frame, ...
                'global_registration_weight', global_registration_weight);

            % Log output
            reportProcess = sprintf(' - movie (%d/%d): %s\n  - BP: %s\n  - MC: %s', ...
                mn, movie_num, input_fileInfo(mn).name, bp_filename, mc_filename);
            disp(reportProcess)

            % Optionally delete intermediate bandpass file
            if rmBPfile
                delete(bp_file_fullpath);
                disp(' - delete BP file to release disk space');
            end
        end
    end
end
