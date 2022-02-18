function [fov] = get_fov_info(rec_data,varargin)
	% Return Field of View (FOV) information in a readable way
	% Require 'FOV_loc' field in the second column of recording data (rec_data)

	rec_name = char(rec_data{1});
	try
		fov_data = rec_data{2}.FOV_loc;
		fov = sprintf('%s hemisphere, %s side, \nmedial-lateral: %s, anterial-posterial: %s',...
		fov_data.hemi, fov_data.hemi_ext, fov_data.ml, fov_data.ap);
	catch
		warning('Recording "%s" does not have FOV information', rec_name);
        fov = [];
	end
end