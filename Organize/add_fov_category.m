function [rec_data,varargout] = add_fov_category(rec_data,varargin)
	% Read FOV_loc information of each recording, classify them and add the fov_category to the FOV_loc in recdata 

	% Defaults
	hemi_sort = 'hemi_ext'; % 'hemi' or 'hemi_ext'. field in fov_info to sort fovs. 
	fov_contents.hemi = {'left', 'right'};
	fov_contents.hemi_ext = {'chR-pos', 'chR_neg'};
	fov_contents.ml = {'medial', 'lateral'};
	fov_contents.ap = {'anterior', 'intermediate', 'posterior'};

	% Optionals
	for ii = 1:2:(nargin-1)
		if strcmpi('hemi_sort', varargin{ii})
			hemi_sort = varargin{ii+1};
		elseif strcmpi('fov_contents', varargin{ii})
			fov_contents = varargin{ii+1};
		end
	end

	rec_num = size(rec_data, 1);
	fovIDs = cell(rec_num, 1);
	for ii = 1:rec_num
		if isfield(rec_data{ii, 2}, 'FOV_loc');
			rec_name = char(rec_data{ii, 1});
			FOV_loc = rec_data{ii, 2}.FOV_loc;
			[fov_category,fov_contents,hemi_sort] = get_fov_category(FOV_loc,...
				'hemi_sort', hemi_sort, 'fov_contents', fov_contents);
			fovIDs{ii} = sprintf('fov-%d', fov_category);
			rec_data{ii, 2}.fovID = fovIDs{ii};
			
		else
			rec_name = char(rec_data{ii, 1});
			fprintf('"FOV_loc" is not found in recording %s\n', rec_name);
			break
		end
	end		
	varargout{1} = fovIDs;
	varargout{2} = hemi_sort;
end