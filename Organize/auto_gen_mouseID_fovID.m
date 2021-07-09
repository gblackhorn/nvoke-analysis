function [rec_data,varargout] = auto_gen_mouseID_fovID(rec_data,varargin)
	% Automatic generate mouseIDs and fovIDs according to date

	rec_name_col = 1;
	rec_data_col = 2;


	% Defaults
	overwrite = false;
	generate = false;

	hemi_sort = 'hemi_ext'; % 'hemi' or 'hemi_ext'. field in fov_info to sort fovs. 
	fov_contents.hemi = {'left', 'right'};
	fov_contents.hemi_ext = {'chR-pos', 'chR_neg'};
	fov_contents.ml = {'medial', 'lateral'};
	fov_contents.ap = {'anterior', 'intermediate', 'posterior'};

	% Optionals
	for ii = 1:2:(nargin-1)
    	if strcmpi('overwrite', varargin{ii})
    		overwrite = varargin{ii+1};
    	elseif strcmpi('hemi_sort', varargin{ii})
    		hemi_sort = varargin{ii+1};
    	elseif strcmpi('fov_contents', varargin{ii})
    		fov_contents = varargin{ii+1};
    	% elseif strcmpi('stim_winT', varargin{ii})
    	% 	setting.stim_winT = varargin{ii+1};
    	end
    end

    % Main content
    data_1st_rec_trial = rec_data{1, rec_data_col}; % Check the existence of mouseID and fovID in the first recording
    TF_mouseID = isfield(data_1st_rec_trial, 'mouseID'); % mouseID true/false
    TF_fovID = isfield(data_1st_rec_trial, 'fovID'); % fovID true/false

    if overwrite
    	generate = true;
    else
    	if ~TF_mouseID || ~TF_fovID
    		generate = true;
    	elseif TF_mouseID && TF_fovID
    		if isempty(TF_mouseID) || isempty(TF_fovID)
    			generate = true;
            end
    	end
    end

    if generate

		[rec_data, mouseIDs] = add_mouse_ID(rec_data);
		[rec_data, fovIDs] = add_fov_category(rec_data,...
			'hemi_sort', hemi_sort, 'fov_contents', fov_contents);

		varargout{1} = mouseIDs;
		varargout{2} = fovIDs;
	end
end