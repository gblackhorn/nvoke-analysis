function [matrix_data] = organize_multiple_range_data_from_one_vector_in_matrix(vector_data,range_start_end_idx)
    % Use a n*2 array, range_start_end_idx, as windows to get the contents in a vector, vector_data.
    % Concatenate these small vectors with diferent lengts by padding with NaN

    
    range_start = range_start_end_idx(:, 1);
    range_end = range_start_end_idx(:, 2);
    window_num = length(range_start);
    matrix_data_cell = cell(1, window_num);

    % Get the vector_data in a range defined by range_start and rang_end. Store it in a cell in 'matrix_data_cell'
    for wn = 1:window_num
    	matrix_data_cell{wn} = vector_data(range_start(wn):range_end(wn));
    end

    % Convert matrix_data_cell to a matrix, fill the short arrays with NaN
    if window_num ==1
        matrix_data = matrix_data_cell{1};
    else
        matrix_data = padcat(matrix_data_cell{:});
    end
end

