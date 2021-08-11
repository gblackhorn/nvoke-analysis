function [single_recording_fov_loc,varargout] = organize_add_fov_loc_info(single_recording,varargin)
    % add field of view (FOV) location information to recording data
    % FOV location: hemisphere related to 

    % Defaults
    loc_opt.hemi = {'left', 'right'}; % hemisphere: IO with chrimsonR (pos) or without (neg)
    loc_opt.hemi_ext = {'chR-pos', 'chR-neg'}; % hemisphere: IO with chrimsonR (pos) or without (neg)
    loc_opt.ml = {'medial', 'lateral'}; % medial lateral
    loc_opt.ap = {'anterior', 'intermediate', 'posterior'}; % anterior poterior. intermediate is not well defined in the experiment
    modify_info = 'yes'; % yes, no or ask. modify the FOV location information if it exists.

    name_col = 1; % column idx of recording name
    stim_col = 3; % column idx of stimulation name
    fov_col = 2; % column idx where FOV location info will be saved to. 

    % Optionals
    for ii = 1:2:(nargin-1)
    	if strcmpi('loc_opt', varargin{ii})
    		loc_opt = varargin{ii+1};
    	% elseif strcmpi('hemi_ext_loc_opt', varargin{ii})
    	% 	hemi_ext_loc_opt = varargin{ii+1};
    	% elseif strcmpi('ml_loc_opt', varargin{ii})
    	% 	ml_loc_opt = varargin{ii+1};
    	% elseif strcmpi('ap_loc_opt', varargin{ii})
    	% 	ap_loc_opt = varargin{ii+1};
    	elseif strcmpi('modify_info', varargin{ii})
    		modify_info = varargin{ii+1};
    	end
    end

    % Main contents
    write_info = 0; 
    rec_name = single_recording{name_col}(1:15);
    rec_stim = char(single_recording{stim_col}); 
    fprintf('recording: %s\t stimulation: %s', rec_name, rec_stim);
    if isfield(single_recording{fov_col}, 'FOV_loc')
    	fprintf('\n\tFOV_loc info exists: %s hemisphere (%s), %s-%s',...
    		single_recording{fov_col}.FOV_loc.hemi, single_recording{fov_col}.FOV_loc.hemi_ext,...
    		single_recording{fov_col}.FOV_loc.ap, single_recording{fov_col}.FOV_loc.ml);
    	if strcmpi(modify_info, 'yes')
    		write_info = 1;
        elseif strcmpi(modify_info, 'no')
            varargout{1} = single_recording{fov_col}.FOV_loc;
        elseif strcmpi(modify_info, 'ask')
            mod_choice = input(sprintf('\n\tmodify the FOV location info? (y)yes/ (n)no [default-n]'), 's');
            if isempty(mod_choice)
                mod_choice = 'n'; 
            end
            if strcmpi(mod_choice, 'y')
                write_info = 1;
            elseif strcmpi(mod_choice, 'n')
                varargout{1} = single_recording{fov_col}.FOV_loc;
                write_info = 0; 
            end
    	end
    else
    	write_info = 1;
    end

    single_recording_fov_loc = single_recording;

    if write_info
    	FOV_loc = struct;
    	field_names = fieldnames(loc_opt);
    	field_num = numel(field_names);
    	
        fprintf('\n\tInput FOV location information. choose locations for:\n')
    	for nOpt = 1:field_num
    		sub_opt = getfield(loc_opt, field_names{nOpt});
    		sub_opt = [sub_opt, 'N/A'];
    		prompt_str = [];
    		for n = 1:numel(sub_opt)
    			prompt_str = [prompt_str, sprintf('(%d)%s/', n, sub_opt{n})];
    		end
    		
    		input_prompt = sprintf('\t\t- %s - %s [default-%d]: ',...
    			field_names{nOpt}, prompt_str, n);
    		choice = input(input_prompt);
    		if isempty(choice)
    			choice = n;
    		end
    		FOV_loc = setfield(FOV_loc, field_names{nOpt}, sub_opt{choice});
    	end
    	single_recording_fov_loc{fov_col}.FOV_loc = FOV_loc;	
        varargout{1} = FOV_loc;
    else
        fprintf('\tFOV location information not written');
    end
end

