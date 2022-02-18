function [gpio_info_modified, varargout] = delete_false_gpio_info(gpio_info, varargin)
    % Delete false GPIO information imported from gpio.csv

    % Defaults
    ogled_thr = 0.8; % standard signal exported by nVoke is 1
    gpio1_thr = 10000; % standard signal exported by nVoke is higher than 50'000
    digitalGPO_thr = 0.8;

    discard_gpio_idx = [];
    channel_num = numel(gpio_info); 

    for i = 3:channel_num % 'BNC Sync Output' and 'EX-LED' are the first 2. Not stimulation channels
        ch_name = gpio_info(i).name{:};
        signal_max = max(gpio_info(i).time_value(:, 2));

        if ~isempty(strfind(ch_name, 'OG-LED'))
            if signal_max < ogled_thr
                discard_gpio_idx = [discard_gpio_idx i];
            end
        elseif ~isempty(strfind(ch_name, 'Digital GPO'))
            if signal_max < digitalGPO_thr
                discard_gpio_idx = [discard_gpio_idx i];
            end
        elseif ~isempty(strfind(ch_name, 'GPIO'))
            if signal_max < gpio1_thr
                discard_gpio_idx = [discard_gpio_idx i];
            end
        end
    end

    gpio_info(discard_gpio_idx) = [];
    gpio_info_modified = gpio_info;
    varargout{1} = discard_gpio_idx;
end

