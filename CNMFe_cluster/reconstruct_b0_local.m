function b0_ = reconstruct_b0_local(obj, folderPath)

% Alternative to 'reconstruct_b0' in Sources2D
% Use the local patch data


    try
        % Get the patch data from a recording folder
        patchDataPath = getLocalPatchData(folderPath);

        mat_data = matfile(patchDataPath);  % Create a matfile object

        % dimension of data
        dims = mat_data.dims;
        d1 = dims(1);
        d2 = dims(2);
        T = dims(3);
        obj.options.d1 = d1;
        obj.options.d2 = d2;
        
        % parameters for patching information
        patch_pos = mat_data.patch_pos;
        % number of patches
        [nr_patch, nc_patch] = size(patch_pos);
    catch
        error('No data file selected');
        b0_= [];
        return;
    end
    
    b0_ = zeros(d1, d2);
    for mpatch=1:(nr_patch*nc_patch)
        b0_patch = obj.b0{mpatch};
        tmp_patch = patch_pos{mpatch};
        r0 = tmp_patch(1);
        r1 = tmp_patch(2);
        c0 = tmp_patch(3);
        c1 = tmp_patch(4);
        b0_(r0:r1, c0:c1) = reshape(b0_patch, r1-r0+1, c1-c0+1);
    end
end