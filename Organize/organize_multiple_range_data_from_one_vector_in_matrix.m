function [matrix_data] = organize_multiple_range_data_from_one_vector_in_matrix(vector_data,range_start_end_idx)
    % Accquire multiple windows of data from a vector using "range_start" (a
    % vector containing index) and "range_end" to creat a matrix, within which
    % each column includs data from one window. Shorter column is felt by NaN
    %   Detailed explanation goes here
    
    range_start = range_start_end_idx(:, 1);
    range_end = range_start_end_idx(:, 2);
    window_num = length(range_start);
    matrix_data_cell = cell(1, window_num);

    % fill trace data in each window in window_idx_cell
    for wn = 1:window_num
    	matrix_data_cell{wn} = roi_trace(range_start(wn):range_end(wn));
    end

    % convert roi_trace_window_cell to a matrix, fill the short arrays with NaN
    matrix_data = padcat(matrix_data_cell{:});
end

