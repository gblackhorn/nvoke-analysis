function remove_cnmfe_output
% Remove cnmfe generated files for a new process
% Be extra careful. This code will eliminate the CNMFe output in the
% subfolders of the selected location

dir_path_clear = '/flash/UusisaariU/GD';
keywords_file = {'*contours*', '*results.mat'};
keywords_dir = {'*source_extraction*'};

dir_path_clear = uigetdir(dir_path_clear,...
	'Warning: about to delete objects in the subfolders!');
if dir_path_clear ~= 0

	rm_subdir_files('dir_path', dir_path_clear,...
		'keywords_file', keywords_file, 'keywords_dir', keywords_dir);
    sprintf('CNMFe ouput in subfolders of the following location has been deleted: \n %s',dir_path_clear);
else
	fprintf('folder not selected')
	return
end