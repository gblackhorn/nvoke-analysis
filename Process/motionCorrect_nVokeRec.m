function [varargout] = motionCorrect_nVokeRec(movieFolder,varargin)
    % Use spatial bandpass filter and motion correction algorithm to stablize the movies (isxd files) 


    % Defaults
    keyword = ''; % filter won't be applied if keyword is empty
    overwrite = false;

    low_cutoff = 0.005; % spatial filter
    high_cutoff = 0.5; % spatial filter
    mc_reference_frame = 1; % the frame used as an reference in motion correction
    global_registration_weight = 1;
    max_translation = 20; 
    reference_segment_index = 0;
    rmBPfile = false; % true/false. Remove the spatial filtered file ('bp_file') after creating the motion-corrected video
    % useGUI = false; % true/false. If to use a GUI interface to choose where to load the 
% 
    % Optionals for inputs
    for ii = 1:2:(nargin-1)
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


    input_fileInfo = dir(fullfile(movieFolder,['*',keyword,'.isxd']));
    movie_num = numel(input_fileInfo);
    corrected_num = 0;

    startMSG = sprintf('\nMotion correcting %g movies (isxd files)\n - input folder: %s\n - output folder: %s',...
        movie_num,movieFolder,movieFolder);
    disp(startMSG)
    disp('Motion-corrected movie list:')

    for mn=1:movie_num
        input_file_fullpath = fullfile(movieFolder, input_fileInfo(mn).name);

        [~, file_name_stem, ~] = fileparts(input_file_fullpath);
        bp_filename = [file_name_stem,'-BP.isxd'];
        mc_filename = [file_name_stem,'-BP-MC.isxd'];
        % output_filename = [file_name_stem, '-.isxd'];
        bp_file_fullpath = fullfile(movieFolder, bp_filename);
        mc_file_fullpath = fullfile(movieFolder, mc_filename);

        existFileInfo = dir(bp_file_fullpath);

        if isempty(existFileInfo) || overwrite
            % reportProcess = sprintf(' - movie (%d/%d): %s',mn,movie_num,input_fileInfo(mn).name);
            isx.spatial_filter(input_file_fullpath, bp_file_fullpath,...
                'low_cutoff', low_cutoff, 'high_cutoff', high_cutoff);
            isx.motion_correct(bp_file_fullpath, mc_file_fullpath,...
                'max_translation', max_translation,...
                'reference_segment_index', reference_segment_index,...
                'reference_frame_index', mc_reference_frame,...
                'global_registration_weight', global_registration_weight);
            % exported_num = exported_num+1;
            reportProcess = sprintf(' - movie (%d/%d): %s\n  - BP: %s\n  - MC: %s',...
                mn,movie_num,input_fileInfo(mn).name,bp_filename,mc_filename);
            % reportCrop = sprintf('file: %s\n - output file: %s\n - cropRectangle: [%s] [top left bottom right]',...
            %     input_fileinfo(mn).name,output_filename,num2str(cropRectangle));
            disp(reportProcess)

            if rmBPfile
                delete(bp_file_fullpath);
                rmBPfileMsg = sprintf(' - delete BP file to release disk space');
                disp(rmBPfileMsg)
            end
        end
    end
    % fprintf('\n%d movies were cropped and saved to\n %s\n',exported_num,output_folder);
end
