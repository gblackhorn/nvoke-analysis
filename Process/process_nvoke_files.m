function [outputArg1,outputArg2] = process_nvoke_files(folderpath,varargin)
    % Process all recordings in a single folder and copy the processed files to
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
    project_dir = 'G:\Workspace\Inscopix_Seagate\Projects\IO_GCaMP_IO_ChrimsonR_CN_ventral_data_nvoke2\IO_GCaMP_IO_ChrimsonR_CN_ventral_data_nvoke2_data';
    mc_reference_frame = 1;
    overwrite = false;

    % Options
    for ii = 1:2:(nargin-1)
    	if strcmpi('project_dir', varargin{ii})
    		project_dir = varargin{ii+1};
    	elseif strcmpi('mc_reference_frame', varargin{ii})
    		mc_reference_frame = varargin{ii+1};
    	elseif strcmpi('overwrite', varargin{ii})
    		overwrite = varargin{ii+1};
        end
    end

    % Main contents
    fileinfo = dir(fullfile(folderpath, '*.isxd'));
    recording_num = length(fileinfo);
    for rn = 1:recording_num
    	file_fullpath = fullfile(fileinfo(rn).folder, fileinfo(rn).name);
    	process_nvoke_file_with_api(file_fullpath,...
    		'project_dir', project_dir);
    end
end

