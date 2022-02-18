function [outputArg1,outputArg2] = process_nvoke_file_with_api(file_fullpath,varargin)
    % Process a single recording and copy the processed file to project folder.
    %   Process the original recording and output PP, PP-BP, PP-BP-MC, and PP-BP-DFF files
    %       - PP: preprocess
    %       - PP-BP: spatial bandpass
    %       - PP-BP-MC: motion correction 
    %       - PP-BP-DFF: dF/F
    %	Copy the gpio information containing sync, trigger, optogenetic stimulation information to project folder
    %	file_fullpath: folder/filename(with extension)
    %	Example:
    %		process_nvoke_file_with_api(file_fullpath,...
    %			'project_dir', 'G:\aaa\bbb\ccc', 'mc_reference_frame', 10,...
    %			'overwrite', true); 
    
    % Defaults
    % recording_dir = 'G:\Workspace\Inscopix_Seagate\recordings'; % default folder of nVoke recordings.
    project_dir = 'G:\Workspace\Inscopix_Seagate\Projects\IO_GCaMP_IO_ChrimsonR_CN_ventral_data_nvoke2\IO_GCaMP_IO_ChrimsonR_CN_ventral_data_nvoke2_data';
    mc_reference_frame = 1;
    overwrite = false;
    % export_mc_tiff = true;

    % Options
    for ii = 1:2:(nargin-1)
    	% if strcmpi('recording_dir', varargin{ii})
    	% 	recording_dir = varargin{ii+1};
    	if strcmpi('project_dir', varargin{ii})
    		project_dir = varargin{ii+1};
    	elseif strcmpi('mc_reference_frame', varargin{ii})
    		mc_reference_frame = varargin{ii+1};
    	elseif strcmpi('overwrite', varargin{ii})
    		overwrite = varargin{ii+1};
        % elseif strcmpi('export_mc_tiff', varargin{ii})
        %     export_mc_tiff = varargin{ii+1};
        end
    end

    % Main contents
    % Set file names for outputs
    [filepath, filename_wo_ext, fileext] = fileparts(file_fullpath);
    file_fullpath_wo_ext = fullfile(filepath, filename_wo_ext);
    gpio_file = [file_fullpath_wo_ext, '.gpio'];
    file_fullpath_wo_ext_output = fullfile(project_dir, filename_wo_ext);
    pp_file_output = [file_fullpath_wo_ext_output, '-PP.isxd'];  
    bp_file_output = [file_fullpath_wo_ext_output, '-PP-BP.isxd'];  
    mc_file_output = [file_fullpath_wo_ext_output, '-PP-BP-MC.isxd'];  
    % mc_trans_file_output = [file_fullpath_wo_ext_output, '-PP-BP-MC-trans.isxd']; % translation info of motion correction
    mc_crop_file_output = [file_fullpath_wo_ext_output, '-PP-BP-MC-crop.isxd']; % crop rectangle info applied to the motion corrected movie
    dff_file_output = [file_fullpath_wo_ext_output, '-PP-BP-MC-DFF.isxd'];  
    gpio_file_output = [file_fullpath_wo_ext_output, '.gpio']; 

    % process files with preprocess
    if ~exist(pp_file_output, 'file') || overwrite == true
    	isx.preprocess(file_fullpath, pp_file_output,...
    		'temporal_downsample_factor', 1, 'spatial_downsample_factor', 1);
    	disp([' - Output: ', pp_file_output])
    end

    % process files with bandpass filter
    if ~exist(bp_file_output, 'file') || overwrite == true
    	isx.spatial_filter(pp_file_output, bp_file_output,...
    		'low_cutoff', 0.005, 'high_cutoff', 0.5);
    	disp([' - Output: ', bp_file_output])
    end

    % Motion correct the movies using the xth frame as a reference frame
    if ~exist(mc_file_output, 'file') || overwrite == true
    	isx.motion_correct(bp_file_output, mc_file_output,...
			'max_translation', 20,...
			'reference_segment_index', 0, 'reference_frame_index', mc_reference_frame,...
			'global_registration_weight', 1);
    	disp([' - Output: ', mc_file_output])
    end

    % Run dF/F on the motion corrected movies
    if ~exist(dff_file_output, 'file') || overwrite == true
    	isx.dff(mc_file_output, dff_file_output,...
			'f0_type', 'mean');
    	disp([' - Output: ', dff_file_output])
    end

    % copy the GPIO file to output folder if it is not there
    if ~exist(gpio_file_output, 'file')
    	copyfile(gpio_file, gpio_file_output);
    	disp([' - Output: ', gpio_file_output])
    end
end

