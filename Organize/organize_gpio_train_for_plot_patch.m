function [stim_ch_patch] = organize_gpio_train_for_plot_patch(stim_ch_time_range)
    % Input a 2-column matrix (gpio_train_start_time, gpio_train_end_time) and
    % return a 2-column matrix (x, y) for plotting stimulation with patch func
    %   Detailed explanation goes here
    
    gpio_train_start_time = stim_ch_time_range(:, 1);
    gpio_train_end_time = stim_ch_time_range(:, 2);

    % organize gpio info for plotting patches for the durations of stim_trains
    gpio_train_num = size(stim_ch_time_range, 1);
    for tn = 1:gpio_train_num % loop through gpio trains
    	stim_ch_patch((tn-1)*4+1, 1) = gpio_train_start_time(tn);
    	stim_ch_patch((tn-1)*4+2, 1) = gpio_train_start_time(tn);
    	stim_ch_patch((tn-1)*4+3, 1) = gpio_train_end_time(tn);
    	stim_ch_patch((tn-1)*4+4, 1) = gpio_train_end_time(tn);

    	stim_ch_patch((tn-1)*4+1, 2) = 0;
    	stim_ch_patch((tn-1)*4+2, 2) = 1;
    	stim_ch_patch((tn-1)*4+3, 2) = 1;
    	stim_ch_patch((tn-1)*4+4, 2) = 0;
    end
end

