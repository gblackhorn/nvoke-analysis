function [recording_num,export_num] = export_nvoke_files_to_tiff(folderpath,varargin)
    % export isxd files to tiff files
    % Process the original recordings and output PP, PP-BP, PP-BP-MC, and PP-BP-DFF files
    %       - PP: preprocess
    %       - PP-BP: spatial bandpass
    %       - PP-BP-MC: motion correction 
    %       - PP-BP-DFF: dF/F
    %	Copy the gpio information containing sync, trigger, optogenetic stimulation information to project folder
    %	Example:
    %		process_nvoke_files(folderpath,...
    %			'project_dir','G:\aaa\bbb\ccc',...
    %			'mc_reference_frame', 10,...
    %			'overwrite', true); 
    
    % Defaults
    % folderpath = 'G:\Workspace\Inscopix_Seagate\recordings'; % default folder of nVoke recordings.
    export_dir = 'G:\Workspace\Inscopix_Seagate\Projects\Exported_tiff';
    % mc_reference_frame = 1;
    overwrite = false;
    key_string = '';
    show_progress = false; % show the progress of exportation

    % Options
    for ii = 1:2:(nargin-1)
    	if strcmpi('export_dir', varargin{ii})
    		export_dir = varargin{ii+1};
    	elseif strcmpi('key_string', varargin{ii})
    		key_string = varargin{ii+1};
    	elseif strcmpi('overwrite', varargin{ii})
    		overwrite = varargin{ii+1};
        elseif strcmpi('show_progress', varargin{ii})
            show_progress = varargin{ii+1};
        end
    end

    % Main contents
    filename_key_string = ['*', key_string, '.isxd'];
    fileinfo = dir(fullfile(folderpath, filename_key_string));
    recording_num = length(fileinfo);
    export_num = 0;
    for rn = 1:recording_num
%         rn
        
    	file_fullpath = fullfile(fileinfo(rn).folder, fileinfo(rn).name);
        [file_path, file_name_stem, file_ext] = fileparts(file_fullpath);
        
%         file_fullpath
        export_fullpath = fullfile(export_dir, [file_name_stem, '.tiff']);
        if ~isfile(export_fullpath)
    	   isx.export_movie_to_tiff(file_fullpath, export_fullpath);
           export_num = export_num+1;
        else
            if overwrite
                isx.export_movie_to_tiff(file_fullpath, export_fullpath);
                export_num = export_num+1;
            end
        end

        if show_progress
            disp(['Export file: ' num2str(rn), '/', num2str(recording_num), ' ', file_name_stem, '.tiff']);
        end

    end
end