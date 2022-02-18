function [fov_category,varargout] = get_fov_category(fov_info, varargin)
	% The category of fov based on its location
	% fov_info is a struct containing fields: hemi, hemi_ext, ml, ap

	% Defaults
	hemi_sort = 'hemi_ext'; % 'hemi' or 'hemi_ext'. field in fov_info to sort fovs. 

	fov_contents.hemi = {'left', 'right'};
	fov_contents.hemi_ext = {'chR-pos', 'chR_neg'};
	fov_contents.ml = {'medial', 'lateral'};
	fov_contents.ap = {'anterior', 'intermediate', 'posterior'};

	hemi_variety_num = numel(fov_contents.hemi);
	hemi_ext_variety_num = numel(fov_contents.hemi_ext);
	ml_variety_num = numel(fov_contents.ml);
	ap_variety_num = numel(fov_contents.ap);

	% Optionals
	for ii = 1:2:(nargin-1)
		if strcmpi('hemi_sort', varargin{ii})
			hemi_sort = varargin{ii+1};
		elseif strcmpi('fov_contents', varargin{ii})
			fov_contents = varargin{ii+1};
		% elseif strcmpi('hemi_ext_variety_num', varargin{ii})
		% 	hemi_ext_variety_num = varargin{ii+1};
		% elseif strcmpi('ml_variety_num', varargin{ii})
		% 	ml_variety_num = varargin{ii+1};
		% elseif strcmpi('ap_variety_num', varargin{ii})
		% 	ap_variety_num = varargin{ii+1};
		% elseif strcmpi('stim_winT', varargin{ii})
		% 	setting.stim_winT = varargin{ii+1};
		end
	end

	if strcmpi(hemi_sort, 'hemi')
		hemi_contents = fov_contents.hemi;
		hemi_variety_num = hemi_variety_num;
		hemi_info = fov_info.hemi;
	elseif strcmpi(hemi_sort, 'hemi_ext')
		hemi_contents = fov_contents.hemi_ext;
		hemi_variety_num = hemi_ext_variety_num;
		hemi_info = fov_info.hemi_ext;
	end

	fov_cat_num = ap_variety_num*ml_variety_num*hemi_variety_num;

	fov_hemi_code = find(strcmpi(hemi_info, hemi_contents));
	fov_ml_code = find(strcmpi(fov_info.ml, fov_contents.ml));
	fov_ap_code = find(strcmpi(fov_info.ap, fov_contents.ap));

	if isempty(fov_hemi_code)
		error('%s information "%s" is not registered in FOV categories', hemi_sort, hemi_info);
	end
	if isempty(fov_ml_code)
		error('ml information "%s" is not registered in FOV categories', fov_contents.ml);
	end
	if isempty(fov_ap_code)
		error('ap information "%s" is not registered in FOV categories', fov_contents.ap);
	end

	fov_category = (fov_hemi_code-1)*ml_variety_num*ap_variety_num+(fov_ml_code-1)*ap_variety_num+fov_ap_code;

	varargout{1} = fov_contents;
	varargout{2} = hemi_sort;
end