function Ypatch = load_local_patch_data(folderPath, patch_pos, frame_range)
    % Read the CNMFe patch data in the subfoler
    % Original CNMFe code locate the patch data using obj.P.mat_file, which contains the path when CNMFe processing took place. 
    % This is an alternative function of 'load_patch_data' in Sources2D
    % It finds the patch data in the subfolder of the recording folder

    patchDataPath = getLocalPatchData(folderPath);

    mat_data = matfile(patchDataPath);  % Create a matfile object
    dims = mat_data.dims;  % Access the 'dims' variable

    d1 = dims(1);
    d2 = dims(2);
    T = dims(3);
    if ~exist('patch_pos', 'var') || isempty(patch_pos)
        patch_pos = [1, d1, 1, d2];
    end
    if ~exist('frame_range', 'var') || isempty(frame_range)
        frame_range = [1, T];
    end
    Ypatch = get_patch_data(mat_data, patch_pos, frame_range, false);
    Ypatch(isnan(Ypatch)) = 0;
end